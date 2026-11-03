---
# demochung-sync (chép từ D:/DemoChung/.claude/commands; sửa ở gốc rồi chạy scripts/sync-app-commands.sh)
description: Xem tình hình toàn bộ app và việc đang dở
model: haiku
effort: low
---
Chạy từ D:/DemoChung: `bash scripts/check.sh --quick` trước (cho biết số app); nếu có nhiều hơn khoảng 15 app thì KHÔNG in cả bảng, chạy `bash scripts/status.sh --stale` và các bộ lọc `--tag`/`--status` phù hợp với lời người dùng; ít app thì chạy `bash scripts/status.sh`. Trình bày: bảng app (đúng như script in ra), danh sách LỖI và CẢNH BÁO của check.sh (nếu có), và đề xuất tối đa 3 việc nên làm tiếp (dựa trên trạng thái, SPEC chưa duyệt, retrospective còn trống, lỗi mở). Không sửa gì.
