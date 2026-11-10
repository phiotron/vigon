// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Vigon';

  @override
  String get settings => 'Settings';

  @override
  String get theme => 'Theme';

  @override
  String get themeSystem => 'System';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get language => 'Language';

  @override
  String get appearanceLanguage => 'Appearance & language';

  @override
  String get categoriesAccountsSection => 'Categories & accounts';

  @override
  String get planSection => 'Plan';

  @override
  String get currencyPeriodSection => 'Currency & period';

  @override
  String get reminderSection => 'Reminder';

  @override
  String get reminderSwitch => 'Daily reminder';

  @override
  String get reminderSwitchNote =>
      'One notification a day at the time you choose, with no figures in it';

  @override
  String get reminderTime => 'Reminder time';

  @override
  String get reminderExplainTitle => 'Turn on the reminder?';

  @override
  String get reminderExplainBody =>
      'Vigon will send one notification every day at the time you choose, to remind you to record your spending. The notification contains no figures.';

  @override
  String get reminderContinue => 'Continue';

  @override
  String get reminderDenied =>
      'Notifications are not allowed. Turn on notifications for Vigon in the system settings.';

  @override
  String get reminderOpenSettings => 'Open settings';

  @override
  String get reminderChannelName => 'Reminder';

  @override
  String get reminderChannelDescription =>
      'A daily reminder to record your spending';

  @override
  String get reminderNotificationBody =>
      'Have you recorded your spending today?';

  @override
  String get emptyPeriod => 'Tap − to record your first expense';

  @override
  String get accountCash => 'Cash';

  @override
  String get categoryFood => 'Food';

  @override
  String get categoryTransport => 'Transport';

  @override
  String get categoryHome => 'Home';

  @override
  String get categoryBills => 'Bills';

  @override
  String get categoryShopping => 'Shopping';

  @override
  String get categoryHealth => 'Health';

  @override
  String get categoryEntertainment => 'Entertainment';

  @override
  String get categoryEducation => 'Education';

  @override
  String get categoryFamily => 'Family';

  @override
  String get categoryOther => 'Other';

  @override
  String get categorySalary => 'Salary';

  @override
  String get categoryBonus => 'Bonus';

  @override
  String get categoryOtherIncome => 'Other income';

  @override
  String get periodDay => 'Day';

  @override
  String get periodWeek => 'Week';

  @override
  String get periodMonth => 'Month';

  @override
  String get periodYear => 'Year';

  @override
  String get periodAll => 'All time';

  @override
  String get periodCustom => 'Custom range';

  @override
  String get choosePeriod => 'Choose period';

  @override
  String get previousPeriod => 'Previous period';

  @override
  String get nextPeriod => 'Next period';

  @override
  String get income => 'Income';

  @override
  String get expense => 'Expenses';

  @override
  String get balance => 'Balance';

  @override
  String balanceLabel(String amount) {
    return 'Balance: $amount';
  }

  @override
  String get addExpense => 'Add expense';

  @override
  String get addIncome => 'Add income';

  @override
  String get allAccounts => 'All accounts';

  @override
  String get entries => 'Records';

  @override
  String chartSummary(String details) {
    return 'Expenses by category: $details';
  }

  @override
  String categoryAmount(String name, String amount, String percent) {
    return '$name, $amount, $percent';
  }

  @override
  String categoryNoEntries(String name) {
    return '$name, no records';
  }

  @override
  String get noEntries => 'No records in this period';

  @override
  String get newExpense => 'New expense';

  @override
  String get newIncome => 'New income';

  @override
  String get editEntry => 'Edit record';

  @override
  String get chooseCategory => 'Choose category';

  @override
  String get otherCategories => 'More categories';

  @override
  String get save => 'Save';

  @override
  String get done => 'Done';

  @override
  String get delete => 'Delete';

  @override
  String get cancel => 'Cancel';

  @override
  String get confirm => 'Confirm';

  @override
  String get noteHint => 'Note';

  @override
  String get amountMustBePositive => 'Amount must be greater than 0';

  @override
  String get invalidExpression => 'Invalid calculation';

  @override
  String get today => 'Today';

  @override
  String get account => 'Account';

  @override
  String get deleted => 'Deleted';

  @override
  String get undo => 'Undo';

  @override
  String get search => 'Search';

  @override
  String get searchHint => 'Note, category or amount';

  @override
  String get searchClose => 'Close search';

  @override
  String get searchAllTime => 'All time';

  @override
  String get searchNoMatch => 'No matching records';

  @override
  String searchTotal(int count, String total) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count records',
      one: '1 record',
    );
    return '$_temp0 · total $total';
  }

  @override
  String get keypadBackspace => 'Backspace';

  @override
  String get keypadEquals => 'Equals';

  @override
  String get repeat => 'Repeat';

  @override
  String get repeatNone => 'Does not repeat';

  @override
  String get repeatDaily => 'Daily';

  @override
  String get repeatWeekly => 'Weekly';

  @override
  String get repeatMonthly => 'Monthly';

  @override
  String get repeatYearly => 'Yearly';

  @override
  String get repeatPickDays => 'Pick days…';

  @override
  String get repeatPickDaysTitle => 'Repeat on';

  @override
  String get weekdayMon => 'Mon';

  @override
  String get weekdayTue => 'Tue';

  @override
  String get weekdayWed => 'Wed';

  @override
  String get weekdayThu => 'Thu';

  @override
  String get weekdayFri => 'Fri';

  @override
  String get weekdaySat => 'Sat';

  @override
  String get weekdaySun => 'Sun';

  @override
  String get repeatAllDaysHint => 'All 7 days = Daily';

  @override
  String repeatFirstOn(String date) {
    return 'First record: $date';
  }

  @override
  String repeatCreatedFirstOn(String date) {
    return 'Repeating record created · first on $date';
  }

  @override
  String onboardingStep(int step, int total) {
    return 'Step $step of $total';
  }

  @override
  String get onboardingSkip => 'Skip';

  @override
  String get onboardingContinue => 'Continue';

  @override
  String get onboardingLanguageTitle => 'Choose your language';

  @override
  String get onboardingLanguageHint => 'You can change it later in Settings.';

  @override
  String get onboardingWelcomeTitle => 'Welcome to Vigon';

  @override
  String get onboardingBenefitFast => 'Record in 3 taps';

  @override
  String get onboardingBenefitFastSub =>
      'Tap a category, type the amount, done.';

  @override
  String get onboardingBenefitClear => 'See where your money goes';

  @override
  String get onboardingBenefitClearSub =>
      'Charts by category, budgets, many currencies.';

  @override
  String get onboardingBenefitPrivate => 'Private by design';

  @override
  String get onboardingBenefitPrivateSub =>
      'Works offline. No account, no ads, no tracking.';

  @override
  String get onboardingStart => 'Get started';

  @override
  String get onboardingCurrencyTitle => 'Your main currency';

  @override
  String get onboardingCurrencyHint =>
      'Totals, charts and budgets use this currency. Your Cash account starts in it; you can add accounts in other currencies later.';

  @override
  String get onboardingOtherCurrency => 'Choose another currency…';

  @override
  String get onboardingReminderTitle => 'A daily reminder to record';

  @override
  String get onboardingReminderHint =>
      'One quiet notification a day at the time you choose. It never shows any amounts.';

  @override
  String get onboardingReminderOn => 'Turn on reminder';

  @override
  String get onboardingLater => 'Not now';

  @override
  String get onboardingPinTitle => 'Lock Vigon with a PIN?';

  @override
  String get onboardingPinHint =>
      'Ask for a 4-digit PIN when opening the app. It keeps curious eyes out; it does not encrypt your data.';

  @override
  String get onboardingPinSet => 'Set a PIN';

  @override
  String get stopRepeat => 'Stop repeating';

  @override
  String get repeatStopped => 'Stopped';

  @override
  String get transfer => 'Transfer';

  @override
  String transferLabel(String from, String to) {
    return '$from → $to';
  }

  @override
  String get transferFrom => 'From';

  @override
  String get transferTo => 'To';

  @override
  String get transferSentAmount => 'Amount sent';

  @override
  String get transferReceivedAmount => 'Amount received';

  @override
  String get sameAccountError => 'Choose two different accounts';

  @override
  String get categories => 'Categories';

  @override
  String get addCategory => 'Add category';

  @override
  String get editCategory => 'Edit category';

  @override
  String get name => 'Name';

  @override
  String get nameRequired => 'Enter a name';

  @override
  String get icon => 'Icon';

  @override
  String get color => 'Color';

  @override
  String get deleteCategory => 'Delete category';

  @override
  String get deleteCategoryConfirm => 'Delete this category?';

  @override
  String moveEntriesTo(int count) {
    return '$count records will be moved to:';
  }

  @override
  String get reorderHint => 'Drag to reorder';

  @override
  String get accounts => 'Accounts';

  @override
  String get addAccount => 'Add account';

  @override
  String get editAccount => 'Edit account';

  @override
  String get archiveAccount => 'Hide account';

  @override
  String get deleteAccount => 'Delete account';

  @override
  String deleteAccountConfirm(String name) {
    return 'Delete the account \"$name\"?';
  }

  @override
  String get accountInUseHint =>
      'This account has records, so it can only be hidden';

  @override
  String get accountLastOneHint => 'At least one account must remain';

  @override
  String get archivedAccounts => 'Hidden accounts';

  @override
  String get unarchiveAccount => 'Show again';

  @override
  String get initialBalance => 'Starting balance';

  @override
  String get currency => 'Currency';

  @override
  String get currencyNote =>
      'Changing the currency converts every amount using an exchange rate downloaded from the internet (or one you enter yourself). Amounts are rounded to the new currency\'s smallest unit, so converting back may differ slightly.';

  @override
  String get currencyLockedPayments =>
      'The currency is locked because this debt already has payments.';

  @override
  String get currencySearchHint => 'Search by code or name';

  @override
  String get currencyNoMatch => 'No matching currency';

  @override
  String get csvColDate => 'date';

  @override
  String get csvColType => 'type';

  @override
  String get csvColAmount => 'amount';

  @override
  String get csvColCurrency => 'currency';

  @override
  String get csvColCategory => 'category';

  @override
  String get csvColAccount => 'account';

  @override
  String get csvColToAccount => 'to_account';

  @override
  String get csvColNote => 'note';

  @override
  String get csvTypeExpense => 'expense';

  @override
  String get csvTypeIncome => 'income';

  @override
  String get csvTypeTransfer => 'transfer';

  @override
  String get weekStart => 'First day of week';

  @override
  String get monday => 'Monday';

  @override
  String get sunday => 'Sunday';

  @override
  String get monthStartDay => 'Month starts on day';

  @override
  String get budget => 'Monthly budget';

  @override
  String get budgetNotSet => 'Not set';

  @override
  String budgetProgress(String spent, String limit) {
    return 'Spent $spent of $limit';
  }

  @override
  String budgetOver(String amount) {
    return 'Over by $amount';
  }

  @override
  String get budgetRemove => 'Remove budget';

  @override
  String get categoryBudget => 'Category monthly budget';

  @override
  String get categoryBudgetHint => 'Leave empty for none';

  @override
  String get recurring => 'Repeating records';

  @override
  String get noRecurring =>
      'No repeating records yet. Turn on Repeat when adding a record.';

  @override
  String get dataSection => 'Data';

  @override
  String get backup => 'Export backup';

  @override
  String get restore => 'Restore from backup';

  @override
  String get exportCsv => 'Export CSV';

  @override
  String get backupNote =>
      'You can protect the file with a password. Without one, the file is not encrypted.';

  @override
  String get backupSetPassword => 'Protect file with a password';

  @override
  String get backupPassword => 'Password';

  @override
  String get backupPasswordConfirm => 'Repeat password';

  @override
  String get backupPasswordWarning =>
      'If you forget the password, this file cannot be opened.';

  @override
  String get backupPasswordTooShort => 'Password needs at least 6 characters';

  @override
  String get backupPasswordMismatch => 'Passwords do not match';

  @override
  String get backupExportAction => 'Export';

  @override
  String get backupEnterPasswordTitle => 'Password-protected file';

  @override
  String get backupEnterPasswordBody =>
      'Enter the password you set when exporting this file.';

  @override
  String get backupOpen => 'Open';

  @override
  String get backupWrongPassword => 'Wrong password or the file is damaged';

  @override
  String get backupWorking => 'Working';

  @override
  String get backupReminder =>
      'Data is stored only on this phone. Export a backup regularly.';

  @override
  String get autoBackup => 'Automatic backup';

  @override
  String get autoBackupNote =>
      'Vigon only writes files to the folder you choose. Uploading to Google Drive or Dropbox is done by that app.';

  @override
  String autoBackupFolder(String name) {
    return 'Folder: $name';
  }

  @override
  String get autoBackupFolderUnknown => 'Chosen folder';

  @override
  String autoBackupLast(String time) {
    return 'Last: $time';
  }

  @override
  String autoBackupLastUnchanged(String time, String checked) {
    return 'Last: $time. Checked $checked: no changes, kept the last backup';
  }

  @override
  String get autoBackupNever => 'No backup yet';

  @override
  String get autoBackupErrorFolder =>
      'Could not write to the folder. Choose the folder again';

  @override
  String get autoBackupErrorOther =>
      'Backup failed. Try again with Back up now';

  @override
  String autoBackupFailedAt(String time, String error) {
    return 'Attempt $time: $error';
  }

  @override
  String get autoBackupBusy =>
      'A backup is already running, try again in a moment';

  @override
  String get autoBackupNow => 'Back up now';

  @override
  String get autoBackupChooseFolder => 'Choose folder again';

  @override
  String get autoBackupDone => 'Backup saved';

  @override
  String get autoBackupOffDone =>
      'Automatic backup is off. Files already written stay in the folder.';

  @override
  String get autoBackupPickFailed => 'Could not open the folder picker';

  @override
  String get autoBackupPasswordTitle => 'Automatic backup password';

  @override
  String get autoBackupPasswordWarning =>
      'If you forget the password, the backup files cannot be opened; you need it to restore on another device.';

  @override
  String get autoBackupTurnOn => 'Turn on';

  @override
  String get restoreConfirm =>
      'Your current data will be replaced by the backup. Continue?';

  @override
  String get restoreDone => 'Data restored';

  @override
  String get restoreFailed =>
      'The file is invalid or damaged. Your data was not changed.';

  @override
  String get deleteAll => 'Delete all data';

  @override
  String get deleteAllConfirm =>
      'Delete all records, categories, accounts and settings on this phone?';

  @override
  String get deleteAllConfirm2 => 'This cannot be undone. Delete everything?';

  @override
  String get deleteAllDone => 'All data deleted';

  @override
  String get security => 'Security';

  @override
  String get pinLock => 'Lock with PIN';

  @override
  String get enterPin => 'Enter PIN';

  @override
  String get newPin => 'Choose a 4-digit PIN';

  @override
  String get confirmPin => 'Enter the PIN again';

  @override
  String get pinMismatch => 'The PINs do not match';

  @override
  String get wrongPin => 'Wrong PIN';

  @override
  String get pinWarning =>
      'If you forget the PIN, the only way back in is to delete all data in the app.';

  @override
  String get forgotPin => 'Forgot PIN';

  @override
  String get forgotPinBody =>
      'Vigon has no server, so a PIN cannot be recovered. You can delete all data in the app to use it again.';

  @override
  String digit(String digit) {
    return 'Digit $digit';
  }

  @override
  String pinProgress(int count) {
    return '$count of 4 digits entered';
  }

  @override
  String get secureWindow => 'Hide content when switching apps';

  @override
  String get secureWindowNote =>
      'Blocks screenshots and hides content in the recent apps list';

  @override
  String get widgetShowAmounts => 'Show amounts on widget';

  @override
  String get widgetShowAmountsNote =>
      'Anyone holding the phone can see this number on the home screen. While PIN lock is on, the widget always hides amounts.';

  @override
  String widgetSpentThisMonth(String spent) {
    return 'Spent this month: $spent';
  }

  @override
  String widgetSpentOfBudget(String spent, String budget) {
    return 'Spent this month: $spent / $budget';
  }

  @override
  String get widgetLockedByPin => 'Locked with PIN';

  @override
  String get about => 'About';

  @override
  String get versionLabel => 'Version';

  @override
  String get aboutBody =>
      'Your data is stored only on this phone. Vigon does not send it anywhere.';

  @override
  String get privacyPolicy => 'Privacy policy';

  @override
  String get terms => 'Terms of use';

  @override
  String get reportSecurity => 'Report a security issue';

  @override
  String get licenses => 'Open-source licences';

  @override
  String get rateApp => 'Rate Vigon';

  @override
  String get feedback => 'Send feedback';

  @override
  String feedbackSubject(String version) {
    return 'Vigon feedback $version';
  }

  @override
  String contactEmail(String email) {
    return 'Contact email: $email';
  }

  @override
  String get securityEmailSubject => 'Vigon security report';

  @override
  String linkOpenFailed(String target) {
    return 'Could not open it. You can write to $target yourself';
  }

  @override
  String iconNumber(int n) {
    return 'Icon $n';
  }

  @override
  String get viewBy => 'View by';

  @override
  String get apply => 'Apply';

  @override
  String get deleteAllTitle => 'Delete all data?';

  @override
  String get cannotUndo => 'This cannot be undone';

  @override
  String get previousMonth => 'Previous month';

  @override
  String get nextMonth => 'Next month';

  @override
  String get rangeHint => 'Pick the first day, then the last day';

  @override
  String get amountLabel => 'Amount';

  @override
  String get initialBalanceHelper =>
      'Leave empty for 0. Negative amounts are allowed.';

  @override
  String get recurringEditNote =>
      'Applies to the records it creates from now on.';

  @override
  String get deleteCategoryEmptyBody => 'This category has no records.';

  @override
  String get showPassword => 'Show password';

  @override
  String get hidePassword => 'Hide password';

  @override
  String get searchClear => 'Clear search';

  @override
  String get showMore => 'Show more';

  @override
  String get showLess => 'Show less';

  @override
  String get csvFormatEn => 'English format: comma separator, dot decimals';

  @override
  String get csvFormatVi =>
      'Vietnamese format: semicolon separator, comma decimals';

  @override
  String categoryLimitThisMonth(String status) {
    return 'This month: $status';
  }

  @override
  String get currencyCurrent => 'Current currency';

  @override
  String get primaryCurrency => 'Main currency';

  @override
  String primaryCurrencyChanged(String currency) {
    return 'Main currency is now $currency. The amounts you entered are unchanged.';
  }

  @override
  String get primaryCurrencyNote =>
      'Totals, charts and the ≈ line use this currency. Each account keeps its own currency; changing this only changes how amounts are added up and shown, never the amounts you entered.';

  @override
  String get exchangeRates => 'Exchange rates';

  @override
  String get ratesOffline =>
      'You\'re offline. Vigon is using the last saved rates.';

  @override
  String get ratesFallback =>
      'Using the built-in rates until the first update.';

  @override
  String get ratesUpdateNow => 'Update now';

  @override
  String get ratesUpdated => 'Exchange rates updated';

  @override
  String get ratesUpdateFailed =>
      'Couldn\'t update. Vigon is using the saved rates.';

  @override
  String get ratesSource => 'Rates by Exchange Rate API';

  @override
  String get ratesUseAuto => 'Use automatic rate';

  @override
  String get ratesUseOwn => 'Use my rate';

  @override
  String get ratesNoPairs => 'No currency pairs need a rate yet.';

  @override
  String ratesPreviewBalance(String account, String amount, String converted) {
    return '$account: $amount ≈ $converted';
  }

  @override
  String ratesSummaryAuto(String ago) {
    return 'Auto · $ago';
  }

  @override
  String get ratesSummaryBuiltIn => 'Built-in';

  @override
  String get ratesSummaryManual => 'Set by you';

  @override
  String ratesIntro(String currency) {
    return 'Balances and totals are in $currency. Rates update once a day when you\'re online; you can set your own to override.';
  }

  @override
  String ratesAuto(String ago) {
    return 'Auto · updated $ago';
  }

  @override
  String ratesAutoOffline(String ago) {
    return 'Offline · rates from $ago';
  }

  @override
  String get ratesBuiltIn => 'Auto · built-in estimate';

  @override
  String get ratesManual => 'Set by you';

  @override
  String ratesPairLabel(String from, String rate, String to) {
    return '1 $from equals $rate $to';
  }

  @override
  String get ratesAgoToday => 'today';

  @override
  String get ratesAgoYesterday => 'yesterday';

  @override
  String ratesAgoDays(int count) {
    return '$count days ago';
  }

  @override
  String get ratesOfflineTitle => 'You\'re offline';

  @override
  String get ratesOfflineBody =>
      'Using the latest rates. They\'ll update when you\'re back online.';

  @override
  String get ratesListedNote => 'Only currencies your data uses are shown.';

  @override
  String ratesNoneUsed(String currency) {
    return 'Everything is in $currency, so there\'s nothing to convert.';
  }

  @override
  String ratesLinkFailed(String url) {
    return 'Couldn\'t open it. You can visit $url yourself.';
  }

  @override
  String get rateUseAuto => 'Use automatic rate';

  @override
  String rateAutoValue(String rate, String ago) {
    return '$rate · updated $ago';
  }

  @override
  String rateAutoValueBuiltIn(String rate) {
    return '$rate · built-in estimate';
  }

  @override
  String rateYours(String from) {
    return 'Your rate · 1 $from =';
  }

  @override
  String get rateSave => 'Save this rate';

  @override
  String get rateRestoreAuto => 'Restore automatic';

  @override
  String rateMissing(String from, String to) {
    return 'No rate for $from to $to. This amount is left out of totals.';
  }

  @override
  String recurringRestartHint(String date) {
    return 'Restarts from the next due date: $date';
  }

  @override
  String get restoreSwitchesNote =>
      'The daily reminder and widget amounts will be turned off. You can turn them on again in Settings.';

  @override
  String get restoreSwitchesNoteIos =>
      'The daily reminder will be turned off. You can turn it on again in Settings.';

  @override
  String archivedAccountsCount(int count) {
    return 'Hidden accounts ($count)';
  }

  @override
  String get autoBackupNoteIos =>
      'Vigon only writes files to the folder you choose in the Files app, for example in iCloud Drive.';

  @override
  String get autoBackupRunsOnOpenIos =>
      'iPhone does not let closed apps run on their own. At the time you chose, Vigon sends a notification; tap it or open the app to back up. If the time is missed, the backup catches up when you open the app, at most once a day.';

  @override
  String get autoBackupLocalFolderWarningIos =>
      'This folder may be stored only on this iPhone. If so, losing the phone means losing these files. To keep them safe, choose a folder in iCloud Drive or Google Drive.';

  @override
  String get autoBackupTime => 'Backup time';

  @override
  String autoBackupNextToday(String time) {
    return 'Next: today, $time';
  }

  @override
  String autoBackupNextTomorrow(String time) {
    return 'Next: tomorrow, $time';
  }

  @override
  String get autoBackupNextSoon => 'Next: when you leave Vigon';

  @override
  String get autoBackupNextSoonIos => 'Next: when you open Vigon again';

  @override
  String get autoBackupNotificationBody =>
      'Time to back up Vigon. Tap to back up.';

  @override
  String get autoBackupNotifyTitleIos => 'Notify me at backup time';

  @override
  String get autoBackupNotifyBodyIos =>
      'iPhone does not let Vigon run on its own while closed. At the time you chose, Vigon sends a notification; tap it to back up. The notification never contains your figures.';

  @override
  String get autoBackupNotifyDeniedIos =>
      'No backup-time notification. Vigon will still catch up when you open the app.';

  @override
  String get secureWindowNoteIos =>
      'Hides content in the app switcher. iPhone does not let apps block screenshots.';

  @override
  String get widgetPickerName => 'Vigon';

  @override
  String get widgetPickerDescription => 'Quickly add an expense or income';

  @override
  String get widgetExpenseButton => 'Expense';

  @override
  String get widgetIncomeButton => 'Income';

  @override
  String get widgetStale => 'Open the app to update';

  @override
  String currencyConvertTitle(String currency) {
    return 'Convert to $currency?';
  }

  @override
  String get exchangeRateLoading => 'Getting the exchange rate…';

  @override
  String exchangeRatePair(String from, String rate, String to) {
    return '1 $from = $rate $to';
  }

  @override
  String exchangeRateDate(String date) {
    return 'Rate updated $date';
  }

  @override
  String get exchangeRateManualSource => 'Rate you entered';

  @override
  String currencyConvertExample(String before, String after) {
    return 'Example: $before → $after';
  }

  @override
  String currencyConvertWarning(String currency) {
    return 'Every amount (entries, transfers, recurring items, opening balances, category limits, monthly budget) will be converted and rounded to the nearest $currency unit. This can\'t be undone automatically, and converting back may differ slightly because of rounding. Consider exporting a backup first.';
  }

  @override
  String get currencyConvertAction => 'Convert';

  @override
  String get exchangeRateUseOther => 'Use a different rate';

  @override
  String get exchangeRateErrorTitle => 'Couldn\'t get the exchange rate';

  @override
  String get exchangeRateOfflineBody =>
      'Check your internet connection and try again, or enter the rate yourself.';

  @override
  String get exchangeRateUnavailableBody =>
      'The exchange rate service isn\'t responding right now. Try again later, or enter the rate yourself.';

  @override
  String exchangeRateMissingPairBody(String from, String to) {
    return 'No exchange rate is available for $from to $to. Enter the rate yourself.';
  }

  @override
  String get exchangeRateManualTitle => 'Enter the exchange rate';

  @override
  String exchangeRateFieldLabel(String from, String to) {
    return '1 $from = ? $to';
  }

  @override
  String get exchangeRateSwap => 'Swap direction';

  @override
  String exchangeRatePrefilled(String date) {
    return 'Filled in with the last rate, from $date';
  }

  @override
  String get exchangeRateInvalid => 'Enter a rate greater than 0';

  @override
  String get exchangeRateRetry => 'Try again';

  @override
  String get exchangeRateContinue => 'Continue';

  @override
  String currencyConverted(String currency) {
    return 'All amounts converted to $currency';
  }

  @override
  String get currencyConvertTooLargeTitle => 'Amounts too large';

  @override
  String get currencyConvertTooLargeBody =>
      'With this rate, some amounts would go over the largest amount Vigon can store. Nothing was changed.';

  @override
  String get currencyConvertFailed => 'Couldn\'t convert. Nothing was changed.';

  @override
  String get currencyConvertOk => 'OK';

  @override
  String get emailImportGroup => 'Email import';

  @override
  String get emailImport => 'Import from bank email';

  @override
  String get emailImportNoMailbox => 'No mailbox yet';

  @override
  String emailImportMailboxCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count mailboxes',
      one: '1 mailbox',
    );
    return '$_temp0';
  }

  @override
  String get emailIntroTitle => 'Record spending from receipt emails';

  @override
  String get emailIntroRead =>
      'Vigon reads your bank\'s transfer receipt emails in the mailbox you add, then puts them in a queue for you to pick a category.';

  @override
  String get emailIntroLocal =>
      'On this phone only: email content is never sent anywhere.';

  @override
  String get emailIntroReadOnly =>
      'No email is changed, deleted or marked as read.';

  @override
  String get emailIntroAppPassword =>
      'Needs an app password from your email provider, not your main sign-in password.';

  @override
  String get emailIntroBanks => 'Only MB Bank is supported for now.';

  @override
  String get emailIntroIos =>
      'On iPhone, Vigon checks email only when you open or return to the app.';

  @override
  String get emailAddMailbox => 'Add mailbox';

  @override
  String get emailMailboxLimit =>
      'You already have 3 mailboxes. Remove one to add another.';

  @override
  String get emailScheduleAndroid =>
      'Vigon checks email when you open the app and about every hour while it\'s closed. Pull down to check now.';

  @override
  String get emailScheduleIos =>
      'On iPhone, Vigon checks email only when you open or return to the app. Pull down to check now.';

  @override
  String get emailConnected => 'Connected';

  @override
  String emailLastCheck(String time) {
    return 'Connected · Last check: $time';
  }

  @override
  String emailErrorAt(String time, String error) {
    return 'Check at $time: $error';
  }

  @override
  String get emailErrorCredentials => 'Wrong address or app password';

  @override
  String get emailErrorImapDisabled => 'IMAP is turned off for this mailbox';

  @override
  String get emailErrorNetwork => 'No internet connection';

  @override
  String get emailErrorSecure =>
      'Couldn\'t make a secure connection to the email server';

  @override
  String get emailErrorServer =>
      'The email server returned an error. Try again later';

  @override
  String get emailPaused =>
      'Checking this mailbox is paused. Enter the app password again to continue.';

  @override
  String emailUnreadable(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count MB emails couldn\'t be read',
      one: '1 MB email couldn\'t be read',
    );
    return '$_temp0';
  }

  @override
  String get emailReenterPassword => 'Re-enter password';

  @override
  String get emailRemoveMailbox => 'Remove mailbox';

  @override
  String get emailRemoveTitle => 'Remove mailbox?';

  @override
  String emailRemoveBody(String address) {
    return 'Vigon will stop reading email from $address and delete the app password from this phone. Records already saved stay as they are.';
  }

  @override
  String get emailRemoved => 'Mailbox removed';

  @override
  String get emailProvider => 'Provider';

  @override
  String get emailStepsTitle => 'Create an app password';

  @override
  String get emailStepsGmail1 =>
      'Turn on 2-Step Verification for your Google account (required for app passwords).';

  @override
  String get emailStepsGmail2 =>
      'Open the App passwords page with the button below, name it \"Vigon\" and tap Create.';

  @override
  String get emailStepsGmail3 =>
      'Copy the 16-character password Google shows into the App password field below.';

  @override
  String get emailStepsYahoo1 =>
      'Open the Yahoo Account security page with the button below.';

  @override
  String get emailStepsYahoo2 =>
      'Choose \"Generate app password\", name it \"Vigon\" and tap Generate.';

  @override
  String get emailStepsYahoo3 =>
      'Copy the password Yahoo shows into the App password field below.';

  @override
  String get emailStepsIcloud1 =>
      'Turn on two-factor authentication for your Apple Account.';

  @override
  String get emailStepsIcloud2 =>
      'Open the Apple Account page with the button below → Sign-In and Security → App-Specific Passwords, name it \"Vigon\".';

  @override
  String get emailStepsIcloud3 =>
      'Copy the password Apple shows into the App password field below; the address is your iCloud email.';

  @override
  String get emailOpenPasswordPage => 'Open the app password page';

  @override
  String get emailAddress => 'Email address';

  @override
  String get emailAddressInvalid => 'Enter a valid email address';

  @override
  String get emailAppPassword => 'App password';

  @override
  String get emailAppPasswordHelper =>
      'Not your main sign-in password. Stored only in this phone\'s secure storage.';

  @override
  String get emailAppPasswordEmpty => 'Enter the app password';

  @override
  String get emailConnect => 'Connect';

  @override
  String get emailDuplicate => 'This mailbox is already added';

  @override
  String get emailSaveReenter => 'Save and reconnect';

  @override
  String get entryTime => 'Time';

  @override
  String get timeNotSet => 'No time set';

  @override
  String get csvColTime => 'Time';

  @override
  String get csvColSource => 'Source';

  @override
  String get csvSourceManual => 'Manual';

  @override
  String get csvSourceEmailMb => 'MB email';

  @override
  String get savings => 'Savings';

  @override
  String get savingsEmpty =>
      'No savings goals yet. Set a goal, then add money to it over time.';

  @override
  String get savingsAdd => 'Add goal';

  @override
  String get savingsEdit => 'Edit goal';

  @override
  String get savingsTarget => 'Target amount';

  @override
  String get savingsDue => 'Deadline (optional)';

  @override
  String get savingsNoDue => 'No deadline';

  @override
  String get savingsClearDue => 'Remove deadline';

  @override
  String get savingsAccount => 'Linked account';

  @override
  String get savingsNewAccount => 'Create a new account';

  @override
  String get savingsNewAccountNote =>
      'The new account is named like the goal and starts at 0.';

  @override
  String get savingsAccountFixed =>
      'The linked account can\'t be changed. To link a different account, delete the goal and create it again.';

  @override
  String get savingsAccountTaken =>
      'This account is already linked to another goal';

  @override
  String savingsProgress(String have, String target) {
    return 'Saved $have of $target';
  }

  @override
  String savingsMissing(String amount) {
    return '$amount to go';
  }

  @override
  String get savingsReached => 'Reached';

  @override
  String savingsDaysLeft(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days left',
      one: '1 day left',
      zero: 'Due today',
    );
    return '$_temp0';
  }

  @override
  String savingsOverdue(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days overdue',
      one: '1 day overdue',
    );
    return '$_temp0';
  }

  @override
  String get savingsContribute => 'Add money';

  @override
  String get savingsNeedOtherAccount =>
      'You need another account to add money from';

  @override
  String get savingsDelete => 'Delete goal';

  @override
  String get savingsDeleteTitle => 'Delete this goal?';

  @override
  String get savingsDeleteBody =>
      'The linked account and all records stay. Only the goal is deleted.';

  @override
  String get savingsDeleted => 'Goal deleted';

  @override
  String get debts => 'Debts';

  @override
  String get debtsEmpty =>
      'No debts yet. Note who owes you, or whom you owe, so you don\'t forget.';

  @override
  String get debtsNote =>
      'A reminder list only: it doesn\'t count in income, expenses or account balances.';

  @override
  String get debtAdd => 'Add debt';

  @override
  String get debtEdit => 'Edit debt';

  @override
  String get debtPerson => 'Person';

  @override
  String get debtDirection => 'Direction';

  @override
  String get debtLent => 'I lent';

  @override
  String get debtBorrowed => 'I borrowed';

  @override
  String get debtGroupLent => 'Owed to you';

  @override
  String get debtGroupBorrowed => 'You owe';

  @override
  String debtGroupTotal(String amount) {
    return '$amount remaining';
  }

  @override
  String debtDoneSection(int count) {
    return 'Settled ($count)';
  }

  @override
  String get debtDone => 'Settled';

  @override
  String get debtAmount => 'Amount';

  @override
  String get debtDate => 'Date';

  @override
  String get debtDue => 'Due date (optional)';

  @override
  String debtDueOn(String date) {
    return 'Due $date';
  }

  @override
  String get debtClearDue => 'Remove due date';

  @override
  String get debtOverdue => 'Overdue';

  @override
  String debtRemaining(String amount) {
    return '$amount remaining';
  }

  @override
  String debtPaidOf(String paid, String total) {
    return 'Paid $paid of $total';
  }

  @override
  String get debtPayments => 'Payments';

  @override
  String get debtNoPayments => 'No payments yet';

  @override
  String get debtAddPayment => 'Add payment';

  @override
  String get debtPaymentAmount => 'Payment amount';

  @override
  String get debtDeletePayment => 'Delete payment';

  @override
  String debtOverpay(String remaining) {
    return 'More than the remaining $remaining';
  }

  @override
  String debtAmountBelowPaid(String paid) {
    return 'Can\'t be less than the $paid already paid';
  }

  @override
  String get debtDelete => 'Delete debt';

  @override
  String get debtDeleteTitle => 'Delete this debt?';

  @override
  String get debtDeleteBody =>
      'Its payments are deleted too. No record or account balance is affected.';

  @override
  String get debtDeleted => 'Debt deleted';

  @override
  String get debtRemainingLabel => 'Remaining';

  @override
  String get importQueue => 'Queue';

  @override
  String get importQueueRow => 'Items awaiting a category';

  @override
  String importQueueRowCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count awaiting',
    );
    return '$_temp0';
  }

  @override
  String importQueueCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count records waiting for a category',
      one: '1 record waiting for a category',
    );
    return '$_temp0';
  }

  @override
  String get importQueueNone => 'Nothing is waiting';

  @override
  String get queueEmpty =>
      'Nothing is waiting. When a new receipt email arrives, it shows up here for you to pick a category.';

  @override
  String get queuePayeeUnknown => 'Unknown payee';

  @override
  String queueFromAccount(String account) {
    return 'From $account';
  }

  @override
  String queueCurrencyNote(String emailCurrency, String appCurrency) {
    return 'The email is in $emailCurrency but the account uses $appCurrency. You\'ll enter the amount in the next step.';
  }

  @override
  String get queueSuggested => 'Suggested';

  @override
  String queueSaveTo(String category) {
    return 'Save to $category';
  }

  @override
  String queueMoveTo(String account) {
    return 'Move to $account';
  }

  @override
  String get queueEditFirst => 'Edit before saving';

  @override
  String get queueMoveToMine => 'Move to my account';

  @override
  String get queueMoveToTitle => 'Move to account';

  @override
  String get queueNoOtherAccount => 'There is no other account to choose';

  @override
  String get queueSkip => 'Skip';

  @override
  String get queueSkipTitle => 'Skip this record?';

  @override
  String get queueSkipBody =>
      'It leaves the queue and won\'t be imported again from this email.';

  @override
  String queueSaved(String category) {
    return 'Saved to $category';
  }

  @override
  String queueMoved(String account) {
    return 'Moved to $account';
  }

  @override
  String get queueSkipped => 'Skipped';

  @override
  String get queueSuggestions => 'Remembered suggestions';

  @override
  String get queueSuggestionsEmpty =>
      'No suggestions yet. Vigon remembers the category you pick for each payee to suggest it next time.';

  @override
  String queueSuggestionMove(String account) {
    return 'Move to $account';
  }

  @override
  String get queueSuggestionDelete => 'Delete suggestion';

  @override
  String get queueSuggestionDeleted => 'Suggestion deleted';

  @override
  String queueAutoAccount(String account) {
    return 'Created account $account';
  }

  @override
  String get queueAttach => 'Attach to an existing account';

  @override
  String get queueAttachTitle => 'Attach to account';

  @override
  String get queueDismiss => 'Dismiss';

  @override
  String queueMatched(String time) {
    return 'Matched with MB email $time';
  }
}
