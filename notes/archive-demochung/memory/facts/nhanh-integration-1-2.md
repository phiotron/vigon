---
name: nhanh-integration-1-2
description: Bản 1.1/1.2 nằm trên nhánh integration/spec-1.1 (worktree riêng), chưa gộp với feature/PLAN-001 của chat khác
type: project
created: 2026-11-04
---
Bản 1.1 (F-14..F-23) và 1.2 (F-24..F-26) nằm trên `integration/spec-1.1`, worktree `apps/APP-001-vi-gon/.claude/worktrees/integration`, cắt từ master af93ccb. Checkout chính đang ở `master`; chat khác làm iOS + token giao diện ở `feature/PLAN-001` (D-010/D-011) cùng các worktree `plan001-t3..t6`. Hai nhánh CHƯA gộp.

**Vì sao:** làm riêng để chat kia chỉ sửa giao diện, không đụng nhau; có lần commit vào checkout chính lọt nhầm sang nhánh của chat kia.
**Áp dụng thế nào:** trước khi commit chạy `git branch --show-current`; chỉ `git add` đúng file; gộp hai nhánh chỉ khi người dùng bảo (sẽ xung đột ở settings_screen, app.dart, l10n, manifest).
