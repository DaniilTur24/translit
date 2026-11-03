#Requires AutoHotkey v2.0

; Russian phonetic transliteration (Latin -> Cyrillic). Port of Sources/Translit.swift.
; Pure functions: no hotkeys, no clipboard, no state outside Translit.Convert.

; "a=b c=d" -> Map("a", "b", "c", "d"). Tokens are separated by spaces or newlines.
TranslitPairs(text) {
    m := Map()
    for tok in StrSplit(text, [" ", "`n", "`r", "`t"]) {
        if tok = ""
            continue
        parts := StrSplit(tok, "=")
        m[parts[1]] := parts[2]
    }
    return m
}

; "a b c" -> Map("a", true, "b", true, "c", true)
TranslitSet(text) {
    m := Map()
    for tok in StrSplit(text, [" ", "`n", "`r", "`t"]) {
        if tok != ""
            m[tok] := true
    }
    return m
}

class Translit {
    ; Converts every Latin word in text; whitespace, punctuation, digits, Cyrillic, URLs,
    ; e-mails and camelCase words are left untouched.
    static Convert(text, smartFixes := true) {
        if text = ""
            return ""
        result := ""
        state := {previousWord: "", openQuote: false}
        chunk := ""
        for ch in StrSplit(text) {
            if Translit.IsWs(ch) {
                result .= Translit.ConvertChunk(chunk, state, smartFixes)
                chunk := ""
                result .= ch
            } else {
                chunk .= ch
            }
        }
        result .= Translit.ConvertChunk(chunk, state, smartFixes)
        return result
    }

    ; ---- Text level ----

    static ConvertChunk(chunk, state, smartFixes) {
        if chunk = ""
            return ""
        if Translit.ShouldLeaveAlone(chunk) {
            state.previousWord := ""
            return chunk
        }
        c := StrSplit(chunk)
        n := c.Length
        out := ""
        i := 1
        while i <= n {
            if !Translit.IsLatin(c[i]) {
                ; a ' right before a word is an opening quote, not a soft sign
                if (Translit.IsApostrophe(c[i]) || c[i] == Chr(0x2018)) && i + 1 <= n && Translit.IsLatin(c[i + 1])
                    state.openQuote := true
                out .= c[i]
                i += 1
                continue
            }
            j := i
            while j <= n {
                x := c[j]
                if Translit.IsLatin(x) {
                    j += 1
                    continue
                }
                nextCh := (j + 1 <= n) ? c[j + 1] : ""
                if Translit.IsApostrophe(x) {
                    if nextCh != "" && Translit.IsLatin(nextCh) {            ; sem'ya
                        j += 1
                        continue
                    }
                    if nextCh != "" && Translit.IsApostrophe(nextCh) && j + 2 <= n && Translit.IsLatin(c[j + 2]) {   ; ob''yem
                        j += 2
                        continue
                    }
                    if state.openQuote            ; closing quote
                        state.openQuote := false
                    else
                        j += 1                    ; mat'
                    break
                }
                if x == '"' && nextCh != "" && Translit.IsLatin(nextCh) {    ; ob"ekt
                    j += 1
                    continue
                }
                break
            }
            runText := ""
            k := i
            while k < j {
                runText .= c[k]
                k += 1
            }
            out .= Translit.ConvertRun(runText, state.previousWord, smartFixes)
            state.previousWord := Translit.LatinOnly(StrLower(runText))
            i := j
        }
        return out
    }

    ; Tokens that look like URLs, e-mails, paths or codes (mp3, b2b) must not be transliterated.
    static ShouldLeaveAlone(chunk) {
        lower := StrLower(chunk)
        if InStr(lower, "@") || InStr(lower, "://") || InStr(lower, "www.")
            return true
        if SubStr(lower, 1, 1) == "/" || SubStr(lower, 1, 1) == "~" || InStr(lower, "\")
            return true
        len := StrLen(lower)
        for tld in [".com", ".ru", ".org", ".net", ".io", ".de", ".ua", ".by", ".me", ".app", ".dev", ".su", ".info"] {
            pos := InStr(lower, tld)
            if pos {
                after := pos + StrLen(tld)
                if after > len || !Translit.IsLatin(SubStr(lower, after, 1))
                    return true
            }
        }
        chars := StrSplit(lower)
        k := 2
        while k <= chars.Length {
            a := chars[k - 1]
            b := chars[k]
            if (Translit.IsLatin(a) && Translit.IsDigit(b)) || (Translit.IsDigit(a) && Translit.IsLatin(b))
                return true
            k += 1
        }
        return false
    }

    static ConvertRun(runText, previousWord, smartFixes) {
        letters := Translit.LatinOnly(runText)
        if letters == StrLower(letters) {
            pattern := "lower"
        } else if letters == StrUpper(letters) {
            pattern := (StrLen(letters) == 1) ? "title" : "upper"
        } else if Translit.IsUpperLatin(SubStr(letters, 1, 1)) && SubStr(letters, 2) == StrLower(SubStr(letters, 2)) {
            pattern := "title"
        } else {
            return runText   ; iPhone, WiFi, ChatGPT ...
        }

        lowerRun := ""
        for ch in StrSplit(StrLower(runText))
            lowerRun .= Translit.IsApostrophe(ch) ? "'" : ch
        word := Translit.Transliterate(lowerRun, Translit.infinitiveTriggers.Has(previousWord))
        if smartFixes
            word := Fixes.Apply(word)
        if pattern == "lower"
            return word
        if pattern == "title"
            return StrUpper(SubStr(word, 1, 1)) . SubStr(word, 2)
        return StrUpper(word)
    }

    ; ---- Word level ----

    static pairs := TranslitPairs("ya=я yo=ё yu=ю ye=е ja=я jo=ё ju=ю je=е zh=ж kh=х ts=ц ch=ч sh=ш")

    static singles := TranslitPairs("a=а b=б d=д e=е f=ф g=г h=х i=и j=й k=к l=л m=м n=н o=о p=п q=к r=р s=с t=т u=у v=в w=в z=з")

    static vowels := "аеёиоуыэюя"
    static latinConsonants := "bcdfghklmnpqrstvwxz"

    ; Prefixes after which ye/ya/yo (or an apostrophe) means a hard sign: ob'yekt, pod'ezd, iz'yat.
    static strongPrefixes := TranslitSet("ob pod ot iz raz nad pred sub mezh kontr super trans")
    ; One-letter prefixes are only hard before e/ye: v'ezd, s'ezd (but v'yuga is soft).
    static weakPrefixes := TranslitSet("s v")

    ; Previous words that make a following "-tsya" an infinitive (-ться), not a 3rd person (-тся).
    static infinitiveTriggers := TranslitSet("chtoby nado nuzhno mozhno pora dolzhen dolzhna dolzhny dolzhno "
        . "khochu hochu khochesh hochesh khochet hochet khotim hotim khotite hotite khotyat hotyat "
        . "mogu mozhesh mozhet mozhem mozhete mogut nachal nachala nachali nachnu stal stala stali "
        . "budu budesh budet budem budete budut lyublyu lyubish lyubit lyubim poshel poshla poydu poydem ")

    static HardBoundary(prefix, rest, afterApostrophe) {
        if Translit.strongPrefixes.Has(prefix) {
            triggers := afterApostrophe ? ["ye", "yo", "ya", "yu", "e"] : ["ye", "yo", "ya"]
            for t in triggers {
                if SubStr(rest, 1, StrLen(t)) == t
                    return true
            }
            return false
        }
        if Translit.weakPrefixes.Has(prefix)
            return SubStr(rest, 1, 2) == "ye" || (afterApostrophe && SubStr(rest, 1, 1) == "e")
        return false
    }

    ; True when the chars of s starting at index `at` (1-based) spell p.
    static Starts(s, p, at) {
        pc := StrSplit(p)
        if at + pc.Length - 1 > s.Length
            return false
        k := 1
        while k <= pc.Length {
            if s[at + k - 1] !== pc[k]
                return false
            k += 1
        }
        return true
    }

    static LastIsVowel(out) {
        return out != "" && InStr(Translit.vowels, SubStr(out, -1), true) > 0
    }

    static LastIsConsonant(out) {
        if out = ""
            return false
        last := SubStr(out, -1)
        return InStr(Translit.vowels, last, true) = 0 && last !== "ь" && last !== "ъ"
    }

    ; s is lowercase Latin (apostrophes normalised to '). Returns lowercase Cyrillic.
    static Transliterate(lowerWord, afterInfinitiveTrigger) {
        s := StrSplit(lowerWord)
        n := s.Length
        out := ""
        i := 1

        while i <= n {
            c := s[i]

            ; soft / hard sign typed explicitly
            if c == "'" {
                if i + 1 <= n && s[i + 1] == "'" {
                    out .= "ъ"
                    i += 2
                    continue
                }
                hard := Translit.HardBoundary(SubStr(lowerWord, 1, i - 1), SubStr(lowerWord, i + 1), true)
                out .= hard ? "ъ" : "ь"
                i += 1
                continue
            }
            if c == '"' {
                out .= "ъ"
                i += 1
                continue
            }

            ; word endings
            if i > 1 && n - i + 1 == 4 && Translit.Starts(s, "tsya", i) {
                out .= afterInfinitiveTrigger ? "ться" : "тся"
                break
            }
            if i > 1 && n - i + 1 == 2 && Translit.Starts(s, "yi", i) && Translit.LastIsConsonant(out) {   ; krasivyi
                out .= "ый"
                break
            }
            if Translit.Starts(s, "shch", i) {
                out .= "щ"
                i += 4
                continue
            }

            if i + 1 <= n {
                pair := c . s[i + 1]
                if Translit.pairs.Has(pair) {
                    cyr := Translit.pairs[pair]
                    if c == "y" && InStr("яёе", cyr, true) && i > 1 {
                        hard := Translit.HardBoundary(SubStr(lowerWord, 1, i - 1), SubStr(lowerWord, i), false)
                        if hard
                            out .= "ъ"
                        else if cyr == "е" && Translit.LastIsConsonant(out)   ; semye -> семье
                            out .= "ь"
                    }
                    if cyr == "ц" {
                        after := (i + 2 <= n) ? s[i + 2] : ""
                        ; отсюда, отсутствие (but оценка, оцифровать)
                        if i == 2 && s[1] == "o" && after !== "e" && after !== "i" {
                            out .= "тс"
                            i += 2
                            continue
                        }
                        ; богатство, отстой (but немецкий, станция)
                        if i > 1 && after != "" && InStr(Translit.latinConsonants, after, true) && after !== "k" {
                            out .= "тс"
                            i += 2
                            continue
                        }
                    }
                    out .= cyr
                    i += 2
                    continue
                }
            }

            if c == "c" {
                if i + 1 <= n && s[i + 1] == "k" {
                    out .= "к"
                    i += 2
                    continue
                }
                nextCh := (i + 1 <= n) ? s[i + 1] : ""
                out .= (nextCh == "e" || nextCh == "i" || nextCh == "y" || nextCh == "j") ? "ц" : "к"
            } else if c == "x" {
                out .= "кс"
            } else if c == "y" {
                out .= Translit.LastIsVowel(out) ? "й" : "ы"
            } else {
                out .= Translit.singles.Has(c) ? Translit.singles[c] : c
            }
            i += 1
        }
        return out
    }

    ; ---- Character helpers ----

    static LatinOnly(str) {
        r := ""
        for ch in StrSplit(str) {
            if Translit.IsLatin(ch)
                r .= ch
        }
        return r
    }

    static IsLatin(ch) {
        o := Ord(ch)
        return (o >= 65 && o <= 90) || (o >= 97 && o <= 122)
    }

    static IsUpperLatin(ch) {
        o := Ord(ch)
        return o >= 65 && o <= 90
    }

    static IsDigit(ch) {
        o := Ord(ch)
        return o >= 48 && o <= 57
    }

    ; ' ’ ʼ ` ´
    static IsApostrophe(ch) {
        o := Ord(ch)
        return o == 39 || o == 0x2019 || o == 0x2BC || o == 96 || o == 0xB4
    }

    static IsWs(ch) {
        o := Ord(ch)
        return (o >= 9 && o <= 13) || o == 32 || o == 0x85 || o == 0xA0 || o == 0x1680
            || (o >= 0x2000 && o <= 0x200A) || o == 0x2028 || o == 0x2029 || o == 0x202F || o == 0x205F || o == 0x3000
    }
}
