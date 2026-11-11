# Vigon Privacy Policy

**Last updated:** 2026-11-11

Vigon is a personal income-and-expense tracker for Android and iPhone, published by Phiotron. This policy explains what data the app stores, where it stores it and how you control it.

## 1. We do not collect your data

Vigon has no server, no user account, no advertising, no analytics, crash-reporting or tracking service from a third party. The app does not send the data you enter to the developer; the developer does not receive, view or share it.

The app uses the internet for two things only, both started by you: downloading an exchange-rate table when you change currency (section 4) and reading bank receipt emails from a mailbox you add yourself (section 3). There are no other connections, no tracking code, no advertising ID and no device identifier.

## 2. Your data stays on your phone

What you enter — income and expenses, categories, accounts, transfers, notes, monthly and per-category budgets, recurring items, savings goals, debts, the queue of items waiting for a category, payee-based category suggestions and settings — is stored only in the app's private storage on your phone. Other apps cannot read it.

- **Android:** the app turns off Android's automatic backup (`allowBackup=false`), so your data is not uploaded to the cloud by the system.
- **iPhone:** the app excludes its data from iCloud backups and from computer backups of your iPhone, so your data is not uploaded to the cloud or included in device backups.

So on both platforms, do not rely on your phone's backup to keep Vigon data: if you reinstall the app or restore your phone from a backup, the app's data is not restored with it. To move data to another phone, export a `.vigon` backup file yourself (section 5) and choose "Restore from backup" on the new phone.

If you turn on the PIN lock, the app stores only a salted hash of your PIN, never the PIN itself. On Android this value lives in secure storage protected by the Android Keystore. On iPhone it lives in the device Keychain and is not synchronised through iCloud Keychain. iOS may keep this Keychain item after you uninstall the app; when you reinstall and the app starts with empty data, it notices and removes the old PIN, so you are not locked out by a PIN from a previous install.

**Home-screen widget (Android and iPhone).** If you add the widget, it always has two buttons, "Expense" and "Income", to open the entry screen quickly. By default the widget shows no amounts. Only if you turn on "Show amounts on widget" and do not use the PIN lock does the widget show the amount spent this month (and the monthly limit if you set a budget). While the PIN lock is on, the widget always hides amounts. This data stays only in the app's private storage on the phone (on iPhone, in the shared container used only by Vigon and its own widget) and on your home screen; it is not sent anywhere and is removed when you turn the switch off or turn the PIN on. While the switch is on, anyone holding your phone can see the amount on the home screen.

## 3. Importing expenses from bank email (optional, off by default)

If you add a mailbox in Settings → Email import, the app signs in over IMAP with an encrypted connection (TLS, port 993) to exactly the mailbox you chose, to read bank receipt emails. This version supports only MB Bank and three email providers: Gmail, Yahoo and iCloud.

- The app reads only messages sent from the bank's addresses; other mail is not downloaded.
- The app reads only mail that arrives after you connect the mailbox, not older mail.
- Mail is read in view-only mode (`BODY.PEEK`): it does not mark messages as read, edit, delete or move them.
- The message body is processed on the phone to extract the date and time, amount, beneficiary, transfer description, the last four digits of the debited account and the reference number. No message content is sent to the developer or to any third party.
- A parsed item **is not an expense yet**: it goes to the Queue for you to pick a category and confirm. Until you confirm, it is not counted in totals, charts or budgets.
- You use an **app password** created by your email provider, not your main password. The mailbox address and the app password are stored in the phone's secure key store (Android Keystore, iPhone Keychain), never in the database, backup file, CSV or logs. The password is used only to sign in to IMAP.
- Up to three mailboxes. Deleting a mailbox in the app deletes its configuration and app password from the key store; "Delete all data" deletes all of this too. You may also revoke the app password in your email account to be certain.
- Android checks mail about once an hour while the app is closed; iPhone checks only when you open or return to the app. Both check as soon as you open the app.
- Your email provider (Google, Yahoo, Apple) sees the IP address and sign-in time as it does for any other mail app, and handles them under its own policy. If it blocks app-password sign-in, this feature stops working and you can delete the mailbox.

## 4. Exchange rates

When you choose another currency in Settings, the app downloads a public rate table (based on US dollars, the same for every user) from ExchangeRate-API (open.er-api.com) over an encrypted HTTPS connection and converts amounts on the phone. The request contains no amounts, no current currency and no information you entered. As with any internet connection, the rate provider sees the IP address, time and technical details of the connection, and handles them under its own policy (exchangerate-api.com). The rate table is stored on the phone for use offline; you can also enter rates manually.

## 5. Backup and CSV files you export yourself

When you choose "Export backup" or "Export CSV", the app creates a file in its temporary folder and opens the operating system's share sheet so you can choose where to send or keep it, for example the Files app, Google Drive or email. You decide where the file goes. You may set a password for the backup file; it is then encrypted on the phone with AES-256-GCM (the password is not stored anywhere, and if you forget it the file cannot be opened). Without a password the file is not encrypted, so keep it somewhere safe. From then on the file is governed by the service you chose. The operating system cleans the app's temporary folder.

Backup files do not contain email mailboxes, app passwords or the queue of items waiting for a category.

You can also turn on "Automatic backup" (off by default). When it is on, you pick a folder and set a backup password. On Android you pick the folder with the system picker and choose the backup time (default 21:00, phone time); at that time the app writes the file even when you are not using it (the system may delay it by a few minutes to save battery). On iPhone you pick a folder in the Files app, for example in iCloud Drive; because iPhone does not let a closed app run, at that time the app shows a notification on your phone, and when you tap it or open Vigon the app writes the file. If the time is missed, the app catches up when you open it again (on Android also when you leave the app). At most once a day and only when data has changed; the app keeps the two most recent automatic files. Automatic files are always encrypted, never written in plain text. The password is stored only in the phone's secure key store, never in the file, logs or database, and is not sent anywhere.

Folder write access is managed by the operating system and applies only to the folder you chose. If the folder belongs to a storage service such as iCloud Drive, Google Drive or OneDrive, uploading the file to the cloud is done by Apple or that service under its own policy; Vigon does not upload it and the developer does not receive it. If the folder is only on the phone, losing the phone means losing these files. When you turn "Automatic backup" off, the app removes the password from the key store and drops access to the folder, but does not delete files already written; delete them yourself if you wish.

## 6. Permissions on your phone

On Android, Vigon has the internet permission to download the rate table (section 4) and read the mailboxes you added (section 3); Android grants it at install time without asking. Beyond that the app has only three permissions, used solely for reminders (the "Daily reminder", off by default; "Deadline reminders" for savings goals and debts, on by default) and the background mail check:

- Notifications: the app asks only when you turn on the daily reminder or deadline reminders, when you first set a due date on a savings goal or debt, or (iPhone only) when you turn on or change the automatic backup time, always after an explanation (Android 13 and later; on iPhone it is an iOS dialog). The iPhone backup notification says only "Time to back up Vigon. Tap to back up."; if you decline, the app still backs up when you open it. All reminder notifications are created and kept on the phone and never pass through a server. The daily reminder uses generic wording with no amounts. Deadline reminders show the goal or person name and the amount left (for example "Debt with An: 2,000,000 ₫ left, due in 7 days") and can appear on the lock screen, even when a PIN is set; you can turn them off in Settings → Deadline reminders. If you decline, the app still works normally.
- Receive boot completed (Android only): granted at install time without asking. The app uses it only to reset the reminder, automatic-backup and mail-check schedules after you restart your phone (if you turned them on); it gives the app no access to any data.
- Alarms & reminders (Android 12 and later only): not granted by Android by default. The app only invites you to allow it in system settings after you turn on a reminder, so reminders arrive at the exact minute; without it, reminders still arrive but may be a few minutes late. It only lets the app schedule notifications and gives no access to any data.

The app does not request location, contacts, photos, camera or microphone. Picking a restore file and a backup folder uses the operating system's pickers, which give access only to the file or folder you choose.

## 7. Links to other sites

Settings → About can open your browser (to read this policy, the terms of use or the support page) or your email app (to send feedback or report a security issue). The Rates screen and the mailbox setup guide link to ExchangeRate-API and to the app-password pages of Google, Yahoo and Apple. Those apps and sites operate under their own policies.

## 8. Data the app stores may collect

When you download the app from Google Play or the App Store, Google or Apple may collect information about the installation and app crashes under their own policies and your device settings (for example, the option to share analytics with developers on iPhone). The developer sees only aggregate, anonymous figures in Play Console and App Store Connect and cannot use them to identify you.

## 9. Your rights

Because data stays on your phone, you exercise every right inside the app: view and edit each entry; export all data to a backup or CSV file; delete a mailbox and its app password; delete all data (including the PIN, mailboxes and app passwords) in Settings → "Delete all data"; or uninstall the app. Uninstalling removes data on the phone, except files you exported yourself and automatic backup files in the folder you chose. On iPhone, iOS may keep the PIN Keychain item after you uninstall; the app removes it when reinstalled with new data (section 2).

## 10. Children

Vigon is not aimed at children and does not collect data from anyone, including children.

## 11. Security

Data is protected by Android's and iOS's app sandboxing, the optional PIN lock and the optional "Hide content when switching apps". The PIN lock prevents others from opening the app on your phone, but it does not encrypt data. When the hide option is on: on Android the app blocks screenshots and hides its preview in the recent-apps list; on iPhone the app covers its content when you leave the app or open the app switcher, but iPhone does not let apps block screenshots. When the option is off, the app's preview in the task switcher may show the figures on screen. Mailbox app passwords and the automatic-backup password live in the operating system's secure key store, not in the database or backup files. If you find a security vulnerability, please email the address in section 13.

## 12. Changes to this policy

If Vigon changes how it handles data (for example, adds a feature that sends data over the internet), we will update this policy and its date before releasing the version with the change. This is the first version of the policy.

## 13. Contact

Phiotron, developer of Vigon — email: phamphuongphuongnd@gmail.com
