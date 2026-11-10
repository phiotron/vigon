# TextFields

Outlined text fields: name, amount with currency suffix, note with counter, and password with a visibility toggle.

Fields are 56 dp, with a 1 dp `outline`. Focus = a 2 dp `primary` border with the label in `primary`; error = a 2 dp `error` border with the label and message in `error`. The message replaces the helper so the layout does not jump. Password fields are obscured with no suggestions; the eye toggle has NEW labels "Show password" / "Hide password". At 200 % fields grow to 112 dp.
