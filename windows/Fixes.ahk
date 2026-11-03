#Requires AutoHotkey v2.0

; Rule-based repair of the most common transliteration slips: a missing soft sign
; ("pomoch" -> помочь), "eto" -> это, and similar. Port of Sources/Fixes.swift
; (without the macOS dictionary part). Input and output are lowercase Cyrillic words.

class Fixes {
    static Apply(word) {
        if Fixes.words.Has(word)
            return Fixes.words[word]
        w := word

        ; это, этот, экран ... (word-initial "e" is ambiguous, so only known starts)
        isE := Fixes.HasPrefix(w, "ет")
        if !isE {
            for p in Fixes.eInitial {
                if Fixes.HasPrefix(w, p) {
                    isE := true
                    break
                }
            }
        }
        if isE
            w := "э" . SubStr(w, 2)
        ; детский: "tsk" is kept as ц for немецкий, so repair the common word here
        if Fixes.HasPrefix(w, "децк")
            w := "детск" . SubStr(w, 5)

        ; делат -> делать, посмотрет -> посмотреть
        for stem in Fixes.infinitiveStems {
            if Fixes.HasSuffix(w, stem) {
                prefix := SubStr(w, 1, StrLen(w) - StrLen(stem))
                if prefix == "" || Fixes.verbPrefixes.Has(prefix)
                    return w . "ь"
            }
        }

        ; учишся -> учишься
        for suf in ["ешся", "ишся", "ёшся"] {
            if Fixes.HasSuffix(w, suf)
                return SubStr(w, 1, StrLen(w) - 2) . "ься"
        }
        ; можеш -> можешь, говориш -> говоришь
        if !Fixes.noSoftSign.Has(w) {
            for suf in ["еш", "иш", "ёш"] {
                if Fixes.HasSuffix(w, suf)
                    return w . "ь"
            }
        }
        ; двадцат -> двадцать, возможност -> возможность, учител -> учитель,
        ; рассказыват -> рассказывать, пользуюс -> пользуюсь
        for suf in Fixes.softSuffixes {
            if Fixes.HasSuffix(w, suf)
                return w . "ь"
        }
        return w
    }

    static HasPrefix(s, p) {
        return SubStr(s, 1, StrLen(p)) == p
    }

    static HasSuffix(s, p) {
        return StrLen(s) >= StrLen(p) && SubStr(s, -StrLen(p)) == p
    }

    ; Endings that are (almost) never valid without a soft sign.
    static softSuffixes := ["дцат", "ност", "ател", "ител", "ыват", "иват", "ироват", "юс"]

    ; Names / loanwords that really end in -еш / -иш.
    static noSoftSign := TranslitSet("миш гриш леш киш кеш флеш меш")

    static eInitial := StrSplit("екран екзам експ екстр економ ефек ефир емоц енерг елект елемент ентуз епох епиз ескиз естет ешелон", " ")

    static verbPrefixes := TranslitSet("по с за на при про вы у от под об пере раз до недо пред со подо обо")

    static infinitiveStems := StrSplit("делат работат думат читат писат знат ждат хотет смотрет видет слышат понимат начинат играт гулят сказат показат умет успет искат купат помогат отдыхат пытат решат получат встречат отвечат", " ")

    ; Naive transliteration -> correct spelling. Only keys that are not common words themselves.
    static words := TranslitPairs("ест=есть "
        . "помоч=помочь моч=мочь ноч=ночь доч=дочь реч=речь печ=печь проч=прочь "
        . "помощ=помощь мощ=мощь вещ=вещь жизн=жизнь любов=любовь кров=кровь "
        . "двер=дверь тетрад=тетрадь ден=день осен=осень очеред=очередь "
        . "пользовател=пользователь "
        . "толко=только сколко=сколько несколко=несколько болше=больше болшой=большой "
        . "денги=деньги друзя=друзья статя=статья очен=очень "
        . "пят=пять шест=шесть сем=семь восем=восемь девят=девять десят=десять "
        . "пятдесят=пятьдесят шестдесят=шестьдесят семдесят=семьдесят восемдесят=восемьдесят "
        . "пятсот=пятьсот шестсот=шестьсот семсот=семьсот восемсот=восемьсот "
        . "январ=январь феврал=февраль апрел=апрель июн=июнь июл=июль "
        . "сентябр=сентябрь октябр=октябрь ноябр=ноябрь декабр=декабрь "
        . "игор=игорь олга=ольга наталя=наталья татяна=татьяна даря=дарья "
        . "въетнам=вьетнам ")
}
