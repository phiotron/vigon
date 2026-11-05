---
name: flutter-test-khoa-sqlite3-dll
description: Nhiều agent chạy flutter test/build cùng một worktree thì khóa build/native_assets/windows/sqlite3.dll và treo
type: project
created: 2026-11-04
---
Khi vài agent cùng chạy `flutter test` hay `flutter build` trong một worktree, lần chạy sau báo "Flutter failed to delete file ... build/native_assets/windows/sqlite3.dll"; một lần chạy bị dừng còn để lại `flutter_tester` mồ côi (taskkill bị hệ thống chặn).

**Vì sao:** thư mục `build/` dùng chung trong worktree.
**Áp dụng thế nào:** brief agent chia theo nhóm file, mỗi agent chỉ chạy test của mình; điều phối chạy `flutter test` toàn bộ và build MỘT lần sau khi mọi agent xong. Test widget dùng `pumpApp` cộng nhiều override có thể treo thật: chạy với `--timeout`.
