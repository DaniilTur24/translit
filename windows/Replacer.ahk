#Requires AutoHotkey v2.0

; Replaces the current selection in the active window with Translit.Convert(selection).
;
; Works through the clipboard (Ctrl+C, Ctrl+V) because that behaves the same in browsers,
; Electron apps, Telegram and native fields. The whole clipboard (every format) is saved
; and put back afterwards. Nothing is logged or stored.

class Replacer {
    ; Time the target app gets to process the paste before the clipboard is restored (ms).
    static pasteSettleTime := 300

    static busy := false

    static Run() {
        if Replacer.busy
            return
        Replacer.busy := true
        try {
            Replacer.Perform()
        } finally {
            Replacer.busy := false
        }
    }

    static Perform() {
        if Replacer.FocusedIsPassword() {
            SoundBeep()
            return
        }

        ; The hotkey's own modifiers are still held when it fires; wait so that
        ; Ctrl+C is not seen as Ctrl+Alt+C.
        KeyWait "Ctrl", "T0.8"
        KeyWait "Alt", "T0.8"
        KeyWait "Shift", "T0.8"

        saved := ClipboardAll()
        A_Clipboard := ""
        Send "^c"
        ; Nothing selected -> the app copies nothing -> there is nothing to replace.
        if !ClipWait(0.5) {
            A_Clipboard := saved
            return
        }
        Sleep 30

        selected := A_Clipboard
        if selected = "" {
            A_Clipboard := saved
            return
        }
        converted := Translit.Convert(selected)
        if converted == selected {
            A_Clipboard := saved
            return
        }

        A_Clipboard := converted
        if !ClipWait(0.5) {
            A_Clipboard := saved
            return
        }
        Send "^v"
        Sleep Replacer.pasteSettleTime
        A_Clipboard := saved
    }

    ; Classic Windows edit boxes can be password fields (ES_PASSWORD = 0x20). Browsers and
    ; other custom fields do not expose this, so those are NOT detected.
    static FocusedIsPassword() {
        try {
            ctl := ControlGetFocus("A")
            if !ctl
                return false
            if WinGetClass("ahk_id " ctl) !== "Edit"
                return false
            return (ControlGetStyle(ctl, "A") & 0x20) != 0
        } catch {
            return false
        }
    }
}
