---
name: sync-readme
description: docs/ 以下の各mdファイル（csv-format.md, data-schedule.md, ftp.md, faq.md）とREADME.mdの内容を突き合わせ、相違があればdocs側を正として README.md を更新する。docsを編集した後や、READMEとdocsの整合性を確認・同期したいときに使う。
---

# README.md と docs/ の同期

`docs/` 以下のファイルが「正」（一次情報）で、`README.md` はその要約・抜粋。
このスキルは、両者を突き合わせて食い違いを見つけ、**docs側を優先してREADME.mdを直す**作業を毎回同じ手順で行うためのもの。

## 対応関係

| README.mdのセクション | 対応するdocsファイル・箇所 |
| --- | --- |
| `## CSVについて` の表 | `docs/csv-format.md` の `## 前提項目` 表 |
| `## データ作成スケジュール` | `docs/data-schedule.md` の `## 作成スケジュール` |
| `## FTPについて` | `docs/ftp.md`（アカウント・接続モード・NOTEボックス） |
| `## よくある質問（抜粋）` | `docs/faq.md`（Q&A全体からの抜粋・言い換え） |

`## 会社情報` `## EOS担当` `## リンク` など、docsに対応ファイルがないセクションは対象外（比較不要）。

## 手順

1. `README.md` と `docs/csv-format.md`, `docs/data-schedule.md`, `docs/ftp.md`, `docs/faq.md` を全て読む。
2. 上表の対応関係に沿って、事実（数値・条件・手順・用語など）が一致しているか確認する。
   - README.mdは要約・言い換えのため、**文章が完全一致している必要はない**。事実として矛盾していないか、docsにある情報がREADME.mdで欠落していないかを見る。
   - 逆に、docsにない情報がREADME.mdだけにある場合は矛盾ではないので触らない（会社情報・EOS担当など、README.md独自のセクションは対象外）。
3. 相違・欠落が見つかったら、**docs側の内容を正としてREADME.mdを手直しする**。README.mdの元の文体・簡潔さは保ったまま、事実だけをdocsに合わせる（docsの文章をそのまま貼り付けるのではなく、README.mdの既存の要約スタイルに合わせて書き直す）。
4. README.md編集後、`docs/` 自体も変更していた場合は `bash scripts/build-specification.sh` を実行し、`specification.md` / `specification.pdf` を再生成する（README.mdのみの修正で docs に変更がなければ不要）。
5. 何を比較し、何を直したか（または「相違なし」）を簡潔に報告する。
6. **コミット・pushはユーザーから明示的に依頼されるまで行わない**（このリポジトリでは毎回ユーザーが「コミットしてください」「pushしてください」と個別に指示する運用）。
