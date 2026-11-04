/// Bảng tiền tệ ISO 4217 đang lưu hành (AC-53). Bảng tĩnh, không dùng mạng.
/// Mã tiền tệ lưu trong cơ sở dữ liệu vẫn là chữ mã ISO (D-005).
///
/// Chỉ gồm tiền tệ dùng để thanh toán; không gồm mã quỹ, kim loại quý và mã
/// thử nghiệm (XAU, XDR, XTS, CLF, UYI...). Thứ tự: 31 mã phổ biến đã có từ
/// bản 1.0 (giữ nguyên thứ tự cũ), rồi các mã còn lại theo bảng chữ cái.
library;

class CurrencyInfo {
  const CurrencyInfo(this.code, this.nameVi, this.nameEn, [this.digits = 2]);

  /// Mã ISO 4217, ba chữ cái in hoa.
  final String code;
  final String nameVi;
  final String nameEn;

  /// Số chữ số thập phân theo ISO 4217 (0, 2 hoặc 3).
  final int digits;

  String name(String languageCode) => languageCode == 'vi' ? nameVi : nameEn;
}

const currencyTable = <CurrencyInfo>[
  // 31 mã phổ biến (thứ tự của bản trước).
  CurrencyInfo('VND', 'Đồng Việt Nam', 'Vietnamese dong', 0),
  CurrencyInfo('USD', 'Đô la Mỹ', 'US dollar'),
  CurrencyInfo('EUR', 'Euro', 'Euro'),
  CurrencyInfo('GBP', 'Bảng Anh', 'Pound sterling'),
  CurrencyInfo('JPY', 'Yên Nhật', 'Japanese yen', 0),
  CurrencyInfo('KRW', 'Won Hàn Quốc', 'South Korean won', 0),
  CurrencyInfo('CNY', 'Nhân dân tệ Trung Quốc', 'Chinese yuan'),
  CurrencyInfo('TWD', 'Đô la Đài Loan mới', 'New Taiwan dollar'),
  CurrencyInfo('HKD', 'Đô la Hồng Kông', 'Hong Kong dollar'),
  CurrencyInfo('SGD', 'Đô la Singapore', 'Singapore dollar'),
  CurrencyInfo('THB', 'Baht Thái', 'Thai baht'),
  CurrencyInfo('MYR', 'Ringgit Malaysia', 'Malaysian ringgit'),
  CurrencyInfo('IDR', 'Rupiah Indonesia', 'Indonesian rupiah'),
  CurrencyInfo('PHP', 'Peso Philippines', 'Philippine peso'),
  CurrencyInfo('INR', 'Rupee Ấn Độ', 'Indian rupee'),
  CurrencyInfo('AUD', 'Đô la Úc', 'Australian dollar'),
  CurrencyInfo('NZD', 'Đô la New Zealand', 'New Zealand dollar'),
  CurrencyInfo('CAD', 'Đô la Canada', 'Canadian dollar'),
  CurrencyInfo('CHF', 'Franc Thụy Sĩ', 'Swiss franc'),
  CurrencyInfo('SEK', 'Krona Thụy Điển', 'Swedish krona'),
  CurrencyInfo('NOK', 'Krone Na Uy', 'Norwegian krone'),
  CurrencyInfo('DKK', 'Krone Đan Mạch', 'Danish krone'),
  CurrencyInfo('PLN', 'Zloty Ba Lan', 'Polish zloty'),
  CurrencyInfo('CZK', 'Koruna Séc', 'Czech koruna'),
  CurrencyInfo('HUF', 'Forint Hungary', 'Hungarian forint'),
  CurrencyInfo('TRY', 'Lira Thổ Nhĩ Kỳ', 'Turkish lira'),
  CurrencyInfo('BRL', 'Real Brazil', 'Brazilian real'),
  CurrencyInfo('MXN', 'Peso Mexico', 'Mexican peso'),
  CurrencyInfo('ZAR', 'Rand Nam Phi', 'South African rand'),
  CurrencyInfo('AED', 'Dirham UAE', 'UAE dirham'),
  CurrencyInfo('SAR', 'Riyal Ả Rập Xê Út', 'Saudi riyal'),
  // Các mã còn lại, theo bảng chữ cái.
  CurrencyInfo('AFN', 'Afghani Afghanistan', 'Afghan afghani'),
  CurrencyInfo('ALL', 'Lek Albania', 'Albanian lek'),
  CurrencyInfo('AMD', 'Dram Armenia', 'Armenian dram'),
  CurrencyInfo('AOA', 'Kwanza Angola', 'Angolan kwanza'),
  CurrencyInfo('ARS', 'Peso Argentina', 'Argentine peso'),
  CurrencyInfo('AWG', 'Florin Aruba', 'Aruban florin'),
  CurrencyInfo('AZN', 'Manat Azerbaijan', 'Azerbaijani manat'),
  CurrencyInfo('BAM', 'Mark chuyển đổi Bosnia', 'Bosnia-Herzegovina mark'),
  CurrencyInfo('BBD', 'Đô la Barbados', 'Barbadian dollar'),
  CurrencyInfo('BDT', 'Taka Bangladesh', 'Bangladeshi taka'),
  CurrencyInfo('BGN', 'Lev Bulgaria', 'Bulgarian lev'),
  CurrencyInfo('BHD', 'Dinar Bahrain', 'Bahraini dinar', 3),
  CurrencyInfo('BIF', 'Franc Burundi', 'Burundian franc', 0),
  CurrencyInfo('BMD', 'Đô la Bermuda', 'Bermudian dollar'),
  CurrencyInfo('BND', 'Đô la Brunei', 'Brunei dollar'),
  CurrencyInfo('BOB', 'Boliviano Bolivia', 'Bolivian boliviano'),
  CurrencyInfo('BSD', 'Đô la Bahamas', 'Bahamian dollar'),
  CurrencyInfo('BTN', 'Ngultrum Bhutan', 'Bhutanese ngultrum'),
  CurrencyInfo('BWP', 'Pula Botswana', 'Botswana pula'),
  CurrencyInfo('BYN', 'Rúp Belarus', 'Belarusian ruble'),
  CurrencyInfo('BZD', 'Đô la Belize', 'Belize dollar'),
  CurrencyInfo('CDF', 'Franc Congo', 'Congolese franc'),
  CurrencyInfo('CLP', 'Peso Chile', 'Chilean peso', 0),
  CurrencyInfo('COP', 'Peso Colombia', 'Colombian peso'),
  CurrencyInfo('CRC', 'Colón Costa Rica', 'Costa Rican colón'),
  CurrencyInfo('CUP', 'Peso Cuba', 'Cuban peso'),
  CurrencyInfo('CVE', 'Escudo Cabo Verde', 'Cape Verdean escudo'),
  CurrencyInfo('DJF', 'Franc Djibouti', 'Djiboutian franc', 0),
  CurrencyInfo('DOP', 'Peso Dominica', 'Dominican peso'),
  CurrencyInfo('DZD', 'Dinar Algeria', 'Algerian dinar'),
  CurrencyInfo('EGP', 'Bảng Ai Cập', 'Egyptian pound'),
  CurrencyInfo('ERN', 'Nakfa Eritrea', 'Eritrean nakfa'),
  CurrencyInfo('ETB', 'Birr Ethiopia', 'Ethiopian birr'),
  CurrencyInfo('FJD', 'Đô la Fiji', 'Fijian dollar'),
  CurrencyInfo('FKP', 'Bảng quần đảo Falkland', 'Falkland Islands pound'),
  CurrencyInfo('GEL', 'Lari Georgia', 'Georgian lari'),
  CurrencyInfo('GHS', 'Cedi Ghana', 'Ghanaian cedi'),
  CurrencyInfo('GIP', 'Bảng Gibraltar', 'Gibraltar pound'),
  CurrencyInfo('GMD', 'Dalasi Gambia', 'Gambian dalasi'),
  CurrencyInfo('GNF', 'Franc Guinea', 'Guinean franc', 0),
  CurrencyInfo('GTQ', 'Quetzal Guatemala', 'Guatemalan quetzal'),
  CurrencyInfo('GYD', 'Đô la Guyana', 'Guyanese dollar'),
  CurrencyInfo('HNL', 'Lempira Honduras', 'Honduran lempira'),
  CurrencyInfo('HTG', 'Gourde Haiti', 'Haitian gourde'),
  CurrencyInfo('ILS', 'Shekel Israel mới', 'Israeli new shekel'),
  CurrencyInfo('IQD', 'Dinar Iraq', 'Iraqi dinar', 3),
  CurrencyInfo('IRR', 'Rial Iran', 'Iranian rial'),
  CurrencyInfo('ISK', 'Krona Iceland', 'Icelandic króna', 0),
  CurrencyInfo('JMD', 'Đô la Jamaica', 'Jamaican dollar'),
  CurrencyInfo('JOD', 'Dinar Jordan', 'Jordanian dinar', 3),
  CurrencyInfo('KES', 'Shilling Kenya', 'Kenyan shilling'),
  CurrencyInfo('KGS', 'Som Kyrgyzstan', 'Kyrgyzstani som'),
  CurrencyInfo('KHR', 'Riel Campuchia', 'Cambodian riel'),
  CurrencyInfo('KMF', 'Franc Comoros', 'Comorian franc', 0),
  CurrencyInfo('KPW', 'Won Triều Tiên', 'North Korean won'),
  CurrencyInfo('KWD', 'Dinar Kuwait', 'Kuwaiti dinar', 3),
  CurrencyInfo('KYD', 'Đô la quần đảo Cayman', 'Cayman Islands dollar'),
  CurrencyInfo('KZT', 'Tenge Kazakhstan', 'Kazakhstani tenge'),
  CurrencyInfo('LAK', 'Kip Lào', 'Lao kip'),
  CurrencyInfo('LBP', 'Bảng Li-băng', 'Lebanese pound'),
  CurrencyInfo('LKR', 'Rupee Sri Lanka', 'Sri Lankan rupee'),
  CurrencyInfo('LRD', 'Đô la Liberia', 'Liberian dollar'),
  CurrencyInfo('LSL', 'Loti Lesotho', 'Lesotho loti'),
  CurrencyInfo('LYD', 'Dinar Libya', 'Libyan dinar', 3),
  CurrencyInfo('MAD', 'Dirham Morocco', 'Moroccan dirham'),
  CurrencyInfo('MDL', 'Leu Moldova', 'Moldovan leu'),
  CurrencyInfo('MGA', 'Ariary Madagascar', 'Malagasy ariary'),
  CurrencyInfo('MKD', 'Denar Bắc Macedonia', 'Macedonian denar'),
  CurrencyInfo('MMK', 'Kyat Myanmar', 'Myanmar kyat'),
  CurrencyInfo('MNT', 'Tugrik Mông Cổ', 'Mongolian tögrög'),
  CurrencyInfo('MOP', 'Pataca Ma Cao', 'Macanese pataca'),
  CurrencyInfo('MRU', 'Ouguiya Mauritania', 'Mauritanian ouguiya'),
  CurrencyInfo('MUR', 'Rupee Mauritius', 'Mauritian rupee'),
  CurrencyInfo('MVR', 'Rufiyaa Maldives', 'Maldivian rufiyaa'),
  CurrencyInfo('MWK', 'Kwacha Malawi', 'Malawian kwacha'),
  CurrencyInfo('MZN', 'Metical Mozambique', 'Mozambican metical'),
  CurrencyInfo('NAD', 'Đô la Namibia', 'Namibian dollar'),
  CurrencyInfo('NGN', 'Naira Nigeria', 'Nigerian naira'),
  CurrencyInfo('NIO', 'Córdoba Nicaragua', 'Nicaraguan córdoba'),
  CurrencyInfo('NPR', 'Rupee Nepal', 'Nepalese rupee'),
  CurrencyInfo('OMR', 'Rial Oman', 'Omani rial', 3),
  CurrencyInfo('PAB', 'Balboa Panama', 'Panamanian balboa'),
  CurrencyInfo('PEN', 'Sol Peru', 'Peruvian sol'),
  CurrencyInfo('PGK', 'Kina Papua New Guinea', 'Papua New Guinean kina'),
  CurrencyInfo('PKR', 'Rupee Pakistan', 'Pakistani rupee'),
  CurrencyInfo('PYG', 'Guaraní Paraguay', 'Paraguayan guaraní', 0),
  CurrencyInfo('QAR', 'Riyal Qatar', 'Qatari riyal'),
  CurrencyInfo('RON', 'Leu Romania', 'Romanian leu'),
  CurrencyInfo('RSD', 'Dinar Serbia', 'Serbian dinar'),
  CurrencyInfo('RUB', 'Rúp Nga', 'Russian ruble'),
  CurrencyInfo('RWF', 'Franc Rwanda', 'Rwandan franc', 0),
  CurrencyInfo('SBD', 'Đô la quần đảo Solomon', 'Solomon Islands dollar'),
  CurrencyInfo('SCR', 'Rupee Seychelles', 'Seychellois rupee'),
  CurrencyInfo('SDG', 'Bảng Sudan', 'Sudanese pound'),
  CurrencyInfo('SHP', 'Bảng Saint Helena', 'Saint Helena pound'),
  CurrencyInfo('SLE', 'Leone Sierra Leone', 'Sierra Leonean leone'),
  CurrencyInfo('SOS', 'Shilling Somalia', 'Somali shilling'),
  CurrencyInfo('SRD', 'Đô la Suriname', 'Surinamese dollar'),
  CurrencyInfo('SSP', 'Bảng Nam Sudan', 'South Sudanese pound'),
  CurrencyInfo(
    'STN',
    'Dobra São Tomé và Príncipe',
    'São Tomé and Príncipe dobra',
  ),
  CurrencyInfo('SVC', 'Colón El Salvador', 'Salvadoran colón'),
  CurrencyInfo('SYP', 'Bảng Syria', 'Syrian pound'),
  CurrencyInfo('SZL', 'Lilangeni Eswatini', 'Swazi lilangeni'),
  CurrencyInfo('TJS', 'Somoni Tajikistan', 'Tajikistani somoni'),
  CurrencyInfo('TMT', 'Manat Turkmenistan', 'Turkmenistani manat'),
  CurrencyInfo('TND', 'Dinar Tunisia', 'Tunisian dinar', 3),
  CurrencyInfo('TOP', 'Paʻanga Tonga', 'Tongan paʻanga'),
  CurrencyInfo('TTD', 'Đô la Trinidad và Tobago', 'Trinidad and Tobago dollar'),
  CurrencyInfo('TZS', 'Shilling Tanzania', 'Tanzanian shilling'),
  CurrencyInfo('UAH', 'Hryvnia Ukraine', 'Ukrainian hryvnia'),
  CurrencyInfo('UGX', 'Shilling Uganda', 'Ugandan shilling', 0),
  CurrencyInfo('UYU', 'Peso Uruguay', 'Uruguayan peso'),
  CurrencyInfo('UZS', 'Som Uzbekistan', 'Uzbekistani som'),
  CurrencyInfo('VES', 'Bolívar Venezuela', 'Venezuelan bolívar'),
  CurrencyInfo('VUV', 'Vatu Vanuatu', 'Vanuatu vatu', 0),
  CurrencyInfo('WST', 'Tala Samoa', 'Samoan tala'),
  CurrencyInfo('XAF', 'Franc CFA Trung Phi', 'Central African CFA franc', 0),
  CurrencyInfo('XCD', 'Đô la Đông Caribe', 'East Caribbean dollar'),
  CurrencyInfo('XCG', 'Guilder Caribe', 'Caribbean guilder'),
  CurrencyInfo('XOF', 'Franc CFA Tây Phi', 'West African CFA franc', 0),
  CurrencyInfo('XPF', 'Franc CFP', 'CFP franc', 0),
  CurrencyInfo('YER', 'Rial Yemen', 'Yemeni rial'),
  CurrencyInfo('ZMW', 'Kwacha Zambia', 'Zambian kwacha'),
  CurrencyInfo('ZWG', 'Vàng Zimbabwe (ZiG)', 'Zimbabwe Gold'),
];

final _byCode = {for (final c in currencyTable) c.code: c};

/// Thông tin của [code], hoặc null nếu mã không có trong bảng.
CurrencyInfo? currencyInfo(String code) => _byCode[code];

const _foldGroups = {
  'a': 'àáạảãâầấậẩẫăằắặẳẵ',
  'e': 'èéẹẻẽêềếệểễ',
  'i': 'ìíịỉĩ',
  'o': 'òóọỏõôồốộổỗơờớợởỡ',
  'u': 'ùúụủũưừứựửữ',
  'y': 'ỳýỵỷỹ',
  'd': 'đ',
};

final _foldMap = {
  for (final g in _foldGroups.entries)
    for (final ch in g.value.runes) ch: g.key,
};

/// Chữ thường, bỏ dấu tiếng Việt (và dấu kết hợp rời): để tìm kiếm không phân
/// biệt hoa thường và dấu.
String foldForSearch(String input) {
  final out = StringBuffer();
  for (final rune in input.toLowerCase().runes) {
    final folded = _foldMap[rune];
    if (folded != null) {
      out.write(folded);
    } else if (rune < 0x300 || rune > 0x36f) {
      out.writeCharCode(rune);
    }
  }
  return out.toString();
}

/// Lọc bảng theo [query]: khớp một phần của mã hoặc tên (vi hoặc en), không
/// phân biệt hoa thường và dấu. Chuỗi rỗng trả về toàn bộ bảng.
List<CurrencyInfo> searchCurrencies(String query) {
  final q = foldForSearch(query.trim());
  if (q.isEmpty) return currencyTable;
  return [
    for (final c in currencyTable)
      if (foldForSearch(c.code).contains(q) ||
          foldForSearch(c.nameVi).contains(q) ||
          foldForSearch(c.nameEn).contains(q))
        c,
  ];
}
