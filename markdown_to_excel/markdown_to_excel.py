"""Markdownを見出しレベルごとに列をずらしてExcelに変換する。"""

from __future__ import annotations

import argparse
import re
from pathlib import Path
from typing import List, Optional, Tuple

from openpyxl import Workbook
from openpyxl.utils import get_column_letter

# Markdownの見出し（#〜######）を検出する正規表現
HEADING_RE = re.compile(r"^(#{1,6})\s+(.*)$")

# Excel設定に関する定数
MAX_EXCEL_COLUMNS = 16384  # XFD
COLUMN_WIDTH = 2.5
START_ROW = 2
HEADING_COL_OFFSET = 1

# 既定の入出力パス（必要に応じて引数で上書き可能）
DEFAULT_INPUT_PATH = (
    "/Users/nakagukihisashi/repositories/sandbox/markdown_to_excel/markdown/input.md"
)
DEFAULT_OUTPUT_PATH = (
    "/Users/nakagukihisashi/repositories/sandbox/markdown_to_excel/excel/output.xlsx"
)


def finalize_section(
    start_row: int, heading_col: int, lines_buf: List[str], sheet
) -> Tuple[int, int]:
    """本文をExcelに書く。

    概要:
        溜めておいた本文を、見出しの右側の列に書き込む。

    引数:
        start_row: 書き込みを始める行番号。
        heading_col: 見出しを書いた列番号。
        lines_buf: 本文として書く行の一覧。
        sheet: 書き込み先のExcelシート。

    返り値:
        次に書く行番号と、この処理で使った最大列番号を返す。
    """

    max_col_used = 1
    # 見出し直下の空行は無視する
    while lines_buf and lines_buf[0] == "":
        lines_buf.pop(0)

    # 末尾の空行は削除して、セル内の不要な空行を防ぐ
    while lines_buf and lines_buf[-1] == "":
        lines_buf.pop()

    if not lines_buf:
        # 本文がない場合は1行だけ進める
        next_row = start_row + 1
        return next_row, max_col_used

    # 本文は見出しの1列右、かつ1行下から、行ごとに書く
    body_col = heading_col + 1
    # 見出しが h2 以降（heading_col > 1）の場合は、見出し行の1行下から本文を開始する
    if heading_col > 1:
        body_start_row = start_row + 1
    else:
        body_start_row = start_row

    # 行ごとに書き込む。空行は空セルを書かずに行だけ進める。
    write_row = body_start_row
    for body_line in lines_buf:
        # 空行の場合は空セルを書かずに行だけ進める
        if body_line == "":
            write_row += 1
            continue
        sheet.cell(row=write_row, column=body_col, value=body_line)
        write_row += 1
    max_col_used = max(max_col_used, body_col)

    # 本文の最後の行の次に空行を入れる
    next_row = body_start_row + len(lines_buf) + 1

    return next_row, max_col_used


def build_heading_text(
    level: int, raw_text: str, heading_counters: List[int]
) -> Tuple[str, List[int]]:
    """見出し番号を付けた文字列を作る。

    概要:
        見出しレベルに合わせて番号を作り、本文の先頭に付ける。

    引数:
        level: 見出しのレベル。h1なら1、h2なら2のように使う。
        raw_text: 元の見出し文字列。
        heading_counters: 各レベルの番号を覚えるための一覧。

    返り値:
        番号付きの見出し文字列と、更新後のカウンタ一覧を返す。
    """

    # 見出し番号を更新する（同レベルを加算し、下位レベルはリセット）
    heading_counters[level - 1] += 1
    for idx in range(level, len(heading_counters)):
        heading_counters[idx] = 0
    # 見出し番号の接頭辞を作る（例: 1. / 1.1. / 1.1.1.）
    number_parts = [str(num) for num in heading_counters[:level] if num > 0]
    number_prefix = ".".join(number_parts) + "."
    return number_prefix + raw_text.strip(), heading_counters


def handle_heading_line(
    row: int,
    match: re.Match,
    current_heading_col: Optional[int],
    body_lines: List[str],
    max_col: int,
    heading_counters: List[int],
    sheet,
) -> Tuple[int, int, int, List[int]]:
    """見出し行を処理する。

    概要:
        それまでの本文を書き出し、見出し番号を付けて見出しを書き込む。

    引数:
        row: 今の書き込み行番号。
        match: 見出しに一致した正規表現の結果。
        current_heading_col: 今までに書いた見出しの列番号。
        body_lines: 今までためていた本文の行。
        max_col: 今まで使った最大列番号。
        heading_counters: 見出し番号を数えるための一覧。
        sheet: 書き込み先のExcelシート。

    返り値:
        更新後の行番号、見出し列番号、最大列番号、見出しカウンタを返す。
    """

    # 次の見出しを書く前に、前の本文を書き込む
    if current_heading_col is not None:
        row, max_col_used = finalize_section(
            row, current_heading_col, body_lines, sheet
        )
        max_col = max(max_col, max_col_used)
    elif body_lines:
        # 見出しより前の本文があれば、B列起点として扱う
        row, max_col_used = finalize_section(row, 1, body_lines, sheet)
        max_col = max(max_col, max_col_used)

    # 見出しレベルを数えて列を決める（h1ならB列）
    level = len(match.group(1))
    heading_text, heading_counters = build_heading_text(
        level, match.group(2), heading_counters
    )
    heading_col = level + HEADING_COL_OFFSET
    # 見出しを指定列に書き込む
    sheet.cell(row=row, column=heading_col, value=heading_text)
    max_col = max(max_col, heading_col)

    return row, heading_col, max_col, heading_counters


def convert_markdown_to_excel(input_path: str, output_path: str) -> None:
    """Markdownを読み、Excelに変換して保存する。

    概要:
        Markdownの見出しを番号付きでExcelに書き込み、本文も決めた位置に入れる。

    引数:
        input_path: 入力Markdownファイルのパス。
        output_path: 出力Excelファイルのパス。

    返り値:
        なし。

    ルール:
        - h1はB列、h2はC列、h3はD列...のように右へずらす。
        - 見出しの本文は、見出しの列から1列右、かつ1行下に書く。
        - 本文を書いたら次の行は空行にする。
        - Markdown内の改行は、Excelの行を1行下にずらして書く。
        - ただし、見出し直下の空行は無視する。
    """
    # 入力ファイルをUTF-8で読み込み、行単位に分割する
    text = Path(input_path).read_text(encoding="utf-8")
    lines = text.splitlines()

    # 新しいExcelブックを作成し、最初のシートを取得する
    workbook = Workbook()
    sheet = workbook.active
    sheet.title = "Sheet1"

    # 書き込み位置などの状態を初期化する
    row = START_ROW
    current_heading_col: Optional[int] = None
    body_lines: List[str] = []
    max_col = 1
    heading_counters = [0, 0, 0, 0, 0, 0]

    for line in lines:
        # 行が見出しかどうかを判定する
        match = HEADING_RE.match(line)

        if not match:
            # 見出しでない行は本文としてバッファに追加する
            body_lines.append(line)
            continue

        # 見出し行が来たら、これまでの本文を書き出し、見出しを書き込む
        row, current_heading_col, max_col, heading_counters = handle_heading_line(
            row,
            match,
            current_heading_col,
            body_lines,
            max_col,
            heading_counters,
            sheet,
        )

        # 本文バッファをリセットする
        body_lines = []

    # 最後の本文が残っていれば書き込む
    if current_heading_col is not None or body_lines:
        heading_col = current_heading_col if current_heading_col is not None else 1
        row, max_col_used = finalize_section(row, heading_col, body_lines, sheet)
        max_col = max(max_col, max_col_used)

    # 全ての列の列幅を一律で設定する（Excelの最大列: XFD = 16384列）
    for col_idx in range(1, MAX_EXCEL_COLUMNS + 1):
        sheet.column_dimensions[get_column_letter(col_idx)].width = COLUMN_WIDTH

    # Excelファイルとして保存する
    workbook.save(output_path)


def main() -> None:
    """コマンドラインから実行するための入口。

    概要:
        コマンドライン引数を受け取り、変換処理を呼び出す。

    引数:
        なし。

    返り値:
        なし。
    """
    # 引数を受け取るための設定を行う
    parser = argparse.ArgumentParser(
        description="Markdownを見出しレベルごとに列をずらしてExcelに変換します。"
    )
    # 入力Markdownと出力Excelのパスを受け取る
    parser.add_argument(
        "input",
        nargs="?",
        default=DEFAULT_INPUT_PATH,
        help="Path to the input Markdown file",
    )
    parser.add_argument(
        "output",
        nargs="?",
        default=DEFAULT_OUTPUT_PATH,
        help="Path to the output Excel file",
    )
    args = parser.parse_args()
    # 変換処理を呼び出す
    convert_markdown_to_excel(args.input, args.output)


if __name__ == "__main__":
    main()
