#Requires AutoHotkey v2.0
#Include Converter.ahk
#Include Fixes.ahk

; Run: double-click this file (or `AutoHotkey64.exe Tests.ahk`). A message box shows the result.
; With the argument /quiet there is no window: the result goes to tests-result.txt and the exit code is 0 / 1.
; The checks are generated from Tests/main.swift (without the macOS dictionary part).

failed := []
total := 0

Check(input, expected, fixes := true) {
    global failed, total
    total += 1
    actual := Translit.Convert(input, fixes)
    if actual !== expected
        failed.Push('"' input '" -> "' actual '", expected "' expected '"')
}

; Examples from the task
Check("privet kak dela", "привет как дела")
Check("ya hochu chtoby eto rabotalo", "я хочу чтобы это работало")
Check("mozhesh mne pomoch", "можешь мне помочь")
Check("u menya est vopros", "у меня есть вопрос")
Check("segodnya ya rabotayu", "сегодня я работаю")

; Digraphs
Check("shchuka", "щука")
Check("ishchu", "ищу")
Check("zhizn", "жизнь")
Check("chay", "чай")
Check("tsvet", "цвет")
Check("khorosho", "хорошо")
Check("horosho", "хорошо")
Check("yozh", "ёж")
Check("lyublyu", "люблю")
Check("stantsiya", "станция")
Check("scena", "сцена")
Check("schitat", "считать")
Check("taxi", "такси")
Check("centr", "центр")
Check("cirk", "цирк")
Check("ya", "я")
Check("yu", "ю")

; y / j / iy endings
Check("seychas", "сейчас")
Check("moy", "мой")
Check("krasivyy", "красивый")
Check("krasivyi", "красивый")
Check("dobryj", "добрый")
Check("pozhaluysta", "пожалуйста")
Check("zdravstvuyte", "здравствуйте")
Check("Dmitriy", "Дмитрий")
Check("Yuriy", "Юрий")
Check("chtoby", "чтобы")

; Case
Check("PRIVET", "ПРИВЕТ")
Check("Privet, Mir!", "Привет, Мир!")
Check("Yolka", "Ёлка")
Check("Shchuka", "Щука")
Check("SHCHUKA", "ЩУКА")
Check("Ya", "Я")
Check("YA", "Я")

; Soft and hard signs
Check("sem'ya", "семья")
Check("mat'", "мать")
Check("semye", "семье")
Check("ob'yekt", "объект")
Check("obyekt", "объект")
Check("obyasnit'", "объяснить")
Check("pod'ezd", "подъезд")
Check("vyezd", "въезд")
Check("ob''yem", "объем")
Check("ob`"yem", "объем")

; -tsya
Check("uchitsya", "учится")
Check("kazhetsya", "кажется")
Check("ya khochu uchitsya", "я хочу учиться")
Check("nuzhno nauchitsya", "нужно научиться")
Check("on budet uchitsya", "он будет учиться")

; ts between letters
Check("detskiy", "детский")
Check("nemetskiy", "немецкий")
Check("otsutstvie", "отсутствие")
Check("otsyuda", "отсюда")
Check("otsenka", "оценка")
Check("bogatstvo", "богатство")

; Smart fixes
Check("delat", "делать")
Check("posmotret", "посмотреть")
Check("napisat", "написать")
Check("rasskazyvat", "рассказывать")
Check("dvadtsat", "двадцать")
Check("vozmozhnost", "возможность")
Check("uchitel", "учитель")
Check("noch", "ночь")
Check("noyabr", "ноябрь")
Check("Igor", "Игорь")
Check("Olga", "Ольга")
Check("hochesh", "хочешь")
Check("uchishsya", "учишься")
Check("tolko", "только")
Check("ochen", "очень")
Check("eto", "это")
Check("Ekaterina", "Екатерина")
Check("delat", "делат", false)

; Leave alone
Check("iPhone", "iPhone")
Check("ChatGPT", "ChatGPT")
Check("name@mail.com", "name@mail.com")
Check("https://ya.ru/x", "https://ya.ru/x")
Check("ya.ru", "ya.ru")
Check("mp3", "mp3")
Check("/start", "/start")
Check("'privet'", "'привет'")
Check("`"privet`"", "`"привет`"")
Check("‘privet’", "‘привет’")
Check("Привет, kak dela?", "Привет, как дела?")
Check("привет", "привет")
Check("2024", "2024")
Check("", "")
Check("   ", "   ")
Check("privet`nkak  dela`t?", "привет`nкак  дела`t?")
Check("ya 5 minut", "я 5 минут")
Check("privet 😀 kak dela", "привет 😀 как дела")

if failed.Length = 0 {
    msg := "OK: " total " checks passed"
} else {
    msg := "FAILED: " failed.Length " of " total "`n`n"
    for line in failed
        msg .= line "`n"
}
if A_Args.Length > 0 && A_Args[1] = "/quiet" {
    ; no window: write the result next to this script (used by AI assistants and scripts)
    resultFile := A_ScriptDir "\tests-result.txt"
    try FileDelete resultFile
    FileAppend msg "`n", resultFile, "UTF-8"
} else {
    MsgBox msg
}
ExitApp(failed.Length > 0 ? 1 : 0)
