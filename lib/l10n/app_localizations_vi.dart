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
  String get languageSystem => 'Theo máy';

  @override
  String get reminderSection => 'Nhắc ghi chép';

  @override
  String get reminderSwitch => 'Nhắc ghi chép hằng ngày';

  @override
  String get reminderSwitchNote =>
      'Mỗi ngày một thông báo vào giờ bạn chọn, không chứa số liệu';

  @override
  String get reminderTime => 'Giờ nhắc';

  @override
  String get reminderExplainTitle => 'Bật nhắc ghi chép?';

  @override
  String get reminderExplainBody =>
      'Ví Gọn sẽ gửi một thông báo mỗi ngày vào giờ bạn chọn để nhắc ghi khoản. Thông báo không chứa số liệu.';

  @override
  String get reminderContinue => 'Tiếp tục';

  @override
  String get reminderDenied =>
      'Chưa có quyền gửi thông báo. Hãy bật thông báo cho Ví Gọn trong cài đặt hệ thống.';

  @override
  String get reminderOpenSettings => 'Mở cài đặt';

  @override
  String get reminderChannelName => 'Nhắc ghi chép';

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
      'Đổi tiền tệ chỉ đổi ký hiệu, không quy đổi tỉ giá. Nếu hai tiền tệ có số chữ số thập phân khác nhau (ví dụ VND và USD), số tiền được nhân hoặc chia để giữ nguyên con số; đổi ngược lại có thể mất phần lẻ.';

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
  String version(String version) {
    return 'Phiên bản $version';
  }

  @override
  String get aboutBody =>
      'Dữ liệu chỉ lưu trên máy này. Ví Gọn không gửi dữ liệu đi đâu.';

  @override
  String get privacyPolicy => 'Chính sách quyền riêng tư';

  @override
  String get reportSecurity => 'Báo lỗi bảo mật';

  @override
  String get licenses => 'Giấy phép nguồn mở';

  @override
  String get privacyPolicyPending => 'Đang chuẩn bị trang web';

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
}
