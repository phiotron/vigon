# Dialogs

Dialogs: normal, destructive, and form with password fields (the password family shared by Export, Restore and Automatic backup).

Dialogs use `surface-container-high` and `radius-xl`, with 24 dp padding: a centred 24 dp icon (`ink-muted`, or `error` when destructive), a centred title, then the body. Actions are right-aligned and wrap. Destructive = `error` filled. In the password family the warning row (`warning` icon + `error` text) sits above the fields, so it stays visible with the keyboard up. At 200 % the body scrolls and the actions stay pinned above a hairline.
