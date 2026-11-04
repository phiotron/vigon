// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Ví Gọn';

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
  String get languageSystem => 'System';

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
      'Changing the currency only changes the symbol; no exchange rate is applied. If the two currencies have a different number of decimals (for example VND and USD), amounts are multiplied or divided so the numbers you see stay the same; switching back may lose the fractional part.';

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
      'Ví Gọn has no server, so a PIN cannot be recovered. You can delete all data in the app to use it again.';

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
  String get about => 'About';

  @override
  String version(String version) {
    return 'Version $version';
  }

  @override
  String get aboutBody =>
      'Your data is stored only on this phone. Ví Gọn does not send it anywhere.';

  @override
  String get privacyPolicy => 'Privacy policy';

  @override
  String get reportSecurity => 'Report a security issue';

  @override
  String get licenses => 'Open source licenses';

  @override
  String get privacyPolicyPending => 'Web page coming soon';

  @override
  String contactEmail(String email) {
    return 'Contact email: $email';
  }

  @override
  String get securityEmailSubject => 'Ví Gọn security report';

  @override
  String linkOpenFailed(String target) {
    return 'Could not open it. You can write to $target yourself';
  }

  @override
  String iconNumber(int n) {
    return 'Icon $n';
  }
}
