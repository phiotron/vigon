// GENERATED from store/legal/*.md — do not edit by hand.
// Regenerate after changing the store texts: python tool/md_to_dart.py

/// In-app copies of the privacy policy and terms (offline fallback and
/// while a public URL is unreachable).
abstract final class LegalTexts {
  /// store/legal/privacy-policy.vi.md
  static const String privacyVi = r'''
# Chính sách quyền riêng tư của Ví Gọn

**Cập nhật lần cuối:** 2026-11-12

Ví Gọn là ứng dụng ghi chép thu chi cá nhân cho Android và iPhone, do Phiotron phát hành. Chính sách này giải thích ứng dụng lưu dữ liệu gì, lưu ở đâu và bạn kiểm soát chúng thế nào.

## 1. Chúng tôi không thu thập dữ liệu của bạn

Ví Gọn không có máy chủ, không có tài khoản người dùng, không có quảng cáo, không có công cụ phân tích, theo dõi hay báo lỗi của bên thứ ba. Ứng dụng không gửi dữ liệu bạn nhập cho nhà phát triển; nhà phát triển không nhận, không xem và không chia sẻ dữ liệu đó.

Ứng dụng chỉ dùng Internet cho hai việc, cả hai đều do bạn chủ động bật hoặc chạm: tải bảng tỷ giá khi bạn đổi tiền tệ (mục 4) và đọc email biên lai ngân hàng từ hộp thư bạn tự thêm (mục 3). Không có kết nối nào khác, không có mã theo dõi, mã quảng cáo hay mã nhận diện thiết bị.

## 2. Dữ liệu nằm trên điện thoại của bạn

Những gì bạn nhập — khoản thu, khoản chi, danh mục, tài khoản, chuyển tiền, ghi chú, ngân sách tháng và ngân sách danh mục, khoản định kỳ, mục tiêu tiết kiệm, khoản nợ, hàng đợi khoản chờ chọn danh mục, gợi ý danh mục theo người thụ hưởng và cài đặt — chỉ được lưu trong vùng lưu trữ riêng của ứng dụng trên điện thoại. Ứng dụng khác không đọc được vùng này.

- **Android:** ứng dụng tắt tính năng sao lưu tự động của Android (`allowBackup=false`), nên dữ liệu không tự được đưa lên đám mây.
- **iPhone:** ứng dụng loại dữ liệu của mình khỏi bản sao lưu iCloud và bản sao lưu iPhone bằng máy tính, nên dữ liệu không được đưa lên đám mây hay vào bản sao lưu của máy.

Vì vậy trên cả hai nền tảng, đừng trông vào bản sao lưu của điện thoại để giữ dữ liệu Ví Gọn: khi bạn cài lại ứng dụng hoặc khôi phục điện thoại từ bản sao lưu, dữ liệu của ứng dụng không được khôi phục theo. Muốn mang dữ liệu sang máy khác, hãy tự xuất file sao lưu `.vigon` (mục 5) rồi chọn "Khôi phục từ bản sao lưu" trên máy mới.

Nếu bạn bật khóa bằng mã PIN, ứng dụng chỉ lưu một giá trị băm có muối của mã PIN, không lưu mã PIN gốc. Trên Android, giá trị này nằm trong bộ nhớ an toàn được bảo vệ bằng Android Keystore. Trên iPhone, nó nằm trong Keychain của máy và không đồng bộ qua iCloud Keychain. iOS có thể giữ mục Keychain này sau khi bạn gỡ ứng dụng; khi bạn cài lại và ứng dụng bắt đầu với dữ liệu trống, ứng dụng tự nhận ra và xóa mã PIN cũ, nên bạn không bị khóa bằng mã PIN của lần cài trước.

Mở khóa bằng vân tay, Face ID hoặc Touch ID là tùy chọn, chỉ bật được khi đã có mã PIN. Khi bật, ứng dụng chỉ lưu một cờ bật/tắt trong kho khóa an toàn. Vân tay hay khuôn mặt do hệ điều hành giữ và đối chiếu: ứng dụng không bao giờ đọc, không nhận và không lưu dữ liệu sinh trắc, chỉ nhận kết quả đúng hoặc sai. Cờ này không nằm trong file sao lưu và tự mất khi bạn tắt mã PIN hoặc chọn "Xóa toàn bộ dữ liệu". Trên Android, tùy chọn chỉ hiện khi máy có sinh trắc lớp mạnh; máy chỉ có mở khóa khuôn mặt 2D sẽ không thấy tùy chọn này.

**Widget màn hình chính (Android và iPhone).** Nếu bạn thêm widget, widget luôn có hai nút "Chi" và "Thu" để mở nhanh màn nhập khoản. Mặc định widget không hiện số tiền nào. Chỉ khi bạn tự bật "Hiện số tiền trên widget" và không dùng khóa PIN thì widget mới hiện số đã chi trong tháng (và hạn mức nếu bạn đã đặt ngân sách tháng). Khi khóa PIN đang bật, widget luôn ẩn số tiền. Số liệu này chỉ nằm trong bộ nhớ riêng của ứng dụng trên máy (trên iPhone là vùng lưu trữ dùng chung chỉ giữa Ví Gọn và widget của chính nó) và trên màn hình chờ của bạn; không gửi đi đâu, và bị xóa khi bạn tắt công tắc hoặc bật PIN. Khi công tắc đang bật, ai cầm máy bạn cũng có thể thấy số trên màn hình chờ.

## 3. Nhập khoản chi từ email ngân hàng (tùy chọn, mặc định tắt)

Nếu bạn thêm hộp thư trong Cài đặt → Nhập từ email, ứng dụng đăng nhập IMAP qua kết nối mã hóa (TLS, cổng 993) vào đúng hộp thư bạn chọn để đọc email biên lai của ngân hàng. Bản này chỉ hỗ trợ MB Bank và ba nhà cung cấp email: Gmail, Yahoo, iCloud.

- Ứng dụng chỉ đọc thư do địa chỉ ngân hàng gửi tới; thư khác không được tải về.
- Ứng dụng chỉ đọc thư đến sau thời điểm bạn kết nối hộp thư, không đọc thư cũ.
- Ứng dụng đọc thư ở chế độ chỉ xem (`BODY.PEEK`): không đánh dấu đã đọc, không sửa, không xóa, không chuyển thư.
- Nội dung thư được xử lý trên máy để lấy ngày, số tiền, người thụ hưởng, nội dung chuyển tiền, bốn số cuối tài khoản trích nợ và số tham chiếu. Không có nội dung thư nào được gửi cho nhà phát triển hay bên thứ ba.
- Khoản đọc được **chưa phải khoản chi**: chúng vào Hàng đợi để bạn chọn danh mục rồi xác nhận. Chưa xác nhận thì không vào tổng, biểu đồ hay ngân sách.
- Bạn dùng **mật khẩu ứng dụng** do nhà cung cấp email tạo, không phải mật khẩu chính. Địa chỉ hộp thư và mật khẩu ứng dụng được lưu trong kho khóa an toàn của điện thoại (Android Keystore, iPhone Keychain), không vào cơ sở dữ liệu, file sao lưu, CSV hay nhật ký. Mật khẩu chỉ dùng để đăng nhập IMAP.
- Tối đa ba hộp thư. Xóa hộp thư trong ứng dụng là xóa cấu hình và mật khẩu ứng dụng khỏi kho khóa; "Xóa toàn bộ dữ liệu" cũng xóa toàn bộ phần này. Bạn nên thu hồi mật khẩu ứng dụng trong tài khoản email nếu muốn chắc chắn.
- Android tự kiểm thư khoảng mỗi giờ khi ứng dụng đóng; iPhone chỉ kiểm khi bạn mở hoặc quay lại ứng dụng. Cả hai đều kiểm ngay khi bạn mở ứng dụng.
- Nhà cung cấp email (Google, Yahoo, Apple) thấy địa chỉ IP và thời điểm đăng nhập như mọi lần bạn kiểm thư bằng ứng dụng khác, và xử lý theo chính sách của họ. Nếu họ chặn đăng nhập bằng mật khẩu ứng dụng, tính năng này ngừng hoạt động và bạn có thể xóa hộp thư.

## 4. Tỷ giá

Khi bạn chọn tiền tệ khác trong Cài đặt, ứng dụng tải một bảng tỷ giá công khai (bảng gốc đô la Mỹ, giống nhau cho mọi người dùng) từ ExchangeRate-API (open.er-api.com) qua kết nối mã hóa HTTPS để quy đổi số tiền trên máy. Yêu cầu không chứa số tiền, tiền tệ đang dùng hay bất kỳ thông tin nào bạn nhập. Như mọi kết nối Internet, nhà cung cấp tỷ giá thấy địa chỉ IP, thời điểm và thông tin kỹ thuật của kết nối, và xử lý theo chính sách của họ (exchangerate-api.com). Bảng tỷ giá được lưu trên máy để dùng khi không có mạng; bạn cũng có thể tự nhập tỷ giá.

## 5. File sao lưu và CSV do bạn tự xuất

Khi bạn chọn "Xuất bản sao lưu" hoặc "Xuất CSV", ứng dụng tạo file trong thư mục tạm của ứng dụng rồi mở bảng chia sẻ của hệ điều hành để bạn chọn nơi gửi hoặc lưu, ví dụ app Tệp (Files), Google Drive hay email. Bạn quyết định file đi đâu. Bạn có thể đặt mật khẩu cho file sao lưu; khi đó file được mã hóa trên máy bằng AES-256-GCM (mật khẩu không được lưu ở đâu cả, quên mật khẩu thì không mở được file). Không đặt mật khẩu thì file không được mã hóa, hãy cất ở nơi an toàn. Từ lúc đó, file chịu chính sách của dịch vụ bạn chọn. Hệ điều hành tự dọn thư mục tạm của ứng dụng.

File sao lưu không chứa hộp thư email, mật khẩu ứng dụng hay hàng đợi khoản chờ chọn danh mục.

Bạn có thể bật thêm "Sao lưu tự động" (mặc định tắt). Khi bật, bạn tự chọn một thư mục và đặt mật khẩu sao lưu. Trên Android, bạn chọn thư mục bằng bộ chọn của hệ thống và chọn giờ sao lưu (mặc định 21:00, theo giờ trên máy); đến giờ đó ứng dụng tự ghi file kể cả khi bạn không mở ứng dụng (hệ thống có thể lùi vài phút để tiết kiệm pin). Trên iPhone, bạn chọn thư mục trong app Tệp, ví dụ trong iCloud Drive; vì iPhone không cho ứng dụng đã đóng tự chạy, đến giờ đó ứng dụng hiện một thông báo trên máy, chạm vào hoặc mở Ví Gọn thì ứng dụng ghi file. Nếu lỡ giờ, ứng dụng sao lưu bù khi bạn mở lại (Android: cả khi bạn rời ứng dụng). Mỗi ngày tối đa một lần và chỉ khi dữ liệu có thay đổi; ứng dụng giữ hai file tự động gần nhất. File tự động luôn được mã hóa, không bao giờ ghi bản rõ. Mật khẩu chỉ được lưu trong kho khóa an toàn của điện thoại, không ghi vào file, nhật ký hay cơ sở dữ liệu và không gửi đi đâu.

Quyền ghi vào thư mục do hệ điều hành quản lý và chỉ áp dụng cho đúng thư mục bạn chọn. Nếu thư mục thuộc một dịch vụ lưu trữ như iCloud Drive, Google Drive hay OneDrive thì việc tải file lên đám mây do Apple hoặc ứng dụng của dịch vụ đó thực hiện theo chính sách của họ; Ví Gọn không tự tải file lên và nhà phát triển không nhận được file. Nếu thư mục chỉ nằm trên điện thoại, mất máy là mất luôn các file này. Khi tắt "Sao lưu tự động", ứng dụng xóa mật khẩu khỏi kho khóa và bỏ quyền truy cập thư mục nhưng không xóa các file đã ghi; bạn tự xóa chúng nếu muốn.

## 6. Quyền trên điện thoại

Trên Android, Ví Gọn có quyền Internet để tải bảng tỷ giá (mục 4) và đọc hộp thư bạn đã thêm (mục 3); Android cấp sẵn quyền này khi cài, không hỏi bạn. Ngoài ra ứng dụng chỉ có ba quyền, chỉ phục vụ các thông báo nhắc ("Nhắc ghi sổ hằng ngày", mặc định tắt; "Nhắc trước hạn" của mục tiêu tiết kiệm và khoản nợ, mặc định bật) và lịch kiểm thư nền:

- Thông báo: ứng dụng chỉ xin khi bạn bật Nhắc ghi sổ hoặc Nhắc trước hạn, khi bạn đặt hạn cho mục tiêu tiết kiệm hay khoản nợ lần đầu, hoặc (chỉ iPhone) khi bạn bật hay đổi giờ Sao lưu tự động, luôn sau một lời giải thích (Android 13 trở lên; trên iPhone là hộp thoại của iOS). Thông báo giờ sao lưu trên iPhone chỉ có câu chung "Đến giờ sao lưu Ví Gọn. Chạm để sao lưu."; từ chối thì ứng dụng vẫn sao lưu khi bạn mở. Mọi thông báo nhắc được tạo và nằm trên máy, không đi qua máy chủ nào. Nhắc ghi sổ có nội dung chung chung, không chứa số liệu. Nhắc trước hạn có tên mục tiêu hoặc tên người và số tiền còn lại (ví dụ "Khoản nợ với An: còn 2.000.000 ₫, đến hạn sau 7 ngày") và có thể hiện trên màn khóa, kể cả khi bạn bật mã PIN; bạn tắt được trong Cài đặt → Nhắc trước hạn. Từ chối thì ứng dụng vẫn dùng bình thường.
- Nhận tín hiệu khởi động lại máy (chỉ Android): Android cấp sẵn khi cài, không hỏi bạn. Ứng dụng chỉ dùng để đặt lại lịch nhắc, lịch sao lưu tự động và lịch kiểm thư sau khi bạn khởi động lại điện thoại (nếu đã bật); quyền này không cho ứng dụng đọc dữ liệu nào.
- Chuông báo và lời nhắc (chỉ Android 12 trở lên; có máy gọi là "Báo thức và lời nhắc"): Android không cấp sẵn. Ứng dụng chỉ mời bạn bật trong cài đặt hệ thống sau khi bạn bật một loại nhắc, để thông báo nhắc đến đúng phút; không bật thì thông báo vẫn đến nhưng có thể trễ vài phút. Quyền này chỉ cho ứng dụng hẹn giờ thông báo, không cho đọc dữ liệu nào.

Ứng dụng không xin quyền vị trí, danh bạ, ảnh, camera hay micro. Chọn file khôi phục và chọn thư mục sao lưu dùng bộ chọn của hệ điều hành, chỉ truy cập đúng file hoặc thư mục bạn chọn.

## 7. Liên kết ra ngoài

Màn Cài đặt → Giới thiệu có thể mở trình duyệt (xem chính sách này, điều khoản sử dụng, trang hỗ trợ) hoặc ứng dụng email (gửi góp ý, báo lỗi bảo mật). Màn Tỷ giá và hướng dẫn thêm hộp thư có link mở trang của ExchangeRate-API và trang tạo mật khẩu ứng dụng của Google, Yahoo, Apple. Các ứng dụng và trang đó hoạt động theo chính sách riêng của họ.

## 8. Dữ liệu cửa hàng ứng dụng có thể thu thập

Khi bạn tải ứng dụng qua Google Play hoặc App Store, Google hoặc Apple có thể thu thập thông tin về việc cài đặt và sự cố ứng dụng theo chính sách của họ và cài đặt trên máy bạn (ví dụ tùy chọn chia sẻ dữ liệu phân tích với nhà phát triển trên iPhone). Nhà phát triển chỉ thấy số liệu tổng hợp, ẩn danh trong Play Console và App Store Connect và không thể dùng chúng để nhận ra bạn.

## 9. Quyền của bạn

Vì dữ liệu chỉ nằm trên máy, bạn tự thực hiện mọi quyền ngay trong ứng dụng: xem và sửa từng khoản; xuất toàn bộ dữ liệu ra file sao lưu hoặc CSV; xóa hộp thư và mật khẩu ứng dụng; xóa toàn bộ dữ liệu (kể cả mã PIN, hộp thư và mật khẩu ứng dụng) trong Cài đặt → "Xóa toàn bộ dữ liệu"; hoặc gỡ ứng dụng. Gỡ ứng dụng sẽ xóa dữ liệu trên máy, trừ các file bạn đã tự xuất và các file sao lưu tự động trong thư mục bạn chọn. Trên iPhone, iOS có thể giữ lại mục mã PIN trong Keychain sau khi gỡ ứng dụng; ứng dụng tự xóa mục này khi được cài lại với dữ liệu mới (mục 2).

## 10. Trẻ em

Ví Gọn không nhắm tới trẻ em và không thu thập dữ liệu của bất kỳ ai, kể cả trẻ em.

## 11. Bảo mật

Dữ liệu được bảo vệ bằng cơ chế cách ly ứng dụng của Android và iOS, khóa PIN tùy chọn (có thể mở bằng sinh trắc học) và tùy chọn "Che nội dung khi chuyển ứng dụng". Khóa PIN giúp ngăn người khác mở ứng dụng trên máy bạn, nhưng không mã hóa dữ liệu. Sinh trắc chỉ là cách mở khóa nhanh: dữ liệu sinh trắc do hệ điều hành giữ, ứng dụng không đọc và không lưu (mục 2). Khi bật tùy chọn che nội dung: trên Android, ứng dụng chặn chụp màn hình và ẩn ảnh xem trước trong danh sách ứng dụng gần đây; trên iPhone, ứng dụng phủ một lớp che lên nội dung khi bạn rời ứng dụng hoặc mở màn chuyển ứng dụng, nhưng iPhone không cho ứng dụng chặn chụp màn hình. Khi chưa bật tùy chọn này, ảnh xem trước của ứng dụng trong màn đa nhiệm có thể hiện số liệu đang mở. Mật khẩu ứng dụng của hộp thư và mật khẩu sao lưu tự động nằm trong kho khóa an toàn của hệ điều hành, không nằm trong cơ sở dữ liệu hay file sao lưu. Nếu bạn phát hiện lỗ hổng bảo mật, hãy gửi email tới địa chỉ ở mục 13.

## 12. Thay đổi chính sách

Nếu Ví Gọn thay đổi cách xử lý dữ liệu (ví dụ thêm tính năng gửi dữ liệu qua Internet), chúng tôi sẽ cập nhật chính sách này và ngày cập nhật trước khi phát hành bản có thay đổi. Đây là bản đầu tiên của chính sách.

## 13. Liên hệ

Phiotron, nhà phát triển Ví Gọn — email: phamphuongphuongnd@gmail.com
''';

  /// store/legal/privacy-policy.en.md
  static const String privacyEn = r'''
# Vigon Privacy Policy

**Last updated:** 2026-11-12

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

Unlocking with a fingerprint, Face ID or Touch ID is optional and can only be turned on while the PIN lock is on. When it is on, the app stores just an on/off flag in secure storage. Your fingerprint or face is held and matched by the operating system: the app never reads, receives or stores biometric data, and only gets a yes or no result. The flag is not included in backup files and is removed when you turn the PIN off or choose "Delete all data". On Android the option only appears when the phone has strong biometrics; a phone with only 2D face unlock will not show it.

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

Data is protected by Android's and iOS's app sandboxing, the optional PIN lock (which can be opened with biometrics) and the optional "Hide content when switching apps". The PIN lock prevents others from opening the app on your phone, but it does not encrypt data. Biometrics are only a quick way to unlock: your biometric data is held by the operating system, and the app neither reads nor stores it (section 2). When the hide option is on: on Android the app blocks screenshots and hides its preview in the recent-apps list; on iPhone the app covers its content when you leave the app or open the app switcher, but iPhone does not let apps block screenshots. When the option is off, the app's preview in the task switcher may show the figures on screen. Mailbox app passwords and the automatic-backup password live in the operating system's secure key store, not in the database or backup files. If you find a security vulnerability, please email the address in section 13.

## 12. Changes to this policy

If Vigon changes how it handles data (for example, adds a feature that sends data over the internet), we will update this policy and its date before releasing the version with the change. This is the first version of the policy.

## 13. Contact

Phiotron, developer of Vigon — email: phamphuongphuongnd@gmail.com
''';

  /// store/legal/terms-of-use.vi.md
  static const String termsVi = r'''
# Điều khoản sử dụng Ví Gọn

**Cập nhật lần cuối:** 2026-11-10

Khi dùng **Ví Gọn** ("Ví Gọn", "ứng dụng") do Phiotron ("chúng tôi") phát hành, bạn đồng ý với các điều khoản này. Nếu bạn tải ứng dụng từ Apple App Store, Thoả thuận cấp phép người dùng cuối tiêu chuẩn (Standard EULA) của Apple cũng được áp dụng.

1. **Ví Gọn là gì.** Một công cụ cá nhân miễn phí để ghi lại khoản thu, khoản chi, tài khoản và chuyển tiền, ngân sách, khoản định kỳ, mục tiêu tiết kiệm, khoản nợ, rồi xem tổng quan, thống kê và lịch chi tiêu. Ứng dụng không kết nối với ngân hàng để chuyển tiền, không phải ví điện tử và không thể trả, huỷ hay thay đổi giao dịch nào giúp bạn.

2. **Không phải lời khuyên tài chính.** Mọi số liệu — số dư, tổng thu chi, ngân sách, tiến độ tiết kiệm, khoản nợ, tỷ giá — chỉ để bạn tham khảo và dựa trên những gì bạn nhập hoặc những gì ứng dụng đọc được. Chúng tôi không đưa ra lời khuyên đầu tư, thuế, kế toán hay pháp lý. Hãy tự kiểm tra và tự quyết định.

3. **Bạn chịu trách nhiệm về dữ liệu nhập.** Số tiền, ngày giờ, danh mục, tài khoản và các thông tin khác do bạn nhập. Ghi sai thì tổng, ngân sách, biểu đồ và báo cáo cũng sai theo. Bạn tự kiểm tra số liệu trước khi dùng cho việc gì quan trọng.

4. **Nhập khoản chi từ email ngân hàng (tuỳ chọn, mặc định tắt).** Nếu bạn thêm hộp thư, ứng dụng đọc email biên lai của MB Bank trong đúng hộp thư đó. Ứng dụng có thể đọc sai số tiền, ngày giờ, người thụ hưởng hoặc nội dung chuyển tiền nếu ngân hàng đổi mẫu email, hoặc bỏ qua email không đọc được. Khoản đọc được chỉ vào Hàng đợi để bạn xem lại và xác nhận; bạn phải kiểm tra trước khi lưu. Ứng dụng không kết nối tới ngân hàng, không chuyển, huỷ hay hoàn tiền, và không bảo đảm email nào cũng đọc được. Bạn tự tạo, giữ và thu hồi mật khẩu ứng dụng của hộp thư; nếu nghi ngờ bị lộ, hãy thu hồi mật khẩu đó trong tài khoản email. Nhà cung cấp email có thể chặn đăng nhập bất cứ lúc nào, khi đó tính năng này ngừng hoạt động.

5. **Tỷ giá có thể sai hoặc trễ.** Bảng tỷ giá tải từ ExchangeRate-API và có thể chậm, sai hoặc không có khi không có mạng. Số quy đổi chỉ để tham khảo; số tiền gốc bạn nhập mới là số thật.

6. **Dữ liệu, sao lưu và mất dữ liệu.** Dữ liệu chỉ lưu trên máy bạn. Ứng dụng không có máy chủ và không khôi phục dữ liệu giúp bạn. Nếu bạn xoá dữ liệu trong ứng dụng, gỡ ứng dụng, đặt lại máy, mất máy, hoặc file sao lưu hỏng hay không có, dữ liệu có thể mất vĩnh viễn. Hãy tự xuất file sao lưu `.vigon` định kỳ và giữ ở nơi an toàn. Nếu bạn đặt mật khẩu cho file sao lưu, quên mật khẩu thì không mở được file — chúng tôi cũng không mở được. Cách ứng dụng xử lý dữ liệu được mô tả trong Chính sách quyền riêng tư.

7. **Quyền riêng tư.** Chính sách quyền riêng tư là một phần của các điều khoản này và giải thích dữ liệu nào được lưu, ở đâu và bạn kiểm soát chúng thế nào.

8. **Sở hữu trí tuệ và nhãn hiệu.** Ứng dụng, mã nguồn, giao diện và tên Ví Gọn thuộc về chúng tôi hoặc người cấp phép cho chúng tôi. Tên ngân hàng, tên nhà cung cấp dịch vụ và nhãn hiệu của họ thuộc chủ sở hữu tương ứng; ứng dụng chỉ dùng chúng để nhận diện và không liên kết, bảo trợ hay đại diện cho họ. Thư viện mã nguồn mở dùng trong ứng dụng theo giấy phép của từng thư viện; xem trong ứng dụng tại Cài đặt → Giới thiệu → Giấy phép mã nguồn mở.

9. **Không bảo đảm.** Ứng dụng được cung cấp "nguyên trạng" và "sẵn có". Trong phạm vi pháp luật cho phép, chúng tôi không bảo đảm ứng dụng luôn chạy không lỗi, không mất dữ liệu, hay phù hợp với một mục đích cụ thể.

10. **Giới hạn trách nhiệm.** Trong phạm vi pháp luật cho phép, chúng tôi không chịu trách nhiệm cho thiệt hại gián tiếp, ngẫu nhiên hay hệ quả, mất lợi nhuận, mất dữ liệu, hoặc thiệt hại phát sinh từ việc bạn dựa vào số liệu trong ứng dụng. Điều này không loại trừ trách nhiệm mà pháp luật không cho phép loại trừ.

11. **Luật áp dụng và quyền người tiêu dùng.** Các điều khoản này theo pháp luật Việt Nam. Không điều khoản nào ở đây cắt bỏ quyền lợi bắt buộc mà pháp luật bảo vệ người tiêu dùng tại nơi bạn sinh sống; nếu luật đó cho bạn quyền cao hơn, quyền đó được áp dụng.

12. **Thay đổi điều khoản.** Chúng tôi có thể sửa các điều khoản này khi ứng dụng thay đổi. Bản mới có ngày cập nhật và có hiệu lực từ khi được đăng. Tiếp tục dùng ứng dụng sau khi điều khoản thay đổi nghĩa là bạn chấp nhận bản mới.

13. **Liên hệ.** Phiotron, nhà phát triển Ví Gọn — email: phamphuongphuongnd@gmail.com
''';

  /// store/legal/terms-of-use.en.md
  static const String termsEn = r'''
# Vigon Terms of Use

**Last updated:** 2026-11-10

By using **Vigon** ("Vigon", "the app"), published by Phiotron ("we", "us"), you agree to these terms. If you download the app from the Apple App Store, Apple's Standard End User License Agreement (Standard EULA) also applies.

1. **What Vigon is.** A free personal tool to record income, expenses, accounts and transfers, budgets, recurring items, savings goals and debts, and to view an overview, statistics and a spending calendar. The app does not connect to a bank to move money, is not a digital wallet, and cannot pay, cancel or change any transaction for you.

2. **Not financial advice.** All figures — balances, income and expense totals, budgets, savings progress, debts, exchange rates — are for your reference only and are based on what you enter or what the app manages to read. We do not provide investment, tax, accounting or legal advice. Check for yourself and decide for yourself.

3. **You are responsible for what you enter.** Amounts, dates and times, categories, accounts and other details are entered by you. If they are wrong, totals, budgets, charts and reports are wrong too. Check your figures before relying on them for anything important.

4. **Importing expenses from bank email (optional, off by default).** If you add a mailbox, the app reads MB Bank receipt emails in that mailbox. It may read the wrong amount, date and time, beneficiary or transfer description if the bank changes its email template, or skip emails it cannot read. A parsed item goes to the Queue for you to review and confirm; you must check it before saving. The app does not connect to the bank, does not move, cancel or refund money, and does not guarantee that every email can be read. You create, keep and revoke your mailbox app password yourself; if you suspect it is exposed, revoke it in your email account. Your email provider may block sign-in at any time, in which case this feature stops working.

5. **Exchange rates may be wrong or late.** The rate table is downloaded from ExchangeRate-API and may be delayed, wrong or unavailable offline. Converted figures are for reference only; the original amount you entered is the real one.

6. **Data, backup and data loss.** Your data is stored only on your phone. The app has no server and cannot restore data for you. If you delete data in the app, uninstall the app, reset your phone, lose your phone, or a backup file is damaged or missing, your data may be lost permanently. Export a `.vigon` backup file regularly and keep it somewhere safe. If you password-protect a backup file and forget the password, the file cannot be opened — not even by us. How the app handles data is described in the Privacy Policy.

7. **Privacy.** The Privacy Policy is part of these terms and explains what data is stored, where, and how you control it.

8. **Intellectual property and trademarks.** The app, its source code, its interface and the name Vigon belong to us or to our licensors. Bank names, service-provider names and their trademarks belong to their respective owners; the app uses them only for identification and is not affiliated with, endorsed by or acting for them. Open-source libraries used in the app are under their own licences; see Settings → About → Open-source licences.

9. **No warranty.** The app is provided "as is" and "as available". To the extent the law allows, we do not warrant that it will run without errors, that data will not be lost, or that it fits a particular purpose.

10. **Limitation of liability.** To the extent the law allows, we are not liable for indirect, incidental or consequential damages, lost profits, lost data, or damage arising from your reliance on figures in the app. This does not exclude liability that the law does not allow us to exclude.

11. **Governing law and consumer rights.** These terms are governed by the laws of Vietnam. Nothing here removes mandatory consumer rights granted by the law where you live; if that law gives you stronger rights, those rights apply.

12. **Changes to these terms.** We may change these terms when the app changes. A new version carries an updated date and applies from the day it is published. Continuing to use the app after the terms change means you accept the new version.

13. **Contact.** Phiotron, developer of Vigon — email: phamphuongphuongnd@gmail.com
''';
}
