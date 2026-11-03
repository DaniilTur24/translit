import AppKit
import Carbon.HIToolbox

// Hotkey: Control + Option + R. Change here (key codes are physical positions: R is the same on QWERTZ).
let hotKeyCode = UInt32(kVK_ANSI_R)
let hotKeyModifiers = UInt32(controlKey | optionKey)

let replacer = SelectionReplacer()

// macOS ships a Russian spelling dictionary: used offline to repair words the rules missed (no download).
let speller = NSSpellChecker.shared
let russianLexicon: Fixes.Lexicon? = speller.availableLanguages.contains { $0.hasPrefix("ru") }
    ? Fixes.Lexicon(
        isWord: { word in
            onMain { speller.checkSpelling(of: word, startingAt: 0, language: "ru", wrap: false,
                                           inSpellDocumentWithTag: 0, wordCount: nil).location == NSNotFound }
        },
        completions: { word in
            onMain { speller.completions(forPartialWordRange: NSRange(location: 0, length: word.utf16.count), in: word,
                                         language: "ru", inSpellDocumentWithTag: 0) ?? [] }
        })
    : nil

/// The replacer works off the main thread, the spell checker wants the main one.
func onMain<T>(_ work: () -> T) -> T {
    Thread.isMainThread ? work() : DispatchQueue.main.sync(execute: work)
}

let app = NSApplication.shared
app.setActivationPolicy(.accessory)   // no Dock icon, no menu bar, no windows

var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
InstallEventHandler(GetApplicationEventTarget(), { _, _, _ in
    replacer.run { Translit.convert($0, lexicon: russianLexicon) }
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
