from __future__ import annotations

import csv
import html
import json
import re
from collections import Counter
from pathlib import Path

from reportlab.lib import colors
from reportlab.lib.enums import TA_CENTER, TA_LEFT
from reportlab.lib.pagesizes import A4, landscape
from reportlab.lib.styles import ParagraphStyle, getSampleStyleSheet
from reportlab.lib.units import mm
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont
from reportlab.platypus import (
    BaseDocTemplate,
    Frame,
    NextPageTemplate,
    PageBreak,
    PageTemplate,
    Paragraph,
    Spacer,
    Table,
    TableStyle,
)


ROOT = Path(__file__).resolve().parents[1]
RESULT_DIR = ROOT / "cvdp-results" / "deepseek-v4-mygo-server-20260606"
SUMMARY_JSON = RESULT_DIR / "server_merged_summary.json"
DIRECT_DIR = ROOT / "tests" / "verilog-eval" / "historical" / "runs" / "cvdp_cid003_deepseek_v4_direct_20260602"
OUT_PDF = RESULT_DIR / "mygo_cvdp_server_run_report.pdf"
OUT_COMPARE_CSV = RESULT_DIR / "server_vs_direct_detailed.csv"


def register_fonts() -> tuple[str, str, str]:
    font_dir = Path("C:/Windows/Fonts")
    regular = font_dir / "NotoSansSC-VF.ttf"
    bold = font_dir / "msyhbd.ttc"
    mono = font_dir / "consola.ttf"
    if not regular.exists():
        regular = font_dir / "simhei.ttf"
    pdfmetrics.registerFont(TTFont("ReportCJK", str(regular)))
    pdfmetrics.registerFont(TTFont("ReportCJKBold", str(bold if bold.exists() else regular)))
    if mono.exists():
        pdfmetrics.registerFont(TTFont("ReportMono", str(mono)))
        mono_name = "ReportMono"
    else:
        mono_name = "Courier"
    return "ReportCJK", "ReportCJKBold", mono_name


FONT, FONT_BOLD, MONO = register_fonts()


def para(text: object, style: ParagraphStyle) -> Paragraph:
    safe = html.escape(str(text or "")).replace("\n", "<br/>")
    return Paragraph(safe, style)


def pct(value: int, total: int) -> str:
    return f"{value / total * 100:.2f}%" if total else "0.00%"


def short(text: str, limit: int = 180) -> str:
    text = re.sub(r"\s+", " ", text or "").strip()
    return text if len(text) <= limit else text[: limit - 3] + "..."


def load_server_rows() -> tuple[dict, list[dict]]:
    data = json.loads(SUMMARY_JSON.read_text(encoding="utf-8"))
    rows = data["tasks"]
    for row in rows:
        row["index"] = int(row["index"])
    rows.sort(key=lambda row: row["index"])
    return data["summary"], rows


def find_direct_summary_csv() -> Path:
    for csv_path in sorted(DIRECT_DIR.glob("*.csv"), key=lambda path: path.stat().st_size, reverse=True):
        with csv_path.open("r", encoding="utf-8-sig", newline="") as f:
            fields = set(csv.DictReader(f).fieldnames or [])
        if {"id", "difficulty", "status"}.issubset(fields):
            return csv_path
    raise FileNotFoundError(f"no direct summary CSV found under {DIRECT_DIR}")


def load_direct_rows() -> dict[str, dict]:
    with find_direct_summary_csv().open("r", encoding="utf-8-sig", newline="") as f:
        direct_rows = list(csv.DictReader(f))

    failure_types: dict[str, str] = {}
    for csv_path in DIRECT_DIR.glob("*.csv"):
        with csv_path.open("r", encoding="utf-8-sig", newline="") as f:
            reader = csv.DictReader(f)
            fields = set(reader.fieldnames or [])
            if {"id", "type"}.issubset(fields):
                for row in reader:
                    failure_types[row["id"]] = row.get("type", "")
                break

    direct: dict[str, dict] = {}
    for row in direct_rows:
        status = "PASS" if row.get("status", "").lower() == "pass" else "FAIL"
        direct[row["id"]] = {
            "direct_status": status,
            "difficulty": row.get("difficulty", ""),
            "direct_failure_type": failure_types.get(row["id"], ""),
        }
    return direct


def transition(direct_status: str, mygo_status: str) -> str:
    direct_pass = direct_status == "PASS"
    mygo_pass = mygo_status == "PASS"
    if direct_pass and mygo_pass:
        return "both_pass"
    if not direct_pass and mygo_pass:
        return "improved_by_mygo"
    if direct_pass and not mygo_pass:
        return "regressed_by_mygo"
    return "both_failed"


def transition_cn(value: str) -> str:
    return {
        "both_pass": "两边都通过",
        "improved_by_mygo": "MyGo 改善",
        "regressed_by_mygo": "MyGo 回退",
        "both_failed": "两边都失败",
    }[value]


def mygo_failure_category(row: dict) -> str:
    status = row["status"]
    reason = row.get("reason", "")
    if status == "PASS":
        return "通过"
    if status == "FAIL":
        return "CVDP 功能判错"
    if "timeout" in reason.lower():
        return "超时"
    if "verilog FAIL" in reason:
        return "MyGo/CIRCT Verilog 生成失败"
    if "ir FAIL" in reason or "compile failed" in reason:
        return "MyGo/Go 编译失败"
    return "模型或 MyGo 工具链错误"


def build_comparison_rows(server_rows: list[dict], direct: dict[str, dict]) -> list[dict]:
    rows = []
    for row in server_rows:
        direct_row = direct.get(row["task_id"], {})
        direct_status = direct_row.get("direct_status", "UNKNOWN")
        trans = transition(direct_status, row["status"]) if direct_status != "UNKNOWN" else "both_failed"
        rows.append(
            {
                "index": row["index"],
                "task_id": row["task_id"],
                "difficulty": direct_row.get("difficulty", ""),
                "direct_status": direct_status,
                "direct_failure_type": direct_row.get("direct_failure_type", ""),
                "mygo_status": row["status"],
                "mygo_category": mygo_failure_category(row),
                "transition": trans,
                "reason": row.get("reason", ""),
            }
        )
    return rows


def write_compare_csv(rows: list[dict]) -> None:
    with OUT_COMPARE_CSV.open("w", encoding="utf-8-sig", newline="") as f:
        writer = csv.DictWriter(
            f,
            fieldnames=[
                "index",
                "task_id",
                "difficulty",
                "direct_status",
                "direct_failure_type",
                "mygo_status",
                "mygo_category",
                "transition",
                "reason",
            ],
        )
        writer.writeheader()
        writer.writerows(rows)


def styles() -> dict[str, ParagraphStyle]:
    base = getSampleStyleSheet()
    return {
        "title": ParagraphStyle(
            "title",
            parent=base["Title"],
            fontName=FONT_BOLD,
            fontSize=20,
            leading=27,
            alignment=TA_CENTER,
            textColor=colors.HexColor("#12324A"),
            spaceAfter=8,
        ),
        "subtitle": ParagraphStyle(
            "subtitle",
            parent=base["Normal"],
            fontName=FONT,
            fontSize=9,
            leading=14,
            alignment=TA_CENTER,
            textColor=colors.HexColor("#50606B"),
            spaceAfter=12,
        ),
        "h1": ParagraphStyle(
            "h1",
            parent=base["Heading1"],
            fontName=FONT_BOLD,
            fontSize=14,
            leading=20,
            textColor=colors.HexColor("#12324A"),
            spaceBefore=7,
            spaceAfter=6,
        ),
        "body": ParagraphStyle(
            "body",
            parent=base["BodyText"],
            fontName=FONT,
            fontSize=8.8,
            leading=13.2,
            textColor=colors.HexColor("#1F2933"),
            alignment=TA_LEFT,
            spaceAfter=5,
        ),
        "small": ParagraphStyle("small", parent=base["BodyText"], fontName=FONT, fontSize=7.4, leading=10.2),
        "tiny": ParagraphStyle("tiny", parent=base["BodyText"], fontName=FONT, fontSize=6.0, leading=7.6),
        "mono": ParagraphStyle("mono", parent=base["BodyText"], fontName=MONO, fontSize=5.8, leading=7.2),
        "note": ParagraphStyle(
            "note",
            parent=base["BodyText"],
            fontName=FONT,
            fontSize=7.8,
            leading=11.2,
            textColor=colors.HexColor("#52616B"),
        ),
    }


def make_table(data, widths, font_size=7.0, leading=9.0) -> Table:
    table = Table(data, colWidths=widths, repeatRows=1, hAlign="LEFT")
    table.setStyle(
        TableStyle(
            [
                ("FONTNAME", (0, 0), (-1, -1), FONT),
                ("FONTSIZE", (0, 0), (-1, -1), font_size),
                ("LEADING", (0, 0), (-1, -1), leading),
                ("TEXTCOLOR", (0, 0), (-1, 0), colors.white),
                ("BACKGROUND", (0, 0), (-1, 0), colors.HexColor("#1E5674")),
                ("GRID", (0, 0), (-1, -1), 0.25, colors.HexColor("#B9C5CC")),
                ("VALIGN", (0, 0), (-1, -1), "TOP"),
                ("LEFTPADDING", (0, 0), (-1, -1), 2.5),
                ("RIGHTPADDING", (0, 0), (-1, -1), 2.5),
                ("TOPPADDING", (0, 0), (-1, -1), 2.5),
                ("BOTTOMPADDING", (0, 0), (-1, -1), 2.5),
                ("ROWBACKGROUNDS", (0, 1), (-1, -1), [colors.white, colors.HexColor("#F5F8FA")]),
            ]
        )
    )
    return table


def draw_page(canvas, doc) -> None:
    canvas.saveState()
    width, _height = doc.pagesize
    canvas.setFont(FONT, 7.5)
    canvas.setFillColor(colors.HexColor("#6A737B"))
    canvas.drawString(doc.leftMargin, 8 * mm, "MyGo CVDP server run report")
    canvas.drawRightString(width - doc.rightMargin, 8 * mm, f"Page {doc.page}")
    canvas.setStrokeColor(colors.HexColor("#D8E0E5"))
    canvas.line(doc.leftMargin, 13 * mm, width - doc.rightMargin, 13 * mm)
    canvas.restoreState()


def build_story(summary: dict, rows: list[dict]) -> list:
    s = styles()
    status_counts = Counter(row["mygo_status"] for row in rows)
    direct_counts = Counter(row["direct_status"] for row in rows)
    trans_counts = Counter(row["transition"] for row in rows)
    category_counts = Counter(row["mygo_category"] for row in rows if row["mygo_status"] != "PASS")
    total = len(rows)

    story = [
        para("MyGo CVDP 服务器测试报告", s["title"]),
        para("DeepSeek V4 Pro -> MyGo -> CIRCT -> Icarus/CVDP cocotb, 2026-06-06", s["subtitle"]),
        para("1. 结论摘要", s["h1"]),
        para(
            "本轮在服务器 Trifoliate 上完整跑完 78 道 CVDP cid003 题目。"
            "不带 MyGo 的 direct Verilog baseline 为 37/78 PASS；本次 MyGo 路线为 56/78 PASS，"
            "相对 baseline 多通过 19 题。未通过的 22 题中，14 题已经进入 CVDP cocotb 功能判题并失败，"
            "8 题停在模型或 MyGo 工具链阶段，未形成有效功能判题结果。",
            s["body"],
        ),
    ]

    story.append(
        make_table(
            [
                [para("指标", s["small"]), para("结果", s["small"]), para("说明", s["small"])],
                [para("Direct baseline", s["small"]), para(f"{direct_counts['PASS']}/78", s["small"]), para("DeepSeek 直接生成 Verilog 后交给 CVDP", s["small"])],
                [para("MyGo server run", s["small"]), para(f"{status_counts['PASS']}/78", s["small"]), para("DeepSeek 生成 Go/MyGo，经 MyGo 编译为 HDL 后交给 CVDP", s["small"])],
                [para("MyGo 净提升", s["small"]), para(f"+{status_counts['PASS'] - direct_counts['PASS']} 题", s["small"]), para("只比较最终 PASS 数，不代表每题单调改善", s["small"])],
                [para("MyGo pass rate", s["small"]), para(pct(status_counts["PASS"], total), s["small"]), para("本次服务器完整运行结果", s["small"])],
            ],
            [38 * mm, 34 * mm, 100 * mm],
            font_size=8,
            leading=11,
        )
    )
    story.append(Spacer(1, 4 * mm))

    story.append(para("2. 状态统计", s["h1"]))
    story.append(
        make_table(
            [
                [para("状态", s["small"]), para("数量", s["small"]), para("比例", s["small"]), para("含义", s["small"])],
                [para("PASS", s["small"]), para(status_counts["PASS"], s["small"]), para(pct(status_counts["PASS"], total), s["small"]), para("MyGo 产物通过 CVDP 功能判题", s["small"])],
                [para("FAIL", s["small"]), para(status_counts["FAIL"], s["small"]), para(pct(status_counts["FAIL"], total), s["small"]), para("HDL 已进入 CVDP cocotb 判题，但功能不符合参考测试", s["small"])],
                [para("MODEL_OR_MYGO_ERROR", s["small"]), para(status_counts["MODEL_OR_MYGO_ERROR"], s["small"]), para(pct(status_counts["MODEL_OR_MYGO_ERROR"], total), s["small"]), para("模型输出或 MyGo/CIRCT 链路未产出可判题 HDL", s["small"])],
            ],
            [42 * mm, 22 * mm, 26 * mm, 82 * mm],
            font_size=8,
            leading=11,
        )
    )
    story.append(Spacer(1, 4 * mm))

    story.append(
        make_table(
            [
                [para("对照关系", s["small"]), para("数量", s["small"]), para("说明", s["small"])],
                [para("两边都通过", s["small"]), para(trans_counts["both_pass"], s["small"]), para("Direct 和 MyGo 都 PASS", s["small"])],
                [para("MyGo 改善", s["small"]), para(trans_counts["improved_by_mygo"], s["small"]), para("Direct FAIL，但 MyGo PASS", s["small"])],
                [para("MyGo 回退", s["small"]), para(trans_counts["regressed_by_mygo"], s["small"]), para("Direct PASS，但 MyGo 未 PASS", s["small"])],
                [para("两边都失败", s["small"]), para(trans_counts["both_failed"], s["small"]), para("两条路线都未通过", s["small"])],
            ],
            [42 * mm, 22 * mm, 108 * mm],
            font_size=8,
            leading=11,
        )
    )

    story.append(para("3. 失败原因解释", s["h1"]))
    story.append(
        para(
            "这次结果不能简单理解成“CVDP 不能判题”。14 个 FAIL 是 CVDP 已经执行功能测试后的失败，"
            "说明当前 MyGo 路线生成的 HDL 行为没有通过 benchmark；8 个 MODEL_OR_MYGO_ERROR 才是模型或 MyGo 工具链层面的失败。",
            s["body"],
        )
    )
    cat_rows = [[para("失败类型", s["small"]), para("数量", s["small"]), para("解释", s["small"])]]
    explanations = {
        "CVDP 功能判错": "生成 HDL 已进入 cocotb 判题，但断言或输出行为不符合参考测试。",
        "MyGo/CIRCT Verilog 生成失败": "MyGo 生成 IR 后在 Verilog/CIRCT 阶段失败。",
        "MyGo/Go 编译失败": "模型输出的 Go/MyGo 或 MyGo IR 编译失败。",
        "超时": "模型、MyGo 或判题阶段超过设置时间。",
        "模型或 MyGo 工具链错误": "其他未能形成有效 CVDP 功能判题的错误。",
    }
    for name, count in category_counts.most_common():
        cat_rows.append([para(name, s["small"]), para(count, s["small"]), para(explanations.get(name, ""), s["small"])])
    story.append(make_table(cat_rows, [48 * mm, 22 * mm, 102 * mm], font_size=8, leading=11))

    story.append(PageBreak())
    story.append(para("4. 未通过题目清单", s["h1"]))
    failed = [row for row in rows if row["mygo_status"] != "PASS"]
    fail_rows = [[para("#", s["tiny"]), para("题目", s["tiny"]), para("Direct", s["tiny"]), para("MyGo", s["tiny"]), para("类型", s["tiny"]), para("原因", s["tiny"])]]
    for row in failed:
        fail_rows.append(
            [
                para(row["index"], s["tiny"]),
                para(row["task_id"], s["mono"]),
                para(row["direct_status"], s["tiny"]),
                para(row["mygo_status"], s["tiny"]),
                para(row["mygo_category"], s["tiny"]),
                para(short(row["reason"] or row["direct_failure_type"], 190), s["tiny"]),
            ]
        )
    story.append(make_table(fail_rows, [9 * mm, 63 * mm, 20 * mm, 34 * mm, 36 * mm, 96 * mm], font_size=5.9, leading=7.6))

    story.append(PageBreak())
    story.append(para("5. 完整 78 题对照表", s["h1"]))
    all_rows = [[para("#", s["tiny"]), para("题目", s["tiny"]), para("难度", s["tiny"]), para("Direct", s["tiny"]), para("MyGo", s["tiny"]), para("对照", s["tiny"]), para("MyGo 说明", s["tiny"])]]
    for row in rows:
        note = "通过" if row["mygo_status"] == "PASS" else short(row["reason"] or row["mygo_category"], 120)
        all_rows.append(
            [
                para(row["index"], s["tiny"]),
                para(row["task_id"], s["mono"]),
                para(row["difficulty"], s["tiny"]),
                para(row["direct_status"], s["tiny"]),
                para(row["mygo_status"], s["tiny"]),
                para(transition_cn(row["transition"]), s["tiny"]),
                para(note, s["tiny"]),
            ]
        )
    story.append(make_table(all_rows, [8 * mm, 62 * mm, 18 * mm, 20 * mm, 31 * mm, 29 * mm, 90 * mm], font_size=5.5, leading=7.1))

    story.append(Spacer(1, 4 * mm))
    story.append(para("数据文件", s["h1"]))
    story.append(
        para(
            f"服务器汇总: {SUMMARY_JSON.relative_to(ROOT)}\n"
            f"对照明细: {OUT_COMPARE_CSV.relative_to(ROOT)}\n"
            f"Direct baseline: {DIRECT_DIR.relative_to(ROOT)}\n"
            f"运行设置: {summary.get('parallelism', '')}; MyGo commit {summary.get('mygo_commit', '')}",
            s["note"],
        )
    )
    return story


def build_pdf(story: list) -> None:
    doc = BaseDocTemplate(
        str(OUT_PDF),
        pagesize=A4,
        leftMargin=16 * mm,
        rightMargin=16 * mm,
        topMargin=16 * mm,
        bottomMargin=18 * mm,
        title="MyGo CVDP server run report",
        author="Codex",
    )
    portrait = Frame(doc.leftMargin, doc.bottomMargin, doc.width, doc.height, id="portrait")
    landscape_size = landscape(A4)
    wide = Frame(14 * mm, 17 * mm, landscape_size[0] - 28 * mm, landscape_size[1] - 32 * mm, id="landscape")
    doc.addPageTemplates(
        [
            PageTemplate(id="portrait", pagesize=A4, frames=[portrait], onPage=draw_page),
            PageTemplate(id="landscape", pagesize=landscape_size, frames=[wide], onPage=draw_page),
        ]
    )
    final_story = []
    for i, flowable in enumerate(story):
        next_flowable = story[i + 1] if i + 1 < len(story) else None
        if isinstance(flowable, PageBreak) and isinstance(next_flowable, Paragraph):
            if next_flowable.getPlainText().startswith(("4.", "5.")):
                final_story.append(NextPageTemplate("landscape"))
        final_story.append(flowable)
    doc.build(final_story)


def main() -> None:
    summary, server_rows = load_server_rows()
    comparison = build_comparison_rows(server_rows, load_direct_rows())
    write_compare_csv(comparison)
    build_pdf(build_story(summary, comparison))
    print(OUT_COMPARE_CSV)
    print(OUT_PDF)


if __name__ == "__main__":
    main()
