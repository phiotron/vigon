import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_vi.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('vi'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Ví Gọn'**
  String get appTitle;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @theme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get theme;

  /// No description provided for @themeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get themeSystem;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @languageSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get languageSystem;

  /// No description provided for @emptyPeriod.
  ///
  /// In en, this message translates to:
  /// **'Tap − to record your first expense'**
  String get emptyPeriod;

  /// No description provided for @accountCash.
  ///
  /// In en, this message translates to:
  /// **'Cash'**
  String get accountCash;

  /// No description provided for @categoryFood.
  ///
  /// In en, this message translates to:
  /// **'Food'**
  String get categoryFood;

  /// No description provided for @categoryTransport.
  ///
  /// In en, this message translates to:
  /// **'Transport'**
  String get categoryTransport;

  /// No description provided for @categoryHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get categoryHome;

  /// No description provided for @categoryBills.
  ///
  /// In en, this message translates to:
  /// **'Bills'**
  String get categoryBills;

  /// No description provided for @categoryShopping.
  ///
  /// In en, this message translates to:
  /// **'Shopping'**
  String get categoryShopping;

  /// No description provided for @categoryHealth.
  ///
  /// In en, this message translates to:
  /// **'Health'**
  String get categoryHealth;

  /// No description provided for @categoryEntertainment.
  ///
  /// In en, this message translates to:
  /// **'Entertainment'**
  String get categoryEntertainment;

  /// No description provided for @categoryEducation.
  ///
  /// In en, this message translates to:
  /// **'Education'**
  String get categoryEducation;

  /// No description provided for @categoryFamily.
  ///
  /// In en, this message translates to:
  /// **'Family'**
  String get categoryFamily;

  /// No description provided for @categoryOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get categoryOther;

  /// No description provided for @categorySalary.
  ///
  /// In en, this message translates to:
  /// **'Salary'**
  String get categorySalary;

  /// No description provided for @categoryBonus.
  ///
  /// In en, this message translates to:
  /// **'Bonus'**
  String get categoryBonus;

  /// No description provided for @categoryOtherIncome.
  ///
  /// In en, this message translates to:
  /// **'Other income'**
  String get categoryOtherIncome;

  /// No description provided for @periodDay.
  ///
  /// In en, this message translates to:
  /// **'Day'**
  String get periodDay;

  /// No description provided for @periodWeek.
  ///
  /// In en, this message translates to:
  /// **'Week'**
  String get periodWeek;

  /// No description provided for @periodMonth.
  ///
  /// In en, this message translates to:
  /// **'Month'**
  String get periodMonth;

  /// No description provided for @periodYear.
  ///
  /// In en, this message translates to:
  /// **'Year'**
  String get periodYear;

  /// No description provided for @periodAll.
  ///
  /// In en, this message translates to:
  /// **'All time'**
  String get periodAll;

  /// No description provided for @periodCustom.
  ///
  /// In en, this message translates to:
  /// **'Custom range'**
  String get periodCustom;

  /// No description provided for @choosePeriod.
  ///
  /// In en, this message translates to:
  /// **'Choose period'**
  String get choosePeriod;

  /// No description provided for @previousPeriod.
  ///
  /// In en, this message translates to:
  /// **'Previous period'**
  String get previousPeriod;

  /// No description provided for @nextPeriod.
  ///
  /// In en, this message translates to:
  /// **'Next period'**
  String get nextPeriod;

  /// No description provided for @income.
  ///
  /// In en, this message translates to:
  /// **'Income'**
  String get income;

  /// No description provided for @expense.
  ///
  /// In en, this message translates to:
  /// **'Expenses'**
  String get expense;

  /// No description provided for @balance.
  ///
  /// In en, this message translates to:
  /// **'Balance'**
  String get balance;

  /// No description provided for @balanceLabel.
  ///
  /// In en, this message translates to:
  /// **'Balance: {amount}'**
  String balanceLabel(String amount);

  /// No description provided for @addExpense.
  ///
  /// In en, this message translates to:
  /// **'Add expense'**
  String get addExpense;

  /// No description provided for @addIncome.
  ///
  /// In en, this message translates to:
  /// **'Add income'**
  String get addIncome;

  /// No description provided for @allAccounts.
  ///
  /// In en, this message translates to:
  /// **'All accounts'**
  String get allAccounts;

  /// No description provided for @entries.
  ///
  /// In en, this message translates to:
  /// **'Records'**
  String get entries;

  /// No description provided for @chartSummary.
  ///
  /// In en, this message translates to:
  /// **'Expenses by category: {details}'**
  String chartSummary(String details);

  /// No description provided for @categoryAmount.
  ///
  /// In en, this message translates to:
  /// **'{name}, {amount}, {percent}'**
  String categoryAmount(String name, String amount, String percent);

  /// No description provided for @categoryNoEntries.
  ///
  /// In en, this message translates to:
  /// **'{name}, no records'**
  String categoryNoEntries(String name);

  /// No description provided for @noEntries.
  ///
  /// In en, this message translates to:
  /// **'No records in this period'**
  String get noEntries;

  /// No description provided for @newExpense.
  ///
  /// In en, this message translates to:
  /// **'New expense'**
  String get newExpense;

  /// No description provided for @newIncome.
  ///
  /// In en, this message translates to:
  /// **'New income'**
  String get newIncome;

  /// No description provided for @editEntry.
  ///
  /// In en, this message translates to:
  /// **'Edit record'**
  String get editEntry;

  /// No description provided for @chooseCategory.
  ///
  /// In en, this message translates to:
  /// **'Choose category'**
  String get chooseCategory;

  /// No description provided for @otherCategories.
  ///
  /// In en, this message translates to:
  /// **'More categories'**
  String get otherCategories;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @noteHint.
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get noteHint;

  /// No description provided for @amountMustBePositive.
  ///
  /// In en, this message translates to:
  /// **'Amount must be greater than 0'**
  String get amountMustBePositive;

  /// No description provided for @invalidExpression.
  ///
  /// In en, this message translates to:
  /// **'Invalid calculation'**
  String get invalidExpression;

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @account.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get account;

  /// No description provided for @deleted.
  ///
  /// In en, this message translates to:
  /// **'Deleted'**
  String get deleted;

  /// No description provided for @undo.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get undo;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// No description provided for @searchHint.
  ///
  /// In en, this message translates to:
  /// **'Note, category or amount'**
  String get searchHint;

  /// No description provided for @searchClose.
  ///
  /// In en, this message translates to:
  /// **'Close search'**
  String get searchClose;

  /// No description provided for @searchAllTime.
  ///
  /// In en, this message translates to:
  /// **'All time'**
  String get searchAllTime;

  /// No description provided for @searchNoMatch.
  ///
  /// In en, this message translates to:
  /// **'No matching records'**
  String get searchNoMatch;

  /// No description provided for @searchTotal.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{1 record} other{{count} records}} · total {total}'**
  String searchTotal(int count, String total);

  /// No description provided for @keypadBackspace.
  ///
  /// In en, this message translates to:
  /// **'Backspace'**
  String get keypadBackspace;

  /// No description provided for @keypadEquals.
  ///
  /// In en, this message translates to:
  /// **'Equals'**
  String get keypadEquals;

  /// No description provided for @repeat.
  ///
  /// In en, this message translates to:
  /// **'Repeat'**
  String get repeat;

  /// No description provided for @repeatNone.
  ///
  /// In en, this message translates to:
  /// **'Does not repeat'**
  String get repeatNone;

  /// No description provided for @repeatDaily.
  ///
  /// In en, this message translates to:
  /// **'Daily'**
  String get repeatDaily;

  /// No description provided for @repeatWeekly.
  ///
  /// In en, this message translates to:
  /// **'Weekly'**
  String get repeatWeekly;

  /// No description provided for @repeatMonthly.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get repeatMonthly;

  /// No description provided for @repeatYearly.
  ///
  /// In en, this message translates to:
  /// **'Yearly'**
  String get repeatYearly;

  /// No description provided for @stopRepeat.
  ///
  /// In en, this message translates to:
  /// **'Stop repeating'**
  String get stopRepeat;

  /// No description provided for @repeatStopped.
  ///
  /// In en, this message translates to:
  /// **'Stopped'**
  String get repeatStopped;

  /// No description provided for @transfer.
  ///
  /// In en, this message translates to:
  /// **'Transfer'**
  String get transfer;

  /// No description provided for @transferLabel.
  ///
  /// In en, this message translates to:
  /// **'{from} → {to}'**
  String transferLabel(String from, String to);

  /// No description provided for @transferFrom.
  ///
  /// In en, this message translates to:
  /// **'From'**
  String get transferFrom;

  /// No description provided for @transferTo.
  ///
  /// In en, this message translates to:
  /// **'To'**
  String get transferTo;

  /// No description provided for @sameAccountError.
  ///
  /// In en, this message translates to:
  /// **'Choose two different accounts'**
  String get sameAccountError;

  /// No description provided for @categories.
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get categories;

  /// No description provided for @addCategory.
  ///
  /// In en, this message translates to:
  /// **'Add category'**
  String get addCategory;

  /// No description provided for @editCategory.
  ///
  /// In en, this message translates to:
  /// **'Edit category'**
  String get editCategory;

  /// No description provided for @name.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get name;

  /// No description provided for @nameRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter a name'**
  String get nameRequired;

  /// No description provided for @icon.
  ///
  /// In en, this message translates to:
  /// **'Icon'**
  String get icon;

  /// No description provided for @color.
  ///
  /// In en, this message translates to:
  /// **'Color'**
  String get color;

  /// No description provided for @deleteCategory.
  ///
  /// In en, this message translates to:
  /// **'Delete category'**
  String get deleteCategory;

  /// No description provided for @deleteCategoryConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete this category?'**
  String get deleteCategoryConfirm;

  /// No description provided for @moveEntriesTo.
  ///
  /// In en, this message translates to:
  /// **'{count} records will be moved to:'**
  String moveEntriesTo(int count);

  /// No description provided for @reorderHint.
  ///
  /// In en, this message translates to:
  /// **'Drag to reorder'**
  String get reorderHint;

  /// No description provided for @accounts.
  ///
  /// In en, this message translates to:
  /// **'Accounts'**
  String get accounts;

  /// No description provided for @addAccount.
  ///
  /// In en, this message translates to:
  /// **'Add account'**
  String get addAccount;

  /// No description provided for @editAccount.
  ///
  /// In en, this message translates to:
  /// **'Edit account'**
  String get editAccount;

  /// No description provided for @archiveAccount.
  ///
  /// In en, this message translates to:
  /// **'Hide account'**
  String get archiveAccount;

  /// No description provided for @deleteAccount.
  ///
  /// In en, this message translates to:
  /// **'Delete account'**
  String get deleteAccount;

  /// No description provided for @deleteAccountConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete the account \"{name}\"?'**
  String deleteAccountConfirm(String name);

  /// No description provided for @accountInUseHint.
  ///
  /// In en, this message translates to:
  /// **'This account has records, so it can only be hidden'**
  String get accountInUseHint;

  /// No description provided for @accountLastOneHint.
  ///
  /// In en, this message translates to:
  /// **'At least one account must remain'**
  String get accountLastOneHint;

  /// No description provided for @archivedAccounts.
  ///
  /// In en, this message translates to:
  /// **'Hidden accounts'**
  String get archivedAccounts;

  /// No description provided for @unarchiveAccount.
  ///
  /// In en, this message translates to:
  /// **'Show again'**
  String get unarchiveAccount;

  /// No description provided for @initialBalance.
  ///
  /// In en, this message translates to:
  /// **'Starting balance'**
  String get initialBalance;

  /// No description provided for @currency.
  ///
  /// In en, this message translates to:
  /// **'Currency'**
  String get currency;

  /// No description provided for @currencyNote.
  ///
  /// In en, this message translates to:
  /// **'Changing the currency only changes the symbol; no exchange rate is applied. If the two currencies have a different number of decimals (for example VND and USD), amounts are multiplied or divided so the numbers you see stay the same; switching back may lose the fractional part.'**
  String get currencyNote;

  /// No description provided for @currencySearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search by code or name'**
  String get currencySearchHint;

  /// No description provided for @currencyNoMatch.
  ///
  /// In en, this message translates to:
  /// **'No matching currency'**
  String get currencyNoMatch;

  /// No description provided for @csvColDate.
  ///
  /// In en, this message translates to:
  /// **'date'**
  String get csvColDate;

  /// No description provided for @csvColType.
  ///
  /// In en, this message translates to:
  /// **'type'**
  String get csvColType;

  /// No description provided for @csvColAmount.
  ///
  /// In en, this message translates to:
  /// **'amount'**
  String get csvColAmount;

  /// No description provided for @csvColCurrency.
  ///
  /// In en, this message translates to:
  /// **'currency'**
  String get csvColCurrency;

  /// No description provided for @csvColCategory.
  ///
  /// In en, this message translates to:
  /// **'category'**
  String get csvColCategory;

  /// No description provided for @csvColAccount.
  ///
  /// In en, this message translates to:
  /// **'account'**
  String get csvColAccount;

  /// No description provided for @csvColToAccount.
  ///
  /// In en, this message translates to:
  /// **'to_account'**
  String get csvColToAccount;

  /// No description provided for @csvColNote.
  ///
  /// In en, this message translates to:
  /// **'note'**
  String get csvColNote;

  /// No description provided for @csvTypeExpense.
  ///
  /// In en, this message translates to:
  /// **'expense'**
  String get csvTypeExpense;

  /// No description provided for @csvTypeIncome.
  ///
  /// In en, this message translates to:
  /// **'income'**
  String get csvTypeIncome;

  /// No description provided for @csvTypeTransfer.
  ///
  /// In en, this message translates to:
  /// **'transfer'**
  String get csvTypeTransfer;

  /// No description provided for @weekStart.
  ///
  /// In en, this message translates to:
  /// **'First day of week'**
  String get weekStart;

  /// No description provided for @monday.
  ///
  /// In en, this message translates to:
  /// **'Monday'**
  String get monday;

  /// No description provided for @sunday.
  ///
  /// In en, this message translates to:
  /// **'Sunday'**
  String get sunday;

  /// No description provided for @monthStartDay.
  ///
  /// In en, this message translates to:
  /// **'Month starts on day'**
  String get monthStartDay;

  /// No description provided for @budget.
  ///
  /// In en, this message translates to:
  /// **'Monthly budget'**
  String get budget;

  /// No description provided for @budgetNotSet.
  ///
  /// In en, this message translates to:
  /// **'Not set'**
  String get budgetNotSet;

  /// No description provided for @budgetProgress.
  ///
  /// In en, this message translates to:
  /// **'Spent {spent} of {limit}'**
  String budgetProgress(String spent, String limit);

  /// No description provided for @budgetOver.
  ///
  /// In en, this message translates to:
  /// **'Over by {amount}'**
  String budgetOver(String amount);

  /// No description provided for @budgetRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove budget'**
  String get budgetRemove;

  /// No description provided for @categoryBudget.
  ///
  /// In en, this message translates to:
  /// **'Category monthly budget'**
  String get categoryBudget;

  /// No description provided for @categoryBudgetHint.
  ///
  /// In en, this message translates to:
  /// **'Leave empty for none'**
  String get categoryBudgetHint;

  /// No description provided for @recurring.
  ///
  /// In en, this message translates to:
  /// **'Repeating records'**
  String get recurring;

  /// No description provided for @noRecurring.
  ///
  /// In en, this message translates to:
  /// **'No repeating records yet. Turn on Repeat when adding a record.'**
  String get noRecurring;

  /// No description provided for @dataSection.
  ///
  /// In en, this message translates to:
  /// **'Data'**
  String get dataSection;

  /// No description provided for @backup.
  ///
  /// In en, this message translates to:
  /// **'Export backup'**
  String get backup;

  /// No description provided for @restore.
  ///
  /// In en, this message translates to:
  /// **'Restore from backup'**
  String get restore;

  /// No description provided for @exportCsv.
  ///
  /// In en, this message translates to:
  /// **'Export CSV'**
  String get exportCsv;

  /// No description provided for @backupNote.
  ///
  /// In en, this message translates to:
  /// **'Backup files are not encrypted. Keep them somewhere safe.'**
  String get backupNote;

  /// No description provided for @backupReminder.
  ///
  /// In en, this message translates to:
  /// **'Data is stored only on this phone. Export a backup regularly.'**
  String get backupReminder;

  /// No description provided for @restoreConfirm.
  ///
  /// In en, this message translates to:
  /// **'Your current data will be replaced by the backup. Continue?'**
  String get restoreConfirm;

  /// No description provided for @restoreDone.
  ///
  /// In en, this message translates to:
  /// **'Data restored'**
  String get restoreDone;

  /// No description provided for @restoreFailed.
  ///
  /// In en, this message translates to:
  /// **'The file is invalid or damaged. Your data was not changed.'**
  String get restoreFailed;

  /// No description provided for @deleteAll.
  ///
  /// In en, this message translates to:
  /// **'Delete all data'**
  String get deleteAll;

  /// No description provided for @deleteAllConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete all records, categories, accounts and settings on this phone?'**
  String get deleteAllConfirm;

  /// No description provided for @deleteAllConfirm2.
  ///
  /// In en, this message translates to:
  /// **'This cannot be undone. Delete everything?'**
  String get deleteAllConfirm2;

  /// No description provided for @deleteAllDone.
  ///
  /// In en, this message translates to:
  /// **'All data deleted'**
  String get deleteAllDone;

  /// No description provided for @security.
  ///
  /// In en, this message translates to:
  /// **'Security'**
  String get security;

  /// No description provided for @pinLock.
  ///
  /// In en, this message translates to:
  /// **'Lock with PIN'**
  String get pinLock;

  /// No description provided for @enterPin.
  ///
  /// In en, this message translates to:
  /// **'Enter PIN'**
  String get enterPin;

  /// No description provided for @newPin.
  ///
  /// In en, this message translates to:
  /// **'Choose a 4-digit PIN'**
  String get newPin;

  /// No description provided for @confirmPin.
  ///
  /// In en, this message translates to:
  /// **'Enter the PIN again'**
  String get confirmPin;

  /// No description provided for @pinMismatch.
  ///
  /// In en, this message translates to:
  /// **'The PINs do not match'**
  String get pinMismatch;

  /// No description provided for @wrongPin.
  ///
  /// In en, this message translates to:
  /// **'Wrong PIN'**
  String get wrongPin;

  /// No description provided for @pinWarning.
  ///
  /// In en, this message translates to:
  /// **'If you forget the PIN, the only way back in is to delete all data in the app.'**
  String get pinWarning;

  /// No description provided for @forgotPin.
  ///
  /// In en, this message translates to:
  /// **'Forgot PIN'**
  String get forgotPin;

  /// No description provided for @forgotPinBody.
  ///
  /// In en, this message translates to:
  /// **'Ví Gọn has no server, so a PIN cannot be recovered. You can delete all data in the app to use it again.'**
  String get forgotPinBody;

  /// No description provided for @digit.
  ///
  /// In en, this message translates to:
  /// **'Digit {digit}'**
  String digit(String digit);

  /// No description provided for @pinProgress.
  ///
  /// In en, this message translates to:
  /// **'{count} of 4 digits entered'**
  String pinProgress(int count);

  /// No description provided for @secureWindow.
  ///
  /// In en, this message translates to:
  /// **'Hide content when switching apps'**
  String get secureWindow;

  /// No description provided for @secureWindowNote.
  ///
  /// In en, this message translates to:
  /// **'Blocks screenshots and hides content in the recent apps list'**
  String get secureWindowNote;

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// No description provided for @version.
  ///
  /// In en, this message translates to:
  /// **'Version {version}'**
  String version(String version);

  /// No description provided for @aboutBody.
  ///
  /// In en, this message translates to:
  /// **'Your data is stored only on this phone. Ví Gọn does not send it anywhere.'**
  String get aboutBody;

  /// No description provided for @privacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy policy'**
  String get privacyPolicy;

  /// No description provided for @reportSecurity.
  ///
  /// In en, this message translates to:
  /// **'Report a security issue'**
  String get reportSecurity;

  /// No description provided for @licenses.
  ///
  /// In en, this message translates to:
  /// **'Open source licenses'**
  String get licenses;

  /// No description provided for @privacyPolicyPending.
  ///
  /// In en, this message translates to:
  /// **'Web page coming soon'**
  String get privacyPolicyPending;

  /// No description provided for @contactEmail.
  ///
  /// In en, this message translates to:
  /// **'Contact email: {email}'**
  String contactEmail(String email);

  /// No description provided for @securityEmailSubject.
  ///
  /// In en, this message translates to:
  /// **'Ví Gọn security report'**
  String get securityEmailSubject;

  /// No description provided for @linkOpenFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not open it. You can write to {target} yourself'**
  String linkOpenFailed(String target);

  /// No description provided for @iconNumber.
  ///
  /// In en, this message translates to:
  /// **'Icon {n}'**
  String iconNumber(int n);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'vi'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'vi':
      return AppLocalizationsVi();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
