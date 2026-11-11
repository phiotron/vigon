# [A002-vigon] Lọc nâng cao + Xuất Excel/PDF (F-39, F-40) — 2026-11-11

Phiên con của đợt 5 (C3). Nhánh `a002-filter-export-v5` (từ `dev` 72fb8ee), chưa push, chưa gộp.
Worktree app: `D:/Mobile App/.claude/worktrees/a002-overview-stats-4eb9ea/apps/A002-vigon-fe`
(KHÔNG phải `.../apps/A002-vigon` trong cùng thư mục xưởng — chỗ đó là worktree cũ của nhánh
`feature/overview-stats-calendar` từ 2026-11-06, còn việc chưa commit; không đụng tới).

## Đã làm / file đổi
- **F-39** cherry-pick `e0ec7d7` (không xung đột) rồi khớp D-042:
  - `lib/src/data/entry_filter.dart`: `FilterTotals.of(rows, service:)` cộng số gốc theo từng tiền tệ
    bằng `MoneyBag` rồi quy về Tiền tệ chính một lần; khoản thiếu tỷ giá được đếm nhưng không vào tổng
    (AC-134). Khoảng số tiền so với **số theo Tiền tệ chính** (`Entry.amount`, số to trên dòng khoản).
  - `lib/src/features/entries/entry_search.dart`: truyền `currencyServiceProvider` vào dòng tổng.
  - Các file F-39 khác (bảng lọc, chip, state) giữ như commit cũ.
- **F-40** (file mới):
  - `lib/src/data/xlsx_writer.dart`: dựng `.xlsx` tự viết (zip + XML qua `archive`). Ô chữ luôn ở bảng
    chuỗi dùng chung (`t="s"`) → không bao giờ là công thức; chữ mở đầu `= + - @` thêm cờ `quotePrefix`.
    Ô tiền = số thập phân chính xác từ số nguyên (không qua double), định dạng `#,##0` / `#,##0.00`
    theo số lẻ tiền tệ; ô ngày thật `yyyy-mm-dd`; ô % `0.0%`; dòng tiêu đề đậm, cố định.
  - `lib/src/data/export_data.dart`: nạp khoản trong phạm vi (mọi tài khoản, cũ nhất trước), tài khoản,
    mọi khoản nợ; `PeriodSummary.of(..., service)` cho theo danh mục (D-042).
  - `lib/src/features/export/export_xlsx.dart`: sheet "Khoản" (ngày, giờ, loại, số tiền gốc, tiền tệ,
    số tiền theo Tiền tệ chính, danh mục, tài khoản, đến tài khoản, số nhận + tiền tệ nhận cho chuyển
    tiền khác tiền tệ, ghi chú, nguồn), "Theo danh mục" (loại, danh mục, tổng theo TT chính, %),
    "Khoản nợ" (người, chiều, số tiền, đã trả, còn lại, tiền tệ, còn lại theo TT chính, ngày, hạn,
    trạng thái, ghi chú).
  - `lib/src/features/export/export_pdf.dart`: A4, "Báo cáo thu chi {kỳ}", 3 ô tổng thu/chi/chênh lệch,
    bảng theo danh mục, danh sách khoản (số TT chính trên, số gốc nhỏ dưới — AC-146; thiếu tỷ giá ghi
    "Thiếu tỷ giá"), nhúng Be Vietnam Pro Regular + Bold, `MultiPage` tự sang trang (`maxPages: 1000`),
    chân trang "Trang n/m". Font không có "→" → tự chọn ký tự thay (›, >).
  - `lib/src/features/export/export_actions.dart`: bảng "Xuất khoảng nào" (kỳ đang xem · tên kỳ /
    Khoảng tùy chọn… mở `showRangeCalendar`), hộp "Đang tạo file…", dựng file trong `Isolate.run`,
    ghi thư mục tạm, mở bảng chia sẻ (như CSV, không xin quyền bộ nhớ).
  - `settings_screen.dart`: thêm 2 dòng "Xuất Excel", "Xuất PDF" sau "Xuất CSV" trong nhóm Dữ liệu
    (cả nhánh Android có sao lưu tự động và nhánh iOS). `data_actions.dart` không đổi.
  - `.arb` vi/en: khối `export*` liền ở cuối file (khối `filter*` từ cherry-pick nằm giữa file, dòng ~88).
- **Thư viện**: `pdf ^3.13.1` (Apache-2.0, thuần Dart, không mạng), `archive ^4.6.0` (MIT; trước là
  phụ thuộc gián tiếp, nay trực tiếp). Kéo thêm gián tiếp: barcode (Apache-2.0), bidi (MIT), image (MIT),
  path_parsing (MIT), qr (BSD-3). Dev: `xml ^7.0.1` (MIT, đã có gián tiếp) để test đọc lại xlsx.
  Không chọn gói `excel` (khó kiểm kiểu ô/định dạng số, lỗi số lẻ) và Syncfusion (giấy phép thương mại).
  SBOM: `python tool/make_sbom.py` → `docs/sbom/vigon.cdx.json`.

## Kiểm thế nào
- `flutter analyze`: sạch. `flutter test` toàn bộ: 918 pass, 1 skip (như trước).
- `test/data/entry_filter_test.dart` (+2): tổng D-042 (3×10 000 ₫ → $1.16, không phải $1.17), thiếu tỷ
  giá, khoảng tiền theo TT chính.
- `test/features/f39_filter_test.dart` (+1): lọc VÀ với lọc tài khoản và tìm kiếm.
- `test/features/f40_export_test.dart` (mới, 10): đọc lại xlsx (tên sheet vi/en, tiêu đề, kiểu ô số,
  định dạng đúng số lẻ, ô ngày, chuyển tiền khác tiền tệ, % theo danh mục, khoản nợ còn lại theo TT
  chính); chặn công thức (không ô nào có `<f>`, ô `= @ + -` là chữ + quotePrefix); thoát ký tự XML;
  PDF: trích chữ (giải nén stream + ToUnicode) có tiêu đề, tổng, danh mục có dấu, ₫, ghi chú, "Trang 1/1";
  1.000 khoản → > 10 trang, "Trang n/n", xlsx 1.001 dòng, tất cả < 10 giây (trên PC ~2 giây);
  font có đủ chữ Việt + ₫.
- `test/features/f40_export_flow_test.dart` (mới, 3): Cài đặt → Xuất Excel → Kỳ đang xem → file chia
  sẻ là .xlsx đọc lại được; Xuất PDF → Khoảng tùy chọn 1–2/11 → PDF chỉ có khoản trong khoảng (font
  nạp từ assets thật); đóng bảng phạm vi thì không xuất. Bảng chia sẻ + thư mục tạm giả bằng
  MethodChannel mock.
- `test/features/g6_accessibility_test.dart` (+4): bảng Lọc và bảng Xuất, sáng/tối, chữ 100/200%.
- Bộ đọc dùng chung cho test: `test/export_readers.dart` (`readXlsx`, `extractPdfText`, `pdfPageCount`).
- Chưa thử trên máy (không dùng adb theo brief): **[M]** mở .xlsx bằng Excel + Google Sheets, PDF
  hiển thị + thời gian 1.000 khoản trên Galaxy A13.

## Việc dở / rủi ro
- **CSV chưa theo D-042**: `exportCsv` (backup.dart, ngoài phạm vi) vẫn ghi `e.amount` (số dẫn xuất) +
  một mã Tiền tệ chính cho mọi dòng → khoản ₫ khi TT chính USD ghi số USD. Cột Giờ/Nguồn (AC-124) đã
  có từ trước. Nên sửa: cột số gốc + tiền tệ gốc (+ cột theo TT chính ở cuối).
- **Dòng kết quả tìm/lọc** (`SearchResultTile`) vẫn hiện số gốc một dòng, chưa "TT chính trên, gốc
  dưới" (AC-146) — là phần F-15 dùng chung; để phiên giao diện D-042 sửa cùng dòng khoản thường.
- Phạm vi xuất lấy **mọi tài khoản** (không theo Lọc tài khoản của màn chính) và sheet "Khoản nợ" xuất
  **mọi khoản nợ** (không theo khoảng ngày) — SPEC không nói; đổi dễ trong `loadExportData`.
- Bộ lọc giữ id danh mục đã chọn; khôi phục/xoá toàn bộ dữ liệu không xoá bộ lọc (chip danh mục không
  còn thì không hiện). Chưa gặp lỗi, nhưng nên `clear()` cùng chỗ bỏ Lọc tài khoản.
- Ghi chú có emoji/ký tự font không có → PDF bỏ ký tự đó (gói pdf in cảnh báo), không lỗi.

## Chỗ có thể xung đột khi gộp
- `lib/l10n/app_{vi,en}.arb` + 3 file sinh `app_localizations*.dart` (khối cuối file; phiên C2/C4 cũng
  thêm ở cuối → xung đột vị trí, giữ cả hai khối rồi `flutter pub get` sinh lại).
- `settings_screen.dart` nhóm Dữ liệu (C4 thêm công tắc vân tay ở nhóm Bảo mật — khác chỗ).
- `pubspec.yaml`/`pubspec.lock`, `docs/sbom/vigon.cdx.json` (nếu phiên khác cũng thêm gói: chạy lại
  `flutter pub get` + `python tool/make_sbom.py` sau khi gộp).
- `test/features/g6_accessibility_test.dart` (khối thêm ở cuối `main`).

## Đề xuất cải tiến xưởng
- `test/export_readers.dart` (đọc lại xlsx, trích chữ PDF của gói `pdf`) và `xlsx_writer.dart` dùng lại
  được cho A001 và app sau → đưa vào code dùng chung của xưởng khi có thư mục shared.
- Mẫu worktree trong brief: kiểm `apps/<mã>` trong worktree xưởng đã tồn tại chưa trước khi
  `git worktree add` (lần này tên worktree xưởng trùng worktree cũ có việc dở) — thêm một dòng vào
  BRIEF-phien-con: "nếu đã có thì dùng `apps/<mã>-<việc>`".
