#Requires AutoHotkey v2.0
#SingleInstance Force
Persistent

#Include Converter.ahk
#Include Fixes.ahk
#Include Replacer.ahk

; Hotkey: Ctrl + Alt + R. sc013 is the physical R key, so it works with any keyboard layout
; (also while the Russian layout is active). To change it, replace ^!sc013 below:
; ^ Ctrl, ! Alt, + Shift, # Win; for example ^+sc013 is Ctrl + Shift + R.
Hotkey "^!sc013", (*) => Replacer.Run()

; Tray icon: the only UI. Right click -> autostart on/off, exit.
autostartLink := A_Startup "\Translit.lnk"
A_IconTip := "Translit: select text, press Ctrl+Alt+R"
tray := A_TrayMenu
tray.Delete()
tray.Add("Запускать при входе в Windows", ToggleAutostart)
tray.Add("Выход", (*) => ExitApp())
if FileExist(autostartLink)
    tray.Check("Запускать при входе в Windows")

ToggleAutostart(itemName, *) {
    global autostartLink, tray
    if FileExist(autostartLink) {
        FileDelete autostartLink
        tray.Uncheck(itemName)
    } else {
        FileCreateShortcut A_AhkPath, autostartLink, A_ScriptDir, '"' A_ScriptFullPath '"'
        tray.Check(itemName)
    }
}
