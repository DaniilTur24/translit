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

    /// A Russian word source. `isWord` says whether a lowercase word is real; `completions` lists
    /// likely completions of a word, most likely first (the macOS dictionary ranks by frequency).
    struct Lexicon {
        let isWord: (String) -> Bool
        var completions: (String) -> [String] = { _ in [] }
    }

    /// Last resort for a word the rules left alone, using a Russian dictionary.
    /// 1. The most likely completion is the word plus ь and the word itself is not among the completions:
    ///    очен -> очень, пят -> пять (the dictionary accepts both, but nobody completes to the typo).
    ///    Real words such as ответ (-> ответь) or вес (-> весь) list themselves, so they stay.
    /// 2. The dictionary does not know the word: try small edits (ь at the end or inside, э instead of е,
    ///    ий <-> ый, final и -> й) and keep the first real word.
    /// Returns `word` unchanged when it is fine or nothing fits (names, slang, unknown words).
    static func repair(_ word: String, lexicon: Lexicon) -> String {
        guard word.count >= 3 else { return word }
        let completions = lexicon.completions(word)
        if completions.first == word + "ь", !completions.contains(word) { return word + "ь" }
        let isWord = lexicon.isWord
        guard !isWord(word) else { return word }
        let c = Array(word)
        var candidates = [word + "ь"]
        if c[0] == "е" { candidates.append("э" + String(c.dropFirst())) }
        if word.hasSuffix("ий") { candidates.append(String(c.dropLast(2)) + "ый") }
        if word.hasSuffix("ый") { candidates.append(String(c.dropLast(2)) + "ий") }
        if word.hasSuffix("и") { candidates.append(String(c.dropLast()) + "й") }   // днеи -> дней, дорогои -> дорогой
        for i in stride(from: c.count - 1, to: 0, by: -1) where !"аеёиоуыэюяьъ".contains(c[i - 1]) {
            candidates.append(String(c[..<i]) + "ь" + String(c[i...]))   // толко -> только
        }
        return candidates.first(where: isWord) ?? word
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
        "денги": "деньги", "друзя": "друзья", "статя": "статья", "очен": "очень",
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
