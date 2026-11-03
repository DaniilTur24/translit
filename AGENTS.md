# Translit: instructions for an AI assistant

Translit is a tiny offline hotkey tool: select Russian text typed in Latin letters (`privet kak dela`), press the hotkey, and it becomes Cyrillic (`привет как дела`) in place. macOS (Swift) and Windows (AutoHotkey v2). MIT licensed, everything runs locally.

The most likely task: **a person pasted this repository link and asked you to clone it and help them set it up.** They may not be technical. Read this whole file, then guide them.

## How to behave

- Reply in the person's language (probably Russian). Be friendly and short. Go **one step at a time**, say in a sentence what you are about to do and why, then do it. No walls of text, no jargon.
- **Ask for a clear yes before** installing anything (Xcode command line tools, AutoHotkey) and before running `./install.sh`. Say what it touches (see below).
- The permission prompt (macOS Accessibility) must be clicked **by the person**. You cannot and must not do it for them. Never ask for their password.
- Do not push to this repository, do not edit files outside the project folder except what the install scripts do, and do not change the hotkey unless asked.
- If something fails, show the real error, say what you think it means, and fix it step by step. Do not claim it works until the final check below succeeded.

## Step 0: which system?

Run `uname -s` (macOS prints `Darwin`) or check for Windows (`$env:OS` is `Windows_NT`). Linux is not supported: say so kindly and stop.

## macOS (12 or newer)

What `./install.sh` does (tell the person first): builds one small app, copies it to `~/Applications/Translit.app`, adds a login item `~/Library/LaunchAgents/local.translit.plist` and a log `~/Library/Logs/Translit.log`. No sudo, nothing outside the home folder, no network.

1. **Build tools.** Run `swiftc --version`. If it is missing, ask permission and run `xcode-select --install` (a system dialog opens, about 1 GB, the person clicks Install and waits). Check again afterwards.
2. **Tests.** Run `./test.sh`. Expected last line: `OK: <number> checks passed`. If not, show the output and stop.
3. **Install.** After a clear yes, run `./install.sh`.
4. **Permission (the person does this).** macOS shows a dialog that Translit wants to control the computer. Tell them to click "Open System Settings" and switch **Translit** on under *Privacy & Security → Accessibility* (the menu names are localised: German *Datenschutz & Sicherheit → Bedienungshilfen*, Russian *Конфиденциальность и безопасность → Универсальный доступ*). If no dialog appears, they add `~/Applications/Translit.app` with the **+** button.
5. **Final check.** Confirm the app runs: `launchctl print gui/$(id -u)/local.translit | grep -E "state|pid"`. Then ask the person to open Notes (or any text field), type `privet kak dela`, select it and press **Control + Option + R**. It must become `привет как дела`. Only then tell them it works.

Using it: write Latin text, select it, press Control + Option + R. Nothing selected means nothing happens. Hints for the person: `'` gives ь (`mat'` → мать), `j` or `y` after a vowel gives й (`moy` → мой). More in [README.md](README.md).

### macOS troubleshooting

| Symptom | Cause and fix |
|---|---|
| Beeps, nothing changes | No Accessibility permission, or the focus is in a password field, or Secure Keyboard Entry is on (e.g. in Terminal). |
| Permission is on in Settings but the dialog keeps appearing or the hotkey beeps (typical after reinstalling) | The ad-hoc signature changed, so the old entry no longer matches. Run `tccutil reset Accessibility local.translit`, then `launchctl kickstart -k gui/$(id -u)/local.translit`, and have the person switch Translit on again. |
| Hotkey does nothing, log says it cannot register | Another app uses Control+Option+R. Change `hotKeyCode` / `hotKeyModifiers` at the top of `Sources/main.swift`, then `./install.sh` (and redo the permission fix above). |
| An old clipboard item gets pasted | The target app is slow. Increase `pasteSettleTime` in `Sources/SelectionReplacer.swift`, reinstall. |
| A word is converted wrongly | Add it to `Fixes.words` in `Sources/Fixes.swift`, add a check to `Tests/main.swift`, run `./test.sh`, reinstall. |

Stop until next login: `launchctl bootout gui/$(id -u)/local.translit`. Remove everything: `./uninstall.sh`.

## Windows (experimental)

The Windows version is newer and less tested than the Mac one. Say so, and if something breaks, treat it as a bug to fix together, not as the person's mistake. See [windows/README.md](windows/README.md).

1. **AutoHotkey v2.** Check for `C:\Program Files\AutoHotkey\v2\AutoHotkey64.exe` (or `Get-Command AutoHotkey64`). If missing, ask permission and run `winget install --id AutoHotkey.AutoHotkey`. It must be **v2**, not v1.
2. **Tests (quiet mode).** From the repository folder run `& "$env:ProgramFiles\AutoHotkey\v2\AutoHotkey64.exe" windows\Tests.ahk /quiet`, wait for it to finish, then read `windows\tests-result.txt`. Expected: `OK: 96 checks passed`. A script error dialog or `FAILED` means a bug in this experimental version: show the text to the person and fix it together.
3. **Start.** Run `windows\Translit.ahk` (double-click or `Start-Process`). An AutoHotkey icon appears in the tray (maybe under the ^ arrow).
4. **Autostart (the person does this).** Right-click the tray icon → *Запускать при входе в Windows*.
5. **Final check.** Ask them to type `privet kak dela` in Notepad, select it and press **Ctrl + Alt + R**.

Known limits on Windows: no system dictionary (fewer automatic repairs), password fields are detected only in classic windows (not in browsers), and windows running as administrator need Translit to run as administrator too.

## For contributors

- Layout: `Sources/Translit.swift` (converter), `Sources/Fixes.swift` (rules and dictionary repair), `Sources/SelectionReplacer.swift` (clipboard replace), `Sources/main.swift` (hotkey); the Windows port lives in `windows/` and mirrors the converter and the rule-based fixes.
- Run `./test.sh` after every change to the converter. Keep `windows/*.ahk` in step with the Swift files, and keep `windows/Tests.ahk` equal to the non-dictionary checks in `Tests/main.swift`.
- Privacy rules of the project: nothing is logged, stored or sent anywhere; the clipboard is restored after every use.
