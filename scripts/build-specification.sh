#!/bin/bash
# docs/ 以下の各mdファイル（schedule.md, csv-format.md, data-schedule.md, ftp.md, faq.md）を
# specification.md に統合し、続けて PDF (specification.pdf) を生成する。
#
# Usage: ./scripts/build-specification.sh [--md-only]
#   --md-only : specification.md の再生成のみ行い、PDF化はスキップする。

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

OUT="specification.md"
TITLE="株式会社　スーパーキタムラEOS仕様書"

# 各docファイルを、specification.md に埋め込む形に整形して標準出力へ流す:
#  - docファイル内の「[← 仕様書に戻る]」の戻りリンク行を削除
#  - 見出しレベルを1段階下げる（# -> ## など。specification.md内では
#    docファイルの見出しが1つネストした位置に来るため）
#  - csv-format.md内の画像パス（docs/からの相対パス）をルート相対に補正
#  - schedule.md/csv-format.md内のサンプルCSVリンク・schedule.md内のPDF自己参照リンクを
#    ルート相対に補正
#  - faq.md内のdata-schedule.mdへのファイルリンクを、同一ファイル内アンカーに補正
#
# faq.md だけは元の見出し構成が「# Q&A」→「### Qn」とh2を飛ばしているため、
# 他ファイルと同じ一律+1シフトを行うと質問見出しがh4まで下がってしまい、
# 他セクション内の主要見出し（前提項目など、h3相当）と階層が揃わなくなる。
# そのためfaq.mdはタイトル行のみ# -> ##にし、質問見出し(###)はそのまま保つ。
render_section() {
  local file="$1"
  local shift_all="$2"
  local shift_expr='s/^(#+) /#\1 /'
  [ "$shift_all" = "no" ] && shift_expr='1s/^(#+) /#\1 /'
  sed -E \
    -e '/^\[← 仕様書に戻る\]\(\.\.\/specification\.md\)$/d' \
    -e "$shift_expr" \
    -e 's|\.\./伝票イメージ\.png|伝票イメージ.png|' \
    -e 's|\.\./sample/1234\.csv|sample/1234.csv|' \
    -e 's|\.\./specification\.pdf|specification.pdf|' \
    -e 's|\[データ作成スケジュール\]\(data-schedule\.md\)|[データ作成スケジュール](#データ作成スケジュール)|' \
    "$file"
}

{
  echo "# ${TITLE}"
  echo
  echo "リポジトリ: <https://github.com/SeijiKitamura/eos>"
  echo
  echo "## 目次"
  echo
  echo "- [本番までのスケジュール](#本番までのスケジュール)"
  echo "- [CSVファイル仕様](#csvファイル仕様)"
  echo "- [データ作成スケジュール](#データ作成スケジュール)"
  echo "- [FTPについて](#ftpについて)"
  echo "- [Q&A](#qa)"
  echo "- [会社情報](#会社情報)"
  echo "- [EOS担当](#eos担当)"
  echo
  render_section docs/schedule.md yes
  echo
  render_section docs/csv-format.md yes
  echo
  render_section docs/data-schedule.md yes
  echo
  render_section docs/ftp.md yes
  echo
  render_section docs/faq.md no
  echo
  echo "## 会社情報"
  echo
  echo "| 項目 | 値 |"
  echo "| --- | --- |"
  echo "| 会社名 | 株式会社スーパーキタムラ |"
  echo "| 所在地 | 東京都大田区南馬込4-21-10 |"
  echo "| 店休日 | なし |"
  echo "| 営業時間 | 9:30-22:00 |"
  echo "| ホームページ | https://market.kita-grp.co.jp |"
  echo "| TEL/FAX | 03-3771-8284 / 03-3774-9541 |"
  echo "| 店舗数 | 1 |"
  echo
  echo "## EOS担当"
  echo
  echo "- 株式会社　スーパーキタムラ　EOS担当　北村　成吏"
  echo "- Email: seiji_kitamura@kita-grp.co.jp"
} | cat -s > "$OUT"

echo "Wrote: $OUT"

if [ "${1:-}" = "--md-only" ]; then
  exit 0
fi

bash "$REPO_ROOT/pdf-template/generate-pdf.sh" "$OUT"
