"""학식·교통 탭의 앱 안 고정 데이터 만들기(개선판 2차).

학교 홈페이지(www.ut.ac.kr)에서 식단, 버스 시간표, 학사일정(공휴일·학기)을 가져와
assets/data/ 아래 JSON 세 개를 만든다. 앱은 이 파일만 읽고 학교 사이트에 접속하지 않는다.

- meals.json: 캠퍼스별 식당과 한 주 식단(충주 학생식당·교직원식당은 학교 식단 페이지의 데이터,
  증평 생활관 식당은 그림으로만 올라와 tool/data/meals_manual.json에 옮겨 적은 것)
- transit.json: 시내버스(999·700), 통학버스(청주·이천·충주 시내), 캠퍼스 순환버스, 캠퍼스별 길찾기 주소
- holidays.json: 공휴일과 학기 기간(학사일정)

실행(저장소 맨 위에서, Python 3.9 이상, 추가 패키지 없음):
    python3 tool/make_data.py all                  # 셋 다
    python3 tool/make_data.py meals                # 이번 주 식단만 다시
    python3 tool/make_data.py meals --date 2026-11-02   # 그 날짜가 든 주
    python3 tool/make_data.py holidays --year 2027
    python3 tool/make_data.py transit

학교 사이트의 화면 구성이 바뀌면 파싱이 실패하고 기존 파일은 그대로 둔다. 그때는 오류 메시지를
보고 이 스크립트의 해당 함수를 고치거나 JSON을 직접 고친다(README.md "데이터 갱신").
"""

from __future__ import annotations

import argparse
import datetime as dt
import html
import json
import pathlib
import re
import sys
import urllib.parse
import urllib.request
from html.parser import HTMLParser

ROOT = pathlib.Path(__file__).resolve().parent.parent
OUT = ROOT / "assets" / "data"
MANUAL = ROOT / "tool" / "data" / "meals_manual.json"
SITE = "https://www.ut.ac.kr"

# ---------------------------------------------------------------------------
# 설정: 캠퍼스·식당·노선을 더할 때 여기를 고친다.
# ---------------------------------------------------------------------------

CAMPUSES = [
    {"id": "chungju", "name": "충주캠퍼스", "short": "충주"},
    {"id": "jeungpyeong", "name": "증평캠퍼스", "short": "증평"},
    {"id": "uiwang", "name": "의왕캠퍼스", "short": "의왕"},
]

# 학교 식단 페이지(mealManage)에서 가져오는 식당. fields: 식단 칸 이름 → 분류 이름.
# 장소·운영 시간·비고는 "편의시설" 페이지(/kor/sub06_02_01_0N.do) 내용이다.
SITE_RESTAURANTS = [
    {
        "campus": "chungju",
        "id": "chungju-student",
        "name": "학생식당",
        "section": "MT01",
        "page": "sub06_02_02_01",
        "place": "대학본부 복지관 1층",
        "days": [1, 2, 3, 4, 5],
        "note": "방학 중 휴점. 라면은 09:00~15:00",
    },
    {
        "campus": "chungju",
        "id": "chungju-staff",
        "name": "교직원식당",
        "section": "MT02",
        "page": "sub06_02_02_02",
        "place": "대학본부 복지관 3층",
        "days": [1, 2, 3, 4, 5],
        "note": None,
    },
]
MEAL_FIELDS = [("koreaFood", "한식"), ("topFood", "일품")]

# 학교 식단 페이지에 없는 캠퍼스 안내.
CAMPUS_MEAL_NOTES = {
    "uiwang": "학교 홈페이지에 의왕캠퍼스 식당 안내가 없습니다. 의왕생활관도 식당을 운영하지 않습니다"
    "(생활관 안내: 식비 미포함, 식당 미운영).",
}
CAMPUS_MEAL_SOURCES = {
    "uiwang": f"{SITE}/dorm/sub03_01_06.do",
}

# 통학버스 노선: 노선 제목에 들어 있는 낱말 → (칩 이름, id)
ROUTE_CHIPS = [
    ("청주", "청주", "commute-cheongju"),
    ("부발", "이천", "commute-icheon"),
    ("충주터미널", "충주 시내", "commute-chungju-city"),
]

# 캠퍼스 순환버스 표의 칸 이름 → 캠퍼스(캠퍼스가 아닌 칸은 거쳐 가는 곳)
SHUTTLE_COLUMNS = {"충주": "chungju", "증평(청아관)": "jeungpyeong", "의왕": "uiwang"}

# 캠퍼스별 길찾기·지도. 충주 길찾기 주소는 로컬 세션이 앱에서 확인한 값(2026-10-27).
# 증평·의왕의 길찾기 divisionId는 클라우드에서 길찾기 사이트에 접속되지 않아 확인하지 못해,
# 학교 홈페이지 캠퍼스 지도(campus_code)를 연다.
CAMPUS_MAPS = {
    "chungju": {
        "title": "길찾기",
        "url": "https://direction.ut.ac.kr/service/mobile/page/index?divisionId=1",
    },
    "jeungpyeong": {
        "title": "캠퍼스 지도",
        "url": f"{SITE}/prog/campusMap/kor/sub01_07_02/list.do?campus_code=dorm2",
    },
    "uiwang": {
        "title": "캠퍼스 지도",
        "url": f"{SITE}/prog/campusMap/kor/sub01_07_02/list.do?campus_code=dorm3",
    },
}

# 시간표가 없는 캠퍼스의 시내버스 안내("찾아오시는길" 페이지 /kor/sub01_06_0N.do).
CITY_GUIDE_PAGES = {"jeungpyeong": "sub01_06_02", "uiwang": "sub01_06_03"}

# 학사일정에서 쉬는 날로 보는 일정 이름
HOLIDAY_PATTERN = re.compile(
    r"신정|설\s*연휴|설날|삼일절|대체\s*휴일|대체공휴일|노동절|근로자의\s*날|어린이날|부처님|선거|"
    r"개교기념일|현충일|광복절|추석|개천절|한글날|성탄절"
)

WEEKDAY_NAMES = "월화수목금토일"


# ---------------------------------------------------------------------------
# 공통
# ---------------------------------------------------------------------------


def fetch(url: str, data: dict | None = None) -> bytes:
    body = urllib.parse.urlencode(data).encode() if data is not None else None
    request = urllib.request.Request(url, data=body, method="POST" if body is not None else "GET")
    with urllib.request.urlopen(request, timeout=30) as response:
        return response.read()


def fetch_text(url: str) -> str:
    return fetch(url).decode("utf-8", errors="replace")


def fetch_json(url: str, data: dict) -> object:
    return json.loads(fetch(url, data).decode("utf-8"))


def write_json(name: str, value: dict) -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    path = OUT / name
    path.write_text(json.dumps(value, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(f"썼습니다: {path.relative_to(ROOT)}")


def iso(day: dt.date) -> str:
    return day.isoformat()


def monday_of(day: dt.date) -> dt.date:
    return day - dt.timedelta(days=day.weekday())


def clean(text: str) -> str:
    return re.sub(r"\s+", " ", html.unescape(text)).strip()


def hhmm(text: str) -> str:
    hour, minute = text.split(":")
    return f"{int(hour):02d}:{int(minute):02d}"


class Tables(HTMLParser):
    """페이지의 표·제목·문단을 나온 순서대로 모은다(colspan·rowspan을 풀어 칸 격자로)."""

    def __init__(self) -> None:
        super().__init__(convert_charrefs=True)
        self.blocks: list[tuple[str, object]] = []
        self._table: list[list[tuple[str, int, int]]] | None = None
        self._row: list[tuple[str, int, int]] | None = None
        self._cell: list[str] | None = None
        self._span = (1, 1)
        self._text: list[str] | None = None
        self._text_tag = ""

    def handle_starttag(self, tag, attrs):
        attrs = dict(attrs)
        if tag == "table":
            self._table = []
        elif tag == "tr" and self._table is not None:
            self._row = []
        elif tag in ("td", "th") and self._row is not None:
            self._cell = []
            self._span = (int(attrs.get("colspan") or 1), int(attrs.get("rowspan") or 1))
        elif tag == "br" and self._cell is not None:
            self._cell.append("\n")
        elif tag in ("h2", "h3", "h4", "p", "li") and self._table is None:
            self._text = []
            self._text_tag = tag

    def handle_endtag(self, tag):
        if tag in ("td", "th") and self._cell is not None and self._row is not None:
            self._row.append(("".join(self._cell), *self._span))
            self._cell = None
        elif tag == "tr" and self._row is not None and self._table is not None:
            self._table.append(self._row)
            self._row = None
        elif tag == "table" and self._table is not None:
            self.blocks.append(("table", grid(self._table)))
            self._table = None
        elif tag == self._text_tag and self._text is not None:
            self.blocks.append((tag, clean("".join(self._text))))
            self._text = None

    def handle_data(self, data):
        if self._cell is not None:
            self._cell.append(data)
        elif self._text is not None:
            self._text.append(data)


def grid(rows: list[list[tuple[str, int, int]]]) -> list[list[str]]:
    """colspan·rowspan을 풀어 같은 칸 내용을 반복한 격자."""
    out: list[list[str]] = []
    pending: dict[tuple[int, int], str] = {}
    for r, row in enumerate(rows):
        line: list[str] = []
        c = 0
        cells = iter(row)
        while True:
            if (r, c) in pending:
                line.append(pending.pop((r, c)))
                c += 1
                continue
            cell = next(cells, None)
            if cell is None:
                break
            text, colspan, rowspan = cell
            text = "\n".join(clean(part) for part in text.split("\n")).strip()
            for i in range(colspan):
                line.append(text)
                for k in range(1, rowspan):
                    pending[(r + k, c + i)] = text
            c += colspan
        while (r, c) in pending:
            line.append(pending.pop((r, c)))
            c += 1
        out.append(line)
    return out


def page_blocks(page_html: str) -> list[tuple[str, object]]:
    start = page_html.find('id="txt"')
    end = page_html.find('id="point"', start)
    if start < 0:
        raise SystemExit("페이지에서 본문(id=\"txt\")을 찾지 못했습니다. 학교 사이트 구성이 바뀌었는지 확인하세요.")
    parser = Tables()
    parser.feed(page_html[start: end if end > 0 else None])
    return parser.blocks


# ---------------------------------------------------------------------------
# 학사일정: 공휴일과 학기
# ---------------------------------------------------------------------------

SCHEDULE_PAGE = f"{SITE}/prog/schedule/kor/sub05_01/1/scheduleList.do"
SCHEDULE_DATA = f"{SITE}/prog/schedule/kor/1/schedule.do"


def fetch_schedule(year: int) -> list[dict]:
    events = []
    for month in range(1, 13):
        for item in fetch_json(SCHEDULE_DATA, {"rdate": f"{year}-{month:02d}"}):
            events.append(
                {
                    "start": item["startDate"][:10],
                    "end": item["endDate"][:10],
                    "subject": clean(item["subject"]),
                }
            )
    return events


def build_holidays(year: int, today: dt.date) -> dict:
    events = fetch_schedule(year)
    holidays: dict[str, str] = {}
    for event in events:
        if not HOLIDAY_PATTERN.search(event["subject"]):
            continue
        # "2026 지방선거" → "지방선거", "대체 휴일" → "대체휴일"
        name = re.sub(r"^\d{4}\s*", "", event["subject"]).replace("대체 휴일", "대체휴일")
        day = dt.date.fromisoformat(event["start"])
        last = dt.date.fromisoformat(event["end"])
        while day <= last:
            if day.year == year:
                holidays.setdefault(iso(day), name)
            day += dt.timedelta(days=1)

    def first(pattern: str) -> dt.date | None:
        for event in events:
            if re.search(pattern, event["subject"]):
                return dt.date.fromisoformat(event["start"])
        return None

    terms = []
    for name, opening, vacation in (
        ("1학기", r"제\s*1\s*학기\s*개강", r"하계\s*방학"),
        ("2학기", r"제\s*2\s*학기\s*개강", r"동계\s*방학"),
    ):
        start = first(opening)
        end = first(vacation)
        if start is None or end is None:
            raise SystemExit(f"학사일정에서 {name} 개강일·방학 시작일을 찾지 못했습니다.")
        terms.append({"name": name, "start": iso(start), "end": iso(end - dt.timedelta(days=1))})

    return {
        "title": f"{year}년 공휴일·학기",
        "source": SCHEDULE_PAGE,
        "fetchedAt": iso(today),
        "validFrom": f"{year}-01-01",
        "validTo": f"{year}-12-31",
        "notes": [
            "학교 학사일정에서 쉬는 날(공휴일·대체휴일·개교기념일·선거일 등)만 골랐습니다.",
            "학기 기간은 개강일부터 방학 시작 전날까지입니다. 이 기간 밖은 방학으로 봅니다.",
        ],
        "holidays": [{"date": d, "name": holidays[d]} for d in sorted(holidays)],
        "terms": terms,
    }


# ---------------------------------------------------------------------------
# 식단
# ---------------------------------------------------------------------------

ITEM_WITH_PRICE = re.compile(r"^(.+?)\s*\(\s*([\d,]+)\s*원\s*\)$")
HOURS_LINE = re.compile(r"^이용\s*시간\s*[:：]?\s*(.+)$")
SET_PRICE = re.compile(r"^(.+?)\s*([\d,]+)\s*원$")


def normalize_hours(text: str) -> str:
    text = re.sub(r"\s*~\s*", "~", text.strip())
    return re.sub(r"(\d{1,2}):(\d{2})", lambda m: f"{int(m.group(1)):02d}:{m.group(2)}", text)


def parse_meal_text(text: str, course_name: str) -> dict:
    """학교 식단 칸 하나(줄바꿈으로 나뉜 글)를 분류 하나로 나눈다.

    - `메뉴(5,000원)` → 메뉴와 가격
    - `이용시간: 11:30~ 13:00 / 백반정식 5,500원` → 이용 시간, 정식 이름과 가격
    - `**…**`, `<…>`, `!!`가 든 줄 → 안내
    - 그 밖의 줄 → 가격 없는 메뉴
    - 한 줄뿐이고 가격·이용 시간이 없으면(`한글날`, `대체공휴일`) → 쉬는 날
    """
    lines = [html.unescape(line).strip() for line in text.replace("\r", "").split("\n")]
    lines = [line for line in lines if line]
    course: dict = {"name": course_name, "price": None, "hours": None, "items": []}
    notices: list[str] = []
    for line in lines:
        match = HOURS_LINE.match(line)
        if match:
            parts = [part.strip() for part in match.group(1).split("/")]
            course["hours"] = normalize_hours(parts[0])
            for part in parts[1:]:
                price = SET_PRICE.match(part)
                if price:
                    course["name"] = price.group(1).strip()
                    course["price"] = int(price.group(2).replace(",", ""))
            continue
        if line.startswith("**") or (line.startswith("<") and line.endswith(">")) or "!!" in line:
            notices.append(clean(line.replace("**", " ").strip("<> ")))
            continue
        match = ITEM_WITH_PRICE.match(line)
        if match:
            course["items"].append(
                {"name": match.group(1).strip(), "price": int(match.group(2).replace(",", ""))}
            )
        else:
            course["items"].append({"name": line, "price": None})
    closed = None
    if (
        len(lines) == 1
        and not notices
        and course["hours"] is None
        and len(course["items"]) == 1
        and course["items"][0]["price"] is None
    ):
        closed = course["items"][0]["name"]
        course["items"] = []
    return {"course": course, "notices": notices, "closed": closed}


def fetch_meal_week(restaurant: dict, monday: dt.date) -> list[dict]:
    url = f"{SITE}/prog/mealManage/{restaurant['section']}/kor/{restaurant['page']}/dayList.do"
    # searchKeyword가 가리키는 주의 다음 주를 준다.
    rows = fetch_json(url, {"searchKeyword": iso(monday - dt.timedelta(days=7)), "searchCondition": "next"})
    menus = []
    for row in rows:
        if not row.get("cntNo"):
            continue  # 입력되지 않은 날
        courses, notices, closed, hours = [], [], None, None
        if row.get("guidanceMatter"):
            notices.append(clean(row["guidanceMatter"]))
        for field, name in MEAL_FIELDS:
            if not row.get(field):
                continue
            parsed = parse_meal_text(row[field], name)
            notices += parsed["notices"]
            closed = closed or parsed["closed"]
            course = parsed["course"]
            hours = hours or course["hours"]
            if course["items"]:
                courses.append(course)
        menu: dict = {"date": row["mealDate"]}
        if notices:
            menu["notices"] = notices
        if courses:
            menu["courses"] = courses
        elif closed:
            menu["closed"] = closed
        if hours:
            menu["hours"] = hours
        menus.append(menu)
    return menus


def build_meals(target: dt.date, weeks: int, today: dt.date) -> dict:
    manual = json.loads(MANUAL.read_text(encoding="utf-8")) if MANUAL.exists() else {"restaurants": []}
    restaurants: dict[str, list[dict]] = {campus["id"]: [] for campus in CAMPUSES}
    first_monday = monday_of(target) - dt.timedelta(days=7 * (weeks - 1))
    for restaurant in SITE_RESTAURANTS:
        menus: list[dict] = []
        for week in range(weeks):
            menus += fetch_meal_week(restaurant, first_monday + dt.timedelta(days=7 * week))
        if not menus:
            print(f"경고: {restaurant['name']}의 {iso(first_monday)} 주 식단이 아직 없습니다.", file=sys.stderr)
        hours = next((menu["hours"] for menu in menus if menu.get("hours")), None)
        restaurants[restaurant["campus"]].append(
            {
                "id": restaurant["id"],
                "name": restaurant["name"],
                "place": restaurant["place"],
                "hours": hours,
                "days": restaurant["days"],
                "note": restaurant["note"],
                "source": f"{SITE}/prog/mealManage/{restaurant['section']}/kor/{restaurant['page']}/list.do",
                "fetchedAt": iso(today),
                "validFrom": iso(first_monday),
                "validTo": iso(first_monday + dt.timedelta(days=7 * weeks - 3)),
                "menus": menus,
            }
        )
    for restaurant in manual.get("restaurants", []):
        restaurants[restaurant["campus"]].append({k: v for k, v in restaurant.items() if k != "campus"})

    all_dates = [
        menu["date"] for items in restaurants.values() for item in items for menu in item["menus"]
    ]
    return {
        "title": "캠퍼스별 식단",
        "fetchedAt": iso(today),
        "validFrom": min(all_dates) if all_dates else None,
        "validTo": max(all_dates) if all_dates else None,
        "notes": [
            "충주 학생식당·교직원식당은 학교 홈페이지 식단 안내의 데이터를 그대로 나눈 것입니다.",
            "증평 생활관 식당은 생활관 '오늘의 식단' 게시판에 그림으로만 올라와 "
            "tool/data/meals_manual.json에 옮겨 적었습니다.",
            "식당 사정에 따라 메뉴가 바뀔 수 있습니다.",
        ],
        "campuses": [
            {
                "id": campus["id"],
                "name": campus["name"],
                "short": campus["short"],
                "note": CAMPUS_MEAL_NOTES.get(campus["id"]),
                "source": CAMPUS_MEAL_SOURCES.get(campus["id"]),
                "restaurants": restaurants[campus["id"]],
            }
            for campus in CAMPUSES
        ],
    }


# ---------------------------------------------------------------------------
# 교통
# ---------------------------------------------------------------------------

CITY_PAGE = f"{SITE}/kor/sub06_06_03.do"
COMMUTE_PAGE = f"{SITE}/kor/sub06_06_01.do"
TIME = re.compile(r"(\d{1,2}:\d{2})")


def build_city() -> dict:
    """시내버스 페이지(999·700): 교통대 → 터미널, 터미널 → 교통대."""
    tables = [block for kind, block in page_blocks(fetch_text(CITY_PAGE)) if kind == "table"]
    if not tables:
        raise SystemExit("시내버스 페이지에서 시간표를 찾지 못했습니다.")
    rows = [row for row in tables[0] if row and TIME.search(" ".join(row)) and not row[0].startswith("차")]
    from_campus, to_campus, skipped = [], [], []
    loop_stops = None
    for row in rows:
        if len(set(row[2:])) == 1:
            # 700 대학순환 경로 줄: 앞 줄 순환버스의 경유지와, 교통대로 돌아오는 차의 터미널 출발 시각
            route = row[2]
            stops = [clean(stop) for stop in route.split("→")]
            middle = [re.sub(r"\(.*?\)", "", stop) for stop in stops[1:] if not stop.startswith("터미널")]
            loop_stops = [stop for stop in middle if stop and stop not in ("차고지", "교통대")]
            if from_campus and from_campus[-1]["line"].startswith("700"):
                via = [stop for stop in loop_stops if stop != "건대정문"]
                from_campus[-1]["note"] = "·".join(via) + " 경유"
            terminal = re.search(r"터미널\((\d{1,2}:\d{2})\)", route)
            campus = re.search(r"교통대\((\d{1,2}:\d{2})\)", route)
            if terminal and campus:
                to_campus.append(
                    {
                        "line": "700 순환",
                        "depart": hhmm(terminal.group(1)),
                        "arrive": hhmm(campus.group(1)),
                        "note": "건대정문 경유",
                    }
                )
            continue
        cells = row + [""] * (8 - len(row))
        terminal_depart, campus_arrive, campus_depart, note, terminal_arrive = (
            cells[2],
            cells[3],
            cells[4],
            cells[5],
            cells[7],
        )
        if TIME.fullmatch(terminal_depart) and TIME.fullmatch(campus_arrive):
            to_campus.append({"line": "999", "depart": hhmm(terminal_depart), "arrive": hhmm(campus_arrive)})
        if TIME.fullmatch(campus_depart):
            if "차고지" in note:
                skipped.append(f"{hhmm(campus_depart)} 교통대 출발은 차고지 직행이라 뺐습니다.")
            elif TIME.fullmatch(terminal_arrive):
                trip = {
                    "line": "700 순환" if "700" in note else "999",
                    "depart": hhmm(campus_depart),
                    "arrive": hhmm(terminal_arrive),
                }
                from_campus.append(trip)
    page = fetch_text(CITY_PAGE)
    notice = re.search(r"※([^<]*운행[^<]*)", page)
    return {
        "id": "chungju-city",
        "kind": "city",
        "campuses": ["chungju"],
        "title": "시내버스 999·700",
        "source": CITY_PAGE,
        "calendar": {"weekdays": [1, 2, 3, 4, 5], "skipHolidays": True, "terms": True},
        "dayLabel": "평일만 운행",
        "notes": ([clean(notice.group(1))] if notice else []) + skipped,
        "directions": [
            {
                "id": "from-campus",
                "label": "교통대 → 터미널",
                "from": "교통대",
                "to": "시외터미널",
                "trips": sorted(from_campus, key=lambda trip: trip["depart"]),
            },
            {
                "id": "to-campus",
                "label": "터미널 → 교통대",
                "from": "시외터미널",
                "to": "교통대",
                "trips": sorted(to_campus, key=lambda trip: trip["depart"]),
            },
        ],
    }


def parse_stops(text: str) -> tuple[list[dict], list[str]]:
    """`청주가경터미널(07:15) → 청주신흥고(07:45) → …`. 시각이 앞 정류장보다 이르면 비운다."""
    stops, notes = [], []
    previous = None
    for part in clean(text).split("→"):
        part = part.strip()
        match = re.match(r"^(.*?)\(\s*(\d{1,2}:\d{2})\s*\)(.*)$", part)
        if not match:
            if part:
                stops.append({"name": part, "time": None})
            continue
        name = clean(f"{match.group(1)} {match.group(3)}")
        time = hhmm(match.group(2))
        if previous is not None and time < previous:
            notes.append(f"{name} 시각은 학교 안내에 적힌 값({time})이 순서에 맞지 않아 비웠습니다.")
            stops.append({"name": name, "time": None})
            continue
        stops.append({"name": name, "time": time})
        previous = time
    return stops, notes


def parse_periods(text: str) -> list[dict]:
    dates = re.findall(r"(\d{4})\.\s*(\d{1,2})\.\s*(\d{1,2})\.", text)
    days = [dt.date(int(y), int(m), int(d)) for y, m, d in dates]
    return [{"start": iso(days[i]), "end": iso(days[i + 1])} for i in range(0, len(days) - 1, 2)]


def build_commute(blocks: list[tuple[str, object]]) -> list[dict]:
    routes = []
    current: dict | None = None
    for kind, block in blocks:
        if kind == "h2":
            current = None
            continue
        if kind == "h3" and "노선" in block:
            title = clean(re.sub(r"^.*?노선\s*[:：]\s*", "", block))
            title = clean(re.sub(r"\((신설|시간변경안내)\)", "", title))
            chip, route_id = next(
                ((label, rid) for word, label, rid in ROUTE_CHIPS if word in title),
                (title.split("⇄")[0].strip(), f"commute-{len(routes) + 1}"),
            )
            current = {
                "id": route_id,
                "kind": "commute",
                "campuses": ["chungju"],
                "chip": chip,
                "title": title,
                "source": COMMUTE_PAGE,
                "calendar": {"weekdays": [1, 2, 3, 4, 5], "skipHolidays": True, "periods": []},
                "periodText": None,
                "fare": None,
                "payment": None,
                "notes": [],
                "toCampus": [],
                "fromCampus": [],
            }
            routes.append(current)
            continue
        if current is None:
            continue
        if kind == "h4" and "운행기간" in block:
            current["periodText"] = clean(block.split(":", 1)[1]) + ", 방학 중 운행 안 함"
            current["calendar"]["periods"] = parse_periods(block)
        elif kind == "table":
            for row in block:
                if len(row) < 2:
                    continue
                stops, notes = parse_stops(row[1])
                current["notes"] += notes
                if row[0].startswith("등교"):
                    current["toCampus"] = stops
                elif row[0].startswith("하교"):
                    current["fromCampus"] = stops
        elif kind == "li" and "이용요금" in block:
            fare = clean(block.split(":", 1)[1])
            current["fare"] = ("편도 " + fare) if "편도" in block else fare
        elif kind == "li" and "결제방식" in block:
            current["payment"] = clean(block.split(":", 1)[1])
        elif kind == "p" and "조정" in block:
            current["notes"].append("교통 상황에 따라 시간이 바뀔 수 있어요")
    for route in routes:
        if not route["toCampus"] or not route["fromCampus"]:
            raise SystemExit(f"통학버스 '{route['title']}'의 등교·하교 정류장을 찾지 못했습니다.")
    return routes


def shuttle_time(text: str) -> tuple[str, str] | None:
    match = re.search(r"(\d{1,2}:\d{2})\s*(?:\(([^)]*)\))?", text)
    if not match:
        return None
    return hhmm(match.group(1)), (match.group(2) or "").strip()


def weekdays_of(marker: str) -> list[int] | None:
    days = [WEEKDAY_NAMES.index(ch) + 1 for ch in marker if ch in WEEKDAY_NAMES]
    return days or None


def build_shuttle(blocks: list[tuple[str, object]]) -> dict:
    """캠퍼스 순환버스 표와 증평캠퍼스 관내 운행 표."""
    directions: dict[str, dict] = {}
    notes: list[str] = []
    heading = ""
    for kind, block in blocks:
        if kind in ("h2", "h3"):
            heading = block
            continue
        if kind == "p" and ("출발장소" in block or "학기 중에만" in block):
            notes.append(block)
        if kind != "table" or ("순환" not in heading and "관내" not in heading):
            continue
        header = next((row for row in block if row and "운행차량" in row[0]), None)
        columns = block[1] if len(block) > 1 else []
        body = [row for row in block if row and not row[0].startswith("운행차량") and TIME.search(" ".join(row))]
        if header is None:
            continue
        for row in body:
            vehicle = row[0]
            cells = []
            for index in range(1, len(columns)):
                if columns[index] in ("비고",) or index >= len(row):
                    continue
                parsed = shuttle_time(row[index])
                if parsed:
                    cells.append((columns[index], parsed[0], parsed[1]))
            if "관내" in heading:
                origin, via, dest = cells[0], cells[1:-1], cells[-1]
                key = "jeungpyeong-local"
                direction = directions.setdefault(
                    key,
                    {
                        "id": key,
                        "label": "증평 관내",
                        "fromCampus": "jeungpyeong",
                        "toCampus": "jeungpyeong",
                        "from": origin[0],
                        "to": dest[0],
                        "trips": [],
                    },
                )
                direction["trips"].append(
                    {
                        "line": vehicle.split("(")[0].strip(),
                        "depart": origin[1],
                        "arrive": dest[1],
                        "note": " · ".join(f"{name} {time}" for name, time, _ in via) + " 경유",
                    }
                )
                continue

            def campus_of(column: str) -> str | None:
                return next((cid for key, cid in SHUTTLE_COLUMNS.items() if column.startswith(key)), None)

            origin = next((cell for cell in cells if "출발" in cell[2]), None)
            dest = next((cell for cell in cells if "도착" in cell[2]), None)
            days = None
            if origin is None and len(cells) == 1:
                origin = cells[0]
                days = weekdays_of(origin[2])
            if origin is None:
                continue
            from_campus = campus_of(origin[0])
            if dest is not None:
                to_campus = campus_of(dest[0])
            else:
                # 도착 시각이 없으면 차량 이름(A↔B)에서 반대쪽 캠퍼스를 찾는다.
                ends = re.search(r"\((.+?)↔(.+?)\)", vehicle)
                names = [ends.group(1), ends.group(2)] if ends else []
                to_campus = next(
                    (cid for name in names for key, cid in SHUTTLE_COLUMNS.items()
                     if key.startswith(name) and cid != from_campus),
                    None,
                )
            if from_campus is None or to_campus is None:
                continue
            via = [cell for cell in cells if cell is not origin and cell is not dest]
            trip: dict = {"line": vehicle.split("(")[0].strip(), "depart": origin[1], "arrive": dest[1] if dest else None}
            if via:
                trip["note"] = " · ".join(f"{cell[2] or cell[0]} {cell[1]}" for cell in via) + " 경유"
            if days:
                trip["weekdays"] = days
                label = "·".join(WEEKDAY_NAMES[day - 1] for day in days) + "만 운행"
                trip["note"] = f"{trip['note']} · {label}" if trip.get("note") else label
            key = f"{from_campus}-{to_campus}"
            short = {c["id"]: c["short"] for c in CAMPUSES}
            place = {campus_of(column): column for column in columns[1:] if campus_of(column)}
            direction = directions.setdefault(
                key,
                {
                    "id": key,
                    "label": f"{short[from_campus]} → {short[to_campus]}",
                    "fromCampus": from_campus,
                    "toCampus": to_campus,
                    "from": origin[0],
                    "to": dest[0] if dest else short[to_campus],
                    "trips": [],
                },
            )
            if dest is None and to_campus in place:
                direction["to"] = place[to_campus]
            direction["trips"].append(trip)
    if not directions:
        raise SystemExit("통학버스 페이지에서 캠퍼스 순환버스 표를 찾지 못했습니다.")
    order = ["chungju-jeungpyeong", "jeungpyeong-chungju", "chungju-uiwang", "uiwang-chungju", "jeungpyeong-local"]
    ordered = sorted(directions.values(), key=lambda d: order.index(d["id"]) if d["id"] in order else 99)
    for direction in ordered:
        direction["trips"].sort(key=lambda trip: trip["depart"])
    return {
        "id": "campus-shuttle",
        "kind": "shuttle",
        "campuses": [campus["id"] for campus in CAMPUSES],
        "title": "캠퍼스 순환버스",
        "source": COMMUTE_PAGE,
        "calendar": {"weekdays": [1, 2, 3, 4, 5], "skipHolidays": True, "terms": True},
        "dayLabel": "평일 학기 중 운행",
        "notes": notes + ["도착 시각이 없는 차는 학교 안내에 출발 시각만 있습니다."],
        "directions": ordered,
    }


def city_guide(campus_id: str) -> list[str]:
    blocks = page_blocks(fetch_text(f"{SITE}/kor/{CITY_GUIDE_PAGES[campus_id]}.do"))
    text = [block for kind, block in blocks if kind in ("p", "li", "h4") and isinstance(block, str)]
    lines = [line for line in text if "→" in line and ("버스" in line or "터미널" in line or "역" in line)]
    lines = [line for line in lines if "나들목" not in line and "IC" not in line]
    return lines


def resolve_terms(service: dict, terms: list[dict]) -> None:
    calendar = service["calendar"]
    if calendar.pop("terms", False):
        calendar["periods"] = [{"start": term["start"], "end": term["end"]} for term in terms]


def build_transit(today: dt.date, holidays: dict) -> dict:
    commute_blocks = page_blocks(fetch_text(COMMUTE_PAGE))
    services = [build_city()] + build_commute(commute_blocks) + [build_shuttle(commute_blocks)]
    for service in services:
        resolve_terms(service, holidays["terms"])
    term = next(
        (t for t in holidays["terms"] if t["start"] <= iso(today) <= t["end"]),
        holidays["terms"][-1],
    )
    campuses = []
    for campus in CAMPUSES:
        entry = {"id": campus["id"], "name": campus["name"], "short": campus["short"], "map": CAMPUS_MAPS[campus["id"]]}
        if campus["id"] in CITY_GUIDE_PAGES:
            entry["cityGuide"] = city_guide(campus["id"])
            entry["cityGuideSource"] = f"{SITE}/kor/{CITY_GUIDE_PAGES[campus['id']]}.do"
        campuses.append(entry)
    return {
        "title": "버스 시간표",
        "fetchedAt": iso(today),
        "validFrom": term["start"],
        "validTo": term["end"],
        "notes": [
            "학교 홈페이지 통학정보(시내버스, 통학버스)의 시간표입니다. 교통 상황에 따라 시간이 바뀔 수 있습니다.",
            "운행 기간(periods) 밖과 공휴일(holidays.json)에는 운행하지 않는 것으로 계산합니다.",
        ],
        "campuses": campuses,
        "services": services,
    }


# ---------------------------------------------------------------------------


def main() -> None:
    parser = argparse.ArgumentParser(description="학식·교통 탭 데이터(assets/data/*.json) 만들기")
    parser.add_argument("what", choices=["all", "meals", "transit", "holidays"])
    parser.add_argument("--date", help="식단을 가져올 주에 든 날짜(YYYY-MM-DD). 기본은 오늘")
    parser.add_argument("--weeks", type=int, default=1, help="그 주까지 몇 주를 가져올지(기본 1)")
    parser.add_argument("--year", type=int, help="공휴일·학기 연도. 기본은 오늘의 연도")
    parser.add_argument("--today", help="가져온 날짜로 적을 날(기본 오늘)")
    args = parser.parse_args()
    today = dt.date.fromisoformat(args.today) if args.today else dt.date.today()
    year = args.year or today.year

    holidays = None
    if args.what in ("all", "holidays", "transit"):
        holidays = build_holidays(year, today)
        if args.what != "transit":
            write_json("holidays.json", holidays)
    if args.what in ("all", "meals"):
        target = dt.date.fromisoformat(args.date) if args.date else today
        write_json("meals.json", build_meals(target, max(1, args.weeks), today))
    if args.what in ("all", "transit"):
        write_json("transit.json", build_transit(today, holidays))


if __name__ == "__main__":
    main()
