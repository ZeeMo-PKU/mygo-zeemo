from __future__ import annotations

import csv
from collections import Counter
from pathlib import Path

from reportlab.lib import colors
from reportlab.lib.enums import TA_CENTER, TA_JUSTIFY, TA_LEFT
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
RESULT_DIR = ROOT / "cvdp-results" / "deepseek-v4-mygo-rerun-20260605"
CSV_PATH = RESULT_DIR / "mygo_final_detailed_results.csv"
OUT_DIR = ROOT / "output" / "pdf"
OUT_PDF = OUT_DIR / "mygo_cvdp_detailed_results_report.pdf"


def register_fonts() -> tuple[str, str]:
    font_dir = Path("C:/Windows/Fonts")
    regular = font_dir / "simhei.ttf"
    mono = font_dir / "consola.ttf"
    pdfmetrics.registerFont(TTFont("SimHei", str(regular)))
    if mono.exists():
        pdfmetrics.registerFont(TTFont("Consolas", str(mono)))
        mono_name = "Consolas"
    else:
        mono_name = "Courier"
    return "SimHei", mono_name


FONT, MONO = register_fonts()


def load_rows() -> list[dict[str, str]]:
    with CSV_PATH.open("r", encoding="utf-8-sig", newline="") as f:
        return list(csv.DictReader(f))


def transition_cn(value: str) -> str:
    return {
        "both_pass": "两边都通过",
        "improved_fail_to_pass": "MyGo 改善",
        "regressed_pass_to_fail": "MyGo 回退",
        "both_fail": "两边都失败",
    }.get(value, value)


def status_cn(value: str) -> str:
    return {
        "PASS": "通过",
        "FAIL": "CVDP 判题失败",
        "MODEL_OR_MYGO_ERROR": "路线错误",
    }.get(value, value)


def failure_category(row: dict[str, str]) -> str:
    status = row["mygo_status"]
    reason = row["failure_reason"]
    if status == "PASS":
        return "通过"
    if "端口不匹配" in reason:
        return "Verilog 接口/端口不匹配"
    if "超时" in reason:
        return "MyGo 编译/转换超时"
    if "undeclared SSA value" in reason:
        return "MyGo/CIRCT 后端错误"
    if "缺少 return" in reason or "Go 不合法" in reason:
        return "LLM 生成 Go 代码错误"
    if "JSONDecodeError" in reason:
        return "LLM/API 返回解析错误"
    if "日志未给出" in reason:
        return "MyGo 编译失败，日志不足"
    if "harness" in reason or "Icarus/cocotb" in reason:
        return "CVDP harness/仿真失败"
    return "其他失败"


def p(text: str, style: ParagraphStyle) -> Paragraph:
    text = (
        str(text)
        .replace("&", "&amp;")
        .replace("<", "&lt;")
        .replace(">", "&gt;")
        .replace("\n", "<br/>")
    )
    return Paragraph(text, style)


def pct(n: int, d: int) -> str:
    return f"{n / d * 100:.2f}%"


def make_styles() -> dict[str, ParagraphStyle]:
    base = getSampleStyleSheet()
    styles = {
        "title": ParagraphStyle(
            "title",
            parent=base["Title"],
            fontName=FONT,
            fontSize=22,
            leading=29,
            textColor=colors.HexColor("#12324A"),
            alignment=TA_CENTER,
            spaceAfter=12,
        ),
        "subtitle": ParagraphStyle(
            "subtitle",
            parent=base["Normal"],
            fontName=FONT,
            fontSize=10,
            leading=16,
            alignment=TA_CENTER,
            textColor=colors.HexColor("#4B5A64"),
            spaceAfter=16,
        ),
        "h1": ParagraphStyle(
            "h1",
            parent=base["Heading1"],
            fontName=FONT,
            fontSize=15,
            leading=21,
            textColor=colors.HexColor("#12324A"),
            spaceBefore=8,
            spaceAfter=8,
        ),
        "h2": ParagraphStyle(
            "h2",
            parent=base["Heading2"],
            fontName=FONT,
            fontSize=12,
            leading=17,
            textColor=colors.HexColor("#12324A"),
            spaceBefore=7,
            spaceAfter=5,
        ),
        "body": ParagraphStyle(
            "body",
            parent=base["BodyText"],
            fontName=FONT,
            fontSize=9.2,
            leading=14.5,
            alignment=TA_JUSTIFY,
            textColor=colors.HexColor("#1E252B"),
            spaceAfter=5,
        ),
        "small": ParagraphStyle(
            "small",
            parent=base["BodyText"],
            fontName=FONT,
            fontSize=7.4,
            leading=10.5,
            textColor=colors.HexColor("#1E252B"),
        ),
        "table": ParagraphStyle(
            "table",
            parent=base["BodyText"],
            fontName=FONT,
            fontSize=6.6,
            leading=8.5,
            textColor=colors.HexColor("#1E252B"),
        ),
        "table_mono": ParagraphStyle(
            "table_mono",
            parent=base["BodyText"],
            fontName=MONO,
            fontSize=6.1,
            leading=8.0,
            textColor=colors.HexColor("#1E252B"),
        ),
        "note": ParagraphStyle(
            "note",
            parent=base["BodyText"],
            fontName=FONT,
            fontSize=8.1,
            leading=12,
            textColor=colors.HexColor("#5A6268"),
            wordWrap="CJK",
            spaceBefore=4,
        ),
    }
    return styles


def table(data, col_widths, header_rows=1, font_size=7, leading=9):
    t = Table(data, colWidths=col_widths, repeatRows=header_rows, hAlign="LEFT")
    t.setStyle(
        TableStyle(
            [
                ("FONTNAME", (0, 0), (-1, -1), FONT),
                ("FONTSIZE", (0, 0), (-1, -1), font_size),
                ("LEADING", (0, 0), (-1, -1), leading),
                ("TEXTCOLOR", (0, 0), (-1, 0), colors.white),
                ("BACKGROUND", (0, 0), (-1, 0), colors.HexColor("#1E5674")),
                ("GRID", (0, 0), (-1, -1), 0.25, colors.HexColor("#B9C5CC")),
                ("VALIGN", (0, 0), (-1, -1), "TOP"),
                ("LEFTPADDING", (0, 0), (-1, -1), 3),
                ("RIGHTPADDING", (0, 0), (-1, -1), 3),
                ("TOPPADDING", (0, 0), (-1, -1), 3),
                ("BOTTOMPADDING", (0, 0), (-1, -1), 3),
                ("ROWBACKGROUNDS", (0, 1), (-1, -1), [colors.white, colors.HexColor("#F5F8FA")]),
            ]
        )
    )
    return t


def status_color(status: str):
    return {
        "PASS": colors.HexColor("#E7F4EA"),
        "FAIL": colors.HexColor("#FDECEC"),
        "MODEL_OR_MYGO_ERROR": colors.HexColor("#FFF3D6"),
    }.get(status, colors.white)


def add_status_backgrounds(t: Table, rows: list[dict[str, str]], status_col: int, start_row: int = 1):
    commands = []
    for i, row in enumerate(rows, start_row):
        commands.append(("BACKGROUND", (status_col, i), (status_col, i), status_color(row["mygo_status"])))
    t.setStyle(TableStyle(commands))


def draw_page(canvas, doc):
    canvas.saveState()
    w, h = doc.pagesize
    canvas.setFont(FONT, 8)
    canvas.setFillColor(colors.HexColor("#6A737B"))
    canvas.drawString(doc.leftMargin, 9 * mm, "MyGo CVDP 测试结果详细报告")
    canvas.drawRightString(w - doc.rightMargin, 9 * mm, f"Page {doc.page}")
    canvas.setStrokeColor(colors.HexColor("#D8E0E5"))
    canvas.line(doc.leftMargin, 14 * mm, w - doc.rightMargin, 14 * mm)
    canvas.restoreState()


def build_story(rows: list[dict[str, str]]):
    s = make_styles()
    total = len(rows)
    status_counts = Counter(r["mygo_status"] for r in rows)
    trans_counts = Counter(r["transition"] for r in rows)
    category_counts = Counter(failure_category(r) for r in rows if r["mygo_status"] != "PASS")

    story = []
    story.append(p("MyGo CVDP 测试结果详细报告", s["title"]))
    story.append(
        p(
            "DeepSeek v4 + LLM-Go/MyGo 路线；结果基于 2026-06-05 补跑后的 78 题合并记录。",
            s["subtitle"],
        )
    )
    story.append(p("1. 结论摘要", s["h1"]))
    story.append(
        p(
            "本次测试比较了直接生成 Verilog 与 LLM 先生成受限 Go、再由 MyGo 编译到 Verilog 的路线。"
            "直接 Verilog 基线通过 37/78；MyGo 初跑通过 37/78；对 20 个 MODEL_OR_MYGO_ERROR 题目补跑后，"
            "MyGo 最终通过 45/78，比直接 Verilog 基线多通过 8 题。这个结果说明 MyGo 路线在本批任务上存在"
            "可观的修正能力，但优势并不稳定：它同时把 24 个 direct 失败题提升为通过，也把 16 个 direct 通过题变成未通过。",
            s["body"],
        )
    )
    summary_data = [
        [p("指标", s["small"]), p("数值", s["small"]), p("说明", s["small"])],
        [p("Direct Verilog PASS", s["small"]), p("37/78", s["small"]), p("直接让 LLM 生成 Verilog 后 CVDP 判题", s["small"])],
        [p("MyGo 初跑 PASS", s["small"]), p("37/78", s["small"]), p("补跑前 LLM-Go/MyGo 路线结果", s["small"])],
        [p("MyGo 最终 PASS", s["small"]), p("45/78", s["small"]), p("补跑 20 个路线错误题后的最终合并结果", s["small"])],
        [p("净提升", s["small"]), p("+8 题", s["small"]), p("相对 direct Verilog 基线", s["small"])],
        [p("Union PASS", s["small"]), p("61/78", s["small"]), p("如果 direct 与 MyGo 两条路线任意一条通过即计通过", s["small"])],
    ]
    story.append(table(summary_data, [45 * mm, 35 * mm, 95 * mm], font_size=8, leading=11))
    story.append(Spacer(1, 5 * mm))

    story.append(p("2. 状态统计", s["h1"]))
    status_data = [
        [p("MyGo 状态", s["small"]), p("数量", s["small"]), p("比例", s["small"]), p("含义", s["small"])],
        [p("PASS", s["small"]), p(str(status_counts["PASS"]), s["small"]), p(pct(status_counts["PASS"], total), s["small"]), p("MyGo 产物通过 CVDP 判题", s["small"])],
        [p("FAIL", s["small"]), p(str(status_counts["FAIL"]), s["small"]), p(pct(status_counts["FAIL"], total), s["small"]), p("MyGo 已产出 Verilog，但 CVDP 编译/仿真/断言未通过", s["small"])],
        [
            p("MODEL_OR_MYGO_ERROR", s["small"]),
            p(str(status_counts["MODEL_OR_MYGO_ERROR"]), s["small"]),
            p(pct(status_counts["MODEL_OR_MYGO_ERROR"], total), s["small"]),
            p("在有效 CVDP 判题前失败，例如 Go 不合法、MyGo 超时、后端错误或 API 解析失败", s["small"]),
        ],
    ]
    story.append(table(status_data, [48 * mm, 20 * mm, 25 * mm, 82 * mm], font_size=8, leading=11))
    story.append(Spacer(1, 5 * mm))

    trans_data = [
        [p("Direct-vs-MyGo 关系", s["small"]), p("数量", s["small"]), p("解释", s["small"])],
        [p("两边都通过", s["small"]), p(str(trans_counts["both_pass"]), s["small"]), p("direct Verilog 和 MyGo 都通过", s["small"])],
        [p("MyGo 改善", s["small"]), p(str(trans_counts["improved_fail_to_pass"]), s["small"]), p("direct Verilog 失败，但 MyGo 通过", s["small"])],
        [p("MyGo 回退", s["small"]), p(str(trans_counts["regressed_pass_to_fail"]), s["small"]), p("direct Verilog 通过，但 MyGo 未通过", s["small"])],
        [p("两边都失败", s["small"]), p(str(trans_counts["both_fail"]), s["small"]), p("两条路线都未通过", s["small"])],
    ]
    story.append(table(trans_data, [55 * mm, 22 * mm, 98 * mm], font_size=8, leading=11))

    story.append(p("3. 失败原因分析", s["h1"]))
    story.append(
        p(
            "最终未通过 33 题，其中 24 题是 FAIL，表示 MyGo 已经生成 Verilog，但 CVDP 判题失败；9 题是 "
            "MODEL_OR_MYGO_ERROR，表示路线在进入有效 CVDP 结果前失败。最主要的失败模式是 Verilog 接口/端口不匹配，"
            "这类问题通常表现为 Icarus Verilog elaboration 阶段提示 testbench 期望的端口在 MyGo 输出模块中不存在。",
            s["body"],
        )
    )
    cat_data = [[p("失败类型", s["small"]), p("数量", s["small"]), p("说明", s["small"])]]
    explanations = {
        "Verilog 接口/端口不匹配": "MyGo 输出模块与 CVDP testbench 期望端口不一致，是本次最主要的普通 FAIL 来源。",
        "MyGo 编译/转换超时": "MyGo IR 或 MLIR 阶段超过设定时间，导致没有可判题 Verilog。",
        "MyGo/CIRCT 后端错误": "MyGo 生成 MLIR 后，CIRCT 后端处理时报 undeclared SSA value 等错误。",
        "LLM 生成 Go 代码错误": "LLM 输出的 Go 程序本身不合法，例如函数缺少 return。",
        "LLM/API 返回解析错误": "补跑过程中模型/API 输出无法解析为预期 JSON。",
        "MyGo 编译失败，日志不足": "记录只保留 compile failed，缺少更细的错误行。",
        "CVDP harness/仿真失败": "CVDP 子命令返回非零状态，但保留日志不足以确认更细原因。",
    }
    for name, count in category_counts.most_common():
        cat_data.append([p(name, s["small"]), p(str(count), s["small"]), p(explanations.get(name, ""), s["small"])])
    story.append(table(cat_data, [55 * mm, 22 * mm, 98 * mm], font_size=8, leading=11))

    story.append(PageBreak())
    story.append(p("4. 未通过题目详细清单", s["h1"]))
    failed = [r for r in rows if r["mygo_status"] != "PASS"]
    fail_data = [[p("#", s["table"]), p("题目", s["table"]), p("MyGo 状态", s["table"]), p("Direct 对照", s["table"]), p("失败类型", s["table"]), p("失败原因", s["table"])]]
    for r in failed:
        fail_data.append(
            [
                p(r["idx"], s["table"]),
                p(r["id"], s["table_mono"]),
                p(status_cn(r["mygo_status"]), s["table"]),
                p(transition_cn(r["transition"]), s["table"]),
                p(failure_category(r), s["table"]),
                p(r["failure_reason"], s["table"]),
            ]
        )
    fail_table = table(fail_data, [10 * mm, 60 * mm, 24 * mm, 24 * mm, 36 * mm, 104 * mm], font_size=6.2, leading=8.2)
    add_status_backgrounds(fail_table, failed, 2)
    story.append(fail_table)

    story.append(PageBreak())
    story.append(p("5. 完整 78 题结果附录", s["h1"]))
    story.append(
        p(
            "附录给出每一道题的最终状态。Direct 列中括号为 direct Verilog 基线失败类型；MyGo 失败原因优先采用补跑后的最终记录，"
            "普通 FAIL 则从 CVDP harness 日志中抽取首要错误摘要。",
            s["note"],
        )
    )
    all_data = [[p("#", s["table"]), p("题目", s["table"]), p("Direct", s["table"]), p("MyGo", s["table"]), p("对照", s["table"]), p("原因/说明", s["table"])]]
    for r in rows:
        direct = r["direct_status"]
        if r["direct_failure_type"]:
            direct += f" ({r['direct_failure_type']})"
        reason = "通过" if r["mygo_status"] == "PASS" else r["failure_reason"]
        all_data.append(
            [
                p(r["idx"], s["table"]),
                p(r["id"], s["table_mono"]),
                p(direct, s["table"]),
                p(r["mygo_status"], s["table"]),
                p(transition_cn(r["transition"]), s["table"]),
                p(reason, s["table"]),
            ]
        )
    all_table = table(all_data, [9 * mm, 64 * mm, 31 * mm, 28 * mm, 31 * mm, 95 * mm], font_size=5.9, leading=7.8)
    add_status_backgrounds(all_table, rows, 3)
    story.append(all_table)

    story.append(Spacer(1, 5 * mm))
    story.append(p("数据来源", s["h1"]))
    story.append(
        p(
            "最终合并结果：cvdp-results/deepseek-v4-mygo-rerun-20260605/merged_after_rerun_summary.json\n"
            "详细表：cvdp-results/deepseek-v4-mygo-rerun-20260605/mygo_final_detailed_results.csv\n"
            "原始 MyGo 运行目录：Desktop/CVDP_MyGo_Deepseek_v4\n"
            "补跑目录：Desktop/CVDP_MyGo_Deepseek_v4_rerun_errors_20260605",
            s["note"],
        )
    )
    return story


def main() -> None:
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    rows = load_rows()
    doc = BaseDocTemplate(
        str(OUT_PDF),
        pagesize=A4,
        leftMargin=16 * mm,
        rightMargin=16 * mm,
        topMargin=16 * mm,
        bottomMargin=18 * mm,
        title="MyGo CVDP 测试结果详细报告",
        author="Codex",
    )
    portrait_frame = Frame(doc.leftMargin, doc.bottomMargin, doc.width, doc.height, id="portrait")
    landscape_size = landscape(A4)
    landscape_frame = Frame(14 * mm, 17 * mm, landscape_size[0] - 28 * mm, landscape_size[1] - 32 * mm, id="landscape")
    doc.addPageTemplates(
        [
            PageTemplate(id="portrait", pagesize=A4, frames=[portrait_frame], onPage=draw_page),
            PageTemplate(id="landscape", pagesize=landscape_size, frames=[landscape_frame], onPage=draw_page),
        ]
    )
    full_story = build_story(rows)
    final_story = []
    wide_started = False
    for i, flowable in enumerate(full_story):
        next_flowable = full_story[i + 1] if i + 1 < len(full_story) else None
        if (
            isinstance(flowable, PageBreak)
            and isinstance(next_flowable, Paragraph)
            and getattr(next_flowable, "text", "").startswith("4. 未通过题目详细清单")
        ):
            final_story.append(NextPageTemplate("landscape"))
            wide_started = True
        final_story.append(flowable)
    if not wide_started:
        final_story = full_story
    doc.build(final_story)
    print(OUT_PDF)


if __name__ == "__main__":
    main()
