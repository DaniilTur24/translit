import Foundation

// Run with ./test.sh — compiles Sources/Translit.swift + Sources/Fixes.swift with this file.

var failed = 0
var total = 0

func check(_ input: String, _ expected: String, fixes: Bool = true, line: Int = #line) {
    total += 1
    let actual = Translit.convert(input, smartFixes: fixes)
    if actual != expected {
        failed += 1
        print("FAIL (line \(line)): \(input.debugDescription) -> \(actual.debugDescription), expected \(expected.debugDescription)")
    }
}

// Examples from the task
check("privet kak dela", "привет как дела")
check("ya hochu chtoby eto rabotalo", "я хочу чтобы это работало")
check("mozhesh mne pomoch", "можешь мне помочь")
check("u menya est vopros", "у меня есть вопрос")
check("segodnya ya rabotayu", "сегодня я работаю")

// Digraphs
check("shchuka", "щука")
check("ishchu", "ищу")
check("zhizn", "жизнь")
check("chay", "чай")
check("tsvet", "цвет")
check("khorosho", "хорошо")
check("horosho", "хорошо")
check("yozh", "ёж")
check("lyublyu", "люблю")
check("stantsiya", "станция")
check("scena", "сцена")
check("schitat", "считать")
check("taxi", "такси")
check("centr", "центр")
check("cirk", "цирк")
check("ya", "я")
check("yu", "ю")

// y / j / iy endings
check("seychas", "сейчас")
check("moy", "мой")
check("krasivyy", "красивый")
check("krasivyi", "красивый")
check("dobryj", "добрый")
check("pozhaluysta", "пожалуйста")
check("zdravstvuyte", "здравствуйте")
check("Dmitriy", "Дмитрий")
check("Yuriy", "Юрий")
check("chtoby", "чтобы")

// Case
check("PRIVET", "ПРИВЕТ")
check("Privet, Mir!", "Привет, Мир!")
check("Yolka", "Ёлка")
check("Shchuka", "Щука")
check("SHCHUKA", "ЩУКА")
check("Ya", "Я")
check("YA", "Я")

// Soft and hard signs
check("sem'ya", "семья")
check("mat'", "мать")
check("semye", "семье")
check("ob'yekt", "объект")
check("obyekt", "объект")
check("obyasnit'", "объяснить")
check("pod'ezd", "подъезд")
check("vyezd", "въезд")
check("ob''yem", "объем")
check("ob\"yem", "объем")

// -tsya
check("uchitsya", "учится")
check("kazhetsya", "кажется")
check("ya khochu uchitsya", "я хочу учиться")
check("nuzhno nauchitsya", "нужно научиться")
check("on budet uchitsya", "он будет учиться")

// ts between letters
check("detskiy", "детский")
check("nemetskiy", "немецкий")
check("otsutstvie", "отсутствие")
check("otsyuda", "отсюда")
check("otsenka", "оценка")
check("bogatstvo", "богатство")

// Smart fixes
check("delat", "делать")
check("posmotret", "посмотреть")
check("napisat", "написать")
check("rasskazyvat", "рассказывать")
check("dvadtsat", "двадцать")
check("vozmozhnost", "возможность")
check("uchitel", "учитель")
check("noch", "ночь")
check("noyabr", "ноябрь")
check("Igor", "Игорь")
check("Olga", "Ольга")
check("hochesh", "хочешь")
check("uchishsya", "учишься")
check("tolko", "только")
check("ochen", "очень")
check("eto", "это")
check("Ekaterina", "Екатерина")
check("delat", "делат", fixes: false)

// Dictionary repair: a tiny fake dictionary stands in for the macOS one
let fakeDictionary: Set<String> = ["советовать", "только", "это", "эхо", "красивый", "привет", "как", "дела", "тест", "площад", "весь", "вес", "ответ", "ответь"]
let fakeCompletions = ["площад": ["площадь", "площадка"], "вес": ["весь", "вес"], "ответ": ["ответь", "ответы", "ответ"], "тест": ["тест", "тестовый"]]
let fakeLexicon = Fixes.Lexicon(isWord: { fakeDictionary.contains($0) }, completions: { fakeCompletions[$0] ?? [] })
func checkDict(_ input: String, _ expected: String, line: Int = #line) {
    total += 1
    let actual = Translit.convert(input, lexicon: fakeLexicon)
    if actual != expected {
        failed += 1
        print("FAIL (line \(line)): \(input.debugDescription) -> \(actual.debugDescription), expected \(expected.debugDescription)")
    }
}
checkDict("sovetovat", "советовать")      // not in the rules, found by the dictionary
checkDict("Sovetovat", "Советовать")
checkDict("eho", "эхо")
checkDict("ploshchad", "площадь")          // the dictionary accepts площад, but its top completion is площадь
checkDict("ves", "вес")                   // вес lists itself among the completions: stays вес, not весь
checkDict("otvet", "ответ")               // same for ответ, not ответь
checkDict("test", "тест")                 // completions start with the word itself: unchanged
checkDict("privet kak dela", "привет как дела")   // valid words stay as they are
checkDict("xyzzy", "ксыззы")            // nothing fits: plain transliteration stays

// Leave alone
check("iPhone", "iPhone")
check("ChatGPT", "ChatGPT")
check("name@mail.com", "name@mail.com")
check("https://ya.ru/x", "https://ya.ru/x")
check("ya.ru", "ya.ru")
check("mp3", "mp3")
check("/start", "/start")
check("'privet'", "'привет'")
check("\"privet\"", "\"привет\"")
check("\u{2018}privet\u{2019}", "\u{2018}привет\u{2019}")
check("Привет, kak dela?", "Привет, как дела?")
check("привет", "привет")
check("2024", "2024")
check("", "")
check("   ", "   ")
check("privet\nkak  dela\t?", "привет\nкак  дела\t?")
check("ya 5 minut", "я 5 минут")
check("privet 😀 kak dela", "привет 😀 как дела")

print(failed == 0 ? "OK: \(total) checks passed" : "FAILED: \(failed) of \(total)")
exit(failed == 0 ? 0 : 1)
