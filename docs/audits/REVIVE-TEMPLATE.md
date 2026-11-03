# REVIVE — APP-001 · Ví Gọn — {{REVIVE_DATE}}

Khôi phục app đã ngủ lâu. Quy tắc: mọi nhận định có bằng chứng (`file:dòng` hoặc lệnh đã chạy + kết quả) hoặc đánh dấu `[suy luận]` / `[chưa rõ]`. Yêu cầu hiện hành của store và nền tảng PHẢI tra cứu lại (kèm ngày và đường dẫn nguồn), không dùng trí nhớ vì chúng thay đổi theo thời gian.

## 0. Phạm vi và quyền đã được cấp
- Được chạy cài đặt thư viện/gọi mạng: có / không
- Được chạy lint, typecheck, test, build: có / không
- Được đọc giá trị trong `.env`: có / không
- Không đụng tới: (khóa ký, tài khoản store, dữ liệu thật)

## 1. Tóm tắt (tối đa 8 dòng)
- App này làm gì (một câu, theo SPEC):
- Ngủ bao lâu, lần cuối làm gì:
- Khôi phục được không / mức nâng cấp: nhỏ | vừa | lớn (nêu căn cứ):
- 3 rủi ro lớn nhất:
- Đề xuất: nâng cấp | giữ nguyên | đặt `paused` | bỏ (`abandoned`)

## 2. Dữ kiện tự động (đo bằng script, không phải nhận định)
<!-- FACTS -->

## 3. Baseline: dựng lại thật bằng công cụ hiện tại
Chạy theo mục 1 của RUNBOOK (nếu có). Ghi từng lệnh, thời gian, kết quả thật; lệnh nào không chạy được thì ghi "CHƯA kiểm chứng" và lý do.
| Bước | Lệnh | Kết quả thật | Ghi chú |
|------|------|--------------|---------|
| Cài đặt sạch | | | |
| Lint | | | |
| Typecheck | | | |
| Test | | | |
| Build | | | |
| Chạy thử (máy/giả lập) | | | |

## 4. Tài liệu có còn đúng code không
(Đối chiếu ARCHITECTURE.md, SPEC.md, RUNBOOK.md với code hiện tại và với báo cáo audit mới; liệt kê chỗ lệch, kèm bằng chứng. Sửa tài liệu cho đúng thực tế.)

## 5. Thư viện và nền tảng lỗi thời
- Kết quả kiểm tra thư viện (ví dụ `npm outdated`, `npm audit` hoặc `flutter pub outdated`; ghi rõ nếu chưa được phép chạy):
- Phiên bản SDK/framework hiện dùng và tình trạng hỗ trợ (tra nguồn chính thức, ghi ngày và URL):
- Yêu cầu hiện hành của Google Play / App Store ảnh hưởng tới app (mức API tối thiểu, bản công cụ build, chính sách quyền riêng tư, khai báo dữ liệu) — tra nguồn chính thức, ghi ngày và URL:

## 6. Hạ tầng và tài khoản cần người dùng xác nhận còn dùng được
- [ ] Khóa ký / chứng chỉ: còn, ở đúng nơi RUNBOOK ghi, còn hạn
- [ ] Tài khoản nhà phát triển trên store: còn hiệu lực
- [ ] Dịch vụ ngoài và API: còn sống, còn gói, khóa còn hạn
- [ ] Tên miền, chứng chỉ SSL: còn hạn
- [ ] Kho mã nguồn từ xa hoặc bản sao lưu: tồn tại
(Claude không tự kiểm tra được các mục này; hỏi người dùng.)

## 7. Rủi ro
| Mức (chặn/nặng/nhẹ) | Mô tả | Bằng chứng | Đề xuất |
|---------------------|-------|------------|---------|

## 8. Kế hoạch nâng cấp đề xuất
(Tạo PLAN riêng bằng `bash scripts/new-plan.sh APP-001 "Nâng cấp ..."`; chia bước nhỏ, mỗi bước kiểm chứng được; nâng từng bậc thay vì nhảy nhiều phiên bản cùng lúc nếu framework khuyến cáo. Chờ người dùng duyệt trước khi sửa code.)

## 9. Chưa kiểm chứng / câu hỏi mở
-
