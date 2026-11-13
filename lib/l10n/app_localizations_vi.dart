// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Vietnamese (`vi`).
class AppLocalizationsVi extends AppLocalizations {
  AppLocalizationsVi([String locale = 'vi']) : super(locale);

  @override
  String get appTitle => 'Ví Gọn';

  @override
  String get settings => 'Cài đặt';

  @override
  String get theme => 'Giao diện';

  @override
  String get themeSystem => 'Theo hệ thống';

  @override
  String get themeLight => 'Sáng';

  @override
  String get themeDark => 'Tối';

  @override
  String get language => 'Ngôn ngữ';

  @override
  String get appearanceLanguage => 'Giao diện & ngôn ngữ';

  @override
  String get categoriesAccountsSection => 'Danh mục & tài khoản';

  @override
  String get planSection => 'Kế hoạch';

  @override
  String get currencyPeriodSection => 'Tiền tệ & kỳ';

  @override
  String get reminderSection => 'Nhắc ghi sổ';

  @override
  String get reminderSwitch => 'Nhắc ghi sổ hằng ngày';

  @override
  String get reminderSwitchNote =>
      'Mỗi ngày một thông báo vào giờ bạn chọn, không chứa số liệu';

  @override
  String get reminderTime => 'Giờ nhắc';

  @override
  String get reminderExplainTitle => 'Bật nhắc ghi sổ?';

  @override
  String get reminderExplainBody =>
      'Ví Gọn sẽ gửi một thông báo mỗi ngày vào giờ bạn chọn để nhắc bạn ghi lại chi tiêu. Thông báo không chứa số liệu.';

  @override
  String get reminderContinue => 'Tiếp tục';

  @override
  String get reminderDenied =>
      'Chưa có quyền gửi thông báo. Hãy bật thông báo cho Ví Gọn trong cài đặt hệ thống.';

  @override
  String get reminderOpenSettings => 'Mở cài đặt';

  @override
  String get reminderChannelName => 'Nhắc ghi sổ';

  @override
  String get reminderChannelDescription => 'Nhắc ghi chi tiêu mỗi ngày';

  @override
  String get reminderNotificationBody => 'Hôm nay bạn đã ghi chi tiêu chưa?';

  @override
  String get emptyPeriod => 'Bấm − để ghi khoản chi đầu tiên';

  @override
  String get accountCash => 'Tiền mặt';

  @override
  String get categoryFood => 'Ăn uống';

  @override
  String get categoryTransport => 'Đi lại';

  @override
  String get categoryHome => 'Nhà cửa';

  @override
  String get categoryBills => 'Hóa đơn';

  @override
  String get categoryShopping => 'Mua sắm';

  @override
  String get categoryHealth => 'Sức khỏe';

  @override
  String get categoryEntertainment => 'Giải trí';

  @override
  String get categoryEducation => 'Giáo dục';

  @override
  String get categoryFamily => 'Gia đình';

  @override
  String get categoryOther => 'Khác';

  @override
  String get categorySalary => 'Lương';

  @override
  String get categoryBonus => 'Thưởng';

  @override
  String get categoryOtherIncome => 'Thu khác';

  @override
  String get periodDay => 'Ngày';

  @override
  String get periodWeek => 'Tuần';

  @override
  String get periodMonth => 'Tháng';

  @override
  String get periodYear => 'Năm';

  @override
  String get periodAll => 'Tất cả';

  @override
  String get periodCustom => 'Khoảng tùy chọn';

  @override
  String get choosePeriod => 'Chọn kỳ xem';

  @override
  String get previousPeriod => 'Kỳ trước';

  @override
  String get nextPeriod => 'Kỳ sau';

  @override
  String get income => 'Thu';

  @override
  String get expense => 'Chi';

  @override
  String get balance => 'Số dư';

  @override
  String balanceLabel(String amount) {
    return 'Số dư: $amount';
  }

  @override
  String get addExpense => 'Thêm khoản chi';

  @override
  String get addIncome => 'Thêm khoản thu';

  @override
  String get allAccounts => 'Tất cả tài khoản';

  @override
  String get entries => 'Các khoản';

  @override
  String chartSummary(String details) {
    return 'Chi tiêu theo danh mục: $details';
  }

  @override
  String categoryAmount(String name, String amount, String percent) {
    return '$name, $amount, $percent';
  }

  @override
  String categoryNoEntries(String name) {
    return '$name, chưa có khoản';
  }

  @override
  String get noEntries => 'Kỳ này chưa có khoản nào';

  @override
  String get newExpense => 'Khoản chi mới';

  @override
  String get newIncome => 'Khoản thu mới';

  @override
  String get editEntry => 'Sửa khoản';

  @override
  String get chooseCategory => 'Chọn danh mục';

  @override
  String get otherCategories => 'Danh mục khác';

  @override
  String get save => 'Lưu';

  @override
  String get done => 'Xong';

  @override
  String get delete => 'Xóa';

  @override
  String get cancel => 'Hủy';

  @override
  String get confirm => 'Đồng ý';

  @override
  String get noteHint => 'Ghi chú';

  @override
  String get amountMustBePositive => 'Số tiền phải lớn hơn 0';

  @override
  String get invalidExpression => 'Phép tính không hợp lệ';

  @override
  String get today => 'Hôm nay';

  @override
  String get account => 'Tài khoản';

  @override
  String get deleted => 'Đã xóa';

  @override
  String get undo => 'Hoàn tác';

  @override
  String get search => 'Tìm';

  @override
  String get searchHint => 'Ghi chú, danh mục hoặc số tiền';

  @override
  String get searchClose => 'Đóng tìm kiếm';

  @override
  String get searchAllTime => 'Tất cả thời gian';

  @override
  String get searchNoMatch => 'Không có khoản nào khớp';

  @override
  String searchTotal(int count, String total) {
    return '$count khoản · tổng $total';
  }

  @override
  String get filter => 'Lọc';

  @override
  String get filterAmountRange => 'Khoảng số tiền';

  @override
  String get filterFrom => 'Từ';

  @override
  String get filterTo => 'Đến';

  @override
  String get filterAmountInvalid => 'Nhập số tiền hợp lệ';

  @override
  String get filterAmountRangeError => '“Từ” không được lớn hơn “Đến”';

  @override
  String get filterCategories => 'Danh mục';

  @override
  String get filterDateRange => 'Khoảng ngày';

  @override
  String get filterAnyDate => 'Mọi ngày';

  @override
  String get filterRemoveDates => 'Bỏ khoảng ngày';

  @override
  String get filterClear => 'Xóa';

  @override
  String get filterClearAll => 'Xóa lọc';

  @override
  String filterRemove(String name) {
    return 'Bỏ lọc $name';
  }

  @override
  String filterChipFrom(String amount) {
    return 'Từ $amount';
  }

  @override
  String filterChipUpTo(String amount) {
    return 'Tới $amount';
  }

  @override
  String filterSummary(int count, String spent, String income) {
    return '$count khoản · chi $spent · thu $income';
  }

  @override
  String get keypadBackspace => 'Xóa lùi';

  @override
  String get keypadEquals => 'Bằng';

  @override
  String get repeat => 'Lặp lại';

  @override
  String get repeatNone => 'Không lặp';

  @override
  String get repeatDaily => 'Hằng ngày';

  @override
  String get repeatWeekly => 'Hằng tuần';

  @override
  String get repeatMonthly => 'Hằng tháng';

  @override
  String get repeatYearly => 'Hằng năm';

  @override
  String get repeatPickDays => 'Chọn thứ…';

  @override
  String get repeatPickDaysTitle => 'Lặp vào các thứ';

  @override
  String get weekdayMon => 'T2';

  @override
  String get weekdayTue => 'T3';

  @override
  String get weekdayWed => 'T4';

  @override
  String get weekdayThu => 'T5';

  @override
  String get weekdayFri => 'T6';

  @override
  String get weekdaySat => 'T7';

  @override
  String get weekdaySun => 'CN';

  @override
  String get repeatAllDaysHint => 'Chọn đủ 7 thứ = Hằng ngày';

  @override
  String repeatFirstOn(String date) {
    return 'Khoản đầu: $date';
  }

  @override
  String repeatCreatedFirstOn(String date) {
    return 'Đã tạo khoản định kỳ · khoản đầu $date';
  }

  @override
  String onboardingStep(int step, int total) {
    return 'Bước $step/$total';
  }

  @override
  String get onboardingSkip => 'Bỏ qua';

  @override
  String get onboardingContinue => 'Tiếp tục';

  @override
  String get onboardingLanguageTitle => 'Chọn ngôn ngữ';

  @override
  String get onboardingLanguageHint => 'Đổi lại được trong Cài đặt.';

  @override
  String get onboardingWelcomeTitle => 'Chào mừng đến Ví Gọn';

  @override
  String get onboardingBenefitFast => 'Ghi một khoản trong 3 chạm';

  @override
  String get onboardingBenefitFastSub => 'Chạm danh mục, gõ số tiền, xong.';

  @override
  String get onboardingBenefitClear => 'Biết tiền đi đâu';

  @override
  String get onboardingBenefitClearSub =>
      'Biểu đồ theo danh mục, ngân sách, nhiều loại tiền.';

  @override
  String get onboardingBenefitPrivate => 'Riêng tư';

  @override
  String get onboardingBenefitPrivateSub =>
      'Dùng offline. Không tài khoản, không quảng cáo, không theo dõi.';

  @override
  String get onboardingStart => 'Bắt đầu';

  @override
  String get onboardingCurrencyTitle => 'Tiền tệ chính';

  @override
  String get onboardingCurrencyHint =>
      'Tổng, biểu đồ và ngân sách tính theo tiền tệ này. Tài khoản Tiền mặt cũng dùng tiền tệ này; sau này vẫn thêm được tài khoản tiền tệ khác.';

  @override
  String get onboardingOtherCurrency => 'Chọn tiền tệ khác…';

  @override
  String get onboardingReminderTitle => 'Nhắc ghi sổ mỗi ngày';

  @override
  String get onboardingReminderHint =>
      'Mỗi ngày một thông báo vào giờ bạn chọn. Không bao giờ hiện số tiền.';

  @override
  String get onboardingReminderOn => 'Bật nhắc';

  @override
  String get onboardingLater => 'Để sau';

  @override
  String get onboardingPinTitle => 'Khoá Ví Gọn bằng mã PIN?';

  @override
  String get onboardingPinHint =>
      'Hỏi mã PIN 4 số khi mở app. Chặn người tò mò; không mã hoá dữ liệu.';

  @override
  String get onboardingPinSet => 'Đặt mã PIN';

  @override
  String get stopRepeat => 'Dừng lặp lại';

  @override
  String get repeatStopped => 'Đã dừng';

  @override
  String get transfer => 'Chuyển tiền';

  @override
  String transferLabel(String from, String to) {
    return '$from → $to';
  }

  @override
  String get transferFrom => 'Từ';

  @override
  String get transferTo => 'Đến';

  @override
  String get transferSentAmount => 'Số gửi';

  @override
  String get transferReceivedAmount => 'Số nhận';

  @override
  String get sameAccountError => 'Chọn hai tài khoản khác nhau';

  @override
  String get categories => 'Danh mục';

  @override
  String get addCategory => 'Thêm danh mục';

  @override
  String get editCategory => 'Sửa danh mục';

  @override
  String get name => 'Tên';

  @override
  String get nameRequired => 'Nhập tên';

  @override
  String get icon => 'Biểu tượng';

  @override
  String get color => 'Màu';

  @override
  String get deleteCategory => 'Xóa danh mục';

  @override
  String get deleteCategoryConfirm => 'Xóa danh mục này?';

  @override
  String moveEntriesTo(int count) {
    return '$count khoản sẽ được chuyển sang:';
  }

  @override
  String get reorderHint => 'Kéo để sắp xếp';

  @override
  String get accounts => 'Tài khoản';

  @override
  String get addAccount => 'Thêm tài khoản';

  @override
  String get editAccount => 'Sửa tài khoản';

  @override
  String get archiveAccount => 'Ẩn tài khoản';

  @override
  String get deleteAccount => 'Xóa tài khoản';

  @override
  String deleteAccountConfirm(String name) {
    return 'Xóa tài khoản \"$name\"?';
  }

  @override
  String get accountInUseHint => 'Tài khoản đã có khoản, chỉ ẩn được';

  @override
  String get accountLastOneHint => 'Phải còn ít nhất một tài khoản';

  @override
  String get archivedAccounts => 'Tài khoản đã ẩn';

  @override
  String get unarchiveAccount => 'Hiện lại';

  @override
  String get initialBalance => 'Số dư ban đầu';

  @override
  String get currency => 'Tiền tệ';

  @override
  String get currencyNote =>
      'Đổi tiền tệ không sửa số bạn đã nhập; chỉ đổi cách cộng tổng và dòng \"≈\" theo tỷ giá hiện tại (tải qua mạng tối đa 1 lần/ngày, hoặc bạn tự nhập ở màn Tỷ giá).';

  @override
  String get currencyLockedPayments =>
      'Tiền tệ đã khóa vì khoản nợ này đã có lần trả.';

  @override
  String get currencySearchHint => 'Tìm theo mã hoặc tên';

  @override
  String get currencyNoMatch => 'Không có tiền tệ nào khớp';

  @override
  String get csvColDate => 'Ngày';

  @override
  String get csvColType => 'Loại';

  @override
  String get csvColAmount => 'Số tiền';

  @override
  String get csvColCurrency => 'Tiền tệ';

  @override
  String get csvColCategory => 'Danh mục';

  @override
  String get csvColAccount => 'Tài khoản';

  @override
  String get csvColToAccount => 'Đến tài khoản';

  @override
  String get csvColNote => 'Ghi chú';

  @override
  String get csvTypeExpense => 'Chi';

  @override
  String get csvTypeIncome => 'Thu';

  @override
  String get csvTypeTransfer => 'Chuyển tiền';

  @override
  String get weekStart => 'Ngày đầu tuần';

  @override
  String get monday => 'Thứ Hai';

  @override
  String get sunday => 'Chủ Nhật';

  @override
  String get monthStartDay => 'Tháng bắt đầu từ ngày';

  @override
  String get budget => 'Ngân sách tháng';

  @override
  String get budgetNotSet => 'Chưa đặt';

  @override
  String budgetProgress(String spent, String limit) {
    return 'Đã chi $spent / $limit';
  }

  @override
  String budgetOver(String amount) {
    return 'Vượt $amount';
  }

  @override
  String get budgetRemove => 'Bỏ ngân sách';

  @override
  String get categoryBudget => 'Ngân sách tháng của danh mục';

  @override
  String get categoryBudgetHint => 'Để trống nếu không đặt';

  @override
  String get recurring => 'Khoản định kỳ';

  @override
  String get noRecurring => 'Chưa có khoản định kỳ. Bật Lặp lại khi ghi khoản.';

  @override
  String get dataSection => 'Dữ liệu';

  @override
  String get backup => 'Xuất bản sao lưu';

  @override
  String get restore => 'Khôi phục từ bản sao lưu';

  @override
  String get exportCsv => 'Xuất CSV';

  @override
  String get exportExcel => 'Xuất Excel';

  @override
  String get exportPdf => 'Xuất PDF';

  @override
  String get exportExcelNote => 'Khoản, theo danh mục, khoản nợ (.xlsx)';

  @override
  String get exportPdfNote => 'Báo cáo thu chi khổ A4';

  @override
  String get exportRangeTitle => 'Phạm vi xuất';

  @override
  String get exportRangeCurrent => 'Kỳ đang xem';

  @override
  String get exportIncludesExcel =>
      'Tệp Excel ba trang tính: Khoản, Theo danh mục và Khoản nợ.';

  @override
  String get exportIncludesPdf =>
      'Báo cáo A4 có tổng thu, tổng chi, bảng theo danh mục và danh sách khoản.';

  @override
  String get exportAction => 'Xuất';

  @override
  String get exportPreparing => 'Đang chuẩn bị tệp…';

  @override
  String get exportEmpty => 'Không có khoản nào trong phạm vi này';

  @override
  String get exportFailed => 'Không tạo được file';

  @override
  String get xlsxSheetRecords => 'Khoản';

  @override
  String get xlsxSheetByCategory => 'Theo danh mục';

  @override
  String get xlsxSheetDebts => 'Khoản nợ';

  @override
  String get xlsxColDate => 'Ngày';

  @override
  String get xlsxColType => 'Loại';

  @override
  String get xlsxColAmount => 'Số tiền';

  @override
  String get xlsxColCurrency => 'Tiền tệ';

  @override
  String get xlsxColCategory => 'Danh mục';

  @override
  String get xlsxColAccount => 'Tài khoản';

  @override
  String get xlsxColToAccount => 'Đến tài khoản';

  @override
  String get xlsxColNote => 'Ghi chú';

  @override
  String get xlsxTypeExpense => 'Chi';

  @override
  String get xlsxTypeIncome => 'Thu';

  @override
  String get xlsxColTotal => 'Tổng';

  @override
  String get xlsxColShare => 'Tỉ lệ';

  @override
  String get xlsxColPerson => 'Người';

  @override
  String get xlsxColDirection => 'Chiều';

  @override
  String get xlsxColPaid => 'Đã trả';

  @override
  String get xlsxColRemaining => 'Còn lại';

  @override
  String get xlsxColDue => 'Hạn';

  @override
  String get xlsxColStatus => 'Trạng thái';

  @override
  String get xlsxStatusOpen => 'Đang nợ';

  @override
  String pdfTitle(String period) {
    return 'Báo cáo thu chi — $period';
  }

  @override
  String get pdfDifference => 'Chênh lệch';

  @override
  String get pdfNoRecords => 'Không có khoản';

  @override
  String pdfPage(int page, int pages) {
    return 'Trang $page/$pages';
  }

  @override
  String get backupNote =>
      'Có thể đặt mật khẩu cho file. Không đặt thì file không được mã hóa.';

  @override
  String get backupSetPassword => 'Đặt mật khẩu cho file';

  @override
  String get backupPassword => 'Mật khẩu';

  @override
  String get backupPasswordConfirm => 'Nhập lại mật khẩu';

  @override
  String get backupPasswordWarning =>
      'Quên mật khẩu thì không mở được file này.';

  @override
  String get backupPasswordTooShort => 'Mật khẩu tối thiểu 6 ký tự';

  @override
  String get backupPasswordMismatch => 'Hai mật khẩu không khớp';

  @override
  String get backupExportAction => 'Xuất';

  @override
  String get backupEnterPasswordTitle => 'File có mật khẩu';

  @override
  String get backupEnterPasswordBody =>
      'Nhập mật khẩu đã đặt khi xuất file này.';

  @override
  String get backupOpen => 'Mở';

  @override
  String get backupWrongPassword => 'Sai mật khẩu hoặc file bị hỏng';

  @override
  String get backupWorking => 'Đang xử lý';

  @override
  String get backupReminder =>
      'Dữ liệu chỉ nằm trên máy này. Nên xuất bản sao lưu thường xuyên.';

  @override
  String get autoBackup => 'Sao lưu tự động';

  @override
  String get autoBackupNote =>
      'Ví Gọn chỉ ghi file vào thư mục bạn chọn. Việc tải lên Google Drive hay Dropbox do app đó thực hiện.';

  @override
  String autoBackupFolder(String name) {
    return 'Thư mục: $name';
  }

  @override
  String get autoBackupFolderUnknown => 'Thư mục đã chọn';

  @override
  String autoBackupLast(String time) {
    return 'Lần cuối: $time';
  }

  @override
  String autoBackupLastUnchanged(String time, String checked) {
    return 'Lần cuối: $time. Đã kiểm $checked: dữ liệu không đổi, giữ bản cũ';
  }

  @override
  String get autoBackupNever => 'Chưa sao lưu lần nào';

  @override
  String get autoBackupErrorFolder =>
      'Không ghi được vào thư mục. Chọn lại thư mục';

  @override
  String get autoBackupErrorOther =>
      'Sao lưu không thành công. Thử lại bằng Sao lưu ngay';

  @override
  String autoBackupFailedAt(String time, String error) {
    return 'Lần thử $time: $error';
  }

  @override
  String get autoBackupBusy => 'Đang sao lưu, thử lại sau giây lát';

  @override
  String get autoBackupNow => 'Sao lưu ngay';

  @override
  String get autoBackupChooseFolder => 'Chọn lại thư mục';

  @override
  String get autoBackupDone => 'Đã sao lưu';

  @override
  String get autoBackupOffDone =>
      'Đã tắt sao lưu tự động. File đã ghi vẫn còn trong thư mục.';

  @override
  String get autoBackupPickFailed => 'Không mở được bộ chọn thư mục';

  @override
  String get autoBackupPasswordTitle => 'Mật khẩu sao lưu tự động';

  @override
  String get autoBackupPasswordWarning =>
      'Quên mật khẩu thì không mở được các file sao lưu; bạn cần nhớ nó khi khôi phục trên máy khác.';

  @override
  String get autoBackupTurnOn => 'Bật';

  @override
  String get restoreConfirm =>
      'Dữ liệu hiện tại sẽ bị thay thế bằng bản sao lưu. Tiếp tục?';

  @override
  String get restoreDone => 'Đã khôi phục dữ liệu';

  @override
  String get restoreFailed =>
      'File không hợp lệ hoặc bị hỏng. Dữ liệu hiện tại không thay đổi.';

  @override
  String get deleteAll => 'Xóa toàn bộ dữ liệu';

  @override
  String get deleteAllConfirm =>
      'Xóa mọi khoản ghi, danh mục, tài khoản và cài đặt trên máy này?';

  @override
  String get deleteAllConfirm2 => 'Không hoàn tác được. Xóa hết?';

  @override
  String get deleteAllDone => 'Đã xóa toàn bộ dữ liệu';

  @override
  String get security => 'Bảo mật';

  @override
  String get pinLock => 'Khóa bằng mã PIN';

  @override
  String get enterPin => 'Nhập mã PIN';

  @override
  String get newPin => 'Đặt mã PIN 4 số';

  @override
  String get confirmPin => 'Nhập lại mã PIN';

  @override
  String get pinMismatch => 'Hai lần nhập không khớp';

  @override
  String get wrongPin => 'Sai mã PIN';

  @override
  String get pinWarning =>
      'Nếu quên mã, cách duy nhất để dùng lại là xóa toàn bộ dữ liệu trong app.';

  @override
  String get forgotPin => 'Quên mã';

  @override
  String get forgotPinBody =>
      'Ví Gọn không có máy chủ nên không lấy lại được mã PIN. Bạn có thể xóa toàn bộ dữ liệu trong app để dùng lại.';

  @override
  String digit(String digit) {
    return 'Số $digit';
  }

  @override
  String pinProgress(int count) {
    return 'Đã nhập $count trên 4 số';
  }

  @override
  String get secureWindow => 'Che nội dung khi chuyển app';

  @override
  String get secureWindowNote =>
      'Chặn chụp màn hình và ẩn nội dung trong danh sách app gần đây';

  @override
  String get widgetShowAmounts => 'Hiện số tiền trên widget';

  @override
  String get widgetShowAmountsNote =>
      'Ai cầm máy cũng nhìn thấy số này trên màn hình chờ. Khi đang bật khóa PIN, widget luôn ẩn số.';

  @override
  String widgetSpentThisMonth(String spent) {
    return 'Tháng này đã chi $spent';
  }

  @override
  String widgetSpentOfBudget(String spent, String budget) {
    return 'Tháng này đã chi $spent / $budget';
  }

  @override
  String get widgetLockedByPin => 'Đã khóa bằng PIN';

  @override
  String get about => 'Giới thiệu';

  @override
  String get versionLabel => 'Phiên bản';

  @override
  String get aboutBody =>
      'Dữ liệu chỉ lưu trên máy này. Ví Gọn không gửi dữ liệu đi đâu.';

  @override
  String get privacyPolicy => 'Chính sách quyền riêng tư';

  @override
  String get terms => 'Điều khoản sử dụng';

  @override
  String get reportSecurity => 'Báo lỗi bảo mật';

  @override
  String get licenses => 'Giấy phép mã nguồn mở';

  @override
  String get rateApp => 'Đánh giá Ví Gọn';

  @override
  String get feedback => 'Gửi góp ý';

  @override
  String feedbackSubject(String version) {
    return 'Góp ý Ví Gọn $version';
  }

  @override
  String contactEmail(String email) {
    return 'Email liên hệ: $email';
  }

  @override
  String get securityEmailSubject => 'Báo lỗi bảo mật Ví Gọn';

  @override
  String linkOpenFailed(String target) {
    return 'Không mở được. Bạn có thể tự gửi email tới $target';
  }

  @override
  String iconNumber(int n) {
    return 'Biểu tượng $n';
  }

  @override
  String get viewBy => 'Xem theo';

  @override
  String get apply => 'Áp dụng';

  @override
  String get deleteAllTitle => 'Xóa toàn bộ dữ liệu?';

  @override
  String get cannotUndo => 'Không hoàn tác được';

  @override
  String get previousMonth => 'Tháng trước';

  @override
  String get nextMonth => 'Tháng sau';

  @override
  String get rangeHint => 'Chọn ngày đầu rồi ngày cuối';

  @override
  String get amountLabel => 'Số tiền';

  @override
  String get initialBalanceHelper => 'Để trống = 0. Cho phép số âm.';

  @override
  String get recurringEditNote => 'Áp dụng cho các lần sinh sau.';

  @override
  String get deleteCategoryEmptyBody => 'Danh mục này chưa có khoản nào.';

  @override
  String get showPassword => 'Hiện mật khẩu';

  @override
  String get hidePassword => 'Ẩn mật khẩu';

  @override
  String get searchClear => 'Xóa nội dung tìm';

  @override
  String get showMore => 'Xem thêm';

  @override
  String get showLess => 'Thu gọn';

  @override
  String get csvFormatEn =>
      'Định dạng tiếng Anh: dấu phẩy ngăn cột, dấu chấm thập phân';

  @override
  String get csvFormatVi =>
      'Định dạng tiếng Việt: dấu chấm phẩy ngăn cột, dấu phẩy thập phân';

  @override
  String categoryLimitThisMonth(String status) {
    return 'Tháng này: $status';
  }

  @override
  String get currencyCurrent => 'Tiền tệ đang dùng';

  @override
  String get primaryCurrency => 'Tiền tệ chính';

  @override
  String primaryCurrencyChanged(String currency) {
    return 'Tiền tệ chính giờ là $currency. Số tiền bạn đã nhập vẫn giữ nguyên.';
  }

  @override
  String get primaryCurrencyNote =>
      'Mọi số được hiển thị và cộng theo tiền tệ này. Khoản ghi bằng tiền tệ khác giữ nguyên số gốc, hiện ở dòng dưới.';

  @override
  String get exchangeRates => 'Tỷ giá';

  @override
  String get ratesOffline =>
      'Đang ngoại tuyến. Ví Gọn dùng tỷ giá đã lưu gần nhất.';

  @override
  String get ratesFallback =>
      'Đang dùng bảng tỷ giá có sẵn cho tới lần cập nhật đầu.';

  @override
  String get ratesUpdateNow => 'Cập nhật ngay';

  @override
  String get ratesUpdated => 'Đã cập nhật tỷ giá';

  @override
  String get ratesUpdateFailed =>
      'Không cập nhật được. Ví Gọn dùng tỷ giá đã lưu.';

  @override
  String get ratesSource => 'Tỷ giá từ Exchange Rate API';

  @override
  String get ratesUseAuto => 'Dùng tỷ giá tự động';

  @override
  String get ratesUseOwn => 'Dùng tỷ giá của tôi';

  @override
  String get ratesNoPairs => 'Chưa có cặp tiền tệ nào cần tỷ giá.';

  @override
  String ratesPreviewBalance(String account, String amount, String converted) {
    return '$account: $amount ≈ $converted';
  }

  @override
  String ratesSummaryAuto(String ago) {
    return 'Tự động · $ago';
  }

  @override
  String get ratesSummaryBuiltIn => 'Có sẵn';

  @override
  String get ratesSummaryManual => 'Bạn đặt tay';

  @override
  String ratesIntro(String currency) {
    return 'Số dư và tổng quy về $currency. Tỷ giá tự cập nhật mỗi ngày khi có mạng; bạn có thể tự đặt để ghi đè.';
  }

  @override
  String ratesAuto(String ago) {
    return 'Tự động · cập nhật $ago';
  }

  @override
  String ratesAutoOffline(String ago) {
    return 'Ngoại tuyến · tỷ giá từ $ago';
  }

  @override
  String get ratesBuiltIn => 'Tự động · tỷ giá ước tính có sẵn';

  @override
  String get ratesManual => 'Bạn đặt tay';

  @override
  String ratesPairLabel(String from, String rate, String to) {
    return '1 $from bằng $rate $to';
  }

  @override
  String get ratesAgoToday => 'hôm nay';

  @override
  String get ratesAgoYesterday => 'hôm qua';

  @override
  String ratesAgoDays(int count) {
    return '$count ngày trước';
  }

  @override
  String get ratesOfflineTitle => 'Bạn đang ngoại tuyến';

  @override
  String get ratesOfflineBody =>
      'Đang dùng tỷ giá gần nhất. Sẽ cập nhật khi có mạng trở lại.';

  @override
  String get ratesListedNote =>
      'Chỉ hiện các loại tiền mà dữ liệu của bạn đang dùng.';

  @override
  String ratesNoneUsed(String currency) {
    return 'Mọi số liệu của bạn đều tính bằng $currency, không cần quy đổi.';
  }

  @override
  String ratesLinkFailed(String url) {
    return 'Không mở được. Bạn có thể tự mở $url.';
  }

  @override
  String get rateUseAuto => 'Dùng tỷ giá tự động';

  @override
  String rateAutoValue(String rate, String ago) {
    return '$rate · cập nhật $ago';
  }

  @override
  String rateAutoValueBuiltIn(String rate) {
    return '$rate · tỷ giá ước tính có sẵn';
  }

  @override
  String rateYours(String from) {
    return 'Tỷ giá của bạn · 1 $from =';
  }

  @override
  String get rateSave => 'Lưu tỷ giá này';

  @override
  String get rateRestoreAuto => 'Khôi phục tự động';

  @override
  String rateMissing(String from, String to) {
    return 'Không có tỷ giá từ $from sang $to. Số tiền này không vào tổng.';
  }

  @override
  String recurringRestartHint(String date) {
    return 'Bắt đầu lại từ lần đến hạn kế tiếp: $date';
  }

  @override
  String get restoreSwitchesNote =>
      'Nhắc ghi sổ hằng ngày và số tiền trên widget sẽ tắt. Bạn có thể bật lại trong Cài đặt.';

  @override
  String get restoreSwitchesNoteIos =>
      'Nhắc ghi sổ hằng ngày sẽ tắt. Bạn có thể bật lại trong Cài đặt.';

  @override
  String archivedAccountsCount(int count) {
    return 'Tài khoản đã ẩn ($count)';
  }

  @override
  String get autoBackupNoteIos =>
      'Ví Gọn chỉ ghi file vào thư mục bạn chọn trong app Tệp, ví dụ trong iCloud Drive.';

  @override
  String get autoBackupRunsOnOpenIos =>
      'iPhone không cho app tự chạy khi đã đóng. Đúng giờ bạn chọn, Ví Gọn gửi thông báo; chạm vào hoặc mở app để sao lưu. Lỡ giờ thì sao lưu bù khi bạn mở app, mỗi ngày tối đa một lần.';

  @override
  String get autoBackupLocalFolderWarningIos =>
      'Thư mục này có thể chỉ nằm trên iPhone. Nếu vậy, mất máy là mất luôn các file này. Để giữ an toàn, hãy chọn thư mục trong iCloud Drive hoặc Google Drive.';

  @override
  String get autoBackupTime => 'Giờ sao lưu';

  @override
  String autoBackupNextToday(String time) {
    return 'Lần tới: hôm nay, $time';
  }

  @override
  String autoBackupNextTomorrow(String time) {
    return 'Lần tới: ngày mai, $time';
  }

  @override
  String get autoBackupNextSoon => 'Lần tới: khi bạn rời Ví Gọn';

  @override
  String get autoBackupNextSoonIos => 'Lần tới: khi bạn mở lại Ví Gọn';

  @override
  String get autoBackupNotificationBody =>
      'Đến giờ sao lưu Ví Gọn. Chạm để sao lưu.';

  @override
  String get autoBackupNotifyTitleIos => 'Báo khi đến giờ sao lưu';

  @override
  String get autoBackupNotifyBodyIos =>
      'iPhone không cho Ví Gọn tự chạy khi đã đóng. Đúng giờ bạn chọn, Ví Gọn gửi một thông báo; chạm vào để sao lưu. Thông báo không chứa số liệu của bạn.';

  @override
  String get autoBackupNotifyDeniedIos =>
      'Không có thông báo giờ sao lưu. Ví Gọn vẫn sao lưu bù khi bạn mở app.';

  @override
  String get secureWindowNoteIos =>
      'Ẩn nội dung trong màn chuyển app. iPhone không cho app chặn chụp màn hình.';

  @override
  String get widgetPickerName => 'Ví Gọn';

  @override
  String get widgetPickerDescription => 'Thêm nhanh khoản chi hoặc thu';

  @override
  String get widgetExpenseButton => 'Chi';

  @override
  String get widgetIncomeButton => 'Thu';

  @override
  String get widgetStale => 'Mở app để cập nhật';

  @override
  String currencyConvertTitle(String currency) {
    return 'Quy đổi sang $currency?';
  }

  @override
  String get exchangeRateLoading => 'Đang tải tỉ giá…';

  @override
  String exchangeRatePair(String from, String rate, String to) {
    return '1 $from = $rate $to';
  }

  @override
  String exchangeRateDate(String date) {
    return 'Tỉ giá cập nhật ngày $date';
  }

  @override
  String get exchangeRateManualSource => 'Tỉ giá bạn tự nhập';

  @override
  String currencyConvertExample(String before, String after) {
    return 'Ví dụ: $before → $after';
  }

  @override
  String currencyConvertWarning(String currency) {
    return 'Mọi số tiền (khoản thu chi, chuyển tiền, khoản định kỳ, số dư ban đầu, hạn mức danh mục, ngân sách tháng) sẽ được quy đổi và làm tròn tới đơn vị nhỏ nhất của $currency. Không hoàn tác tự động được, đổi ngược lại có thể lệch một chút do làm tròn. Nên xuất bản sao lưu trước.';
  }

  @override
  String get currencyConvertAction => 'Quy đổi';

  @override
  String get exchangeRateUseOther => 'Dùng tỉ giá khác';

  @override
  String get exchangeRateErrorTitle => 'Không tải được tỉ giá';

  @override
  String get exchangeRateOfflineBody =>
      'Kiểm tra kết nối mạng rồi thử lại, hoặc tự nhập tỉ giá.';

  @override
  String get exchangeRateUnavailableBody =>
      'Dịch vụ tỉ giá đang không phản hồi. Hãy thử lại sau, hoặc tự nhập tỉ giá.';

  @override
  String exchangeRateMissingPairBody(String from, String to) {
    return 'Không có tỉ giá từ $from sang $to. Hãy tự nhập tỉ giá.';
  }

  @override
  String get exchangeRateManualTitle => 'Nhập tỉ giá';

  @override
  String exchangeRateFieldLabel(String from, String to) {
    return '1 $from = ? $to';
  }

  @override
  String get exchangeRateSwap => 'Đổi chiều tỉ giá';

  @override
  String exchangeRatePrefilled(String date) {
    return 'Đã điền tỉ giá gần nhất, ngày $date';
  }

  @override
  String get exchangeRateInvalid => 'Nhập tỉ giá lớn hơn 0';

  @override
  String get exchangeRateRetry => 'Thử lại';

  @override
  String get exchangeRateContinue => 'Tiếp tục';

  @override
  String currencyConverted(String currency) {
    return 'Đã quy đổi mọi số tiền sang $currency';
  }

  @override
  String get currencyConvertTooLargeTitle => 'Số tiền quá lớn';

  @override
  String get currencyConvertTooLargeBody =>
      'Với tỉ giá này, có số tiền sẽ vượt mức lớn nhất Ví Gọn lưu được. Chưa có gì thay đổi.';

  @override
  String get currencyConvertFailed =>
      'Không quy đổi được. Chưa có gì thay đổi.';

  @override
  String get currencyConvertOk => 'Đã hiểu';

  @override
  String get emailImportGroup => 'Nhập từ email';

  @override
  String get emailImport => 'Nhập từ email ngân hàng';

  @override
  String get emailImportNoMailbox => 'Chưa có hộp thư';

  @override
  String emailImportMailboxCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count hộp thư',
    );
    return '$_temp0';
  }

  @override
  String get emailIntroTitle => 'Ghi khoản chi từ email biên lai';

  @override
  String get emailIntroRead =>
      'Ví Gọn đọc email biên lai chuyển tiền của ngân hàng trong hộp thư bạn thêm, rồi đưa vào hàng đợi để bạn chọn danh mục.';

  @override
  String get emailIntroLocal =>
      'Chỉ trên máy này: nội dung email không được gửi đi đâu.';

  @override
  String get emailIntroReadOnly =>
      'Không sửa, không xoá, không đánh dấu đã đọc thư nào.';

  @override
  String get emailIntroAppPassword =>
      'Cần mật khẩu ứng dụng do nhà cung cấp email cấp, không phải mật khẩu đăng nhập chính.';

  @override
  String get emailIntroBanks => 'Hiện chỉ hỗ trợ MB Bank.';

  @override
  String get emailIntroIos =>
      'Trên iPhone, Ví Gọn chỉ kiểm thư khi bạn mở hoặc quay lại app.';

  @override
  String get emailAddMailbox => 'Thêm hộp thư';

  @override
  String get emailMailboxLimit =>
      'Đã đủ 3 hộp thư. Xoá một hộp thư để thêm hộp thư khác.';

  @override
  String get emailScheduleAndroid =>
      'Ví Gọn kiểm thư khi mở app và khoảng mỗi giờ khi app đóng. Kéo xuống để kiểm ngay.';

  @override
  String get emailScheduleIos =>
      'Trên iPhone, Ví Gọn chỉ kiểm thư khi bạn mở hoặc quay lại app. Kéo xuống để kiểm ngay.';

  @override
  String get emailConnected => 'Đã kết nối';

  @override
  String emailLastCheck(String time) {
    return 'Đã kết nối · Lần kiểm cuối: $time';
  }

  @override
  String emailErrorAt(String time, String error) {
    return 'Lần kiểm $time: $error';
  }

  @override
  String get emailErrorCredentials => 'Sai địa chỉ hoặc mật khẩu ứng dụng';

  @override
  String get emailErrorImapDisabled => 'Hộp thư chưa bật IMAP';

  @override
  String get emailErrorNetwork => 'Không có mạng';

  @override
  String get emailErrorSecure => 'Không kết nối an toàn được tới máy chủ email';

  @override
  String get emailErrorServer => 'Máy chủ email báo lỗi. Thử lại sau';

  @override
  String get emailPaused =>
      'Đã dừng kiểm thư hộp thư này. Nhập lại mật khẩu ứng dụng để tiếp tục.';

  @override
  String emailUnreadable(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count email MB không đọc được',
    );
    return '$_temp0';
  }

  @override
  String get emailReenterPassword => 'Nhập lại mật khẩu';

  @override
  String get emailRemoveMailbox => 'Xoá hộp thư';

  @override
  String get emailRemoveTitle => 'Xoá hộp thư?';

  @override
  String emailRemoveBody(String address) {
    return 'Ví Gọn sẽ thôi đọc email của $address và xoá mật khẩu ứng dụng khỏi máy. Các khoản đã ghi vẫn giữ nguyên.';
  }

  @override
  String get emailRemoved => 'Đã xoá hộp thư';

  @override
  String get emailProvider => 'Nhà cung cấp';

  @override
  String get emailStepsTitle => 'Tạo mật khẩu ứng dụng';

  @override
  String get emailStepsGmail1 =>
      'Bật Xác minh 2 bước cho tài khoản Google (bắt buộc để có mật khẩu ứng dụng).';

  @override
  String get emailStepsGmail2 =>
      'Mở trang Mật khẩu ứng dụng bằng nút dưới, đặt tên \"Ví Gọn\" rồi bấm Tạo.';

  @override
  String get emailStepsGmail3 =>
      'Chép mật khẩu 16 ký tự Google hiện ra vào ô Mật khẩu ứng dụng bên dưới.';

  @override
  String get emailStepsYahoo1 =>
      'Mở trang Bảo mật tài khoản Yahoo bằng nút dưới.';

  @override
  String get emailStepsYahoo2 =>
      'Chọn \"Tạo mật khẩu ứng dụng\", đặt tên \"Ví Gọn\" rồi bấm Tạo.';

  @override
  String get emailStepsYahoo3 =>
      'Chép mật khẩu Yahoo hiện ra vào ô Mật khẩu ứng dụng bên dưới.';

  @override
  String get emailStepsIcloud1 =>
      'Bật xác thực hai yếu tố cho Tài khoản Apple.';

  @override
  String get emailStepsIcloud2 =>
      'Mở trang Tài khoản Apple bằng nút dưới → Đăng nhập và bảo mật → Mật khẩu dành riêng cho ứng dụng, đặt tên \"Ví Gọn\".';

  @override
  String get emailStepsIcloud3 =>
      'Chép mật khẩu Apple hiện ra vào ô Mật khẩu ứng dụng bên dưới; địa chỉ là email iCloud của bạn.';

  @override
  String get emailOpenPasswordPage => 'Mở trang tạo mật khẩu ứng dụng';

  @override
  String get emailAddress => 'Địa chỉ email';

  @override
  String get emailAddressInvalid => 'Nhập đúng địa chỉ email';

  @override
  String get emailAppPassword => 'Mật khẩu ứng dụng';

  @override
  String get emailAppPasswordHelper =>
      'Không phải mật khẩu đăng nhập chính. Chỉ lưu trong bộ nhớ an toàn của máy.';

  @override
  String get emailAppPasswordEmpty => 'Nhập mật khẩu ứng dụng';

  @override
  String get emailConnect => 'Kết nối';

  @override
  String get emailDuplicate => 'Hộp thư này đã được thêm';

  @override
  String get emailSaveReenter => 'Lưu và kết nối lại';

  @override
  String get entryTime => 'Giờ';

  @override
  String get timeNotSet => 'Chưa đặt giờ';

  @override
  String get csvColTime => 'Giờ';

  @override
  String get csvColSource => 'Nguồn';

  @override
  String get csvSourceManual => 'Ghi tay';

  @override
  String get csvSourceEmailMb => 'Email MB';

  @override
  String get savings => 'Tiết kiệm';

  @override
  String get savingsEmpty =>
      'Chưa có mục tiêu tiết kiệm. Đặt một mục tiêu rồi góp tiền vào dần.';

  @override
  String get savingsAdd => 'Thêm mục tiêu';

  @override
  String get savingsEdit => 'Sửa mục tiêu';

  @override
  String get savingsTarget => 'Số tiền mục tiêu';

  @override
  String get savingsDue => 'Hạn (tuỳ chọn)';

  @override
  String get savingsNoDue => 'Không đặt hạn';

  @override
  String get savingsClearDue => 'Bỏ hạn';

  @override
  String get savingsAccount => 'Tài khoản';

  @override
  String get savingsNewAccount => 'Tạo tài khoản mới';

  @override
  String get savingsNewAccountNote =>
      'Tài khoản mới có tên giống mục tiêu, số dư ban đầu 0.';

  @override
  String get savingsAccountFixed =>
      'Tài khoản gắn không đổi được. Muốn gắn tài khoản khác, hãy xoá mục tiêu rồi tạo lại.';

  @override
  String get savingsAccountTaken => 'Tài khoản này đã gắn một mục tiêu khác';

  @override
  String savingsProgress(String have, String target) {
    return 'Đã có $have / $target';
  }

  @override
  String savingsMissing(String amount) {
    return 'Còn thiếu $amount';
  }

  @override
  String get savingsReached => 'Đã đạt';

  @override
  String savingsDaysLeft(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Còn $count ngày',
      zero: 'Hạn là hôm nay',
    );
    return '$_temp0';
  }

  @override
  String savingsOverdue(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Quá hạn $count ngày',
    );
    return '$_temp0';
  }

  @override
  String get savingsContribute => 'Góp tiền';

  @override
  String get savingsNeedOtherAccount =>
      'Cần có thêm một tài khoản khác để góp tiền';

  @override
  String get savingsDelete => 'Xoá mục tiêu';

  @override
  String get savingsDeleteTitle => 'Xoá mục tiêu?';

  @override
  String get savingsDeleteBody =>
      'Tài khoản và mọi khoản vẫn giữ nguyên. Chỉ mục tiêu bị xoá.';

  @override
  String get savingsDeleted => 'Đã xoá mục tiêu';

  @override
  String get debts => 'Khoản nợ';

  @override
  String get debtsEmpty =>
      'Chưa có khoản nợ nào. Ghi lại ai nợ bạn, hoặc bạn nợ ai, để khỏi quên.';

  @override
  String get debtsNote =>
      'Chỉ là sổ ghi nhớ: không tính vào thu, chi hay số dư tài khoản.';

  @override
  String get debtAdd => 'Thêm khoản nợ';

  @override
  String get debtEdit => 'Sửa khoản nợ';

  @override
  String get debtPerson => 'Người';

  @override
  String get debtDirection => 'Chiều';

  @override
  String get debtLent => 'Cho vay';

  @override
  String get debtBorrowed => 'Đi vay';

  @override
  String get debtGroupLent => 'Người khác nợ bạn';

  @override
  String get debtGroupBorrowed => 'Bạn nợ người khác';

  @override
  String debtGroupTotal(String amount) {
    return 'Còn lại $amount';
  }

  @override
  String debtDoneSection(int count) {
    return 'Đã xong ($count)';
  }

  @override
  String get debtDone => 'Đã xong';

  @override
  String get debtAmount => 'Số tiền';

  @override
  String get debtDate => 'Ngày';

  @override
  String get debtDue => 'Hạn (tuỳ chọn)';

  @override
  String debtDueOn(String date) {
    return 'Hạn $date';
  }

  @override
  String get debtClearDue => 'Bỏ hạn';

  @override
  String get debtOverdue => 'Quá hạn';

  @override
  String debtRemaining(String amount) {
    return 'Còn lại $amount';
  }

  @override
  String debtPaidOf(String paid, String total) {
    return 'Đã trả $paid / $total';
  }

  @override
  String get debtPayments => 'Các lần trả';

  @override
  String get debtNoPayments => 'Chưa có lần trả nào';

  @override
  String get debtAddPayment => 'Thêm lần trả';

  @override
  String get debtPaymentAmount => 'Số tiền trả';

  @override
  String get debtDeletePayment => 'Xoá lần trả';

  @override
  String debtOverpay(String remaining) {
    return 'Vượt số còn lại ($remaining)';
  }

  @override
  String debtAmountBelowPaid(String paid) {
    return 'Không được nhỏ hơn số đã trả ($paid)';
  }

  @override
  String get debtDelete => 'Xoá khoản nợ';

  @override
  String get debtDeleteTitle => 'Xoá khoản nợ?';

  @override
  String get debtDeleteBody =>
      'Các lần trả cũng bị xoá. Không ảnh hưởng khoản nào khác hay số dư tài khoản.';

  @override
  String get debtDeleted => 'Đã xoá khoản nợ';

  @override
  String get debtRemainingLabel => 'Còn lại';

  @override
  String get importQueue => 'Hàng đợi';

  @override
  String get importQueueRow => 'Khoản chờ chọn danh mục';

  @override
  String importQueueRowCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count khoản chờ',
    );
    return '$_temp0';
  }

  @override
  String importQueueCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count khoản chờ chọn danh mục',
    );
    return '$_temp0';
  }

  @override
  String get importQueueNone => 'Không có khoản nào đang chờ';

  @override
  String get queueEmpty =>
      'Không có khoản nào đang chờ. Khi có email biên lai mới, khoản sẽ hiện ở đây để bạn chọn danh mục.';

  @override
  String get queuePayeeUnknown => 'Không rõ người nhận';

  @override
  String queueFromAccount(String account) {
    return 'Từ $account';
  }

  @override
  String queueCurrencyNote(String emailCurrency, String appCurrency) {
    return 'Email bằng $emailCurrency, tài khoản đang dùng $appCurrency. Bạn nhập số tiền ở bước tiếp theo.';
  }

  @override
  String get queueSuggested => 'Gợi ý';

  @override
  String queueSaveTo(String category) {
    return 'Lưu vào $category';
  }

  @override
  String queueMoveTo(String account) {
    return 'Chuyển sang $account';
  }

  @override
  String get queueEditFirst => 'Sửa trước khi lưu';

  @override
  String get queueMoveToMine => 'Chuyển sang tài khoản của tôi';

  @override
  String get queueMoveToTitle => 'Chuyển sang tài khoản';

  @override
  String get queueNoOtherAccount => 'Chưa có tài khoản nào khác để chọn';

  @override
  String get queueSkip => 'Bỏ qua';

  @override
  String get queueSkipTitle => 'Bỏ qua khoản này?';

  @override
  String get queueSkipBody =>
      'Khoản rời hàng đợi và sẽ không được nhập lại từ email này.';

  @override
  String queueSaved(String category) {
    return 'Đã lưu vào $category';
  }

  @override
  String queueMoved(String account) {
    return 'Đã chuyển sang $account';
  }

  @override
  String get queueSkipped => 'Đã bỏ qua';

  @override
  String get queueSuggestions => 'Gợi ý đã nhớ';

  @override
  String get queueSuggestionsEmpty =>
      'Chưa có gợi ý nào. Ví Gọn nhớ danh mục bạn chọn cho từng người nhận để gợi ý lần sau.';

  @override
  String queueSuggestionMove(String account) {
    return 'Chuyển sang $account';
  }

  @override
  String get queueSuggestionDelete => 'Xoá gợi ý';

  @override
  String get queueSuggestionDeleted => 'Đã xoá gợi ý';

  @override
  String queueAutoAccount(String account) {
    return 'Đã tạo tài khoản $account';
  }

  @override
  String get queueAttach => 'Gắn vào tài khoản có sẵn';

  @override
  String get queueAttachTitle => 'Gắn vào tài khoản';

  @override
  String get queueDismiss => 'Đóng';

  @override
  String queueMatched(String time) {
    return 'Đã ghép với email MB $time';
  }

  @override
  String get savingsGoalName => 'Tên mục tiêu';

  @override
  String get savingsAccountHelper =>
      'Một tài khoản mới chỉ cho mục tiêu này. Chuyển tiền vào bằng Góp tiền.';

  @override
  String get savingsAccountEditHelper => 'Tài khoản giữ tiền của mục tiêu này.';

  @override
  String get savingsAlreadySaved => 'Đã có sẵn (tuỳ chọn)';

  @override
  String get savingsAlreadySavedHelper =>
      'Số tiền bạn đã để riêng. Đây là số dư ban đầu của tài khoản.';

  @override
  String get savingsCurrencyLocked =>
      'Không đổi được tiền tệ khi tài khoản đã có khoản.';

  @override
  String get savingsInProgress => 'Đang tiết kiệm';

  @override
  String savingsDoneSection(int count) {
    return 'Đã xong ($count)';
  }

  @override
  String get savingsDone => 'Đã xong';

  @override
  String savingsDoneOn(String date) {
    return 'Đã xong · $date';
  }

  @override
  String get savingsWithdraw => 'Rút tiền';

  @override
  String get savingsHistory => 'Lịch sử';

  @override
  String get savingsHistoryEmpty => 'Chưa có khoản nào';

  @override
  String savingsHistoryAdded(String account) {
    return 'Góp từ $account';
  }

  @override
  String savingsHistoryWithdrew(String account) {
    return 'Rút về $account';
  }

  @override
  String savingsHistorySpent(String what) {
    return 'Chi: $what';
  }

  @override
  String savingsHistoryIncome(String what) {
    return 'Thu: $what';
  }

  @override
  String get savingsHistoryStart => 'Đã có sẵn';

  @override
  String savingsBalance(String amount) {
    return 'Số dư $amount';
  }

  @override
  String get savingsFromAccount => 'Từ tài khoản';

  @override
  String get savingsToAccount => 'Về tài khoản';

  @override
  String get savingsMoveAmount => 'Số tiền';

  @override
  String get savingsFillToTarget => 'Điền đủ';

  @override
  String get savingsWithdrawAll => 'Rút hết';

  @override
  String savingsOverTarget(String amount) {
    return 'Chỉ cần góp thêm $amount';
  }

  @override
  String savingsOverBalance(String amount) {
    return 'Tài khoản chỉ còn $amount';
  }

  @override
  String savingsSendsApprox(String amount, String account) {
    return 'Chuyển $amount từ $account theo tỷ giá hôm nay';
  }

  @override
  String get savingsNothingToWithdraw => 'Tài khoản đang trống';

  @override
  String get savingsReachedTitle => 'Tiết kiệm thành công';

  @override
  String savingsReachedBody(String amount, String goal) {
    return 'Bạn đã đủ $amount cho $goal.';
  }

  @override
  String get savingsReachedOk => 'Tuyệt';

  @override
  String get savingsReopen => 'Mở lại';

  @override
  String get savingsReopened => 'Đã mở lại mục tiêu';

  @override
  String savingsAdded(String amount) {
    return 'Đã góp $amount';
  }

  @override
  String savingsWithdrawn(String amount) {
    return 'Đã rút $amount';
  }

  @override
  String savingsWalletOf(String goal) {
    return 'Tiết kiệm · $goal';
  }

  @override
  String currencyChipTooltip(String currency) {
    return 'Tiền tệ: $currency';
  }

  @override
  String get deadlineReminders => 'Nhắc trước hạn';

  @override
  String deadlineRemindersValue(int days, String time) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'Trước $days ngày',
    );
    return '$_temp0 · $time';
  }

  @override
  String get deadlineRemindersOff => 'Tắt';

  @override
  String get deadlineRemindersSwitch => 'Nhắc tôi trước hạn';

  @override
  String get deadlineRemindersNote =>
      'Cho mục tiêu tiết kiệm và khoản nợ có hạn. Thông báo có số tiền còn lại.';

  @override
  String get deadlineDaysBefore => 'Nhắc trước';

  @override
  String deadlineDaysValue(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days ngày',
    );
    return '$_temp0';
  }

  @override
  String get deadlineTime => 'Giờ nhắc';

  @override
  String get deadlineExplainTitle => 'Bật nhắc trước hạn?';

  @override
  String get deadlineExplainBody =>
      'Ví Gọn sẽ báo trước hạn và đúng ngày hạn của mục tiêu tiết kiệm và khoản nợ. Thông báo có số tiền còn lại.';

  @override
  String get deadlineChannelName => 'Nhắc trước hạn';

  @override
  String get deadlineChannelDescription =>
      'Nhắc trước hạn mục tiêu tiết kiệm và khoản nợ';

  @override
  String deadlineWhenDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'đến hạn sau $count ngày',
    );
    return '$_temp0';
  }

  @override
  String get deadlineWhenToday => 'đến hạn hôm nay';

  @override
  String deadlineDebtLent(String person, String amount, String when) {
    return 'Khoản nợ với $person: còn $amount, $when';
  }

  @override
  String deadlineDebtBorrowed(String person, String amount, String when) {
    return 'Bạn nợ $person: còn $amount, $when';
  }

  @override
  String deadlineGoal(String goal, String amount, String when) {
    return 'Mục tiêu $goal: còn thiếu $amount, $when';
  }

  @override
  String get debtPayRest => 'Trả hết';

  @override
  String mainFirstNote(String currency) {
    return 'theo $currency';
  }

  @override
  String get homeEmptyTitle => 'Ghi khoản chi đầu tiên';

  @override
  String get homeEmptyBody => 'Chạm danh mục hoặc −';

  @override
  String fromEmailRef(String ref) {
    return 'Từ email MB · mã tham chiếu đuôi $ref';
  }

  @override
  String get setTime => 'Đặt giờ';

  @override
  String get mbLinked => 'Từ email MB';

  @override
  String get savingsWallet => 'Ví tiết kiệm';

  @override
  String totalInMain(String currency) {
    return 'Tổng theo $currency';
  }

  @override
  String get accountCurrencyLabel => 'Tiền tệ của tài khoản';

  @override
  String get youReceive => 'Bên nhận được';

  @override
  String get queueNotCountedNote =>
      'Chưa được tính: khoản ở đây chỉ vào tổng, biểu đồ và ngân sách sau khi bạn lưu.';

  @override
  String get widgetSpentLabel => 'Tháng này đã chi';

  @override
  String widgetOfBudget(String budget, String percent) {
    return 'trên $budget · $percent';
  }

  @override
  String get almostOver => 'Sắp vượt';

  @override
  String get walletBalanceNote =>
      'Tiền trong ví này tính vào tổng số dư, không tính là thu hay chi.';

  @override
  String remindDays(int n) {
    return 'Trước $n ngày';
  }

  @override
  String remindNext(String date) {
    return 'Nhắc ngày $date';
  }

  @override
  String goalsN(int n) {
    return '$n mục tiêu';
  }

  @override
  String owedToYouShort(String amount) {
    return 'Người khác nợ bạn $amount';
  }

  @override
  String rateLine(String from, String rate, String to) {
    return '1 $from = $rate $to · tự động';
  }

  @override
  String get exactAlarmRow => 'Báo đúng giờ';

  @override
  String get exactAlarmOn => 'Đã bật';

  @override
  String get exactAlarmOff => 'Chưa bật · có thể trễ vài phút';

  @override
  String get exactAlarmExplainTitle => 'Báo đúng giờ?';

  @override
  String get exactAlarmExplainBody =>
      'Để thông báo đến đúng phút, Android cần bạn cho phép \"Chuông báo và lời nhắc\" (Báo thức và lời nhắc) cho Ví Gọn. Không bật thì thông báo vẫn đến nhưng có thể trễ vài phút.';

  @override
  String get exactAlarmOpen => 'Mở cài đặt';

  @override
  String budgetAlertUsed(int percent) {
    return 'Đã dùng $percent%';
  }

  @override
  String get budgetAlertThreshold => 'Ngưỡng \"Sắp vượt\"';

  @override
  String budgetAlertPercent(int percent) {
    return '$percent%';
  }

  @override
  String get budgetAlertSwitch => 'Thông báo ngân sách';

  @override
  String get budgetAlertSwitchNote =>
      'Một lần khi chạm ngưỡng, một lần khi đủ 100%; chỉ có phần trăm';

  @override
  String get budgetAlertExplainTitle => 'Bật thông báo ngân sách?';

  @override
  String get budgetAlertExplainBody =>
      'Ví Gọn sẽ gửi một thông báo khi chi tiêu tháng này chạm ngưỡng bạn chọn và một thông báo khi đạt 100% hạn mức, mỗi ngân sách tối đa một lần mỗi tháng. Thông báo chỉ có phần trăm, không bao giờ có số tiền.';

  @override
  String get budgetAlertChannelName => 'Cảnh báo ngân sách';

  @override
  String get budgetAlertChannelDescription =>
      'Thông báo khi chi tiêu sắp hoặc đã vượt ngân sách';

  @override
  String budgetAlertMonthly(String month, int percent) {
    return 'Ngân sách tháng $month: đã dùng $percent%';
  }

  @override
  String budgetAlertCategory(String category, int percent, String month) {
    return '$category: đã dùng $percent% hạn mức tháng $month';
  }

  @override
  String get biometricFingerprint => 'Mở khoá bằng vân tay';

  @override
  String get biometricFaceId => 'Mở khoá bằng Face ID';

  @override
  String get biometricTouchId => 'Mở khoá bằng Touch ID';

  @override
  String get biometricNote =>
      'Mã PIN vẫn luôn dùng được. Ví Gọn không lưu dữ liệu sinh trắc.';

  @override
  String get biometricUnavailable =>
      'Máy không có hoặc chưa đăng ký sinh trắc học mạnh';

  @override
  String get biometricReason => 'Mở khoá Ví Gọn';

  @override
  String get biometricEnableReason =>
      'Xác nhận để bật mở khoá bằng sinh trắc học';

  @override
  String get biometricEnableFailed =>
      'Chưa xác thực được, mở khoá bằng sinh trắc vẫn tắt';

  @override
  String get biometricUnlockButton => 'Mở bằng sinh trắc học';

  @override
  String get biometricCancel => 'Dùng mã PIN';

  @override
  String get exportScopeTitle => 'Xuất khoảng nào';

  @override
  String get exportScopeCurrent => 'Kỳ đang xem';

  @override
  String get exportScopeCustom => 'Khoảng tùy chọn…';

  @override
  String get exportWorking => 'Đang tạo file…';

  @override
  String get exportSheetEntries => 'Khoản';

  @override
  String get exportSheetCategories => 'Theo danh mục';

  @override
  String get exportSheetDebts => 'Khoản nợ';

  @override
  String get exportColDate => 'Ngày';

  @override
  String get exportColTime => 'Giờ';

  @override
  String get exportColType => 'Loại';

  @override
  String get exportColAmount => 'Số tiền';

  @override
  String get exportColCurrency => 'Tiền tệ';

  @override
  String exportColAmountIn(String currency) {
    return 'Số tiền ($currency)';
  }

  @override
  String get exportColCategory => 'Danh mục';

  @override
  String get exportColAccount => 'Tài khoản';

  @override
  String get exportColToAccount => 'Đến tài khoản';

  @override
  String get exportColReceived => 'Số nhận';

  @override
  String get exportColReceivedCurrency => 'Tiền tệ nhận';

  @override
  String get exportColNote => 'Ghi chú';

  @override
  String get exportColSource => 'Nguồn';

  @override
  String exportColTotalIn(String currency) {
    return 'Tổng ($currency)';
  }

  @override
  String get exportColShare => 'Tỷ lệ';

  @override
  String get exportColPerson => 'Người';

  @override
  String get exportColDirection => 'Chiều';

  @override
  String get exportColPaid => 'Đã trả';

  @override
  String get exportColRemaining => 'Còn lại';

  @override
  String exportColRemainingIn(String currency) {
    return 'Còn lại ($currency)';
  }

  @override
  String get exportColDue => 'Hạn';

  @override
  String get exportColStatus => 'Trạng thái';

  @override
  String get exportColInterestRate => 'Lãi suất';

  @override
  String get exportColPrincipalLeft => 'Gốc còn lại';

  @override
  String get exportColInterestToDate => 'Lãi tới hôm nay';

  @override
  String get exportDebtOpen => 'Chưa xong';

  @override
  String exportReportTitle(String period) {
    return 'Báo cáo thu chi $period';
  }

  @override
  String get exportTotalIncome => 'Tổng thu';

  @override
  String get exportTotalExpense => 'Tổng chi';

  @override
  String get exportDifference => 'Chênh lệch';

  @override
  String exportAmountsIn(String currency) {
    return 'Số tiền theo $currency';
  }

  @override
  String get exportEntriesHeading => 'Danh sách khoản';

  @override
  String get exportNoEntries => 'Không có khoản nào trong khoảng này';

  @override
  String get exportMissingRate => 'Thiếu tỷ giá';

  @override
  String exportPage(int page, int total) {
    return 'Trang $page/$total';
  }

  @override
  String get overviewTitle => 'Tổng quan';

  @override
  String get overviewMenu => 'Tổng quan, thống kê, lịch';

  @override
  String get overviewTotalBalance => 'Tổng số dư';

  @override
  String get overviewAllAccounts =>
      'Mọi tài khoản, kể cả tài khoản ẩn. Không gồm khoản nợ.';

  @override
  String get overviewNet => 'Thu − chi tháng';

  @override
  String get overviewBudgetLeft => 'Ngân sách còn lại';

  @override
  String get overviewBudgetOver => 'Đã vượt';

  @override
  String get overviewSetBudget => 'Đặt ngân sách';

  @override
  String get overviewMonthEmpty => 'Tháng này chưa có khoản nào';

  @override
  String get overviewChartTitle => 'Thu và chi 6 tháng gần nhất';

  @override
  String get overviewVsLastMonth => 'So với tháng trước';

  @override
  String overviewChangeUp(int percent) {
    return 'tăng $percent%';
  }

  @override
  String overviewChangeDown(int percent) {
    return 'giảm $percent%';
  }

  @override
  String get overviewChangeSame => 'không đổi';

  @override
  String get overviewChangeNone => '—';

  @override
  String get overviewChangeNoneSpoken => 'không so được, tháng trước bằng 0';

  @override
  String overviewSummaryUp(int percent, String month) {
    return 'Chi tăng $percent% so với $month';
  }

  @override
  String overviewSummaryDown(int percent, String month) {
    return 'Chi giảm $percent% so với $month';
  }

  @override
  String overviewSummarySame(String month) {
    return 'Chi không đổi so với $month';
  }

  @override
  String get overviewDebtTitle => 'Nợ';

  @override
  String overviewDebtOwedToYou(String amount) {
    return 'Người khác nợ bạn $amount';
  }

  @override
  String overviewDebtYouOwe(String amount) {
    return 'Bạn nợ $amount';
  }

  @override
  String get overviewDebtNone => 'Không có khoản nợ nào đang mở';

  @override
  String overviewQueueNote(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count khoản đang chờ, chưa được tính',
    );
    return '$_temp0';
  }

  @override
  String get statsTitle => 'Thống kê';

  @override
  String get statsFlowTitle => 'Thu và chi';

  @override
  String get statsTopCategories => 'Danh mục chi nhiều nhất';

  @override
  String get statsBiggestDay => 'Ngày chi nhiều nhất';

  @override
  String get statsBalanceHistory => 'Lịch sử tổng số dư';

  @override
  String get statsBalanceNote => 'Mọi tài khoản, kể cả tài khoản ẩn';

  @override
  String get statsEmptyHint =>
      'Chọn kỳ hoặc tài khoản khác, hoặc ghi một khoản.';

  @override
  String statsChartRow(String label, String income, String expense) {
    return '$label: thu $income, chi $expense';
  }

  @override
  String statsChartReadout(String label, String income, String expense) {
    return '$label · Thu $income · Chi $expense';
  }

  @override
  String statsValueRow(String label, String amount) {
    return '$label: $amount';
  }

  @override
  String statsChartSummary(String title, String details) {
    return '$title. $details';
  }

  @override
  String statsCategoryRow(String name, String amount, String percent) {
    return '$name, $amount, $percent';
  }

  @override
  String get statsShowTable => 'Xem dạng bảng';

  @override
  String get statsShowChart => 'Xem dạng biểu đồ';

  @override
  String get calendarTitle => 'Lịch';

  @override
  String calendarDaySpent(String date, String amount) {
    return '$date, chi $amount';
  }

  @override
  String calendarDayIncome(String date) {
    return '$date, có thu';
  }

  @override
  String calendarDaySpentIncome(String date, String amount) {
    return '$date, chi $amount, có thu';
  }

  @override
  String calendarDayTotals(String spent, String income) {
    return 'Chi $spent · Thu $income';
  }

  @override
  String get calendarDayEmpty => 'Ngày này chưa có khoản nào';

  @override
  String get calendarTapHint =>
      'Chạm một ngày để xem các khoản. Chấm là ngày có thu.';

  @override
  String ledgerOnlyLeft(String account, String amount) {
    return '$account chỉ còn $amount';
  }

  @override
  String get ledgerDeleteBlockedTitle => 'Không xoá được';

  @override
  String ledgerDeleteBlocked(String account, String amount) {
    return 'Không xoá được: $account sẽ âm $amount';
  }

  @override
  String get ledgerOk => 'Đã hiểu';

  @override
  String get ledgerAllowNegative => 'Cho phép số dư âm';

  @override
  String get ledgerAllowNegativeSub => 'Dùng cho thẻ tín dụng, thấu chi';

  @override
  String get ledgerInitialNegativeOff =>
      'Bật \"Cho phép số dư âm\" để nhập số dư âm';

  @override
  String get ledgerNegativeBadge => 'Âm';

  @override
  String get ledgerUpgradeTitle => 'Đã cho phép số dư âm';

  @override
  String ledgerUpgradeBody(String accounts) {
    return 'Đã cho phép số dư âm cho: $accounts. Các tài khoản này đang âm nên vẫn ghi được như trước. Tài khoản khác từ nay chỉ chi được khi còn tiền (có thu mới có chi). Tắt công tắc trong Sửa tài khoản nếu không cần.';
  }

  @override
  String ledgerSkipped(int count, String accounts) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Bỏ qua $count khoản định kỳ vì $accounts thiếu tiền',
    );
    return '$_temp0';
  }

  @override
  String get ledgerDismiss => 'Đóng';

  @override
  String ledgerIntoWallet(String amount) {
    return 'Vào ví: $amount';
  }

  @override
  String ledgerOutOfWallet(String amount) {
    return 'Rút khỏi ví: $amount';
  }

  @override
  String ledgerFrom(String account, String amount) {
    return 'Trừ từ $account: $amount';
  }

  @override
  String ledgerInto(String account, String amount) {
    return 'Vào $account: $amount';
  }

  @override
  String ledgerDebtSide(String amount) {
    return 'Khoản nợ: $amount';
  }

  @override
  String get topUpTitle => 'Bù tiền';

  @override
  String topUpShort(String account, String amount) {
    return '$account thiếu $amount';
  }

  @override
  String get topUpBody =>
      'Tiền đã ra khỏi ngân hàng nhưng trong sổ tài khoản này không đủ. Bù bằng một cách dưới đây; bù đủ thì mục tự được lưu.';

  @override
  String topUpIncome(String account) {
    return 'Ghi khoản thu vào $account';
  }

  @override
  String topUpTransfer(String account) {
    return 'Chuyển tiền vào $account';
  }

  @override
  String get topUpEditInitial => 'Sửa số dư ban đầu';

  @override
  String topUpStillShort(String account, String amount) {
    return '$account vẫn thiếu $amount · mục vẫn chờ';
  }

  @override
  String get topUpSaved => 'Đã bù đủ · đã lưu mục';

  @override
  String get debtMovementsSection => 'Khoản nợ';

  @override
  String debtMovementLend(String person) {
    return 'Cho vay · $person';
  }

  @override
  String debtMovementBorrow(String person) {
    return 'Đi vay · $person';
  }

  @override
  String debtMovementCollect(String person) {
    return 'Thu nợ · $person';
  }

  @override
  String debtMovementRepay(String person) {
    return 'Trả nợ · $person';
  }

  @override
  String get debtMovementOrphan => 'Khoản nợ đã xoá';

  @override
  String get debtNoAccount => 'Không qua tài khoản';

  @override
  String get debtNoAccountHelper =>
      'Chỉ ghi nhớ, không đổi số dư tài khoản nào';

  @override
  String get debtInterestRate => 'Lãi suất (tuỳ chọn)';

  @override
  String get debtPerMonth => '%/tháng';

  @override
  String get debtPerYear => '%/năm';

  @override
  String get debtRateInvalid => 'Lãi suất từ 0,01 đến 100, tối đa 2 chữ số lẻ';

  @override
  String get debtInterestStart => 'Ngày bắt đầu tính lãi';

  @override
  String debtInterestStartOn(String date) {
    return 'Tính lãi từ $date';
  }

  @override
  String debtInterestPreview(String amount) {
    return 'Lãi 30 ngày đầu khoảng $amount';
  }

  @override
  String debtPrincipalInterest(String principal, String interest) {
    return 'Gốc $principal · Lãi tới hôm nay $interest';
  }

  @override
  String get debtChangeRate => 'Đổi lãi suất';

  @override
  String debtRateFrom(String date) {
    return 'Áp dụng từ $date';
  }

  @override
  String get debtRateSteps => 'Các mốc lãi suất';

  @override
  String get debtRateBeforeStart =>
      'Ngày áp dụng phải từ ngày bắt đầu tính lãi';

  @override
  String get debtNewRate => 'Lãi suất mới';

  @override
  String get debtPaymentInterest => 'Lãi';

  @override
  String get debtPaymentPrincipal => 'Gốc';

  @override
  String get debtInterestOnly => 'Chỉ trả lãi';

  @override
  String get debtPayAll => 'Trả hết';

  @override
  String debtInterestOver(String amount) {
    return 'Lãi tới ngày trả chỉ $amount';
  }

  @override
  String debtPrincipalOver(String amount) {
    return 'Gốc còn lại chỉ $amount';
  }

  @override
  String debtPaymentSplit(String interest, String principal) {
    return 'Lãi $interest · Gốc $principal';
  }

  @override
  String debtDeleteTitlePerson(String person) {
    return 'Xoá khoản nợ với $person?';
  }

  @override
  String get debtDeleteKeepsEntries =>
      'Các khoản trong sổ vẫn giữ. Lần trả và lịch lãi suất bị xoá; số dư tài khoản không đổi.';

  @override
  String get debtCurrencyLockedMovement =>
      'Không đổi được tiền tệ khi khoản nợ đã đi qua tài khoản.';

  @override
  String debtDeadlineLentEstimate(String person, String amount, String when) {
    return 'Khoản nợ với $person: phải thu khoảng $amount, $when';
  }

  @override
  String debtDeadlineBorrowedEstimate(
    String person,
    String amount,
    String when,
  ) {
    return 'Bạn nợ $person: phải trả khoảng $amount, $when';
  }

  @override
  String get categoryLoanInterest => 'Lãi vay';

  @override
  String get categoryInterestIncome => 'Tiền lãi';

  @override
  String get csvTypeDebt => 'Khoản nợ';
}
