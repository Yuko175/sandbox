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
    """溜めていた本文をExcelに書き込み、次に書く行番号と最大列を返す。"""

    max_col_used = 1
    # 見出し直下の空行は無視する
    while lines_buf and lines_buf[0] == "":
        lines_buf.pop(0)
    # 末尾の空行は削除して、セル内の不要な空行を防ぐ
    while lines_buf and lines_buf[-1] == "":
        lines_buf.pop()

    if lines_buf:
        # 本文は見出しの1列右、かつ1行下から、行ごとに書く
        body_col = heading_col + 1
        body_start_row = start_row + 1 if heading_col > 1 else start_row
        for offset, body_line in enumerate(lines_buf):
            # 空行は空セルとして1行進める
            if body_line == "":
                continue
            sheet.cell(
                row=body_start_row + offset,
                column=body_col,
                value=body_line,
            )
        max_col_used = max(max_col_used, body_col)
        # 本文の最後の行の次に空行を入れる
        return body_start_row + len(lines_buf) + 1, max_col_used

    # 本文がない場合は1行だけ進める
    return start_row + 1, max_col_used


def convert_markdown_to_excel(input_path: str, output_path: str) -> None:
    """Markdownファイルを読み込み、Excelに変換して保存する。

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
    row = 2
    current_heading_col: Optional[int] = None
    body_lines: List[str] = []
    max_col = 1
    heading_counters = [0, 0, 0, 0, 0, 0]

    for line in lines:
        # 行が見出しかどうかを判定する
        match = HEADING_RE.match(line)
        if match:
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
            # 本文バッファをリセットする
            body_lines = []
            # 見出しレベルを数えて列を決める（h1ならB列）
            level = len(match.group(1))
            # 見出し番号を更新する（同レベルを加算し、下位レベルはリセット）
            heading_counters[level - 1] += 1
            for idx in range(level, len(heading_counters)):
                heading_counters[idx] = 0
            # 見出し番号の接頭辞を作る（例: 1. / 1.1. / 1.1.1.）
            number_parts = [str(num) for num in heading_counters[:level] if num > 0]
            number_prefix = ".".join(number_parts) + "."
            heading_text = number_prefix + match.group(2).strip()
            heading_col = level + 1
            # 見出しを指定列に書き込む
            sheet.cell(row=row, column=heading_col, value=heading_text)
            max_col = max(max_col, heading_col)
            current_heading_col = heading_col
        else:
            # 見出しでない行は本文としてバッファに追加する
            body_lines.append(line)
    # 最後の本文が残っていれば書き込む
    if current_heading_col is not None or body_lines:
        heading_col = current_heading_col if current_heading_col is not None else 1
        row, max_col_used = finalize_section(row, heading_col, body_lines, sheet)
        max_col = max(max_col, max_col_used)
    # 全ての列の列幅を一律で設定する（Excelの最大列: XFD = 16384列）
    for col_idx in range(1, 16384 + 1):
        sheet.column_dimensions[get_column_letter(col_idx)].width = 2.5
    # Excelファイルとして保存する
    workbook.save(output_path)


def main() -> None:
    """コマンドラインからの実行入口。"""
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
