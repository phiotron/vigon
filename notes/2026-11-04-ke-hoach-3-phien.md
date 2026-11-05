> **Cập nhật 2026-11-04 (sau khi duyệt):** iOS build/test bằng **GitHub Actions macOS runner** (không phải Codemagic) — đồng bộ fact xưởng; người dùng **không có iPhone** → thử iOS trên simulator của CI; người dùng cho phép push để chạy CI. Mọi chỗ "Codemagic"/"codemagic.yaml" dưới đây hiểu là GitHub Actions/`.github/workflows/`.

# [A002-vigon] Chuyển Ví Gọn vào Mobile App Studio + kế hoạch 3 phiên điều phối

## Context
Ví Gọn là app Flutter ghi thu chi offline, đã code trước khi vào xưởng (118 test đạt; còn chờ người dùng: link chính sách, TalkBack, khóa ký). Người dùng muốn:
1. Chuyển hẳn app sang `D:/Mobile App/apps/` và đưa hẳn vào khung xưởng (APP.md, notes/, WORKFLOW §3/§7).
2. Viết `product.md` (tiếng Anh) mô tả chi tiết tính năng + giao diện để gửi **Claude Design** làm mockup Hi-Fi, theo hướng **nâng cấp từ UI hiện tại**, đúng phạm vi SPEC hiện tại.
3. Áp mockup và phát hành trên **Android + iOS**. App xong trong **≤ 3 phiên điều phối**. Phiên này là phiên điều phối #1, tách riêng khỏi chat Subnest đang chạy.

Các quyết định đã chốt: mã **`A002-vigon`** (A001 là Subnest). **Di chuyển hẳn** thư mục, **không sửa gì ở nơi cũ**. **Giữ** remote `phiotron/vigon`. **Giữ 16 worktree cũ** và sửa liên kết sau khi chuyển. Build iOS bằng **Codemagic**. Tài khoản Apple **chưa có**, sẽ đăng ký (cá nhân). Có iPhone thật. Google Play là **tài khoản cá nhân**, nên phải chạy closed test 12 tester trong 14 ngày. **Không** mang các bài học của khung quy trình cũ sang.

Làm việc theo `CLAUDE.md` + `WORKFLOW.md`: phiên điều phối + phiên con (`start_session`), **không dùng subagent**. Các phiên con của cùng một app phải có tập file không chồng nhau.

---

## Phiên điều phối #1 — Chuyển + product.md (phiên này)

### Bước điều phối tự làm (tuần tự)
0. **Điều kiện trước:** người dùng xác nhận không còn phiên Claude, Android Studio hay terminal nào đang mở trong thư mục cũ ngoài xưởng. Chạy `android/gradlew --stop` để nhả khóa file.
1. **Cấp mã:** thêm dòng `A002-vigon` vào `apps/REGISTRY.md` ngay. Nội dung: Ví Gọn, thu chi offline, `com.phiotron.vigon`, 🔨, repo `phiotron/vigon`, ghi chú "Flutter; vi/en; Android+iOS; app đã code trước khi vào xưởng". File này đang có dòng A001 chưa commit của phiên Subnest: chỉ thêm dòng của mình, không commit đè phần của phiên kia.
2. **Di chuyển:** `mv <thư mục cũ> "D:/Mobile App/apps/A002-vigon"`. Cùng ổ D nên đây là đổi tên nguyên khối: nếu còn file bị khóa thì lệnh thất bại và không có gì bị chuyển dở.
3. **Sửa git:**
   - `git worktree repair <16 đường dẫn mới trong .claude/worktrees/*>` → kiểm bằng `git worktree list`.
   - Đổi tên `master` → `main` (`git branch -m master main`, upstream `origin/main`; `origin/main` đang chậm 1 commit). **Chưa push**: chỉ push khi người dùng bảo (theo dặn cũ trong app).
4. **Đưa vào khung xưởng** (theo lựa chọn "chuyển hẳn"):
   - Tạo `APP.md` từ `playbook/templates/APP.md`. Gộp vào đó: mô tả và người dùng (từ `CLAUDE.md` app), MVP và các màn (tóm tắt `docs/SPEC.md` + `ui-spec.md`), việc dở (mục `[ ]` trong `docs/BACKLOG.md`), quyết định D-001..D-009 (sửa D-001 thành **thêm iOS**), mục **Lệnh** và **Lưu ý dễ vấp** (Flutter chưa vào PATH, máy 32-bit BUG-001, không tự dùng adb khi chưa hỏi, test drift trong `runAsync`), và bảng trạng thái "#1 2026-11-04".
   - Xoá các file khung quy trình cũ sau khi đã gộp: `CLAUDE.md` app, `docs/BACKLOG.md`, `docs/PROMPTS.md`, `docs/RUNBOOK.md`, `docs/plans/`, `.claude/commands/`, `.claude/agents/`. Kiểm `.claude/settings.json`: bỏ hook/permission trỏ tới script cũ ngoài xưởng. Chuyển `RETROSPECTIVE.md` vào `notes/`.
   - Sắp xếp lại: `docs/store/` → `store/`, còn `ui-spec.md` và `design-mobile/` → `design/current/`. Giữ làm tài liệu tham chiếu: `docs/SPEC.md` (AC dùng cho test), `ARCHITECTURE`, `TESTING`, `SECURITY`, `COMPLIANCE`, `RISKS`, `RELEASE`, `legal/`, `sbom/`, `security/`, `audits/`.
   - `grep -rn "\.\./\.\./"` + tên nơi cũ rồi sửa hết các tham chiếu còn sót. Chạy `flutter analyze` + `flutter test` để chắc chắn việc chuyển không làm hỏng gì (vẫn phải 118 test đạt).
   - Commit `[A002-vigon] move into Mobile App Studio framework` (chỉ `git add` các file cụ thể).
5. **File cấp xưởng:** thêm dòng A002 vào bảng app và việc của người dùng trong `TASKS.md` (chỉ dòng của A002). Thêm fact `memory/facts/ios-build-codemagic.md` + 1 dòng vào `MEMORY.md`.
6. Mở 3 phiên con song song (dưới đây) bằng `start_session` (`use_worktree: false`, cwd = `apps/A002-vigon`), mỗi brief theo `playbook/templates/BRIEF-phien-con.md`.

### Phiên con #1 (song song, file không chồng nhau)
| Phiên con | Phạm vi file | Kết quả |
|---|---|---|
| **A. `[A002-vigon] product.md cho Claude Design`** | chỉ `product.md`, `CONTEXT.md` | Viết `product.md` **tiếng Anh**, đọc từ SPEC, `design/current/`, `lib/l10n/*.arb`, `lib/src/features/`. Gồm: tổng quan, persona, nguyên tắc (offline, riêng tư, nhập nhanh ≤ 3 chạm), ràng buộc thiết kế (Material 3 thích ứng iOS, sáng/tối, cỡ chữ 200%, vùng chạm 48dp, chỉ dọc, màn 360×800 và iPhone), **từng màn**: mục đích, thành phần, trạng thái (trống/lỗi/khóa), tương tác, chữ hiển thị (EN; ghi chú chữ VI dài nhất), các luồng chính, điểm UX đang yếu cần tối ưu, khác biệt Android/iOS (back, share sheet, chọn file), và danh sách màn + định dạng xuất mong muốn từ Claude Design. Thêm `CONTEXT.md` (bảng thuật ngữ nghiệp vụ: Entry, Category, Account, Transfer, Recurring series, Budget, Period, Backup…, theo mẫu `A001-subnest/CONTEXT.md`). |
| **B. `[A002-vigon] Nền iOS + Codemagic`** | `ios/`, `codemagic.yaml`, `pubspec.yaml`/`pubspec.lock` (**chỉ phiên này** được đổi dependency), code riêng nền tảng nếu bắt buộc (ghi rõ file) | `flutter create --platforms ios --org com.phiotron .`. Info.plist: tên hiển thị, `ITSAppUsesNonExemptEncryption=false`, khai báo kiểu file `.vigon` để mở/nhập. Thêm `PrivacyInfo.xcprivacy`. Kiểm từng plugin (drift/sqlite, secure storage → Keychain, share, chọn file) có hỗ trợ iOS. `codemagic.yaml`: workflow build simulator không ký + workflow release dùng env group (không có bí mật trong repo). `flutter analyze`/`test` vẫn đạt. Ghi rõ phần **CHƯA kiểm chứng** vì chưa có Apple account và Codemagic chưa nối repo. |
| **C. `[A002-vigon] Store & pháp lý 2 nền tảng`** | `store/`, `docs/legal/`, `docs/COMPLIANCE.md` | Listing App Store EN/VI (tên ≤ 30, phụ đề, keyword 100 ký tự, mô tả), App Privacy "Data Not Collected", độ tuổi. Cập nhật chính sách cho iOS. Rà lại Data safety của Play. Checklist closed test Play cá nhân (12 tester, 14 ngày). Danh sách kích thước ảnh chụp cần có (chụp thật ở #3 với UI mới). |

### Điều phối kiểm và đóng #1
- Đọc kỹ `product.md` (đúng SPEC, đủ màn, đủ trạng thái). Đưa người dùng duyệt **trước khi gửi Claude Design**. Kiểm diff của B (build/test chạy thật) và C.
- Gộp báo cáo `notes/` vào `APP.md`, `/dong-phien` (session log `memory/sessions/2026-11-04-A002-vigon.md`, METRICS ghi "app đã code trước khi vào xưởng").

### Việc của người dùng giữa #1 và #2 (ghi vào TASKS)
- Gửi `product.md` + `design/current/` sang Claude Design, lưu mockup xuất ra vào `apps/A002-vigon/design/hifi/` (ảnh/HTML theo màn).
- Đăng ký Apple Developer (cá nhân), tạo App ID `com.phiotron.vigon`, App Store Connect API key → Codemagic env group. Nối Codemagic với repo `phiotron/vigon`.
- Mở tài khoản Play Console cá nhân. Tự tạo upload keystore (Claude không nhập mật khẩu). **Bắt đầu closed test 14 ngày sớm nhất có thể**, dùng ngay build hiện tại.
- Các việc còn treo từ trước: đăng chính sách lên web lấy link, TalkBack + cỡ chữ lớn nhất, mở CSV bằng Excel.

---

## Phiên điều phối #2 — Áp UI Hi-Fi + test 2 nền tảng
Đầu vào: `design/hifi/`. Điều phối đối chiếu mockup với các màn và chia phiên con:
| Phiên con | Phạm vi | Thứ tự |
|---|---|---|
| D0. Theme, token, widget dùng chung, **toàn bộ chữ mới trong `.arb`** | `lib/src/app.dart` (theme), `lib/src/ui/`, `lib/l10n/` | chạy **trước, một mình**. Sau đó các phiên khác không sửa `.arb`; thiếu chữ thì ghi notes |
| D1. Màn chính + nhập khoản | `lib/src/features/home*`, `entry*` + test tương ứng | sau D0 |
| D2. Kỳ, danh mục, tài khoản, chuyển tiền | `features/period*`, `category*`, `account*`, `transfer*` | song song D1 |
| D3. Định kỳ, ngân sách, cài đặt, sao lưu, PIN, giới thiệu | `features/recurring*`, `budget*`, `settings*`, `backup*`, `lock*`, `about*` | song song D1 |
| D4. Thử máy thật: Android (adb, hỏi trước) + iPhone (TestFlight qua Codemagic) | chỉ `notes/`, sửa lỗi nhỏ ghi rõ file | sau D1–D3 |
Cổng: `flutter analyze` sạch, `flutter test` đạt (cập nhật widget test theo UI mới), thử trên 2 máy thật, người dùng duyệt UI.

## Phiên điều phối #3 — Phát hành
- E. Ảnh chụp store từ UI mới cho cả 2 nền tảng (`store/`). F. Android: AAB đã ký → closed test → production khi đủ 14 ngày. G. iOS: Codemagic → TestFlight → App Review, xử lý bị từ chối.
- Chạy `playbook/checklists/release-*.md`. Tag `v1.0.0`. Retro trong APP.md, METRICS, chọn 1–3 cải tiến Playbook. Thời gian chờ store duyệt không tính là phiên.

---

## Kiểm chứng
- Sau khi chuyển: `git -C apps/A002-vigon worktree list` không còn dòng "prunable"; `git status` sạch (trừ các file đã chủ động sắp xếp); `flutter analyze` + `flutter test` (với `export PATH="/c/src/flutter/bin:$PATH"`) đạt như trước; grep tên nơi cũ không còn kết quả nào.
- Thư mục cũ ngoài xưởng không còn tồn tại; các file khác ở đó không bị đụng tới.
- Cuối #1: `product.md` đã được người dùng duyệt. B có kết quả build/test thật, hoặc đánh dấu rõ CHƯA kiểm chứng kèm lý do. APP.md, TASKS, REGISTRY phản ánh đúng trạng thái.
