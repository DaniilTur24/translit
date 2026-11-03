import Foundation

/// Russian phonetic transliteration (Latin -> Cyrillic).
///
/// Pure functions only: no AppKit, no clipboard, no state. A future
/// "convert after space" mode can call `Translit.convert` unchanged.
enum Translit {
    /// Converts every Latin word in `text`; whitespace, punctuation, digits,
    /// Cyrillic, URLs, e-mails and camelCase words are left untouched.
    ///
    /// `lexicon` is an optional Russian dictionary. When given, words that the rules leave
    /// misspelled get one more repair attempt (see `Fixes.repair`).
    static func convert(_ text: String, smartFixes: Bool = true, lexicon: Fixes.Lexicon? = nil) -> String {
        var result = ""
        var state = State()
        var chunk = ""
        for ch in text {
            if ch.isWhitespace {
                result += convertChunk(chunk, &state, smartFixes, lexicon)
                chunk = ""
                result.append(ch)
            } else {
                chunk.append(ch)
            }
        }
        result += convertChunk(chunk, &state, smartFixes, lexicon)
        return result
    }

    // MARK: - Text level

    private struct State {
        var previousWord = ""   // last Latin word, lowercase (decides -tsya vs -t'sya)
        var openQuote = false   // a ' opened a quote and is still waiting for its closing '
    }

    private static func convertChunk(_ chunk: String, _ state: inout State, _ smartFixes: Bool, _ lexicon: Fixes.Lexicon?) -> String {
        if chunk.isEmpty { return "" }
        if shouldLeaveAlone(chunk) {
            state.previousWord = ""
            return chunk
        }
        let c = Array(chunk)
        var out = ""
        var i = 0
        while i < c.count {
            guard isLatin(c[i]) else {
                // a ' right before a word is an opening quote, not a soft sign
                if (isApostrophe(c[i]) || c[i] == "\u{2018}"), i + 1 < c.count, isLatin(c[i + 1]) {
                    state.openQuote = true
                }
                out.append(c[i])
                i += 1
                continue
            }
            var j = i
            scan: while j < c.count {
                let x = c[j]
                if isLatin(x) { j += 1; continue }
                let next: Character? = j + 1 < c.count ? c[j + 1] : nil
                if isApostrophe(x) {
                    if let n = next, isLatin(n) { j += 1; continue }                              // sem'ya
                    if let n = next, isApostrophe(n), j + 2 < c.count, isLatin(c[j + 2]) { j += 2; continue }  // ob''yem
                    if state.openQuote { state.openQuote = false } else { j += 1 }                // mat' (or closing quote)
                    break scan
                }
                if x == "\"", let n = next, isLatin(n) { j += 1; continue }                       // ob"ekt
                break scan
            }
            let run = String(c[i..<j])
            out += convertRun(run, state.previousWord, smartFixes, lexicon)
            state.previousWord = String(run.lowercased().filter(isLatin))
            i = j
        }
        return out
    }

    /// Tokens that look like URLs, e-mails, paths or codes (mp3, b2b) must not be transliterated.
    private static func shouldLeaveAlone(_ chunk: String) -> Bool {
        let lower = chunk.lowercased()
        if lower.contains("@") || lower.contains("://") || lower.contains("www.") { return true }
        if lower.hasPrefix("/") || lower.hasPrefix("~") || lower.contains("\\") { return true }
        for tld in [".com", ".ru", ".org", ".net", ".io", ".de", ".ua", ".by", ".me", ".app", ".dev", ".su", ".info"] {
            if let r = lower.range(of: tld) {
                if r.upperBound == lower.endIndex || !isLatin(lower[r.upperBound]) { return true }
            }
        }
        for (a, b) in zip(lower, lower.dropFirst()) {
            if (isLatin(a) && isDigit(b)) || (isDigit(a) && isLatin(b)) { return true }
        }
        return false
    }

    private static func convertRun(_ run: String, _ previousWord: String, _ smartFixes: Bool, _ lexicon: Fixes.Lexicon?) -> String {
        let letters = run.filter(isLatin)
        let pattern: CasePattern
        if letters == letters.lowercased() { pattern = .lower }
        else if letters == letters.uppercased() { pattern = letters.count == 1 ? .title : .upper }
        else if letters.first!.isUppercase, String(letters.dropFirst()) == letters.dropFirst().lowercased() { pattern = .title }
        else { return run }   // iPhone, WiFi, ChatGPT ...

        let lower = Array(run.lowercased().map { isApostrophe($0) ? "'" : $0 })
        var word = transliterate(lower, afterInfinitiveTrigger: infinitiveTriggers.contains(previousWord))
        if smartFixes {
            word = Fixes.apply(word)
            if let lexicon { word = Fixes.repair(word, lexicon: lexicon) }
        }
        switch pattern {
        case .lower: return word
        case .title: return word.prefix(1).uppercased() + word.dropFirst()
        case .upper: return word.uppercased()
        }
    }

    private enum CasePattern { case lower, title, upper }

    // MARK: - Word level

    private static let pairs: [String: Character] = [
        "ya": "я", "yo": "ё", "yu": "ю", "ye": "е",
        "ja": "я", "jo": "ё", "ju": "ю", "je": "е",
        "zh": "ж", "kh": "х", "ts": "ц", "ch": "ч", "sh": "ш",
    ]

    private static let singles: [Character: Character] = [
        "a": "а", "b": "б", "d": "д", "e": "е", "f": "ф", "g": "г", "h": "х", "i": "и", "j": "й",
        "k": "к", "l": "л", "m": "м", "n": "н", "o": "о", "p": "п", "q": "к", "r": "р", "s": "с",
        "t": "т", "u": "у", "v": "в", "w": "в", "z": "з",
    ]

    private static let vowels = Set("аеёиоуыэюя")
    private static let latinConsonants = Set("bcdfghklmnpqrstvwxz")

    /// Prefixes after which `ye/ya/yo` (or an apostrophe) means a hard sign: ob'yekt, pod'ezd, iz'yat.
    private static let strongPrefixes: Set<String> = ["ob", "pod", "ot", "iz", "raz", "nad", "pred", "sub", "mezh", "kontr", "super", "trans"]
    /// One-letter prefixes are only hard before `e`/`ye`: v'ezd, s'ezd (but v'yuga is soft).
    private static let weakPrefixes: Set<String> = ["s", "v"]

    /// Previous words that make a following "-tsya" an infinitive (-ться), not a 3rd person (-тся).
    private static let infinitiveTriggers: Set<String> = [
        "chtoby", "nado", "nuzhno", "mozhno", "pora", "dolzhen", "dolzhna", "dolzhny", "dolzhno",
        "khochu", "hochu", "khochesh", "hochesh", "khochet", "hochet", "khotim", "hotim", "khotite", "hotite", "khotyat", "hotyat",
        "mogu", "mozhesh", "mozhet", "mozhem", "mozhete", "mogut", "nachal", "nachala", "nachali", "nachnu", "stal", "stala", "stali",
        "budu", "budesh", "budet", "budem", "budete", "budut", "lyublyu", "lyubish", "lyubit", "lyubim", "poshel", "poshla", "poydu", "poydem",
    ]

    private static func hardBoundary(prefix: String, rest: String, afterApostrophe: Bool) -> Bool {
        if strongPrefixes.contains(prefix) {
            let triggers = afterApostrophe ? ["ye", "yo", "ya", "yu", "e"] : ["ye", "yo", "ya"]
            return triggers.contains { rest.hasPrefix($0) }
        }
        if weakPrefixes.contains(prefix) {
            return rest.hasPrefix("ye") || (afterApostrophe && rest.hasPrefix("e"))
        }
        return false
    }

    /// `s` is lowercase Latin (apostrophes normalised to '). Returns lowercase Cyrillic.
    private static func transliterate(_ s: [Character], afterInfinitiveTrigger: Bool) -> String {
        let n = s.count
        var out: [Character] = []
        var i = 0

        func starts(_ p: String, _ at: Int) -> Bool {
            let pc = Array(p)
            guard at + pc.count <= n else { return false }
            for k in 0..<pc.count where s[at + k] != pc[k] { return false }
            return true
        }
        func lastIsVowel() -> Bool { out.last.map(vowels.contains) ?? false }
        func lastIsConsonant() -> Bool { out.last.map { !vowels.contains($0) && $0 != "ь" && $0 != "ъ" } ?? false }

        while i < n {
            let c = s[i]

            // soft / hard sign typed explicitly
            if c == "'" {
                if i + 1 < n, s[i + 1] == "'" { out.append("ъ"); i += 2; continue }
                let hard = hardBoundary(prefix: String(s[0..<i]), rest: String(s[(i + 1)...]), afterApostrophe: true)
                out.append(hard ? "ъ" : "ь")
                i += 1
                continue
            }
            if c == "\"" { out.append("ъ"); i += 1; continue }

            // word endings
            if i > 0, n - i == 4, starts("tsya", i) {
                out += Array(afterInfinitiveTrigger ? "ться" : "тся")
                break
            }
            if i > 0, n - i == 2, starts("yi", i), lastIsConsonant() { out += Array("ый"); break }   // krasivyi
            if starts("shch", i) { out.append("щ"); i += 4; continue }

            if i + 1 < n, let cyr = pairs[String([c, s[i + 1]])] {
                if c == "y", "яёе".contains(cyr), i > 0 {
                    let hard = hardBoundary(prefix: String(s[0..<i]), rest: String(s[i...]), afterApostrophe: false)
                    if hard { out.append("ъ") }
                    else if cyr == "е", lastIsConsonant() { out.append("ь") }   // semye -> семье
                }
                if cyr == "ц" {
                    let after: Character? = i + 2 < n ? s[i + 2] : nil
                    // отсюда, отсутствие (but оценка, оцифровать)
                    if i == 1, s[0] == "o", after != "e", after != "i" { out += Array("тс"); i += 2; continue }
                    // богатство, отстой (but немецкий, станция)
                    if i > 0, let a = after, latinConsonants.contains(a), a != "k" { out += Array("тс"); i += 2; continue }
                }
                out.append(cyr)
                i += 2
                continue
            }

            switch c {
            case "c":
                if i + 1 < n, s[i + 1] == "k" { out.append("к"); i += 2; continue }
                let next: Character? = i + 1 < n ? s[i + 1] : nil
                out.append(next == "e" || next == "i" || next == "y" || next == "j" ? "ц" : "к")
            case "x": out += Array("кс")
            case "y": out.append(lastIsVowel() ? "й" : "ы")
            default: out.append(singles[c] ?? c)
            }
            i += 1
        }
        return String(out)
    }

    // MARK: - Character helpers

    private static func isLatin(_ c: Character) -> Bool {
        guard let a = c.asciiValue else { return false }
        return (a >= 65 && a <= 90) || (a >= 97 && a <= 122)
    }

    private static func isDigit(_ c: Character) -> Bool {
        guard let a = c.asciiValue else { return false }
        return a >= 48 && a <= 57
    }

    private static func isApostrophe(_ c: Character) -> Bool {
        c == "'" || c == "\u{2019}" || c == "\u{02BC}" || c == "`" || c == "\u{00B4}"
    }
}
