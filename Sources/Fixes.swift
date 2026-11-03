import Foundation

/// Rule-based repair of the most common transliteration slips: a missing soft
/// sign ("pomoch" -> помочь), "eto" -> это, and similar. No AI, no network.
///
/// Input and output are lowercase Cyrillic words. Everything here is optional:
/// `Translit.convert(_, smartFixes: false)` bypasses the whole file.
enum Fixes {
    static func apply(_ word: String) -> String {
        if let exact = words[word] { return exact }
        var w = word

        // это, этот, экран ... (word-initial "e" is ambiguous, so only known starts)
        if w.hasPrefix("ет") || eInitial.contains(where: { w.hasPrefix($0) }) { w = "э" + w.dropFirst() }
        // детский: "tsk" is kept as ц for немецкий, so repair the common word here
        if w.hasPrefix("децк") { w = "детск" + w.dropFirst(4) }

        // делат -> делать, посмотрет -> посмотреть
        for stem in infinitiveStems where w.hasSuffix(stem) {
            if verbPrefixes.contains(String(w.dropLast(stem.count))) { return w + "ь" }
        }

        // учишся -> учишься
        if ["ешся", "ишся", "ёшся"].contains(where: w.hasSuffix) { return String(w.dropLast(2)) + "ься" }
        // можеш -> можешь, говориш -> говоришь
        if ["еш", "иш", "ёш"].contains(where: w.hasSuffix), !noSoftSign.contains(w) { return w + "ь" }
        // двадцат -> двадцать, возможност -> возможность, учител -> учитель,
        // рассказыват -> рассказывать, пользуюс -> пользуюсь
        if softSuffixes.contains(where: w.hasSuffix) { return w + "ь" }
        return w
    }

    /// Endings that are (almost) never valid without a soft sign.
    private static let softSuffixes = ["дцат", "ност", "ател", "ител", "ыват", "иват", "ироват", "юс"]

    /// Names / loanwords that really end in -еш / -иш.
    private static let noSoftSign: Set<String> = ["миш", "гриш", "леш", "киш", "кеш", "флеш", "меш"]

    private static let eInitial = [
        "екран", "екзам", "експ", "екстр", "економ", "ефек", "ефир", "емоц", "енерг", "елект",
        "елемент", "ентуз", "епох", "епиз", "ескиз", "естет", "ешелон",
    ]

    private static let verbPrefixes: Set<String> = [
        "", "по", "с", "за", "на", "при", "про", "вы", "у", "от", "под", "об", "пере", "раз", "до", "недо", "пред", "со", "подо", "обо",
    ]

    private static let infinitiveStems = [
        "делат", "работат", "думат", "читат", "писат", "знат", "ждат", "хотет", "смотрет", "видет", "слышат",
        "понимат", "начинат", "играт", "гулят", "сказат", "показат", "умет", "успет", "искат", "купат",
        "помогат", "отдыхат", "пытат", "решат", "получат", "встречат", "отвечат",
    ]

    /// Naive transliteration -> correct spelling. Only keys that are not common words themselves.
    private static let words: [String: String] = [
        // есть is far more common in chat than ест
        "ест": "есть",
        // soft sign at the end
        "помоч": "помочь", "моч": "мочь", "ноч": "ночь", "доч": "дочь", "реч": "речь", "печ": "печь", "проч": "прочь",
        "помощ": "помощь", "мощ": "мощь", "вещ": "вещь", "жизн": "жизнь", "любов": "любовь", "кров": "кровь",
        "двер": "дверь", "тетрад": "тетрадь", "ден": "день", "осен": "осень", "очеред": "очередь",
        "пользовател": "пользователь",
        // soft sign inside
        "толко": "только", "сколко": "сколько", "несколко": "несколько", "болше": "больше", "болшой": "большой",
        "денги": "деньги", "друзя": "друзья", "статя": "статья",
        // numbers
        "пят": "пять", "шест": "шесть", "сем": "семь", "восем": "восемь", "девят": "девять", "десят": "десять",
        "пятдесят": "пятьдесят", "шестдесят": "шестьдесят", "семдесят": "семьдесят", "восемдесят": "восемьдесят",
        "пятсот": "пятьсот", "шестсот": "шестьсот", "семсот": "семьсот", "восемсот": "восемьсот",
        // months
        "январ": "январь", "феврал": "февраль", "апрел": "апрель", "июн": "июнь", "июл": "июль",
        "сентябр": "сентябрь", "октябр": "октябрь", "ноябр": "ноябрь", "декабр": "декабрь",
        // names
        "игор": "игорь", "олга": "ольга", "наталя": "наталья", "татяна": "татьяна", "даря": "дарья",
        "въетнам": "вьетнам",
    ]
}
