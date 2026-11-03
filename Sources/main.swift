import AppKit
import Carbon.HIToolbox

// Hotkey: Control + Option + R. Change here (key codes are physical positions: R is the same on QWERTZ).
let hotKeyCode = UInt32(kVK_ANSI_R)
let hotKeyModifiers = UInt32(controlKey | optionKey)

let replacer = SelectionReplacer()

let app = NSApplication.shared
app.setActivationPolicy(.accessory)   // no Dock icon, no menu bar, no windows

var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
InstallEventHandler(GetApplicationEventTarget(), { _, _, _ in
    replacer.run { Translit.convert($0) }
    return noErr
}, 1, &eventType, nil, nil)

var hotKeyRef: EventHotKeyRef?
let hotKeyID = EventHotKeyID(signature: OSType(0x54524E53), id: 1)   // 'TRNS'
let status = RegisterEventHotKey(hotKeyCode, hotKeyModifiers, hotKeyID, GetApplicationEventTarget(), 0, &hotKeyRef)
guard status == noErr else {
    FileHandle.standardError.write(Data("Translit: cannot register hotkey (status \(status)); is it taken by another app?\n".utf8))
    exit(0)
}

// Ask for the Accessibility permission up front, so the first hotkey press just works.
_ = AXIsProcessTrustedWithOptions(["AXTrustedCheckOptionPrompt": true] as CFDictionary)

app.run()
