"""
00_build_piracy_master_dataset.py

Workflow for creating a GIS-ready master dataset from annual IMO piracy
reports provided as PDF files.

Requirements:
    pip install pandas openpyxl pdfplumber

Directory structure:
    reports/
    ├── 2010/
    ├── 2011/
    ├── ...
    ├── 2025/
    └── 00_build_piracy_master_dataset.py

Output files:
    reports/_output/piracy_master_final_documented.xlsx
    reports/_output/piracy_master_final_documented.csv
    reports/_output/piracy_master_quality_report.xlsx
    reports/_output/piracy_monthly_counts.xlsx
"""

from __future__ import annotations

import re
from pathlib import Path
from typing import Optional

import pandas as pd
import pdfplumber


# ============================================================
# 1. Settings
# ============================================================

BASE_FOLDER = Path(r"D:\Studium\6. Semester\Bachelorarbeit\working\data\reports")

OUTPUT_FOLDER = BASE_FOLDER / "_output"
OUTPUT_FOLDER.mkdir(exist_ok=True)

OUTPUT_MASTER_XLSX = OUTPUT_FOLDER / "piracy_master_final_documented.xlsx"
OUTPUT_MASTER_CSV = OUTPUT_FOLDER / "piracy_master_final_documented.csv"
OUTPUT_QA_XLSX = OUTPUT_FOLDER / "piracy_master_quality_report.xlsx"
OUTPUT_MONTHLY_COUNTS_XLSX = OUTPUT_FOLDER / "piracy_monthly_counts.xlsx"


# ============================================================
# 2. Rules and categories
# ============================================================

REGIONS = [
    "EAST AFRICA",
    "WEST AFRICA",
    "ARABIAN SEA",
    "INDIAN OCEAN",
    "MALACCA STRAIT",
    "SOUTH CHINA SEA",
    "SOUTH AMERICA (A)",
    "SOUTH AMERICA (C)",
    "SOUTH AMERICA (P)",
    "MEDITERRANEAN SEA",
]

SHIP_TYPES = [
    "Bulk carrier",
    "Product tanker",
    "Chemical tanker",
    "Tanker",
    "Container ship",
    "General cargo ship",
    "General cargo vessel",
    "General cargo",
    "Vehicle carrier",
    "Ore/bulk/oil Carrier",
    "Ore carrier",
    "LPG tanker",
    "Oil tanker",
    "Fishing vessel",
    "Research ship",
    "Supply ship",
    "Heavy load carrier",
    "Special purpose ship",
    "Rescue/standby ship",
    "Dhow",
    "Tug",
    "Barge",
]

FLAGS = [
    "Panama",
    "Liberia",
    "Singapore",
    "Marshall Islands",
    "Hong Kong, China",
    "Hong Kong",
    "Malta",
    "Cyprus",
    "Bahamas",
    "India",
    "Indonesia",
    "Malaysia",
    "Portugal",
    "United Kingdom",
    "United States",
    "Thailand",
    "Viet Nam",
    "Vietnam",
    "Bangladesh",
    "China",
    "Türkiye",
    "Turkey",
    "Iran",
    "Iran (Islamic Republic of)",
    "Republic of Korea",
    "Korea",
    "Philippines",
    "Libya",
    "Egypt",
    "Denmark",
    "Norway",
    "Belgium",
    "Germany",
    "France",
    "Ghana",
    "Nigeria",
    "Tuvalu",
    "Palau",
    "Curaçao",
    "Sri Lanka",
    "Antigua and Barbuda",
    "Isle of Man",
    "Lao People's Democratic Republic",
    "Japan",
    "Greece",
    "Isle of Man (United Kingdom)",
]

CLASS_RULES = [
    {
        "incident_type": "Hijacking / Kidnapping",
        "incident_code": 1,
        "violence_level": 3,
        "patterns": [
            r"\bhijack(?:ed|ing)?\b",
            r"\bkidnap(?:ped|ping)?\b",
            r"\btaken hostage\b",
            r"\bhostage\b",
            r"\bvessel was hijacked\b",
            r"\bship was hijacked\b",
            r"\bcrew were kidnapped\b",
            r"\bcrew was kidnapped\b",
        ],
    },
    {
        "incident_type": "Fired Upon / Under Fire",
        "incident_code": 6,
        "violence_level": 3,
        "patterns": [
            r"\bfired upon\b",
            r"\bunder fire\b",
            r"\bgunfire\b",
            r"\bexchange of fire\b",
            r"\bshots fired\b",
            r"\bshot at\b",
            r"\bopened fire\b",
            r"\bshoot(?:ing|s|t)?\b",
            r"\bfired on the ship\b",
        ],
    },
    {
        "incident_type": "Armed Robbery",
        "incident_code": 2,
        "violence_level": 2,
        "patterns": [
            r"\brobber(?:s|y)?\b",
            r"\barmed robber(?:y|s)?\b",
            r"\bstole\b",
            r"\bstolen\b",
            r"\btheft\b",
            r"\bengine spares? stolen\b",
            r"\bship'?s stores? stolen\b",
            r"\bcrew personal belongings stolen\b",
            r"\bmanhandled\b",
            r"\btied up\b",
            r"\bassaulted\b",
            r"\bthreatened with\b",
            r"\bknives\b",
            r"\bmachetes\b",
            r"\barmed with knives\b",
            r"\barmed with guns\b",
        ],
    },
    {
        "incident_type": "Boarding / Theft",
        "incident_code": 3,
        "violence_level": 1,
        "patterns": [
            r"\bboard(?:ed|ing)?\b",
            r"\bunauthori[sz]ed persons? onboard\b",
            r"\bintruder(?:s)?\b",
            r"\bperpetrator(?:s)? onboard\b",
            r"\bperpetrator(?:s)? were sighted\b",
            r"\bentered the engine room\b",
            r"\bstores? missing\b",
            r"\bspare parts? missing\b",
            r"\bpadlock .* broken\b",
            r"\bfootprints?\b",
            r"\bproperty missing\b",
            r"\bitems missing\b",
            r"\bnothing was stolen\b",
        ],
    },
    {
        "incident_type": "Attempted Attack / Attempted Boarding",
        "incident_code": 4,
        "violence_level": 1,
        "patterns": [
            r"\battempt(?:ed)?\b",
            r"\battempted attack\b",
            r"\battempted boarding\b",
            r"\baborted the attempted boarding\b",
            r"\baborted the attack\b",
            r"\btrying to board\b",
            r"\bpersons attempting to board\b",
            r"\battempt to board\b",
            r"\bapproached .* using ladders\b",
        ],
    },
    {
        "incident_type": "Suspicious Approach / Suspicious Craft",
        "incident_code": 5,
        "violence_level": 0,
        "patterns": [
            r"\bsuspicious\b",
            r"\bapproached the vessel\b",
            r"\bapproached the ship\b",
            r"\bsmall boat approached\b",
            r"\bcanoe approached\b",
            r"\bskiff approached\b",
            r"\bboat hovering around\b",
            r"\bsuspicious craft\b",
            r"\bsuspicious movements?\b",
        ],
    },
]


# ============================================================
# 3. helper function
# ============================================================

def normalize_text(text: object) -> str:
    if pd.isna(text):
        return ""

    text = str(text)
    text = text.replace("(cid:13)(cid:10)", "\n")
    text = text.replace("(cid:13)", "\n")
    text = text.replace("(cid:10)", "\n")
    text = text.replace("\xa0", " ")
    text = text.replace("’", "'")
    text = text.replace("–", "-")
    text = re.sub(r"[ \t]+", " ", text)
    text = re.sub(r"\n{2,}", "\n", text)
    return text.strip()


def normalize_text_for_classification(text: object) -> str:
    text = normalize_text(text).lower()
    text = re.sub(r"\s+", " ", text)
    return text.strip()


def extract_text_from_pdf(pdf_path: Path) -> str:
    pages: list[str] = []

    with pdfplumber.open(pdf_path) as pdf:
        for page in pdf.pages:
            text = page.extract_text()
            if text:
                pages.append(text)

    return "\n".join(pages)


def dms_to_dd(value: object) -> Optional[float]:
    if pd.isna(value):
        return None

    value = str(value).strip().replace("º", "°")
    if not value:
        return None

    match = re.search(
        r"(\d{1,3})°\s*(\d{1,2}(?:[.,]\d+)?)'?\s*([NSEW])",
        value,
        flags=re.IGNORECASE,
    )

    if not match:
        return None

    deg = float(match.group(1).replace(",", "."))
    minutes = float(match.group(2).replace(",", "."))
    hemi = match.group(3).upper()

    dd = deg + minutes / 60.0

    if hemi in ("S", "W"):
        dd *= -1

    return dd


def extract_lat_raw(text: str) -> Optional[str]:
    match = re.search(
        r"(\d{1,3}°\s*\d{1,2}(?:[.,]\d+)?'?\s*[NS])",
        text,
        flags=re.IGNORECASE,
    )
    return match.group(1) if match else None


def extract_lon_raw(text: str) -> Optional[str]:
    match = re.search(
        r"(\d{1,3}°\s*\d{1,2}(?:[.,]\d+)?'?\s*[EW])",
        text,
        flags=re.IGNORECASE,
    )
    return match.group(1) if match else None


def find_region(text: str) -> Optional[str]:
    text_upper = text.upper()

    for region in REGIONS:
        if region in text_upper:
            return region.title()

    return None


def find_ship_type(text: str) -> Optional[str]:
    for ship_type in SHIP_TYPES:
        if re.search(rf"\b{re.escape(ship_type)}\b", text, flags=re.IGNORECASE):
            return ship_type

    return None


def find_flag(text: str) -> Optional[str]:
    for flag in FLAGS:
        if re.search(rf"\b{re.escape(flag)}\b", text, flags=re.IGNORECASE):
            return flag

    return None


def extract_ship_name(text: str) -> Optional[str]:
    lines = [x.strip() for x in text.split("\n") if x.strip()]
    if not lines:
        return None

    # Old report-type: "1 SHIPNAME"
    match = re.match(r"^\d+\s+(.+)$", lines[0])
    if match:
        candidate = match.group(1).strip()
        candidate = re.split(r"\b\d{2}/\d{2}/\d{4}\b", candidate)[0].strip()
        candidate = re.split(
            r"\b(?:EAST AFRICA|WEST AFRICA|ARABIAN SEA|INDIAN OCEAN|MALACCA STRAIT|SOUTH CHINA SEA|MEDITERRANEAN SEA)\b",
            candidate,
            flags=re.IGNORECASE,
        )[0].strip()
        return candidate or None

    # New Report-Type: single number, shipsname in next line
    if re.match(r"^\d+$", lines[0]) and len(lines) > 1:
        return lines[1].strip()

    return lines[0].strip()


def extract_date(text: str) -> Optional[str]:
    match = re.search(r"(\d{2}/\d{2}/\d{4})", text)
    return match.group(1) if match else None


def extract_time(text: str) -> Optional[str]:
    match = re.search(r"(\d{2}:\d{2})", text)
    return match.group(1) if match else None


def extract_time_zone(text: str) -> Optional[str]:
    match = re.search(r"\b(LT|UTC)\b", text, flags=re.IGNORECASE)
    return match.group(1).upper() if match else None


def estimate_timezone_offset_from_lon(lon: object) -> Optional[int]:
    if pd.isna(lon):
        return None

    try:
        lon_float = float(lon)
    except (TypeError, ValueError):
        return None

    if lon_float < -180 or lon_float > 180:
        return None

    return int(round(lon_float / 15))


def standardize_time_to_local(
    time_value: object,
    time_zone: object,
    lon: object,
) -> tuple[Optional[str], Optional[int], str]:

    if pd.isna(time_value):
        return None, None, "missing_time"

    time_str = str(time_value).strip()
    match = re.search(r"(\d{2}):(\d{2})", time_str)

    if not match:
        return None, None, "invalid_time"

    hour = int(match.group(1))
    minute = int(match.group(2))

    zone = "" if pd.isna(time_zone) else str(time_zone).upper().strip()

    if zone == "LT":
        return f"{hour:02d}:{minute:02d}", 0, "reported_local_time"

    if zone == "UTC":
        offset = estimate_timezone_offset_from_lon(lon)

        if offset is None:
            return f"{hour:02d}:{minute:02d}", None, "utc_no_coordinate_offset"

        local_hour = (hour + offset) % 24
        return f"{local_hour:02d}:{minute:02d}", offset, "converted_from_utc_by_longitude"

    return f"{hour:02d}:{minute:02d}", None, "unknown_time_basis"


def classify_time_period(time_local: object) -> str:
    if pd.isna(time_local):
        return "unknown"

    match = re.search(r"(\d{2}):(\d{2})", str(time_local))

    if not match:
        return "unknown"

    hour = int(match.group(1))

    if 0 <= hour <= 4:
        return "night"
    if 5 <= hour <= 8:
        return "dawn"
    if 9 <= hour <= 17:
        return "day"
    if 18 <= hour <= 21:
        return "dusk"
    if 22 <= hour <= 23:
        return "night"

    return "unknown"


def extract_details(text: str) -> Optional[str]:
    patterns = [
        r"(While .*?)(?=(The crew was|All crew members|Nothing was stolen|Safety navigational|$))",
        r"(Pirates .*?)(?=(The crew was|All crew members|Nothing was stolen|Safety navigational|$))",
        r"(Robbers .*?)(?=(The crew was|All crew members|Nothing was stolen|Safety navigational|$))",
        r"(Perpetrators .*?)(?=(The crew was|All crew members|Nothing was stolen|Safety navigational|$))",
        r"(Armed persons .*?)(?=(The crew was|All crew members|Nothing was stolen|Safety navigational|$))",
        r"(An unknown number .*?)(?=(The crew was|All crew members|Nothing was stolen|Safety navigational|$))",
    ]

    for pattern in patterns:
        match = re.search(pattern, text, flags=re.DOTALL | re.IGNORECASE)

        if match:
            return re.sub(r"\s+", " ", match.group(1)).strip()

    return None


def extract_consequences(text: str) -> Optional[str]:
    patterns = [
        r"(The crew was.*?\.)",
        r"(All crew members.*?\.)",
        r"(Nothing was stolen\.)",
        r"(Ship['’]s .*? stolen\.)",
        r"(.*? were stolen\.)",
        r"(.*? was hijacked\.)",
        r"(.*? were taken hostage\.)",
        r"(The crew was not injured\.)",
        r"(The crew was safe\.)",
    ]

    for pattern in patterns:
        match = re.search(pattern, text, flags=re.DOTALL | re.IGNORECASE)

        if match:
            return re.sub(r"\s+", " ", match.group(1)).strip()

    return None


def extract_action_taken(text: str) -> Optional[str]:
    patterns = [
        r"(Alarm .*?\.)",
        r"(The alarm .*?\.)",
        r"(The master .*? reported .*?\.)",
        r"(The crew .*? search .*?\.)",
        r"(A search .*?\.)",
        r"(Safety navigational broadcast .*?\.)",
        r"(Ship general alarm .*?\.)",
    ]

    for pattern in patterns:
        match = re.search(pattern, text, flags=re.DOTALL | re.IGNORECASE)

        if match:
            return re.sub(r"\s+", " ", match.group(1)).strip()

    return None


def extract_reported_to_authority(text: str) -> Optional[str]:
    match = re.search(r"\b(Yes|No)\b", text, flags=re.IGNORECASE)
    return match.group(1).title() if match else None


def classify_incident(text: str) -> dict:
    text = normalize_text_for_classification(text)

    if not text:
        return {
            "incident_type": "Unknown / Unclassified",
            "incident_code": 0,
            "violence_level": 0,
            "incident_keywords": "",
        }

    for rule in CLASS_RULES:
        matched = []

        for pattern in rule["patterns"]:
            if re.search(pattern, text, flags=re.IGNORECASE):
                matched.append(pattern)

        if matched:
            return {
                "incident_type": rule["incident_type"],
                "incident_code": rule["incident_code"],
                "violence_level": rule["violence_level"],
                "incident_keywords": "; ".join(sorted(set(matched))),
            }

    return {
        "incident_type": "Unknown / Unclassified",
        "incident_code": 0,
        "violence_level": 0,
        "incident_keywords": "",
    }


def update_waters_type_from_line(line: str, current: str) -> str:
    text_upper = line.upper()

    if "IN INTERNATIONAL WATERS" in text_upper:
        return "international_waters"

    if "IN TERRITORIAL WATERS" in text_upper:
        return "territorial_waters"

    if "IN PORT AREA" in text_upper or "IN PORT AREAS" in text_upper:
        return "port_area"

    return current


def starts_new_incident_line(line: str, next_lines: list[str]) -> bool:
    stripped = line.strip()

    # Old Report-Type: "1 SHIPNAME"
    if re.match(r"^\d+\s+[A-Za-z]", stripped):
        return True

    # New Report-Type: Single number, followed by Ship-data
    if re.match(r"^\d+$", stripped):
        lookahead = "\n".join(next_lines[:12])

        has_date_nearby = bool(re.search(r"\d{2}/\d{2}/\d{4}", lookahead))
        has_region_nearby = any(region in lookahead.upper() for region in REGIONS)

        if has_date_nearby or has_region_nearby:
            return True

    return False


def split_incidents_with_waters_type(text: str) -> list[dict]:
    lines = text.splitlines()
    waters_type = "unknown"

    incidents: list[dict] = []
    current_block: list[str] = []
    current_waters_type = waters_type

    for index, line in enumerate(lines):
        stripped = line.strip()

        new_waters_type = update_waters_type_from_line(stripped, waters_type)
        if new_waters_type != waters_type:
            waters_type = new_waters_type
            continue

        next_lines = [x.strip() for x in lines[index + 1:index + 15] if x.strip()]
        starts_new_incident = starts_new_incident_line(stripped, next_lines)

        if starts_new_incident:
            if current_block:
                incidents.append(
                    {
                        "raw_text": "\n".join(current_block).strip(),
                        "waters_type": current_waters_type,
                    }
                )

            current_block = [line]
            current_waters_type = waters_type

        else:
            if current_block:
                current_block.append(line)

    if current_block:
        incidents.append(
            {
                "raw_text": "\n".join(current_block).strip(),
                "waters_type": current_waters_type,
            }
        )

    return incidents


# ============================================================
# 4. Main Workflow
# ============================================================

def build_raw_dataset() -> pd.DataFrame:
    records: list[dict] = []

    year_folders = sorted(
        [p for p in BASE_FOLDER.iterdir() if p.is_dir() and p.name.isdigit()]
    )

    for year_folder in year_folders:
        print(f"\n===== Jahr: {year_folder.name} =====")

        pdf_files = sorted(year_folder.glob("*.pdf"))

        for pdf_path in pdf_files:
            print(f"Verarbeite: {pdf_path.name}")

            text = extract_text_from_pdf(pdf_path)
            incidents = split_incidents_with_waters_type(text)

            print(f"  erkannte Roh-Blöcke: {len(incidents)}")

            for inc in incidents:
                inc_norm = normalize_text(inc["raw_text"])
                lines = [x.strip() for x in inc_norm.split("\n") if x.strip()]

                records.append(
                    {
                        "year_folder": year_folder.name,
                        "source_file": pdf_path.name,
                        "waters_type": inc["waters_type"],
                        "raw_ship_name": extract_ship_name(inc_norm),
                        "raw_ship_type": find_ship_type(inc_norm),
                        "raw_flag": find_flag(inc_norm),
                        "raw_text": inc_norm,
                    }
                )

    return pd.DataFrame(records)


def filter_raw_dataset(df: pd.DataFrame) -> pd.DataFrame:
    df = df.copy()
    df["raw_text"] = df["raw_text"].fillna("").astype(str)

    # a datum is absolutely required
    has_date = df["raw_text"].str.contains(
        r"\d{2}/\d{2}/\d{4}",
        regex=True,
        na=False,
    )

    # Has to look like a real Incident-block:
    # Region or coordinate or typical Incident-phrasings
    region_pattern = (
        r"EAST AFRICA|WEST AFRICA|ARABIAN SEA|INDIAN OCEAN|"
        r"MALACCA STRAIT|SOUTH CHINA SEA|SOUTH AMERICA|"
        r"MEDITERRANEAN SEA|PERSIAN GULF"
    )

    coordinate_pattern = (
        r"\d{1,3}°\s*\d{1,2}(?:[.,]\d+)?'?\s*[NS]"
        r".{0,120}"
        r"\d{1,3}°\s*\d{1,2}(?:[.,]\d+)?'?\s*[EW]"
    )

    incident_keywords = (
        r"boarded|boarding|robber|robbers|pirate|pirates|stolen|missing|"
        r"hijacked|hijack|attempted|attempt|approached|chased|fired|"
        r"threatened|kidnapped|hostage|unauthorized|unauthorised|"
        r"perpetrator|perpetrators|persons|sighted|engine spares|"
        r"crew mustered|nothing was stolen|escaped|alarm raised|"
        r"armed|engine room|steering gear room|poop deck|scrap metal|"
        r"scrap metals|ship.?s stores|ship.?s property|ship.?s properties|"
        r"stores missing|properties missing|items missing|safe|citadel|"
        r"VTIS|VTS|ReCAAP|IMB|PRC|safety navigational broadcast|"
        r"safety broadcast|small boats|small boat|skiff|sampan|"
        r"hawse pipe|forecastle|paint locker|padlock|locked|tied"
    )

    looks_like_incident = (
        df["raw_text"].str.contains(region_pattern, case=False, regex=True, na=False)
        | df["raw_text"].str.contains(coordinate_pattern, case=False, regex=True, na=False)
        | df["raw_text"].str.contains(incident_keywords, case=False, regex=True, na=False)
    )

    df = df[has_date & looks_like_incident].copy()

    bad_starts = [
        "4 ALBERT EMBANKMENT",
        "REPORTS ON ACTS OF PIRACY",
        "Previous incidents reported",
        "The total number of acts of piracy",
        "NOTE: SOUTH AMERICA",
        "N°",
        "Ship Name",
        "Type of Ship",
        "Flag",
        "Gross Tonnage",
        "IMO Number",
    ]

    for bad in bad_starts:
        df = df[~df["raw_text"].str.startswith(bad, na=False)]

    return df


def clean_dataset(df: pd.DataFrame) -> pd.DataFrame:
    df = df.copy()

    df["ship_name"] = df["raw_text"].apply(extract_ship_name)
    df["ship_type"] = df["raw_text"].apply(find_ship_type)
    df["flag"] = df["raw_text"].apply(find_flag)
    df["date_raw"] = df["raw_text"].apply(extract_date)
    df["time"] = df["raw_text"].apply(extract_time)
    df["time_zone"] = df["raw_text"].apply(extract_time_zone)
    df["region"] = df["raw_text"].apply(find_region)

    df["lat_raw"] = df["raw_text"].apply(extract_lat_raw)
    df["lon_raw"] = df["raw_text"].apply(extract_lon_raw)
    df["lat_dd"] = df["lat_raw"].apply(dms_to_dd)
    df["lon_dd"] = df["lon_raw"].apply(dms_to_dd)

    time_standardized = df.apply(
        lambda row: standardize_time_to_local(
            row["time"],
            row["time_zone"],
            row["lon_dd"],
        ),
        axis=1,
    )

    df[["time_local", "time_offset_hours", "time_basis"]] = pd.DataFrame(
        time_standardized.tolist(),
        index=df.index,
    )

    df["time_period"] = df["time_local"].apply(classify_time_period)

    df["details"] = df["raw_text"].apply(extract_details)
    df["details"] = df["details"].combine_first(df["raw_text"])

    df["consequences"] = df["raw_text"].apply(extract_consequences)
    df["action_taken"] = df["raw_text"].apply(extract_action_taken)
    df["reported_to_coastal_authority"] = df["raw_text"].apply(
        extract_reported_to_authority
    )

    df["date"] = pd.to_datetime(df["date_raw"], dayfirst=True, errors="coerce")
    df["year"] = df["date"].dt.year
    df["month"] = df["date"].dt.month
    df["year_month"] = df["date"].dt.to_period("M").astype(str)

    df["coordinate_valid"] = (
        df["lat_dd"].between(-90, 90)
        & df["lon_dd"].between(-180, 180)
    )

    classification_text = (
        df["details"].fillna("").astype(str)
        + " "
        + df["consequences"].fillna("").astype(str)
        + " "
        + df["action_taken"].fillna("").astype(str)
        + " "
        + df["raw_text"].fillna("").astype(str)
    )

    classified = classification_text.apply(classify_incident).apply(pd.Series)

    df["incident_type"] = classified["incident_type"]
    df["incident_code"] = classified["incident_code"]
    df["violence_level"] = classified["violence_level"]
    df["incident_keywords"] = classified["incident_keywords"]

    df["incident_id"] = (
        df["date"].dt.strftime("%Y%m%d").fillna("unknown_date")
        + "_"
        + df["ship_name"]
        .fillna("unknown_ship")
        .astype(str)
        .str.replace(r"\W+", "_", regex=True)
        + "_"
        + df["source_file"]
        .fillna("unknown_source")
        .astype(str)
        .str.replace(r"\W+", "_", regex=True)
    )

    df = df.drop_duplicates(
        subset=["date_raw", "time", "ship_name", "source_file"],
        keep="first",
    ).copy()

    final_columns = [
        "incident_id",
        "source_file",
        "year_folder",
        "year",
        "month",
        "year_month",
        "date_raw",
        "date",
        "time",
        "time_zone",
        "time_local",
        "time_offset_hours",
        "time_basis",
        "time_period",
        "ship_name",
        "ship_type",
        "flag",
        "region",
        "waters_type",
        "lat_raw",
        "lon_raw",
        "lat_dd",
        "lon_dd",
        "coordinate_valid",
        "incident_type",
        "incident_code",
        "violence_level",
        "incident_keywords",
        "details",
        "consequences",
        "action_taken",
        "reported_to_coastal_authority",
        "raw_text",
    ]

    for col in final_columns:
        if col not in df.columns:
            df[col] = pd.NA

    return df[final_columns]


def create_quality_report(
    df_raw: pd.DataFrame,
    df_filtered: pd.DataFrame,
    df_final: pd.DataFrame,
) -> dict[str, pd.DataFrame]:

    summary = pd.DataFrame(
        {
            "metric": [
                "raw_blocks",
                "filtered_incidents",
                "final_records",
                "records_with_valid_coordinates",
                "records_without_valid_coordinates",
                "unknown_incident_type",
            ],
            "value": [
                len(df_raw),
                len(df_filtered),
                len(df_final),
                int(df_final["coordinate_valid"].sum()),
                int((~df_final["coordinate_valid"]).sum()),
                int((df_final["incident_type"] == "Unknown / Unclassified").sum()),
            ],
        }
    )

    missing = df_final.isna().sum().reset_index()
    missing.columns = ["column", "missing_count"]

    by_year = (
        df_final.groupby("year", dropna=False)
        .size()
        .reset_index(name="incident_count")
    )

    by_month = (
        df_final.groupby("year_month", dropna=False)
        .size()
        .reset_index(name="incident_count")
    )

    by_type = (
        df_final.groupby("incident_type", dropna=False)
        .size()
        .reset_index(name="incident_count")
    )

    by_waters_type = (
        df_final.groupby("waters_type", dropna=False)
        .size()
        .reset_index(name="incident_count")
    )

    by_time_period = (
        df_final.groupby("time_period", dropna=False)
        .size()
        .reset_index(name="incident_count")
    )

    coordinate_issues = df_final[~df_final["coordinate_valid"]].copy()

    return {
        "summary": summary,
        "missing_values": missing,
        "incidents_by_year": by_year,
        "incidents_by_month": by_month,
        "incidents_by_type": by_type,
        "incidents_by_waters_type": by_waters_type,
        "incidents_by_time_period": by_time_period,
        "coordinate_issues": coordinate_issues,
    }


def main() -> None:
    print("Starte Erstellung des dokumentationsfähigen Masterdatensatzes...")

    df_raw = build_raw_dataset()
    print(f"\nRoh-Blöcke insgesamt: {len(df_raw)}")

    df_filtered = filter_raw_dataset(df_raw)
    print(f"Nach Incident-Filter: {len(df_filtered)}")

    df_final = clean_dataset(df_filtered)
    print(f"Finale Datensätze: {len(df_final)}")

    df_final.to_excel(OUTPUT_MASTER_XLSX, index=False)
    df_final.to_csv(OUTPUT_MASTER_CSV, index=False, sep=";", encoding="utf-8-sig")

    qa = create_quality_report(df_raw, df_filtered, df_final)

    with pd.ExcelWriter(OUTPUT_QA_XLSX) as writer:
        for sheet_name, sheet_df in qa.items():
            sheet_df.to_excel(writer, sheet_name=sheet_name[:31], index=False)

    qa["incidents_by_month"].to_excel(OUTPUT_MONTHLY_COUNTS_XLSX, index=False)

    print("\nFertig.")
    print(f"Master XLSX: {OUTPUT_MASTER_XLSX}")
    print(f"Master CSV:  {OUTPUT_MASTER_CSV}")
    print(f"Quality Report: {OUTPUT_QA_XLSX}")
    print(f"Monthly Counts: {OUTPUT_MONTHLY_COUNTS_XLSX}")


if __name__ == "__main__":
    main()
