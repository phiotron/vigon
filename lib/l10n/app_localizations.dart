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
  /// **'Vigon'**
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

  /// No description provided for @appearanceLanguage.
  ///
  /// In en, this message translates to:
  /// **'Appearance & language'**
  String get appearanceLanguage;

  /// No description provided for @categoriesAccountsSection.
  ///
  /// In en, this message translates to:
  /// **'Categories & accounts'**
  String get categoriesAccountsSection;

  /// No description provided for @planSection.
  ///
  /// In en, this message translates to:
  /// **'Plan'**
  String get planSection;

  /// No description provided for @currencyPeriodSection.
  ///
  /// In en, this message translates to:
  /// **'Currency & period'**
  String get currencyPeriodSection;

  /// No description provided for @reminderSection.
  ///
  /// In en, this message translates to:
  /// **'Reminder'**
  String get reminderSection;

  /// No description provided for @reminderSwitch.
  ///
  /// In en, this message translates to:
  /// **'Daily reminder'**
  String get reminderSwitch;

  /// No description provided for @reminderSwitchNote.
  ///
  /// In en, this message translates to:
  /// **'One notification a day at the time you choose, with no figures in it'**
  String get reminderSwitchNote;

  /// No description provided for @reminderTime.
  ///
  /// In en, this message translates to:
  /// **'Reminder time'**
  String get reminderTime;

  /// No description provided for @reminderExplainTitle.
  ///
  /// In en, this message translates to:
  /// **'Turn on the reminder?'**
  String get reminderExplainTitle;

  /// No description provided for @reminderExplainBody.
  ///
  /// In en, this message translates to:
  /// **'Vigon will send one notification every day at the time you choose, to remind you to record your spending. The notification contains no figures.'**
  String get reminderExplainBody;

  /// No description provided for @reminderContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get reminderContinue;

  /// No description provided for @reminderDenied.
  ///
  /// In en, this message translates to:
  /// **'Notifications are not allowed. Turn on notifications for Vigon in the system settings.'**
  String get reminderDenied;

  /// No description provided for @reminderOpenSettings.
  ///
  /// In en, this message translates to:
  /// **'Open settings'**
  String get reminderOpenSettings;

  /// No description provided for @reminderChannelName.
  ///
  /// In en, this message translates to:
  /// **'Reminder'**
  String get reminderChannelName;

  /// No description provided for @reminderChannelDescription.
  ///
  /// In en, this message translates to:
  /// **'A daily reminder to record your spending'**
  String get reminderChannelDescription;

  /// No description provided for @reminderNotificationBody.
  ///
  /// In en, this message translates to:
  /// **'Have you recorded your spending today?'**
  String get reminderNotificationBody;

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

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

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

  /// No description provided for @repeatPickDays.
  ///
  /// In en, this message translates to:
  /// **'Pick days…'**
  String get repeatPickDays;

  /// No description provided for @repeatPickDaysTitle.
  ///
  /// In en, this message translates to:
  /// **'Repeat on'**
  String get repeatPickDaysTitle;

  /// No description provided for @weekdayMon.
  ///
  /// In en, this message translates to:
  /// **'Mon'**
  String get weekdayMon;

  /// No description provided for @weekdayTue.
  ///
  /// In en, this message translates to:
  /// **'Tue'**
  String get weekdayTue;

  /// No description provided for @weekdayWed.
  ///
  /// In en, this message translates to:
  /// **'Wed'**
  String get weekdayWed;

  /// No description provided for @weekdayThu.
  ///
  /// In en, this message translates to:
  /// **'Thu'**
  String get weekdayThu;

  /// No description provided for @weekdayFri.
  ///
  /// In en, this message translates to:
  /// **'Fri'**
  String get weekdayFri;

  /// No description provided for @weekdaySat.
  ///
  /// In en, this message translates to:
  /// **'Sat'**
  String get weekdaySat;

  /// No description provided for @weekdaySun.
  ///
  /// In en, this message translates to:
  /// **'Sun'**
  String get weekdaySun;

  /// No description provided for @repeatAllDaysHint.
  ///
  /// In en, this message translates to:
  /// **'All 7 days = Daily'**
  String get repeatAllDaysHint;

  /// No description provided for @repeatFirstOn.
  ///
  /// In en, this message translates to:
  /// **'First record: {date}'**
  String repeatFirstOn(String date);

  /// No description provided for @repeatCreatedFirstOn.
  ///
  /// In en, this message translates to:
  /// **'Repeating record created · first on {date}'**
  String repeatCreatedFirstOn(String date);

  /// No description provided for @onboardingStep.
  ///
  /// In en, this message translates to:
  /// **'Step {step} of {total}'**
  String onboardingStep(int step, int total);

  /// No description provided for @onboardingSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get onboardingSkip;

  /// No description provided for @onboardingContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get onboardingContinue;

  /// No description provided for @onboardingLanguageTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose your language'**
  String get onboardingLanguageTitle;

  /// No description provided for @onboardingLanguageHint.
  ///
  /// In en, this message translates to:
  /// **'You can change it later in Settings.'**
  String get onboardingLanguageHint;

  /// No description provided for @onboardingWelcomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome to Vigon'**
  String get onboardingWelcomeTitle;

  /// No description provided for @onboardingBenefitFast.
  ///
  /// In en, this message translates to:
  /// **'Record in 3 taps'**
  String get onboardingBenefitFast;

  /// No description provided for @onboardingBenefitFastSub.
  ///
  /// In en, this message translates to:
  /// **'Tap a category, type the amount, done.'**
  String get onboardingBenefitFastSub;

  /// No description provided for @onboardingBenefitClear.
  ///
  /// In en, this message translates to:
  /// **'See where your money goes'**
  String get onboardingBenefitClear;

  /// No description provided for @onboardingBenefitClearSub.
  ///
  /// In en, this message translates to:
  /// **'Charts by category, budgets, many currencies.'**
  String get onboardingBenefitClearSub;

  /// No description provided for @onboardingBenefitPrivate.
  ///
  /// In en, this message translates to:
  /// **'Private by design'**
  String get onboardingBenefitPrivate;

  /// No description provided for @onboardingBenefitPrivateSub.
  ///
  /// In en, this message translates to:
  /// **'Works offline. No account, no ads, no tracking.'**
  String get onboardingBenefitPrivateSub;

  /// No description provided for @onboardingStart.
  ///
  /// In en, this message translates to:
  /// **'Get started'**
  String get onboardingStart;

  /// No description provided for @onboardingCurrencyTitle.
  ///
  /// In en, this message translates to:
  /// **'Your main currency'**
  String get onboardingCurrencyTitle;

  /// No description provided for @onboardingCurrencyHint.
  ///
  /// In en, this message translates to:
  /// **'Totals, charts and budgets use this currency. Your Cash account starts in it; you can add accounts in other currencies later.'**
  String get onboardingCurrencyHint;

  /// No description provided for @onboardingOtherCurrency.
  ///
  /// In en, this message translates to:
  /// **'Choose another currency…'**
  String get onboardingOtherCurrency;

  /// No description provided for @onboardingReminderTitle.
  ///
  /// In en, this message translates to:
  /// **'A daily reminder to record'**
  String get onboardingReminderTitle;

  /// No description provided for @onboardingReminderHint.
  ///
  /// In en, this message translates to:
  /// **'One quiet notification a day at the time you choose. It never shows any amounts.'**
  String get onboardingReminderHint;

  /// No description provided for @onboardingReminderOn.
  ///
  /// In en, this message translates to:
  /// **'Turn on reminder'**
  String get onboardingReminderOn;

  /// No description provided for @onboardingLater.
  ///
  /// In en, this message translates to:
  /// **'Not now'**
  String get onboardingLater;

  /// No description provided for @onboardingPinTitle.
  ///
  /// In en, this message translates to:
  /// **'Lock Vigon with a PIN?'**
  String get onboardingPinTitle;

  /// No description provided for @onboardingPinHint.
  ///
  /// In en, this message translates to:
  /// **'Ask for a 4-digit PIN when opening the app. It keeps curious eyes out; it does not encrypt your data.'**
  String get onboardingPinHint;

  /// No description provided for @onboardingPinSet.
  ///
  /// In en, this message translates to:
  /// **'Set a PIN'**
  String get onboardingPinSet;

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

  /// No description provided for @transferSentAmount.
  ///
  /// In en, this message translates to:
  /// **'Amount sent'**
  String get transferSentAmount;

  /// No description provided for @transferReceivedAmount.
  ///
  /// In en, this message translates to:
  /// **'Amount received'**
  String get transferReceivedAmount;

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
  /// **'Changing a currency never changes the amounts you entered; it only changes how totals and the \"≈\" line are converted, using current exchange rates (downloaded at most once a day, or entered by you on the Exchange rates screen).'**
  String get currencyNote;

  /// No description provided for @currencyLockedPayments.
  ///
  /// In en, this message translates to:
  /// **'The currency is locked because this debt already has payments.'**
  String get currencyLockedPayments;

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
  /// **'You can protect the file with a password. Without one, the file is not encrypted.'**
  String get backupNote;

  /// No description provided for @backupSetPassword.
  ///
  /// In en, this message translates to:
  /// **'Protect file with a password'**
  String get backupSetPassword;

  /// No description provided for @backupPassword.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get backupPassword;

  /// No description provided for @backupPasswordConfirm.
  ///
  /// In en, this message translates to:
  /// **'Repeat password'**
  String get backupPasswordConfirm;

  /// No description provided for @backupPasswordWarning.
  ///
  /// In en, this message translates to:
  /// **'If you forget the password, this file cannot be opened.'**
  String get backupPasswordWarning;

  /// No description provided for @backupPasswordTooShort.
  ///
  /// In en, this message translates to:
  /// **'Password needs at least 6 characters'**
  String get backupPasswordTooShort;

  /// No description provided for @backupPasswordMismatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get backupPasswordMismatch;

  /// No description provided for @backupExportAction.
  ///
  /// In en, this message translates to:
  /// **'Export'**
  String get backupExportAction;

  /// No description provided for @backupEnterPasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Password-protected file'**
  String get backupEnterPasswordTitle;

  /// No description provided for @backupEnterPasswordBody.
  ///
  /// In en, this message translates to:
  /// **'Enter the password you set when exporting this file.'**
  String get backupEnterPasswordBody;

  /// No description provided for @backupOpen.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get backupOpen;

  /// No description provided for @backupWrongPassword.
  ///
  /// In en, this message translates to:
  /// **'Wrong password or the file is damaged'**
  String get backupWrongPassword;

  /// No description provided for @backupWorking.
  ///
  /// In en, this message translates to:
  /// **'Working'**
  String get backupWorking;

  /// No description provided for @backupReminder.
  ///
  /// In en, this message translates to:
  /// **'Data is stored only on this phone. Export a backup regularly.'**
  String get backupReminder;

  /// No description provided for @autoBackup.
  ///
  /// In en, this message translates to:
  /// **'Automatic backup'**
  String get autoBackup;

  /// No description provided for @autoBackupNote.
  ///
  /// In en, this message translates to:
  /// **'Vigon only writes files to the folder you choose. Uploading to Google Drive or Dropbox is done by that app.'**
  String get autoBackupNote;

  /// No description provided for @autoBackupFolder.
  ///
  /// In en, this message translates to:
  /// **'Folder: {name}'**
  String autoBackupFolder(String name);

  /// No description provided for @autoBackupFolderUnknown.
  ///
  /// In en, this message translates to:
  /// **'Chosen folder'**
  String get autoBackupFolderUnknown;

  /// No description provided for @autoBackupLast.
  ///
  /// In en, this message translates to:
  /// **'Last: {time}'**
  String autoBackupLast(String time);

  /// No description provided for @autoBackupLastUnchanged.
  ///
  /// In en, this message translates to:
  /// **'Last: {time}. Checked {checked}: no changes, kept the last backup'**
  String autoBackupLastUnchanged(String time, String checked);

  /// No description provided for @autoBackupNever.
  ///
  /// In en, this message translates to:
  /// **'No backup yet'**
  String get autoBackupNever;

  /// No description provided for @autoBackupErrorFolder.
  ///
  /// In en, this message translates to:
  /// **'Could not write to the folder. Choose the folder again'**
  String get autoBackupErrorFolder;

  /// No description provided for @autoBackupErrorOther.
  ///
  /// In en, this message translates to:
  /// **'Backup failed. Try again with Back up now'**
  String get autoBackupErrorOther;

  /// No description provided for @autoBackupFailedAt.
  ///
  /// In en, this message translates to:
  /// **'Attempt {time}: {error}'**
  String autoBackupFailedAt(String time, String error);

  /// No description provided for @autoBackupBusy.
  ///
  /// In en, this message translates to:
  /// **'A backup is already running, try again in a moment'**
  String get autoBackupBusy;

  /// No description provided for @autoBackupNow.
  ///
  /// In en, this message translates to:
  /// **'Back up now'**
  String get autoBackupNow;

  /// No description provided for @autoBackupChooseFolder.
  ///
  /// In en, this message translates to:
  /// **'Choose folder again'**
  String get autoBackupChooseFolder;

  /// No description provided for @autoBackupDone.
  ///
  /// In en, this message translates to:
  /// **'Backup saved'**
  String get autoBackupDone;

  /// No description provided for @autoBackupOffDone.
  ///
  /// In en, this message translates to:
  /// **'Automatic backup is off. Files already written stay in the folder.'**
  String get autoBackupOffDone;

  /// No description provided for @autoBackupPickFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not open the folder picker'**
  String get autoBackupPickFailed;

  /// No description provided for @autoBackupPasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Automatic backup password'**
  String get autoBackupPasswordTitle;

  /// No description provided for @autoBackupPasswordWarning.
  ///
  /// In en, this message translates to:
  /// **'If you forget the password, the backup files cannot be opened; you need it to restore on another device.'**
  String get autoBackupPasswordWarning;

  /// No description provided for @autoBackupTurnOn.
  ///
  /// In en, this message translates to:
  /// **'Turn on'**
  String get autoBackupTurnOn;

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
  /// **'Vigon has no server, so a PIN cannot be recovered. You can delete all data in the app to use it again.'**
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

  /// No description provided for @widgetShowAmounts.
  ///
  /// In en, this message translates to:
  /// **'Show amounts on widget'**
  String get widgetShowAmounts;

  /// No description provided for @widgetShowAmountsNote.
  ///
  /// In en, this message translates to:
  /// **'Anyone holding the phone can see this number on the home screen. While PIN lock is on, the widget always hides amounts.'**
  String get widgetShowAmountsNote;

  /// No description provided for @widgetSpentThisMonth.
  ///
  /// In en, this message translates to:
  /// **'Spent this month: {spent}'**
  String widgetSpentThisMonth(String spent);

  /// No description provided for @widgetSpentOfBudget.
  ///
  /// In en, this message translates to:
  /// **'Spent this month: {spent} / {budget}'**
  String widgetSpentOfBudget(String spent, String budget);

  /// No description provided for @widgetLockedByPin.
  ///
  /// In en, this message translates to:
  /// **'Locked with PIN'**
  String get widgetLockedByPin;

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// No description provided for @versionLabel.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get versionLabel;

  /// No description provided for @aboutBody.
  ///
  /// In en, this message translates to:
  /// **'Your data is stored only on this phone. Vigon does not send it anywhere.'**
  String get aboutBody;

  /// No description provided for @privacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy policy'**
  String get privacyPolicy;

  /// No description provided for @terms.
  ///
  /// In en, this message translates to:
  /// **'Terms of use'**
  String get terms;

  /// No description provided for @reportSecurity.
  ///
  /// In en, this message translates to:
  /// **'Report a security issue'**
  String get reportSecurity;

  /// No description provided for @licenses.
  ///
  /// In en, this message translates to:
  /// **'Open-source licences'**
  String get licenses;

  /// No description provided for @rateApp.
  ///
  /// In en, this message translates to:
  /// **'Rate Vigon'**
  String get rateApp;

  /// No description provided for @feedback.
  ///
  /// In en, this message translates to:
  /// **'Send feedback'**
  String get feedback;

  /// No description provided for @feedbackSubject.
  ///
  /// In en, this message translates to:
  /// **'Vigon feedback {version}'**
  String feedbackSubject(String version);

  /// No description provided for @contactEmail.
  ///
  /// In en, this message translates to:
  /// **'Contact email: {email}'**
  String contactEmail(String email);

  /// No description provided for @securityEmailSubject.
  ///
  /// In en, this message translates to:
  /// **'Vigon security report'**
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

  /// No description provided for @viewBy.
  ///
  /// In en, this message translates to:
  /// **'View by'**
  String get viewBy;

  /// No description provided for @apply.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get apply;

  /// No description provided for @deleteAllTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete all data?'**
  String get deleteAllTitle;

  /// No description provided for @cannotUndo.
  ///
  /// In en, this message translates to:
  /// **'This cannot be undone'**
  String get cannotUndo;

  /// No description provided for @previousMonth.
  ///
  /// In en, this message translates to:
  /// **'Previous month'**
  String get previousMonth;

  /// No description provided for @nextMonth.
  ///
  /// In en, this message translates to:
  /// **'Next month'**
  String get nextMonth;

  /// No description provided for @rangeHint.
  ///
  /// In en, this message translates to:
  /// **'Pick the first day, then the last day'**
  String get rangeHint;

  /// No description provided for @amountLabel.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get amountLabel;

  /// No description provided for @initialBalanceHelper.
  ///
  /// In en, this message translates to:
  /// **'Leave empty for 0. Negative amounts are allowed.'**
  String get initialBalanceHelper;

  /// No description provided for @recurringEditNote.
  ///
  /// In en, this message translates to:
  /// **'Applies to the records it creates from now on.'**
  String get recurringEditNote;

  /// No description provided for @deleteCategoryEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'This category has no records.'**
  String get deleteCategoryEmptyBody;

  /// No description provided for @showPassword.
  ///
  /// In en, this message translates to:
  /// **'Show password'**
  String get showPassword;

  /// No description provided for @hidePassword.
  ///
  /// In en, this message translates to:
  /// **'Hide password'**
  String get hidePassword;

  /// No description provided for @searchClear.
  ///
  /// In en, this message translates to:
  /// **'Clear search'**
  String get searchClear;

  /// No description provided for @showMore.
  ///
  /// In en, this message translates to:
  /// **'Show more'**
  String get showMore;

  /// No description provided for @showLess.
  ///
  /// In en, this message translates to:
  /// **'Show less'**
  String get showLess;

  /// No description provided for @csvFormatEn.
  ///
  /// In en, this message translates to:
  /// **'English format: comma separator, dot decimals'**
  String get csvFormatEn;

  /// No description provided for @csvFormatVi.
  ///
  /// In en, this message translates to:
  /// **'Vietnamese format: semicolon separator, comma decimals'**
  String get csvFormatVi;

  /// No description provided for @categoryLimitThisMonth.
  ///
  /// In en, this message translates to:
  /// **'This month: {status}'**
  String categoryLimitThisMonth(String status);

  /// No description provided for @currencyCurrent.
  ///
  /// In en, this message translates to:
  /// **'Current currency'**
  String get currencyCurrent;

  /// No description provided for @primaryCurrency.
  ///
  /// In en, this message translates to:
  /// **'Main currency'**
  String get primaryCurrency;

  /// No description provided for @primaryCurrencyChanged.
  ///
  /// In en, this message translates to:
  /// **'Main currency is now {currency}. The amounts you entered are unchanged.'**
  String primaryCurrencyChanged(String currency);

  /// No description provided for @primaryCurrencyNote.
  ///
  /// In en, this message translates to:
  /// **'Everything is shown and added up in this currency. Amounts recorded in other currencies keep their original value, shown underneath.'**
  String get primaryCurrencyNote;

  /// No description provided for @exchangeRates.
  ///
  /// In en, this message translates to:
  /// **'Exchange rates'**
  String get exchangeRates;

  /// No description provided for @ratesOffline.
  ///
  /// In en, this message translates to:
  /// **'You\'re offline. Vigon is using the last saved rates.'**
  String get ratesOffline;

  /// No description provided for @ratesFallback.
  ///
  /// In en, this message translates to:
  /// **'Using the built-in rates until the first update.'**
  String get ratesFallback;

  /// No description provided for @ratesUpdateNow.
  ///
  /// In en, this message translates to:
  /// **'Update now'**
  String get ratesUpdateNow;

  /// No description provided for @ratesUpdated.
  ///
  /// In en, this message translates to:
  /// **'Exchange rates updated'**
  String get ratesUpdated;

  /// No description provided for @ratesUpdateFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t update. Vigon is using the saved rates.'**
  String get ratesUpdateFailed;

  /// No description provided for @ratesSource.
  ///
  /// In en, this message translates to:
  /// **'Rates by Exchange Rate API'**
  String get ratesSource;

  /// No description provided for @ratesUseAuto.
  ///
  /// In en, this message translates to:
  /// **'Use automatic rate'**
  String get ratesUseAuto;

  /// No description provided for @ratesUseOwn.
  ///
  /// In en, this message translates to:
  /// **'Use my rate'**
  String get ratesUseOwn;

  /// No description provided for @ratesNoPairs.
  ///
  /// In en, this message translates to:
  /// **'No currency pairs need a rate yet.'**
  String get ratesNoPairs;

  /// No description provided for @ratesPreviewBalance.
  ///
  /// In en, this message translates to:
  /// **'{account}: {amount} ≈ {converted}'**
  String ratesPreviewBalance(String account, String amount, String converted);

  /// No description provided for @ratesSummaryAuto.
  ///
  /// In en, this message translates to:
  /// **'Auto · {ago}'**
  String ratesSummaryAuto(String ago);

  /// No description provided for @ratesSummaryBuiltIn.
  ///
  /// In en, this message translates to:
  /// **'Built-in'**
  String get ratesSummaryBuiltIn;

  /// No description provided for @ratesSummaryManual.
  ///
  /// In en, this message translates to:
  /// **'Set by you'**
  String get ratesSummaryManual;

  /// No description provided for @ratesIntro.
  ///
  /// In en, this message translates to:
  /// **'Balances and totals are in {currency}. Rates update once a day when you\'re online; you can set your own to override.'**
  String ratesIntro(String currency);

  /// No description provided for @ratesAuto.
  ///
  /// In en, this message translates to:
  /// **'Auto · updated {ago}'**
  String ratesAuto(String ago);

  /// No description provided for @ratesAutoOffline.
  ///
  /// In en, this message translates to:
  /// **'Offline · rates from {ago}'**
  String ratesAutoOffline(String ago);

  /// No description provided for @ratesBuiltIn.
  ///
  /// In en, this message translates to:
  /// **'Auto · built-in estimate'**
  String get ratesBuiltIn;

  /// No description provided for @ratesManual.
  ///
  /// In en, this message translates to:
  /// **'Set by you'**
  String get ratesManual;

  /// No description provided for @ratesPairLabel.
  ///
  /// In en, this message translates to:
  /// **'1 {from} equals {rate} {to}'**
  String ratesPairLabel(String from, String rate, String to);

  /// No description provided for @ratesAgoToday.
  ///
  /// In en, this message translates to:
  /// **'today'**
  String get ratesAgoToday;

  /// No description provided for @ratesAgoYesterday.
  ///
  /// In en, this message translates to:
  /// **'yesterday'**
  String get ratesAgoYesterday;

  /// No description provided for @ratesAgoDays.
  ///
  /// In en, this message translates to:
  /// **'{count} days ago'**
  String ratesAgoDays(int count);

  /// No description provided for @ratesOfflineTitle.
  ///
  /// In en, this message translates to:
  /// **'You\'re offline'**
  String get ratesOfflineTitle;

  /// No description provided for @ratesOfflineBody.
  ///
  /// In en, this message translates to:
  /// **'Using the latest rates. They\'ll update when you\'re back online.'**
  String get ratesOfflineBody;

  /// No description provided for @ratesListedNote.
  ///
  /// In en, this message translates to:
  /// **'Only currencies your data uses are shown.'**
  String get ratesListedNote;

  /// No description provided for @ratesNoneUsed.
  ///
  /// In en, this message translates to:
  /// **'Everything is in {currency}, so there\'s nothing to convert.'**
  String ratesNoneUsed(String currency);

  /// No description provided for @ratesLinkFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t open it. You can visit {url} yourself.'**
  String ratesLinkFailed(String url);

  /// No description provided for @rateUseAuto.
  ///
  /// In en, this message translates to:
  /// **'Use automatic rate'**
  String get rateUseAuto;

  /// No description provided for @rateAutoValue.
  ///
  /// In en, this message translates to:
  /// **'{rate} · updated {ago}'**
  String rateAutoValue(String rate, String ago);

  /// No description provided for @rateAutoValueBuiltIn.
  ///
  /// In en, this message translates to:
  /// **'{rate} · built-in estimate'**
  String rateAutoValueBuiltIn(String rate);

  /// No description provided for @rateYours.
  ///
  /// In en, this message translates to:
  /// **'Your rate · 1 {from} ='**
  String rateYours(String from);

  /// No description provided for @rateSave.
  ///
  /// In en, this message translates to:
  /// **'Save this rate'**
  String get rateSave;

  /// No description provided for @rateRestoreAuto.
  ///
  /// In en, this message translates to:
  /// **'Restore automatic'**
  String get rateRestoreAuto;

  /// No description provided for @rateMissing.
  ///
  /// In en, this message translates to:
  /// **'No rate for {from} to {to}. This amount is left out of totals.'**
  String rateMissing(String from, String to);

  /// No description provided for @recurringRestartHint.
  ///
  /// In en, this message translates to:
  /// **'Restarts from the next due date: {date}'**
  String recurringRestartHint(String date);

  /// No description provided for @restoreSwitchesNote.
  ///
  /// In en, this message translates to:
  /// **'The daily reminder and widget amounts will be turned off. You can turn them on again in Settings.'**
  String get restoreSwitchesNote;

  /// No description provided for @restoreSwitchesNoteIos.
  ///
  /// In en, this message translates to:
  /// **'The daily reminder will be turned off. You can turn it on again in Settings.'**
  String get restoreSwitchesNoteIos;

  /// No description provided for @archivedAccountsCount.
  ///
  /// In en, this message translates to:
  /// **'Hidden accounts ({count})'**
  String archivedAccountsCount(int count);

  /// No description provided for @autoBackupNoteIos.
  ///
  /// In en, this message translates to:
  /// **'Vigon only writes files to the folder you choose in the Files app, for example in iCloud Drive.'**
  String get autoBackupNoteIos;

  /// No description provided for @autoBackupRunsOnOpenIos.
  ///
  /// In en, this message translates to:
  /// **'iPhone does not let closed apps run on their own. At the time you chose, Vigon sends a notification; tap it or open the app to back up. If the time is missed, the backup catches up when you open the app, at most once a day.'**
  String get autoBackupRunsOnOpenIos;

  /// No description provided for @autoBackupLocalFolderWarningIos.
  ///
  /// In en, this message translates to:
  /// **'This folder may be stored only on this iPhone. If so, losing the phone means losing these files. To keep them safe, choose a folder in iCloud Drive or Google Drive.'**
  String get autoBackupLocalFolderWarningIos;

  /// No description provided for @autoBackupTime.
  ///
  /// In en, this message translates to:
  /// **'Backup time'**
  String get autoBackupTime;

  /// No description provided for @autoBackupNextToday.
  ///
  /// In en, this message translates to:
  /// **'Next: today, {time}'**
  String autoBackupNextToday(String time);

  /// No description provided for @autoBackupNextTomorrow.
  ///
  /// In en, this message translates to:
  /// **'Next: tomorrow, {time}'**
  String autoBackupNextTomorrow(String time);

  /// No description provided for @autoBackupNextSoon.
  ///
  /// In en, this message translates to:
  /// **'Next: when you leave Vigon'**
  String get autoBackupNextSoon;

  /// No description provided for @autoBackupNextSoonIos.
  ///
  /// In en, this message translates to:
  /// **'Next: when you open Vigon again'**
  String get autoBackupNextSoonIos;

  /// No description provided for @autoBackupNotificationBody.
  ///
  /// In en, this message translates to:
  /// **'Time to back up Vigon. Tap to back up.'**
  String get autoBackupNotificationBody;

  /// No description provided for @autoBackupNotifyTitleIos.
  ///
  /// In en, this message translates to:
  /// **'Notify me at backup time'**
  String get autoBackupNotifyTitleIos;

  /// No description provided for @autoBackupNotifyBodyIos.
  ///
  /// In en, this message translates to:
  /// **'iPhone does not let Vigon run on its own while closed. At the time you chose, Vigon sends a notification; tap it to back up. The notification never contains your figures.'**
  String get autoBackupNotifyBodyIos;

  /// No description provided for @autoBackupNotifyDeniedIos.
  ///
  /// In en, this message translates to:
  /// **'No backup-time notification. Vigon will still catch up when you open the app.'**
  String get autoBackupNotifyDeniedIos;

  /// No description provided for @secureWindowNoteIos.
  ///
  /// In en, this message translates to:
  /// **'Hides content in the app switcher. iPhone does not let apps block screenshots.'**
  String get secureWindowNoteIos;

  /// No description provided for @widgetPickerName.
  ///
  /// In en, this message translates to:
  /// **'Vigon'**
  String get widgetPickerName;

  /// No description provided for @widgetPickerDescription.
  ///
  /// In en, this message translates to:
  /// **'Quickly add an expense or income'**
  String get widgetPickerDescription;

  /// No description provided for @widgetExpenseButton.
  ///
  /// In en, this message translates to:
  /// **'Expense'**
  String get widgetExpenseButton;

  /// No description provided for @widgetIncomeButton.
  ///
  /// In en, this message translates to:
  /// **'Income'**
  String get widgetIncomeButton;

  /// No description provided for @widgetStale.
  ///
  /// In en, this message translates to:
  /// **'Open the app to update'**
  String get widgetStale;

  /// No description provided for @currencyConvertTitle.
  ///
  /// In en, this message translates to:
  /// **'Convert to {currency}?'**
  String currencyConvertTitle(String currency);

  /// No description provided for @exchangeRateLoading.
  ///
  /// In en, this message translates to:
  /// **'Getting the exchange rate…'**
  String get exchangeRateLoading;

  /// No description provided for @exchangeRatePair.
  ///
  /// In en, this message translates to:
  /// **'1 {from} = {rate} {to}'**
  String exchangeRatePair(String from, String rate, String to);

  /// No description provided for @exchangeRateDate.
  ///
  /// In en, this message translates to:
  /// **'Rate updated {date}'**
  String exchangeRateDate(String date);

  /// No description provided for @exchangeRateManualSource.
  ///
  /// In en, this message translates to:
  /// **'Rate you entered'**
  String get exchangeRateManualSource;

  /// No description provided for @currencyConvertExample.
  ///
  /// In en, this message translates to:
  /// **'Example: {before} → {after}'**
  String currencyConvertExample(String before, String after);

  /// No description provided for @currencyConvertWarning.
  ///
  /// In en, this message translates to:
  /// **'Every amount (entries, transfers, recurring items, opening balances, category limits, monthly budget) will be converted and rounded to the nearest {currency} unit. This can\'t be undone automatically, and converting back may differ slightly because of rounding. Consider exporting a backup first.'**
  String currencyConvertWarning(String currency);

  /// No description provided for @currencyConvertAction.
  ///
  /// In en, this message translates to:
  /// **'Convert'**
  String get currencyConvertAction;

  /// No description provided for @exchangeRateUseOther.
  ///
  /// In en, this message translates to:
  /// **'Use a different rate'**
  String get exchangeRateUseOther;

  /// No description provided for @exchangeRateErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t get the exchange rate'**
  String get exchangeRateErrorTitle;

  /// No description provided for @exchangeRateOfflineBody.
  ///
  /// In en, this message translates to:
  /// **'Check your internet connection and try again, or enter the rate yourself.'**
  String get exchangeRateOfflineBody;

  /// No description provided for @exchangeRateUnavailableBody.
  ///
  /// In en, this message translates to:
  /// **'The exchange rate service isn\'t responding right now. Try again later, or enter the rate yourself.'**
  String get exchangeRateUnavailableBody;

  /// No description provided for @exchangeRateMissingPairBody.
  ///
  /// In en, this message translates to:
  /// **'No exchange rate is available for {from} to {to}. Enter the rate yourself.'**
  String exchangeRateMissingPairBody(String from, String to);

  /// No description provided for @exchangeRateManualTitle.
  ///
  /// In en, this message translates to:
  /// **'Enter the exchange rate'**
  String get exchangeRateManualTitle;

  /// No description provided for @exchangeRateFieldLabel.
  ///
  /// In en, this message translates to:
  /// **'1 {from} = ? {to}'**
  String exchangeRateFieldLabel(String from, String to);

  /// No description provided for @exchangeRateSwap.
  ///
  /// In en, this message translates to:
  /// **'Swap direction'**
  String get exchangeRateSwap;

  /// No description provided for @exchangeRatePrefilled.
  ///
  /// In en, this message translates to:
  /// **'Filled in with the last rate, from {date}'**
  String exchangeRatePrefilled(String date);

  /// No description provided for @exchangeRateInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a rate greater than 0'**
  String get exchangeRateInvalid;

  /// No description provided for @exchangeRateRetry.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get exchangeRateRetry;

  /// No description provided for @exchangeRateContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get exchangeRateContinue;

  /// No description provided for @currencyConverted.
  ///
  /// In en, this message translates to:
  /// **'All amounts converted to {currency}'**
  String currencyConverted(String currency);

  /// No description provided for @currencyConvertTooLargeTitle.
  ///
  /// In en, this message translates to:
  /// **'Amounts too large'**
  String get currencyConvertTooLargeTitle;

  /// No description provided for @currencyConvertTooLargeBody.
  ///
  /// In en, this message translates to:
  /// **'With this rate, some amounts would go over the largest amount Vigon can store. Nothing was changed.'**
  String get currencyConvertTooLargeBody;

  /// No description provided for @currencyConvertFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t convert. Nothing was changed.'**
  String get currencyConvertFailed;

  /// No description provided for @currencyConvertOk.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get currencyConvertOk;

  /// No description provided for @emailImportGroup.
  ///
  /// In en, this message translates to:
  /// **'Email import'**
  String get emailImportGroup;

  /// No description provided for @emailImport.
  ///
  /// In en, this message translates to:
  /// **'Import from bank email'**
  String get emailImport;

  /// No description provided for @emailImportNoMailbox.
  ///
  /// In en, this message translates to:
  /// **'No mailbox yet'**
  String get emailImportNoMailbox;

  /// No description provided for @emailImportMailboxCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 mailbox} other{{count} mailboxes}}'**
  String emailImportMailboxCount(int count);

  /// No description provided for @emailIntroTitle.
  ///
  /// In en, this message translates to:
  /// **'Record spending from receipt emails'**
  String get emailIntroTitle;

  /// No description provided for @emailIntroRead.
  ///
  /// In en, this message translates to:
  /// **'Vigon reads your bank\'s transfer receipt emails in the mailbox you add, then puts them in a queue for you to pick a category.'**
  String get emailIntroRead;

  /// No description provided for @emailIntroLocal.
  ///
  /// In en, this message translates to:
  /// **'On this phone only: email content is never sent anywhere.'**
  String get emailIntroLocal;

  /// No description provided for @emailIntroReadOnly.
  ///
  /// In en, this message translates to:
  /// **'No email is changed, deleted or marked as read.'**
  String get emailIntroReadOnly;

  /// No description provided for @emailIntroAppPassword.
  ///
  /// In en, this message translates to:
  /// **'Needs an app password from your email provider, not your main sign-in password.'**
  String get emailIntroAppPassword;

  /// No description provided for @emailIntroBanks.
  ///
  /// In en, this message translates to:
  /// **'Only MB Bank is supported for now.'**
  String get emailIntroBanks;

  /// No description provided for @emailIntroIos.
  ///
  /// In en, this message translates to:
  /// **'On iPhone, Vigon checks email only when you open or return to the app.'**
  String get emailIntroIos;

  /// No description provided for @emailAddMailbox.
  ///
  /// In en, this message translates to:
  /// **'Add mailbox'**
  String get emailAddMailbox;

  /// No description provided for @emailMailboxLimit.
  ///
  /// In en, this message translates to:
  /// **'You already have 3 mailboxes. Remove one to add another.'**
  String get emailMailboxLimit;

  /// No description provided for @emailScheduleAndroid.
  ///
  /// In en, this message translates to:
  /// **'Vigon checks email when you open the app and about every hour while it\'s closed. Pull down to check now.'**
  String get emailScheduleAndroid;

  /// No description provided for @emailScheduleIos.
  ///
  /// In en, this message translates to:
  /// **'On iPhone, Vigon checks email only when you open or return to the app. Pull down to check now.'**
  String get emailScheduleIos;

  /// No description provided for @emailConnected.
  ///
  /// In en, this message translates to:
  /// **'Connected'**
  String get emailConnected;

  /// No description provided for @emailLastCheck.
  ///
  /// In en, this message translates to:
  /// **'Connected · Last check: {time}'**
  String emailLastCheck(String time);

  /// No description provided for @emailErrorAt.
  ///
  /// In en, this message translates to:
  /// **'Check at {time}: {error}'**
  String emailErrorAt(String time, String error);

  /// No description provided for @emailErrorCredentials.
  ///
  /// In en, this message translates to:
  /// **'Wrong address or app password'**
  String get emailErrorCredentials;

  /// No description provided for @emailErrorImapDisabled.
  ///
  /// In en, this message translates to:
  /// **'IMAP is turned off for this mailbox'**
  String get emailErrorImapDisabled;

  /// No description provided for @emailErrorNetwork.
  ///
  /// In en, this message translates to:
  /// **'No internet connection'**
  String get emailErrorNetwork;

  /// No description provided for @emailErrorSecure.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t make a secure connection to the email server'**
  String get emailErrorSecure;

  /// No description provided for @emailErrorServer.
  ///
  /// In en, this message translates to:
  /// **'The email server returned an error. Try again later'**
  String get emailErrorServer;

  /// No description provided for @emailPaused.
  ///
  /// In en, this message translates to:
  /// **'Checking this mailbox is paused. Enter the app password again to continue.'**
  String get emailPaused;

  /// No description provided for @emailUnreadable.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 MB email couldn\'t be read} other{{count} MB emails couldn\'t be read}}'**
  String emailUnreadable(int count);

  /// No description provided for @emailReenterPassword.
  ///
  /// In en, this message translates to:
  /// **'Re-enter password'**
  String get emailReenterPassword;

  /// No description provided for @emailRemoveMailbox.
  ///
  /// In en, this message translates to:
  /// **'Remove mailbox'**
  String get emailRemoveMailbox;

  /// No description provided for @emailRemoveTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove mailbox?'**
  String get emailRemoveTitle;

  /// No description provided for @emailRemoveBody.
  ///
  /// In en, this message translates to:
  /// **'Vigon will stop reading email from {address} and delete the app password from this phone. Records already saved stay as they are.'**
  String emailRemoveBody(String address);

  /// No description provided for @emailRemoved.
  ///
  /// In en, this message translates to:
  /// **'Mailbox removed'**
  String get emailRemoved;

  /// No description provided for @emailProvider.
  ///
  /// In en, this message translates to:
  /// **'Provider'**
  String get emailProvider;

  /// No description provided for @emailStepsTitle.
  ///
  /// In en, this message translates to:
  /// **'Create an app password'**
  String get emailStepsTitle;

  /// No description provided for @emailStepsGmail1.
  ///
  /// In en, this message translates to:
  /// **'Turn on 2-Step Verification for your Google account (required for app passwords).'**
  String get emailStepsGmail1;

  /// No description provided for @emailStepsGmail2.
  ///
  /// In en, this message translates to:
  /// **'Open the App passwords page with the button below, name it \"Vigon\" and tap Create.'**
  String get emailStepsGmail2;

  /// No description provided for @emailStepsGmail3.
  ///
  /// In en, this message translates to:
  /// **'Copy the 16-character password Google shows into the App password field below.'**
  String get emailStepsGmail3;

  /// No description provided for @emailStepsYahoo1.
  ///
  /// In en, this message translates to:
  /// **'Open the Yahoo Account security page with the button below.'**
  String get emailStepsYahoo1;

  /// No description provided for @emailStepsYahoo2.
  ///
  /// In en, this message translates to:
  /// **'Choose \"Generate app password\", name it \"Vigon\" and tap Generate.'**
  String get emailStepsYahoo2;

  /// No description provided for @emailStepsYahoo3.
  ///
  /// In en, this message translates to:
  /// **'Copy the password Yahoo shows into the App password field below.'**
  String get emailStepsYahoo3;

  /// No description provided for @emailStepsIcloud1.
  ///
  /// In en, this message translates to:
  /// **'Turn on two-factor authentication for your Apple Account.'**
  String get emailStepsIcloud1;

  /// No description provided for @emailStepsIcloud2.
  ///
  /// In en, this message translates to:
  /// **'Open the Apple Account page with the button below → Sign-In and Security → App-Specific Passwords, name it \"Vigon\".'**
  String get emailStepsIcloud2;

  /// No description provided for @emailStepsIcloud3.
  ///
  /// In en, this message translates to:
  /// **'Copy the password Apple shows into the App password field below; the address is your iCloud email.'**
  String get emailStepsIcloud3;

  /// No description provided for @emailOpenPasswordPage.
  ///
  /// In en, this message translates to:
  /// **'Open the app password page'**
  String get emailOpenPasswordPage;

  /// No description provided for @emailAddress.
  ///
  /// In en, this message translates to:
  /// **'Email address'**
  String get emailAddress;

  /// No description provided for @emailAddressInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email address'**
  String get emailAddressInvalid;

  /// No description provided for @emailAppPassword.
  ///
  /// In en, this message translates to:
  /// **'App password'**
  String get emailAppPassword;

  /// No description provided for @emailAppPasswordHelper.
  ///
  /// In en, this message translates to:
  /// **'Not your main sign-in password. Stored only in this phone\'s secure storage.'**
  String get emailAppPasswordHelper;

  /// No description provided for @emailAppPasswordEmpty.
  ///
  /// In en, this message translates to:
  /// **'Enter the app password'**
  String get emailAppPasswordEmpty;

  /// No description provided for @emailConnect.
  ///
  /// In en, this message translates to:
  /// **'Connect'**
  String get emailConnect;

  /// No description provided for @emailDuplicate.
  ///
  /// In en, this message translates to:
  /// **'This mailbox is already added'**
  String get emailDuplicate;

  /// No description provided for @emailSaveReenter.
  ///
  /// In en, this message translates to:
  /// **'Save and reconnect'**
  String get emailSaveReenter;

  /// No description provided for @entryTime.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get entryTime;

  /// No description provided for @timeNotSet.
  ///
  /// In en, this message translates to:
  /// **'No time set'**
  String get timeNotSet;

  /// No description provided for @csvColTime.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get csvColTime;

  /// No description provided for @csvColSource.
  ///
  /// In en, this message translates to:
  /// **'Source'**
  String get csvColSource;

  /// No description provided for @csvSourceManual.
  ///
  /// In en, this message translates to:
  /// **'Manual'**
  String get csvSourceManual;

  /// No description provided for @csvSourceEmailMb.
  ///
  /// In en, this message translates to:
  /// **'MB email'**
  String get csvSourceEmailMb;

  /// No description provided for @savings.
  ///
  /// In en, this message translates to:
  /// **'Savings'**
  String get savings;

  /// No description provided for @savingsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No savings goals yet. Set a goal, then add money to it over time.'**
  String get savingsEmpty;

  /// No description provided for @savingsAdd.
  ///
  /// In en, this message translates to:
  /// **'Add goal'**
  String get savingsAdd;

  /// No description provided for @savingsEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit goal'**
  String get savingsEdit;

  /// No description provided for @savingsTarget.
  ///
  /// In en, this message translates to:
  /// **'Target amount'**
  String get savingsTarget;

  /// No description provided for @savingsDue.
  ///
  /// In en, this message translates to:
  /// **'Deadline (optional)'**
  String get savingsDue;

  /// No description provided for @savingsNoDue.
  ///
  /// In en, this message translates to:
  /// **'No deadline'**
  String get savingsNoDue;

  /// No description provided for @savingsClearDue.
  ///
  /// In en, this message translates to:
  /// **'Remove deadline'**
  String get savingsClearDue;

  /// No description provided for @savingsAccount.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get savingsAccount;

  /// No description provided for @savingsNewAccount.
  ///
  /// In en, this message translates to:
  /// **'Create a new account'**
  String get savingsNewAccount;

  /// No description provided for @savingsNewAccountNote.
  ///
  /// In en, this message translates to:
  /// **'The new account is named like the goal and starts at 0.'**
  String get savingsNewAccountNote;

  /// No description provided for @savingsAccountFixed.
  ///
  /// In en, this message translates to:
  /// **'The linked account can\'t be changed. To link a different account, delete the goal and create it again.'**
  String get savingsAccountFixed;

  /// No description provided for @savingsAccountTaken.
  ///
  /// In en, this message translates to:
  /// **'This account is already linked to another goal'**
  String get savingsAccountTaken;

  /// No description provided for @savingsProgress.
  ///
  /// In en, this message translates to:
  /// **'Saved {have} of {target}'**
  String savingsProgress(String have, String target);

  /// No description provided for @savingsMissing.
  ///
  /// In en, this message translates to:
  /// **'{amount} to go'**
  String savingsMissing(String amount);

  /// No description provided for @savingsReached.
  ///
  /// In en, this message translates to:
  /// **'Reached'**
  String get savingsReached;

  /// No description provided for @savingsDaysLeft.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{Due today} =1{1 day left} other{{count} days left}}'**
  String savingsDaysLeft(int count);

  /// No description provided for @savingsOverdue.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 day overdue} other{{count} days overdue}}'**
  String savingsOverdue(int count);

  /// No description provided for @savingsContribute.
  ///
  /// In en, this message translates to:
  /// **'Add money'**
  String get savingsContribute;

  /// No description provided for @savingsNeedOtherAccount.
  ///
  /// In en, this message translates to:
  /// **'You need another account to add money from'**
  String get savingsNeedOtherAccount;

  /// No description provided for @savingsDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete goal'**
  String get savingsDelete;

  /// No description provided for @savingsDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete this goal?'**
  String get savingsDeleteTitle;

  /// No description provided for @savingsDeleteBody.
  ///
  /// In en, this message translates to:
  /// **'The account and all records stay. Only the goal is deleted.'**
  String get savingsDeleteBody;

  /// No description provided for @savingsDeleted.
  ///
  /// In en, this message translates to:
  /// **'Goal deleted'**
  String get savingsDeleted;

  /// No description provided for @debts.
  ///
  /// In en, this message translates to:
  /// **'Debts'**
  String get debts;

  /// No description provided for @debtsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No debts yet. Note who owes you, or whom you owe, so you don\'t forget.'**
  String get debtsEmpty;

  /// No description provided for @debtsNote.
  ///
  /// In en, this message translates to:
  /// **'A reminder list only: it doesn\'t count in income, expenses or account balances.'**
  String get debtsNote;

  /// No description provided for @debtAdd.
  ///
  /// In en, this message translates to:
  /// **'Add debt'**
  String get debtAdd;

  /// No description provided for @debtEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit debt'**
  String get debtEdit;

  /// No description provided for @debtPerson.
  ///
  /// In en, this message translates to:
  /// **'Person'**
  String get debtPerson;

  /// No description provided for @debtDirection.
  ///
  /// In en, this message translates to:
  /// **'Direction'**
  String get debtDirection;

  /// No description provided for @debtLent.
  ///
  /// In en, this message translates to:
  /// **'I lent'**
  String get debtLent;

  /// No description provided for @debtBorrowed.
  ///
  /// In en, this message translates to:
  /// **'I borrowed'**
  String get debtBorrowed;

  /// No description provided for @debtGroupLent.
  ///
  /// In en, this message translates to:
  /// **'Owed to you'**
  String get debtGroupLent;

  /// No description provided for @debtGroupBorrowed.
  ///
  /// In en, this message translates to:
  /// **'You owe'**
  String get debtGroupBorrowed;

  /// No description provided for @debtGroupTotal.
  ///
  /// In en, this message translates to:
  /// **'{amount} remaining'**
  String debtGroupTotal(String amount);

  /// No description provided for @debtDoneSection.
  ///
  /// In en, this message translates to:
  /// **'Settled ({count})'**
  String debtDoneSection(int count);

  /// No description provided for @debtDone.
  ///
  /// In en, this message translates to:
  /// **'Settled'**
  String get debtDone;

  /// No description provided for @debtAmount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get debtAmount;

  /// No description provided for @debtDate.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get debtDate;

  /// No description provided for @debtDue.
  ///
  /// In en, this message translates to:
  /// **'Due date (optional)'**
  String get debtDue;

  /// No description provided for @debtDueOn.
  ///
  /// In en, this message translates to:
  /// **'Due {date}'**
  String debtDueOn(String date);

  /// No description provided for @debtClearDue.
  ///
  /// In en, this message translates to:
  /// **'Remove due date'**
  String get debtClearDue;

  /// No description provided for @debtOverdue.
  ///
  /// In en, this message translates to:
  /// **'Overdue'**
  String get debtOverdue;

  /// No description provided for @debtRemaining.
  ///
  /// In en, this message translates to:
  /// **'{amount} remaining'**
  String debtRemaining(String amount);

  /// No description provided for @debtPaidOf.
  ///
  /// In en, this message translates to:
  /// **'Paid {paid} of {total}'**
  String debtPaidOf(String paid, String total);

  /// No description provided for @debtPayments.
  ///
  /// In en, this message translates to:
  /// **'Payments'**
  String get debtPayments;

  /// No description provided for @debtNoPayments.
  ///
  /// In en, this message translates to:
  /// **'No payments yet'**
  String get debtNoPayments;

  /// No description provided for @debtAddPayment.
  ///
  /// In en, this message translates to:
  /// **'Add payment'**
  String get debtAddPayment;

  /// No description provided for @debtPaymentAmount.
  ///
  /// In en, this message translates to:
  /// **'Payment amount'**
  String get debtPaymentAmount;

  /// No description provided for @debtDeletePayment.
  ///
  /// In en, this message translates to:
  /// **'Delete payment'**
  String get debtDeletePayment;

  /// No description provided for @debtOverpay.
  ///
  /// In en, this message translates to:
  /// **'More than the remaining {remaining}'**
  String debtOverpay(String remaining);

  /// No description provided for @debtAmountBelowPaid.
  ///
  /// In en, this message translates to:
  /// **'Can\'t be less than the {paid} already paid'**
  String debtAmountBelowPaid(String paid);

  /// No description provided for @debtDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete debt'**
  String get debtDelete;

  /// No description provided for @debtDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete this debt?'**
  String get debtDeleteTitle;

  /// No description provided for @debtDeleteBody.
  ///
  /// In en, this message translates to:
  /// **'Its payments are deleted too. No record or account balance is affected.'**
  String get debtDeleteBody;

  /// No description provided for @debtDeleted.
  ///
  /// In en, this message translates to:
  /// **'Debt deleted'**
  String get debtDeleted;

  /// No description provided for @debtRemainingLabel.
  ///
  /// In en, this message translates to:
  /// **'Remaining'**
  String get debtRemainingLabel;

  /// No description provided for @importQueue.
  ///
  /// In en, this message translates to:
  /// **'Queue'**
  String get importQueue;

  /// No description provided for @importQueueRow.
  ///
  /// In en, this message translates to:
  /// **'Items awaiting a category'**
  String get importQueueRow;

  /// No description provided for @importQueueRowCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, other{{count} awaiting}}'**
  String importQueueRowCount(int count);

  /// No description provided for @importQueueCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 record waiting for a category} other{{count} records waiting for a category}}'**
  String importQueueCount(int count);

  /// No description provided for @importQueueNone.
  ///
  /// In en, this message translates to:
  /// **'Nothing is waiting'**
  String get importQueueNone;

  /// No description provided for @queueEmpty.
  ///
  /// In en, this message translates to:
  /// **'Nothing is waiting. When a new receipt email arrives, it shows up here for you to pick a category.'**
  String get queueEmpty;

  /// No description provided for @queuePayeeUnknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown payee'**
  String get queuePayeeUnknown;

  /// No description provided for @queueFromAccount.
  ///
  /// In en, this message translates to:
  /// **'From {account}'**
  String queueFromAccount(String account);

  /// No description provided for @queueCurrencyNote.
  ///
  /// In en, this message translates to:
  /// **'The email is in {emailCurrency} but the account uses {appCurrency}. You\'ll enter the amount in the next step.'**
  String queueCurrencyNote(String emailCurrency, String appCurrency);

  /// No description provided for @queueSuggested.
  ///
  /// In en, this message translates to:
  /// **'Suggested'**
  String get queueSuggested;

  /// No description provided for @queueSaveTo.
  ///
  /// In en, this message translates to:
  /// **'Save to {category}'**
  String queueSaveTo(String category);

  /// No description provided for @queueMoveTo.
  ///
  /// In en, this message translates to:
  /// **'Move to {account}'**
  String queueMoveTo(String account);

  /// No description provided for @queueEditFirst.
  ///
  /// In en, this message translates to:
  /// **'Edit before saving'**
  String get queueEditFirst;

  /// No description provided for @queueMoveToMine.
  ///
  /// In en, this message translates to:
  /// **'Move to my account'**
  String get queueMoveToMine;

  /// No description provided for @queueMoveToTitle.
  ///
  /// In en, this message translates to:
  /// **'Move to account'**
  String get queueMoveToTitle;

  /// No description provided for @queueNoOtherAccount.
  ///
  /// In en, this message translates to:
  /// **'There is no other account to choose'**
  String get queueNoOtherAccount;

  /// No description provided for @queueSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get queueSkip;

  /// No description provided for @queueSkipTitle.
  ///
  /// In en, this message translates to:
  /// **'Skip this record?'**
  String get queueSkipTitle;

  /// No description provided for @queueSkipBody.
  ///
  /// In en, this message translates to:
  /// **'It leaves the queue and won\'t be imported again from this email.'**
  String get queueSkipBody;

  /// No description provided for @queueSaved.
  ///
  /// In en, this message translates to:
  /// **'Saved to {category}'**
  String queueSaved(String category);

  /// No description provided for @queueMoved.
  ///
  /// In en, this message translates to:
  /// **'Moved to {account}'**
  String queueMoved(String account);

  /// No description provided for @queueSkipped.
  ///
  /// In en, this message translates to:
  /// **'Skipped'**
  String get queueSkipped;

  /// No description provided for @queueSuggestions.
  ///
  /// In en, this message translates to:
  /// **'Remembered suggestions'**
  String get queueSuggestions;

  /// No description provided for @queueSuggestionsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No suggestions yet. Vigon remembers the category you pick for each payee to suggest it next time.'**
  String get queueSuggestionsEmpty;

  /// No description provided for @queueSuggestionMove.
  ///
  /// In en, this message translates to:
  /// **'Move to {account}'**
  String queueSuggestionMove(String account);

  /// No description provided for @queueSuggestionDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete suggestion'**
  String get queueSuggestionDelete;

  /// No description provided for @queueSuggestionDeleted.
  ///
  /// In en, this message translates to:
  /// **'Suggestion deleted'**
  String get queueSuggestionDeleted;

  /// No description provided for @queueAutoAccount.
  ///
  /// In en, this message translates to:
  /// **'Created account {account}'**
  String queueAutoAccount(String account);

  /// No description provided for @queueAttach.
  ///
  /// In en, this message translates to:
  /// **'Attach to an existing account'**
  String get queueAttach;

  /// No description provided for @queueAttachTitle.
  ///
  /// In en, this message translates to:
  /// **'Attach to account'**
  String get queueAttachTitle;

  /// No description provided for @queueDismiss.
  ///
  /// In en, this message translates to:
  /// **'Dismiss'**
  String get queueDismiss;

  /// No description provided for @queueMatched.
  ///
  /// In en, this message translates to:
  /// **'Matched with MB email {time}'**
  String queueMatched(String time);

  /// No description provided for @savingsGoalName.
  ///
  /// In en, this message translates to:
  /// **'Goal name'**
  String get savingsGoalName;

  /// No description provided for @savingsAccountHelper.
  ///
  /// In en, this message translates to:
  /// **'A new account just for this goal. Move money in with Add money.'**
  String get savingsAccountHelper;

  /// No description provided for @savingsAccountEditHelper.
  ///
  /// In en, this message translates to:
  /// **'The account that holds this goal\'s money.'**
  String get savingsAccountEditHelper;

  /// No description provided for @savingsAlreadySaved.
  ///
  /// In en, this message translates to:
  /// **'Already saved (optional)'**
  String get savingsAlreadySaved;

  /// No description provided for @savingsAlreadySavedHelper.
  ///
  /// In en, this message translates to:
  /// **'Money you\'ve already put aside. It becomes the account\'s starting balance.'**
  String get savingsAlreadySavedHelper;

  /// No description provided for @savingsCurrencyLocked.
  ///
  /// In en, this message translates to:
  /// **'The currency can\'t change once the account has records.'**
  String get savingsCurrencyLocked;

  /// No description provided for @savingsInProgress.
  ///
  /// In en, this message translates to:
  /// **'In progress'**
  String get savingsInProgress;

  /// No description provided for @savingsDoneSection.
  ///
  /// In en, this message translates to:
  /// **'Done ({count})'**
  String savingsDoneSection(int count);

  /// No description provided for @savingsDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get savingsDone;

  /// No description provided for @savingsDoneOn.
  ///
  /// In en, this message translates to:
  /// **'Done · {date}'**
  String savingsDoneOn(String date);

  /// No description provided for @savingsWithdraw.
  ///
  /// In en, this message translates to:
  /// **'Withdraw'**
  String get savingsWithdraw;

  /// No description provided for @savingsHistory.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get savingsHistory;

  /// No description provided for @savingsHistoryEmpty.
  ///
  /// In en, this message translates to:
  /// **'No money moved yet'**
  String get savingsHistoryEmpty;

  /// No description provided for @savingsHistoryAdded.
  ///
  /// In en, this message translates to:
  /// **'Added from {account}'**
  String savingsHistoryAdded(String account);

  /// No description provided for @savingsHistoryWithdrew.
  ///
  /// In en, this message translates to:
  /// **'Withdrew to {account}'**
  String savingsHistoryWithdrew(String account);

  /// No description provided for @savingsHistorySpent.
  ///
  /// In en, this message translates to:
  /// **'Spent: {what}'**
  String savingsHistorySpent(String what);

  /// No description provided for @savingsHistoryIncome.
  ///
  /// In en, this message translates to:
  /// **'Income: {what}'**
  String savingsHistoryIncome(String what);

  /// No description provided for @savingsHistoryStart.
  ///
  /// In en, this message translates to:
  /// **'Already saved'**
  String get savingsHistoryStart;

  /// No description provided for @savingsBalance.
  ///
  /// In en, this message translates to:
  /// **'Balance {amount}'**
  String savingsBalance(String amount);

  /// No description provided for @savingsFromAccount.
  ///
  /// In en, this message translates to:
  /// **'From account'**
  String get savingsFromAccount;

  /// No description provided for @savingsToAccount.
  ///
  /// In en, this message translates to:
  /// **'To account'**
  String get savingsToAccount;

  /// No description provided for @savingsMoveAmount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get savingsMoveAmount;

  /// No description provided for @savingsFillToTarget.
  ///
  /// In en, this message translates to:
  /// **'Fill to target'**
  String get savingsFillToTarget;

  /// No description provided for @savingsWithdrawAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get savingsWithdrawAll;

  /// No description provided for @savingsOverTarget.
  ///
  /// In en, this message translates to:
  /// **'Only {amount} more needed'**
  String savingsOverTarget(String amount);

  /// No description provided for @savingsOverBalance.
  ///
  /// In en, this message translates to:
  /// **'Only {amount} in this account'**
  String savingsOverBalance(String amount);

  /// No description provided for @savingsSendsApprox.
  ///
  /// In en, this message translates to:
  /// **'Sends {amount} from {account} at today\'s rate'**
  String savingsSendsApprox(String amount, String account);

  /// No description provided for @savingsNothingToWithdraw.
  ///
  /// In en, this message translates to:
  /// **'This account is empty'**
  String get savingsNothingToWithdraw;

  /// No description provided for @savingsReachedTitle.
  ///
  /// In en, this message translates to:
  /// **'Savings goal reached'**
  String get savingsReachedTitle;

  /// No description provided for @savingsReachedBody.
  ///
  /// In en, this message translates to:
  /// **'You\'ve saved {amount} for {goal}.'**
  String savingsReachedBody(String amount, String goal);

  /// No description provided for @savingsReachedOk.
  ///
  /// In en, this message translates to:
  /// **'Great'**
  String get savingsReachedOk;

  /// No description provided for @savingsReopen.
  ///
  /// In en, this message translates to:
  /// **'Reopen'**
  String get savingsReopen;

  /// No description provided for @savingsReopened.
  ///
  /// In en, this message translates to:
  /// **'Goal reopened'**
  String get savingsReopened;

  /// No description provided for @savingsAdded.
  ///
  /// In en, this message translates to:
  /// **'Added {amount}'**
  String savingsAdded(String amount);

  /// No description provided for @savingsWithdrawn.
  ///
  /// In en, this message translates to:
  /// **'Withdrew {amount}'**
  String savingsWithdrawn(String amount);

  /// No description provided for @savingsWalletOf.
  ///
  /// In en, this message translates to:
  /// **'Savings · {goal}'**
  String savingsWalletOf(String goal);

  /// No description provided for @currencyChipTooltip.
  ///
  /// In en, this message translates to:
  /// **'Currency: {currency}'**
  String currencyChipTooltip(String currency);

  /// No description provided for @deadlineReminders.
  ///
  /// In en, this message translates to:
  /// **'Deadline reminders'**
  String get deadlineReminders;

  /// No description provided for @deadlineRemindersValue.
  ///
  /// In en, this message translates to:
  /// **'{days, plural, =1{1 day before} other{{days} days before}} · {time}'**
  String deadlineRemindersValue(int days, String time);

  /// No description provided for @deadlineRemindersOff.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get deadlineRemindersOff;

  /// No description provided for @deadlineRemindersSwitch.
  ///
  /// In en, this message translates to:
  /// **'Remind me before due dates'**
  String get deadlineRemindersSwitch;

  /// No description provided for @deadlineRemindersNote.
  ///
  /// In en, this message translates to:
  /// **'For savings goals and debts with a due date. Notifications show the amount left.'**
  String get deadlineRemindersNote;

  /// No description provided for @deadlineDaysBefore.
  ///
  /// In en, this message translates to:
  /// **'Days before'**
  String get deadlineDaysBefore;

  /// No description provided for @deadlineDaysValue.
  ///
  /// In en, this message translates to:
  /// **'{days, plural, =1{1 day} other{{days} days}}'**
  String deadlineDaysValue(int days);

  /// No description provided for @deadlineTime.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get deadlineTime;

  /// No description provided for @deadlineExplainTitle.
  ///
  /// In en, this message translates to:
  /// **'Turn on deadline reminders?'**
  String get deadlineExplainTitle;

  /// No description provided for @deadlineExplainBody.
  ///
  /// In en, this message translates to:
  /// **'Vigon will notify you before and on the due date of your savings goals and debts. The notification shows the amount left.'**
  String get deadlineExplainBody;

  /// No description provided for @deadlineChannelName.
  ///
  /// In en, this message translates to:
  /// **'Deadline reminders'**
  String get deadlineChannelName;

  /// No description provided for @deadlineChannelDescription.
  ///
  /// In en, this message translates to:
  /// **'Reminders before savings goals and debts are due'**
  String get deadlineChannelDescription;

  /// No description provided for @deadlineWhenDays.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{due in 1 day} other{due in {count} days}}'**
  String deadlineWhenDays(int count);

  /// No description provided for @deadlineWhenToday.
  ///
  /// In en, this message translates to:
  /// **'due today'**
  String get deadlineWhenToday;

  /// No description provided for @deadlineDebtLent.
  ///
  /// In en, this message translates to:
  /// **'Debt with {person}: {amount} left, {when}'**
  String deadlineDebtLent(String person, String amount, String when);

  /// No description provided for @deadlineDebtBorrowed.
  ///
  /// In en, this message translates to:
  /// **'You owe {person}: {amount} left, {when}'**
  String deadlineDebtBorrowed(String person, String amount, String when);

  /// No description provided for @deadlineGoal.
  ///
  /// In en, this message translates to:
  /// **'Goal {goal}: {amount} to go, {when}'**
  String deadlineGoal(String goal, String amount, String when);

  /// No description provided for @debtPayRest.
  ///
  /// In en, this message translates to:
  /// **'Pay the rest'**
  String get debtPayRest;

  /// No description provided for @mainFirstNote.
  ///
  /// In en, this message translates to:
  /// **'in {currency}'**
  String mainFirstNote(String currency);

  /// No description provided for @homeEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'Log your first expense'**
  String get homeEmptyTitle;

  /// No description provided for @homeEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Tap a category or −'**
  String get homeEmptyBody;

  /// No description provided for @fromEmailRef.
  ///
  /// In en, this message translates to:
  /// **'From MB email · reference ending {ref}'**
  String fromEmailRef(String ref);

  /// No description provided for @setTime.
  ///
  /// In en, this message translates to:
  /// **'Set time'**
  String get setTime;

  /// No description provided for @mbLinked.
  ///
  /// In en, this message translates to:
  /// **'From MB email'**
  String get mbLinked;

  /// No description provided for @savingsWallet.
  ///
  /// In en, this message translates to:
  /// **'Savings wallet'**
  String get savingsWallet;

  /// No description provided for @totalInMain.
  ///
  /// In en, this message translates to:
  /// **'Total in {currency}'**
  String totalInMain(String currency);

  /// No description provided for @accountCurrencyLabel.
  ///
  /// In en, this message translates to:
  /// **'Account currency'**
  String get accountCurrencyLabel;

  /// No description provided for @youReceive.
  ///
  /// In en, this message translates to:
  /// **'They receive'**
  String get youReceive;

  /// No description provided for @queueNotCountedNote.
  ///
  /// In en, this message translates to:
  /// **'Not counted yet: items here join totals, charts and budgets only after you save them.'**
  String get queueNotCountedNote;

  /// No description provided for @widgetSpentLabel.
  ///
  /// In en, this message translates to:
  /// **'Spent this month'**
  String get widgetSpentLabel;

  /// No description provided for @widgetOfBudget.
  ///
  /// In en, this message translates to:
  /// **'of {budget} · {percent}'**
  String widgetOfBudget(String budget, String percent);

  /// No description provided for @almostOver.
  ///
  /// In en, this message translates to:
  /// **'Almost over'**
  String get almostOver;

  /// No description provided for @walletBalanceNote.
  ///
  /// In en, this message translates to:
  /// **'Money in this wallet counts in your total balance, not in income or expenses.'**
  String get walletBalanceNote;

  /// No description provided for @remindDays.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{1 day before} other{{n} days before}}'**
  String remindDays(int n);

  /// No description provided for @remindNext.
  ///
  /// In en, this message translates to:
  /// **'Reminder {date}'**
  String remindNext(String date);

  /// No description provided for @goalsN.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{1 goal} other{{n} goals}}'**
  String goalsN(int n);

  /// No description provided for @owedToYouShort.
  ///
  /// In en, this message translates to:
  /// **'{amount} owed to you'**
  String owedToYouShort(String amount);

  /// No description provided for @rateLine.
  ///
  /// In en, this message translates to:
  /// **'1 {from} = {rate} {to} · auto'**
  String rateLine(String from, String rate, String to);
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
