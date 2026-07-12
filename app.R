# =====================================================
# Global Maritime Piracy Monitor
# Bachelor Thesis
#
# Script: app.R
# Purpose: Interactive Shiny/Leaflet dashboard for
#          maritime piracy incidents
# Author: Maximilian Dick
# =====================================================

library(shiny)
library(leaflet)
library(dplyr)
library(tidyr)
library(stringr)
library(sf)
library(units)

piracy_data <- readRDS(file.path("data", "piracy_mappable_2010_2025.rds"))
ports_data <- readRDS(file.path("data", "ports_processed.rds"))

piracy_data <- piracy_data %>%
  mutate(
    region = str_squish(region),
    incident_type = str_squish(incident_type),
    waters_type = str_squish(waters_type)
  )

ports_sf <- ports_data %>%
  filter(!is.na(longitude), !is.na(latitude)) %>%
  st_as_sf(
    coords = c("longitude", "latitude"),
    crs = 4326,
    remove = FALSE
  )

month_lookup <- expand.grid(
  year = 2010:2025,
  month = 1:12
) %>%
  arrange(year, month) %>%
  mutate(
    month_index = row_number(),
    label = sprintf("%04d-%02d", year, month)
  )

incident_colors <- colorFactor(
  palette = c(
    "Hijacking / Kidnapping" = "#e31a1c",
    "Armed Robbery" = "#ff7f00",
    "Boarding / Theft" = "#ffd700",
    "Attempted Attack / Attempted Boarding" = "#1f78b4",
    "Suspicious Approach / Suspicious Craft" = "#ffffff",
    "Fired Upon / Under Fire" = "#984ea3",
    "Unknown / Unclassified" = "#999999"
  ),
  domain = piracy_data$incident_type,
  na.color = "#999999"
)

get_basemap_provider <- function(basemap) {
  switch(
    basemap,
    "CartoDB.DarkMatter" = providers$CartoDB.DarkMatter,
    "CartoDB.DarkMatterNoLabels" = providers$CartoDB.DarkMatterNoLabels,
    "CartoDB.Positron" = providers$CartoDB.Positron,
    "CartoDB.PositronNoLabels" = providers$CartoDB.PositronNoLabels,
    "CartoDB.Voyager" = providers$CartoDB.Voyager,
    "CartoDB.VoyagerNoLabels" = providers$CartoDB.VoyagerNoLabels,
    "Esri.WorldImagery" = providers$Esri.WorldImagery,
    "Esri.NatGeoWorldMap" = providers$Esri.NatGeoWorldMap,
    "Esri.WorldStreetMap" = providers$Esri.WorldStreetMap,
    providers$CartoDB.DarkMatter
  )
}

get_hex_cellsize <- function(zoom) {
  if (is.null(zoom)) return(250000)
  if (zoom <= 3) {
    250000
  } else if (zoom <= 5) {
    100000
  } else if (zoom <= 7) {
    50000
  } else {
    25000
  }
}

create_hex_layer <- function(df, cellsize = 250000) {
  if (nrow(df) == 0) return(NULL)

  df <- df %>%
    filter(!is.na(lon_dd), !is.na(lat_dd)) %>%
    mutate(incident_uid = row_number())

  if (nrow(df) == 0) return(NULL)

  points_sf <- st_as_sf(
    df,
    coords = c("lon_dd", "lat_dd"),
    crs = 4326,
    remove = FALSE
  )

  points_proj <- st_transform(points_sf, 6933)

  hex_grid <- st_make_grid(
    st_union(points_proj),
    cellsize = cellsize,
    square = FALSE
  ) %>%
    st_sf(hex_id = seq_along(.), geometry = .)

  joined <- st_join(hex_grid, points_proj, join = st_intersects)

  hex_counts <- joined %>%
    st_drop_geometry() %>%
    group_by(hex_id) %>%
    summarise(
      n_incidents = sum(!is.na(incident_uid)),
      .groups = "drop"
    )

  hex_data <- hex_grid %>%
    left_join(hex_counts, by = "hex_id") %>%
    mutate(n_incidents = replace_na(n_incidents, 0)) %>%
    filter(n_incidents > 0)

  if (nrow(hex_data) == 0) return(NULL)
  st_transform(hex_data, 4326)
}

ui <- fluidPage(
  tags$head(
    tags$style(
      HTML("
        html, body {
          width: 100%;
          height: 100%;
          margin: 0;
          padding: 0;
          overflow: hidden;
        }

        #piracy_map {
          height: 100vh !important;
        }

        .control-panel {
          position: absolute;
          top: 20px;
          left: 60px;
          z-index: 9999;
          background: rgba(255,255,255,0.88);
          padding: 15px;
          border-radius: 12px;
          box-shadow: 0 2px 15px rgba(0,0,0,0.25);
          width: 360px;
          max-height: calc(100vh - 40px);
          overflow-y: auto;
          box-sizing: border-box;
          backdrop-filter: blur(6px);
        }

        .awesome-marker {
          transform: scale(0.65);
          transform-origin: bottom center;
        }

        .summary-warning,
        .summary-warning table,
        .summary-warning th,
        .summary-warning td {
          color: #c62828 !important;
        }

        .summary-warning table {
          border-color: rgba(198, 40, 40, 0.35) !important;
        }

        .summary-warning-note {
          margin-top: 8px;
          font-weight: 700;
          font-size: 14px;
          color: #c62828;
        }
      ")
    )
  ),

  div(
    class = "control-panel",
    h2("Global Maritime Piracy Monitor"),

    radioButtons(
      "time_mode",
      "Temporal View:",
      choices = c(
        "All (2010-2025)" = "all",
        "Yearly" = "yearly",
        "Monthly" = "monthly"
      ),
      selected = "all",
      inline = TRUE
    ),

    selectInput(
      "basemap",
      "Basemap:",
      choices = c(
        "Dark Matter" = "CartoDB.DarkMatter",
        "Dark Matter (No Labels)" = "CartoDB.DarkMatterNoLabels",
        "Positron" = "CartoDB.Positron",
        "Positron (No Labels)" = "CartoDB.PositronNoLabels",
        "Voyager" = "CartoDB.Voyager",
        "Voyager (No Labels)" = "CartoDB.VoyagerNoLabels",
        "ESRI World Imagery" = "Esri.WorldImagery",
        "ESRI NatGeo" = "Esri.NatGeoWorldMap",
        "ESRI World Street Map" = "Esri.WorldStreetMap"
      ),
      selected = "CartoDB.DarkMatter"
    ),

    conditionalPanel(
      condition = "input.time_mode == 'yearly'",
      sliderInput(
        "year_filter",
        "Select Year:",
        min = 2010,
        max = 2025,
        value = 2025,
        step = 1,
        sep = "",
        animate = animationOptions(interval = 1200, loop = TRUE)
      )
    ),

    conditionalPanel(
      condition = "input.time_mode == 'monthly'",
      sliderInput(
        "month_index_filter",
        "Select Month:",
        min = 1,
        max = nrow(month_lookup),
        value = nrow(month_lookup),
        step = 1,
        sep = "",
        animate = animationOptions(interval = 700, loop = TRUE)
      ),
      strong(textOutput("selected_month_label"))
    ),

    selectInput(
      "incident_filter",
      "Incident Type:",
      choices = c("All", sort(unique(na.omit(piracy_data$incident_type)))),
      selected = "All"
    ),

    selectInput(
      "region_filter",
      "Region:",
      choices = c("All", sort(unique(na.omit(piracy_data$region)))),
      selected = "All"
    ),

    selectInput(
      "waters_filter",
      "Waters Type:",
      choices = c("All", sort(unique(na.omit(piracy_data$waters_type)))),
      selected = "All"
    ),

    checkboxInput(
      "show_hexagons",
      "Show Hexagon Aggregation",
      value = FALSE
    ),

    checkboxInput(
      "show_ports",
      "Show Ports within 100 km of Incidents",
      value = FALSE
    ),

    br(),
    uiOutput("summary_section")
  ),

  leafletOutput("piracy_map", width = "100%", height = "100vh")
)

server <- function(input, output, session) {

  selected_month <- reactive({
    month_lookup %>%
      filter(month_index == input$month_index_filter) %>%
      slice(1)
  })

  output$selected_month_label <- renderText({
    paste("Selected Month:", selected_month()$label)
  })

  filtered_data <- reactive({
    df <- piracy_data

    if (input$time_mode == "yearly") {
      df <- df %>% filter(year == input$year_filter)
    }

    if (input$time_mode == "monthly") {
      selected <- selected_month()
      df <- df %>%
        filter(year == selected$year, month == selected$month)
    }

    if (input$incident_filter != "All") {
      df <- df %>% filter(incident_type == input$incident_filter)
    }

    if (input$region_filter != "All") {
      df <- df %>% filter(region == input$region_filter)
    }

    if (input$waters_filter != "All") {
      df <- df %>% filter(waters_type == input$waters_filter)
    }

    df
  })

  nearby_ports <- reactive({
    incidents <- filtered_data()

    if (nrow(incidents) == 0 || nrow(ports_sf) == 0) {
      return(ports_sf[0, ])
    }

    incidents_sf <- incidents %>%
      filter(!is.na(lon_dd), !is.na(lat_dd)) %>%
      st_as_sf(
        coords = c("lon_dd", "lat_dd"),
        crs = 4326,
        remove = FALSE
      )

    if (nrow(incidents_sf) == 0) return(ports_sf[0, ])

    port_matches <- st_is_within_distance(
      ports_sf,
      incidents_sf,
      dist = set_units(100, "km")
    )

    ports_sf[lengths(port_matches) > 0, ]
  })

  output$piracy_map <- renderLeaflet({
    df <- filtered_data()
    selected_provider <- get_basemap_provider(input$basemap)

    map <- leaflet() %>% addProviderTiles(selected_provider)

    if (nrow(df) == 0) {
      return(map %>% setView(lng = 20, lat = 10, zoom = 2))
    }

    if (!input$show_hexagons) {
      map <- map %>%
        addCircleMarkers(
          data = df,
          lng = ~lon_dd,
          lat = ~lat_dd,
          radius = 2.5,
          stroke = TRUE,
          color = "#111111",
          weight = 0.5,
          fillColor = ~incident_colors(incident_type),
          fillOpacity = 0.85,
          popup = ~paste0(
            "<b>Date:</b> ", date_raw, "<br>",
            "<b>Ship:</b> ", ship_name, "<br>",
            "<b>Incident:</b> ", incident_type, "<br>",
            "<b>Region:</b> ", region, "<br>",
            "<b>Waters:</b> ", waters_type
          )
        ) %>%
        addLegend(
          position = "bottomright",
          pal = incident_colors,
          values = piracy_data$incident_type,
          title = "Incident Type",
          opacity = 0.9
        )
    }

    if (input$show_hexagons) {
      current_cellsize <- get_hex_cellsize(input$piracy_map_zoom)
      hex_data <- create_hex_layer(df = df, cellsize = current_cellsize)

      if (!is.null(hex_data) && nrow(hex_data) > 0) {
        hex_pal <- colorNumeric(
          palette = "YlOrRd",
          domain = hex_data$n_incidents
        )

        map <- map %>%
          addPolygons(
            data = hex_data,
            fillColor = ~hex_pal(n_incidents),
            fillOpacity = 0.75,
            color = "#444444",
            weight = 0.15,
            popup = ~paste0(
              "<b>Incidents in Hexagon:</b> ",
              n_incidents
            )
          ) %>%
          addLegend(
            position = "bottomright",
            pal = hex_pal,
            values = hex_data$n_incidents,
            title = paste0(
              "Incidents per ",
              round(current_cellsize / 1000),
              " km hexagon"
            ),
            opacity = 0.9
          )
      }
    }

    if (input$show_ports) {
      ports_to_show <- nearby_ports()

      if (nrow(ports_to_show) > 0) {
        ports_to_show_df <- ports_to_show %>%
          st_drop_geometry() %>%
          mutate(
            port_size_clean = str_to_lower(port_size),
            marker_color = case_when(
              port_size_clean == "small" ~ "lightgray",
              port_size_clean == "minor" ~ "cadetblue",
              port_size_clean == "major" ~ "orange",
              TRUE ~ "lightgray"
            )
          )

        port_icons <- awesomeIcons(
          icon = "anchor",
          library = "fa",
          markerColor = ports_to_show_df$marker_color,
          iconColor = "white"
        )

        map <- map %>%
          addAwesomeMarkers(
            data = ports_to_show_df,
            lng = ~longitude,
            lat = ~latitude,
            icon = port_icons,
            popup = ~paste0(
              "<b>Port:</b> ", port_name, "<br>",
              "<b>Country:</b> ", port_country, "<br>",
              "<b>State:</b> ", port_state, "<br>",
              "<b>Port size:</b> ", port_size, "<br>",
              "<b>Max vessel size:</b> ", max_vessel_size
            )
          ) %>%
          addLegend(
            position = "bottomright",
            colors = c("#bdbdbd", "#2ec4b6", "#ff9f1c"),
            labels = c("Small", "Minor", "Major"),
            title = "Ports",
            opacity = 0.9
          )
      }
    }

    map %>%
      fitBounds(
        lng1 = min(df$lon_dd, na.rm = TRUE),
        lat1 = min(df$lat_dd, na.rm = TRUE),
        lng2 = max(df$lon_dd, na.rm = TRUE),
        lat2 = max(df$lat_dd, na.rm = TRUE)
      )
  })

  output$summary_section <- renderUI({
    incomplete_year <- (
      input$time_mode == "yearly" &&
        input$year_filter >= 2021
    )

    if (incomplete_year) {
      div(
        class = "summary-warning",
        tableOutput("summary_table"),
        div(
          class = "summary-warning-note",
          "* Incomplete data basis"
        )
      )
    } else {
      div(tableOutput("summary_table"))
    }
  })

  output$summary_table <- renderTable({
    df <- filtered_data()

    if (nrow(df) == 0) {
      return(data.frame(Metric = "Total Incidents", Value = 0))
    }

    most_common_incident <- df %>%
      count(incident_type, sort = TRUE) %>%
      slice(1) %>%
      pull(incident_type)

    most_common_region <- df %>%
      count(region, sort = TRUE) %>%
      slice(1) %>%
      pull(region)

    most_common_waters <- df %>%
      count(waters_type, sort = TRUE) %>%
      slice(1) %>%
      pull(waters_type)

    data.frame(
      Metric = c(
        "Total Incidents",
        "Most Common Incident Type",
        "Most Common Region",
        "Most Common Waters Type",
        "Unique Regions",
        "Unique Incident Types"
      ),
      Value = c(
        nrow(df),
        most_common_incident,
        most_common_region,
        most_common_waters,
        length(unique(df$region)),
        length(unique(df$incident_type))
      )
    )
  })
}

shinyApp(ui = ui, server = server)
