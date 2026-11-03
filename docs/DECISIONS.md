# DECISIONS — Nhật ký quyết định kiến trúc

Mỗi quyết định một mục, mới nhất ở trên cùng.

## D-005 · Mô hình dữ liệu: tiền số nguyên, ngày dạng chữ, cài đặt trong cơ sở dữ liệu · 2026-11-03
- Bối cảnh: SPEC AC-07, AC-22 đòi tổng đúng tới đơn vị nhỏ nhất; AC-29 khôi phục cả cài đặt; AC-15 tên danh mục mặc định theo ngôn ngữ máy.
- Quyết định: Số tiền lưu `int` theo đơn vị nhỏ nhất của tiền tệ (VND: đồng, USD: cent), luôn > 0, chiều thu/chi nằm ở cột `type`. Ngày của khoản lưu chữ `YYYY-MM-DD` (giờ địa phương, so sánh được bằng chuỗi, không lệch múi giờ). Cài đặt lưu bảng khóa-giá trị trong cùng SQLite (không dùng SharedPreferences) để một file sao lưu chứa đủ. Danh mục và tài khoản mặc định có `nameKey` để hiện theo ngôn ngữ; người dùng đổi tên thì ghi `name` và bỏ qua `nameKey`.
- Lý do / phương án đã loại: Số thực `double` (loại: sai số làm tròn khi cộng dồn). Lưu ngày bằng timestamp (loại: đổi múi giờ làm khoản nhảy sang ngày khác). SharedPreferences cho cài đặt (loại: phải sao lưu hai nơi).
- Hệ quả cần nhớ: Đổi tiền tệ ở G3 phải xử lý số chữ số thập phân khác nhau (VND 0, USD 2). Mọi đổi schema phải tăng `schemaVersion` và viết migration kèm test.

## D-004 · SQLite qua drift, file sinh tự động được commit · 2026-11-03
- Bối cảnh: Cần lưu offline, có giao dịch (SPEC 5b: tắt app đột ngột không mất khoản), migration và test không cần máy thật.
- Quyết định: `drift` + `drift_flutter` (SQLite). Sinh mã bằng `dart run build_runner build`; file `*.g.dart` được COMMIT để clone về là `flutter analyze` và `flutter test` chạy được ngay.
- Lý do / phương án đã loại: `sqflite` (loại: SQL viết tay, không kiểm kiểu, test trên máy tính cần thêm gói ffi). Hive/Isar (loại: không phải SQL, truy vấn tổng theo kỳ và danh mục khó hơn; Isar ít được bảo trì).
- Hệ quả cần nhớ: Sửa bảng xong phải chạy lại build_runner rồi mới analyze/test. Test dùng cơ sở dữ liệu trong bộ nhớ (`NativeDatabase.memory()`).

## D-003 · Phiên bản Flutter, quản lý trạng thái, điều hướng, đa ngôn ngữ · 2026-11-03
- Bối cảnh: G1 khởi tạo dự án. Máy đã có Flutter tại `C:\src\flutter`, checkout tag `3.47.8` (Dart 3.13.7), chưa có trong PATH; chưa cài FVM.
- Quyết định: Ghim Flutter 3.47.8 (ghi trong CI và mục "Lệnh"; không cài FVM khi chỉ có một app Flutter). Trạng thái: `flutter_riverpod` 3. Điều hướng: `go_router`. Đa ngôn ngữ: `flutter_localizations` + `gen-l10n` chính thức với file `.arb` (vi, en). Chỉ tạo nền tảng Android (`--platforms android`); thêm iOS sau bằng `flutter create --platforms ios .`. Package: `com.phiotron.vigon` (người dùng chọn).
- Lý do / phương án đã loại: Provider (loại: Riverpod test được không cần widget, ít phụ thuộc BuildContext). Bloc (loại: nhiều mã mẫu cho app nhỏ). Navigator 1.0 (loại: go_router xử lý nút Back và khóa PIN ở G5 gọn hơn bằng redirect).
- Mức SDK thực tế của bản build 2026-11-03: minSdk 24 (Android 7.0), targetSdk 36, do Flutter 3.47.8 quản lý.
- Hệ quả cần nhớ: Khi có app Flutter thứ hai cần phiên bản khác thì cài FVM và thêm `.fvmrc`. Không trộn cách quản lý trạng thái khác.

## D-002 · Chỉ lưu trên máy, không máy chủ, không SDK bên thứ ba · 2026-11-03
- Bối cảnh: App miễn phí, bán ở Việt Nam và toàn cầu, dữ liệu là tài chính cá nhân.
- Quyết định: Dữ liệu chỉ nằm trong SQLite trên máy; không tài khoản, không máy chủ, không analytics, quảng cáo hay SDK báo crash; bản release không có quyền INTERNET. Sao lưu bằng file người dùng tự xuất. Theo dõi crash qua Android vitals của Play Console.
- Lý do / phương án đã loại: Đồng bộ đám mây (loại ở v1: cần máy chủ hoặc đăng nhập Google, kéo theo rất nhiều mục tuân thủ dữ liệu, hợp đồng xử lý, chuyển dữ liệu xuyên biên giới). SDK báo crash như Firebase Crashlytics (loại: gửi dữ liệu ra ngoài, phải xin đồng ý ở EU và khai Data safety).
- Hệ quả cần nhớ: Mất máy mà chưa xuất file là mất dữ liệu; quên PIN là không vào lại được. Thêm bất kỳ tính năng gọi mạng nào sau này phải mở lại COMPLIANCE mục D-xx.

## D-001 · Stack Flutter, Android trước · 2026-11-03
- Bối cảnh: Người dùng chọn Flutter khi tạo app; phát hành Android trước, iOS để sau.
- Quyết định: Flutter (Dart), một codebase; v1 chỉ build và phát hành Android.
- Lý do / phương án đã loại: Expo/React Native (loại: người dùng đã chọn Flutter; Flutter vẽ biểu đồ và giao diện tùy biến mượt, có CI mẫu trong `shared/stacks/flutter.ci.yml`). iOS ở v1 (loại: cần máy Mac và tài khoản Apple Developer).
- Hệ quả cần nhớ: Code không dùng thứ chỉ có trên Android khi có lựa chọn đa nền tảng, để thêm iOS sau không phải viết lại.
