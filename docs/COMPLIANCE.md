# COMPLIANCE — Ví Gọn (APP-001)

Hồ sơ tuân thủ theo `../../../shared/standards/tieu-chuan-ban-app-toan-cau.md` (tài liệu gốc, cập nhật 28/10/2026; ghi "L<n>" là Lớp n trong tài liệu đó).
Không phải tư vấn pháp lý: trước khi mở bán ở nước nào cần luật sư địa phương xác nhận (tài liệu gốc, phần Tóm tắt).

## 1. Phạm vi (điền ở /spec, quyết định mục nào áp dụng)
- Thị trường định bán (ghi nhóm theo "Ma trận theo thị trường": A/B/C; nhóm D không được bán): Việt Nam và toàn cầu: nhóm A và nhóm B (gồm Việt Nam). Nhóm C (Trung Quốc đại lục, Nga) chưa mở. Nhóm D chặn trong Play Console.
- Có tài khoản người dùng: không
- Dữ liệu cá nhân thu thập (loại, mục đích, nơi lưu, bên nhận, thời gian giữ): nhà phát triển không thu thập. Người dùng tự ghi khoản thu chi, danh mục, ghi chú; chỉ lưu trong SQLite trên máy; không bên nhận; giữ tới khi người dùng xóa hoặc gỡ app. File sao lưu do người dùng tự xuất và giữ.
- Dữ liệu rủi ro cao (nhạy cảm, vị trí chính xác, trẻ em, sinh trắc học, hồ sơ hóa bằng AI): không gửi đi đâu; dữ liệu tài chính cá nhân trên máy có thể bị luật VN coi là nhạy cảm, cần luật sư xác nhận (D-07)
- Người dưới 18 tuổi có thể dùng: có (không nhắm tới trẻ em)
- Bán hàng số, thuê bao hoặc thanh toán trong app: không
- SDK bên thứ ba (analytics, quảng cáo, đăng nhập xã hội, AI): không có
- Gửi dữ liệu cho AI bên thứ ba, hoặc app có chatbot/nội dung do AI tạo: không
- Ngành có quy định riêng (y tế, tài chính, trẻ em, ô tô...): không (ghi chép chi tiêu cá nhân, không thanh toán, không dữ liệu thẻ)
- Doanh nghiệp siêu nhỏ (dưới 10 người và doanh thu không quá 2 triệu euro, miễn EAA khi cung cấp dịch vụ, L4): chưa rõ, chờ người dùng xác nhận phát hành dưới tên cá nhân hay công ty; dù thế nào vẫn giữ mục tiêu WCAG 2.2 AA

## 2. Danh mục kiểm (Trạng thái: đạt / không áp dụng / chưa. "Bằng chứng": file:dòng, ảnh chụp, đường dẫn, lệnh đã chạy; ghi ngày kiểm)
| ID | Áp dụng khi | Yêu cầu | Nguồn | Trạng thái | Bằng chứng, ngày |
|----|-------------|---------|-------|------------|------------------|
| M-01 | Mọi app | Danh sách thị trường đã chốt; đã loại nước và vùng bị cấm vận toàn diện (rà danh sách OFAC, EU, Anh, LHQ hiện hành) và chặn theo địa lý nếu cần | Tóm tắt, L6, Ma trận | chưa | |
| D-01 | Có dữ liệu cá nhân | Kiểm kê dữ liệu (RoPA) và bản đồ luồng dữ liệu: loại, mục đích, căn cứ pháp lý, nơi lưu, bên nhận, thời gian giữ | L3 nền chung 1 | đạt | Bản đồ dữ liệu trong `docs/SECURITY.md` mục "Dữ liệu thu thập và lưu trữ": nhà phát triển không nhận dữ liệu; căn cứ pháp lý theo luật VN chờ luật sư (D-07), 2026-11-03 |
| D-02 | Có dữ liệu cá nhân | Chính sách quyền riêng tư; đường dẫn đặt trong Play Console và trong app | L3, L5 Google "Dữ liệu người dùng" | chưa | Chính sách vi/en đã viết: `docs/legal/privacy-policy.md`; liên kết trong app ở màn Giới thiệu (`lib/src/features/about/about_screen.dart`, AC-41). CHƯA đăng Google Sites và chưa điền `lib/src/app_info.dart` + Play Console, 2026-11-03 |
| D-03 | Có dữ liệu cá nhân | Đồng ý theo từng mục đích, không gộp, rút lại dễ như lúc cho; im lặng không coi là đồng ý (Luật VN 91/2025 Điều 9) | L3 nền chung 2 | không áp dụng | Nhà phát triển không nhận dữ liệu; mọi xử lý chỉ trên máy người dùng (D-002), 2026-11-03 |
| D-04 | Có SDK bên thứ ba | SDK analytics/quảng cáo/AI không khởi động trước khi có đồng ý ở nơi luật đòi (EU, Anh); dùng nền tảng quản lý đồng ý hỗ trợ iOS và Android | L3 "Điểm riêng của app mobile" | không áp dụng | Không có SDK bên thứ ba (D-002), 2026-11-03 |
| D-05 | Có tài khoản | Xóa tài khoản ngay trong app (Apple 5.1.1(v)) và qua một trang web ngoài (Google Play) | L3 nền chung 3, L5 | không áp dụng | Không có tài khoản; thay bằng "Xóa toàn bộ dữ liệu" AC-42, 2026-11-03 |
| D-06 | Có dữ liệu cá nhân | Quy trình quyền người dùng: truy cập, sửa, xóa, mang dữ liệu đi, rút đồng ý, phản đối quyết định tự động | L3 nền chung 3 | đạt | Người dùng tự thực hiện trong app: xem/sửa từng khoản, xuất sao lưu và CSV (AC-28, AC-30), xóa toàn bộ (AC-42); không có quyết định tự động; ghi ở chính sách mục 7, 2026-11-03 |
| D-07 | Dữ liệu rủi ro cao | Đánh giá tác động (DPIA/PIA); bán ở Việt Nam: nộp hồ sơ trong 60 ngày kể từ khi bắt đầu xử lý (Điều 21) | L3 nền chung 4 | chưa | Dữ liệu tài chính cá nhân chỉ nằm trên máy; cần luật sư xác nhận có phải lập DPIA/nộp hồ sơ ở VN không |
| D-08 | Có dữ liệu cá nhân | Kịch bản xử lý vi phạm theo hạn ngắn nhất trong các thị trường đã chọn (ví dụ 72 giờ ở EU và Việt Nam; xem ma trận L3) | L3 nền chung 5 | đạt | Thủ tục trong `docs/SECURITY.md` mục "Tiếp nhận và xử lý lỗ hổng"; nhà phát triển không giữ dữ liệu người dùng, 2026-11-03 |
| D-09 | Có dữ liệu cá nhân, bán ở VN | Chỉ định bộ phận hoặc nhân sự bảo vệ dữ liệu (Điều 33(2)); đại diện pháp lý ở nơi luật đòi (EU/Anh, Brazil, Trung Quốc, Hàn Quốc, Thổ Nhĩ Kỳ) | L3 nền chung 6 | chưa | Cần luật sư xác nhận khi nhà phát triển không nhận dữ liệu |
| D-10 | Dùng nhà cung cấp xử lý dữ liệu | Hợp đồng xử lý dữ liệu với cloud, analytics, push, thanh toán, AI; cơ chế chuyển dữ liệu ra nước ngoài hợp pháp (VN: hồ sơ trong 60 ngày từ lần chuyển đầu) | L3 nền chung 7, "Kiến trúc chuyển dữ liệu" | không áp dụng | Không dùng nhà cung cấp xử lý dữ liệu (D-002), 2026-11-03 |
| D-11 | Mọi app | Quyền hệ thống (vị trí, danh bạ, camera, micro, thông báo) chỉ xin khi cần cho tính năng, không ép bật để dùng app | L3 "Điểm riêng", L5 Apple 5.1.1 | đạt | Không xin quyền nào: `aapt2 dump permissions` bản release chỉ có quyền nội bộ AndroidX, 2026-11-03 |
| D-12 | Người dưới 18 có thể dùng | Dùng tín hiệu tuổi của hệ điều hành (Declared Age Range của Apple, Play Age Signals của Google) và đối chiếu luật tuổi theo thị trường ở L3 | L3 "Điểm riêng", L5 | chưa | Chờ người dùng quyết có tích hợp Play Age Signals (SPEC mục 7) |
| D-13 | Gửi dữ liệu cho AI bên thứ ba | Nêu rõ nơi dữ liệu được chia sẻ, kể cả AI bên thứ ba, và xin phép rõ ràng trước khi chia sẻ (Apple 5.1.2(i)) | L3, L5 | không áp dụng | Không dùng AI, 2026-11-03 |
| S-01 | Mọi app | Tự kiểm theo 8 nhóm OWASP MASVS v2.1.0: STORAGE, CRYPTO, AUTH, NETWORK, PLATFORM, CODE, RESILIENCE, PRIVACY (ghi kết quả từng nhóm) | L2 "Tiêu chí kỹ thuật" | đạt | `docs/security/MASVS-SELF-CHECK.md` (8 nhóm, mức L1; lưu ý: dữ liệu không mã hóa, PIN 4 số, chưa quét OSV), 2026-11-03 |
| S-02 | Có API/backend | Kiểm API theo OWASP ASVS 5.0.0; truyền tải mã hóa TLS 1.3 | L2 | không áp dụng | Không có API/backend, 2026-11-03 |
| S-03 | Có đăng nhập | Đăng nhập theo OAuth 2.0/OIDC (RFC 9700) hoặc passkey (WebAuthn/FIDO2); có đăng nhập bên thứ ba trên iOS thì có thêm một lựa chọn tương đương theo Apple 4.8 | L2, L5 | không áp dụng | Không có đăng nhập, 2026-11-03 |
| S-04 | Mọi app | SBOM sinh tự động (SPDX hoặc CycloneDX) và rà giấy phép nguồn mở theo danh sách SPDX | L2 "Chuỗi cung ứng", L6 | đạt | SBOM CycloneDX 1.5 `docs/sbom/vigon.cdx.json` sinh bằng `python tool/make_sbom.py`: 107 gói, BSD-3-Clause 81, MIT 21, Apache-2.0 4, MPL-2.0 1 (`dbus`, phụ thuộc Linux gián tiếp); không có GPL/AGPL, 2026-11-03. Thêm 2026-11-04 (PLAN-001): `material_symbols_icons` (Apache-2.0, trong SBOM, 108 gói); font Be Vietnam Pro (OFL-1.1) là tài sản trong `assets/fonts/`, không phải gói Dart nên không có trong SBOM, giấy phép hiện ở màn giấy phép |
| S-05 | Mọi app | Kênh tiếp nhận lỗ hổng công khai (ví dụ security.txt theo RFC 9116 hoặc email) và thủ tục xử lý | L2 | đạt | Email `phamphuongphuong@gmail.com` trong app (Giới thiệu → Báo lỗi bảo mật, thử trên máy mở đúng Gmail có tiêu đề) và chính sách; thủ tục ở `docs/SECURITY.md`, 2026-11-03 |
| S-06 | Bán ở EU | CRA: kế hoạch báo lỗ hổng đang bị khai thác và sự cố nghiêm trọng (cảnh báo sớm 24 giờ, thông báo 72 giờ, từ 11/09/2026); công bố thời hạn hỗ trợ cập nhật bảo mật (Recital 60: không dưới năm năm trừ khi tuổi thọ dự kiến ngắn hơn) | L2 CRA | chưa | Cần luật sư xác nhận app miễn phí có thuộc phạm vi CRA (SPEC mục 7) |
| S-07 | Lưu, xử lý hoặc truyền dữ liệu thẻ | PCI DSS v4.0.1; gợi ý của tài liệu: dùng cổng thanh toán bên thứ ba (hosted page/redirect) để thu hẹp phạm vi | L2 | không áp dụng | Không xử lý dữ liệu thẻ, 2026-11-03 |
| A-01 | Mọi app | Mục tiêu thiết kế WCAG 2.2 mức AA; bán ở EU: chứng minh theo EN 301 549 v3.2.1; kiểm bằng VoiceOver và TalkBack; lưu tuyên bố accessibility cho từng bản phát hành | L4 | chưa | Tự động đạt: `test/features/g6_accessibility_test.dart` kiểm vùng chạm 48 dp, nhãn, tương phản chữ và lỗi vẽ trên mọi màn chính, sáng/tối, cỡ chữ 100%/200%; máy thật: mọi nút bấm được đều có nhãn (uiautomator). CHƯA: thử TalkBack và cỡ chữ lớn nhất trên máy thật, tuyên bố accessibility, 2026-11-03 |
| C-01 | Bán hàng số/thuê bao | Hiển thị giá và điều kiện trước khi thanh toán; cho hủy ngay trong app; nhắc trước khi gia hạn | L4 "Bảo vệ người tiêu dùng" | không áp dụng | Miễn phí, không bán gì, 2026-11-03 |
| C-02 | Bán trực tuyến cho người tiêu dùng EU | Chức năng rút khỏi hợp đồng (Điều 11a Chỉ thị 2023/2673, áp dụng từ 19/06/2026) | L4 | không áp dụng | Không bán trực tuyến, 2026-11-03 |
| C-03 | Bán ở EU | Trách nhiệm sản phẩm (Chỉ thị 2024/2853, sản phẩm đưa ra thị trường sau 09/12/2026): công bố thời hạn cập nhật bảo mật, lưu hồ sơ kiểm thử và vòng đời | L4 | chưa | |
| P-01 | Phát hành iOS | Build bằng Xcode 26 trở lên với SDK iOS 26 trở lên (từ 28/04/2026) | L5 Apple | chưa | iOS đưa vào phạm vi 2026-11-04 (D-011, PLAN-001 T6); kiểm khi build iOS |
| P-02 | Phát hành iOS | App privacy details khi nộp; tệp `PrivacyInfo.xcprivacy`; SDK phổ biến kèm privacy manifest và chữ ký | L5 Apple | chưa | iOS đưa vào phạm vi 2026-11-04 (D-011, PLAN-001 T6); kiểm khi build iOS |
| P-03 | Phát hành iOS | `ITSAppUsesNonExemptEncryption` trong Info.plist (NO nếu không mã hóa hoặc chỉ mã hóa miễn trừ) | L5 Apple, L6 | chưa | iOS đưa vào phạm vi 2026-11-04 (D-011, PLAN-001 T6); kiểm khi build iOS |
| P-04 | Phát hành iOS, có theo dõi | App Tracking Transparency (từ iOS 14.5; màn hình riêng cho EU từ iOS 27.2) | L5 Apple | không áp dụng | Không theo dõi người dùng, không SDK (D-002); iOS thêm theo D-011, 2026-11-04 |
| P-05 | Phát hành iOS | Bảng câu hỏi xếp hạng độ tuổi mới (Việt Nam: 00+, 12+, 16+, 18+ từ 18/06/2026) | L5 Apple | chưa | iOS đưa vào phạm vi 2026-11-04 (D-011, PLAN-001 T6); kiểm khi build iOS |
| P-06 | Phát hành Android | targetSdk = API 36 cho app mới và bản cập nhật (từ 31/08/2026, gia hạn tới 01/11/2026) | L5 Google | đạt | targetSdkVersion 36 (`aapt2 dump badging` bản release), 2026-11-03 |
| P-07 | Phát hành Android | Hỗ trợ trang bộ nhớ 16 KB (bắt buộc với bản cập nhật từ 01/02/2027) | L5 Google | đạt | `zipalign -c -P 16 -v 4` đạt; `llvm-readelf -lW` các `.so` arm64: LOAD align 0x4000 hoặc 0x10000, 2026-11-03 |
| P-08 | Phát hành Android | Xác minh nhà phát triển (từ 30/09/2026 tại Brazil, Indonesia, Singapore, Thái Lan; toàn cầu năm 2027) | L5 Google | chưa | |
| P-09 | Tài khoản Play cá nhân mới | Closed test với ít nhất 12 người thử, liên tục tối thiểu 14 ngày | L5 Google | chưa | |
| P-10 | Phát hành Android | Khai báo Data safety khớp với dữ liệu SDK thực sự thu thập; xếp hạng nội dung | L5 Google | chưa | |
| P-11 | Bán hàng số trong app | Apple: quy tắc thanh toán trong app của App Store (mục 3.1.1, xem L5); Google: Play Billing trừ khi thuộc §3, 8, 9 | L5 | không áp dụng | Không bán hàng số, 2026-11-03 |
| P-12 | App cho trẻ em trên Play | Chương trình Families: khai báo đối tượng, chỉ SDK quảng cáo được chứng nhận cho Families, tuân thủ COPPA và GDPR | L5 Google | không áp dụng | Không nhắm tới trẻ em, 2026-11-03 |
| T-01 | Bán có thu phí | Thuế giá trị gia tăng theo nơi bán (Apple làm đại lý theo Schedule 2; xem L6) | L6 | không áp dụng | Miễn phí, 2026-11-03 |
| T-02 | Mọi app phát hành | Bản địa hóa và định dạng theo thị trường | L6 | đạt | Giao diện vi/en theo ngôn ngữ máy (AC-36), số tiền và ngày theo ngôn ngữ (AC-22), tiền tệ theo vùng (AC-21): test tự động, 2026-11-03 |
| AI-01 | Có chatbot hoặc nội dung do AI tạo, bán ở EU | Nghĩa vụ minh bạch Điều 50 AI Act (từ 02/08/2026) | L7, Mốc | không áp dụng | Không có AI, 2026-11-03 |

## 3. Trước mỗi lần phát hành
- Kiểm lại trang Apple "Upcoming requirements" và bảng hạn chót của Google, vì đổi theo quý (L5 "Cách làm chung"); ghi ngày kiểm vào đây.
- Tài liệu tiêu chuẩn gốc cũ hơn 3 tháng so với ngày phát hành: kiểm lại các mốc ở bảng đầu tài liệu.
- Ngày kiểm lần cuối: 2026-11-03 (G6, chưa kiểm trang Apple/Google vì chưa tới `/release`)
