; Save the current active window
originalWindow := WinGetID("A")

; Activate Brave
if WinExist("ahk_exe brave.exe") {
    WinActivate("ahk_exe brave.exe")
    Sleep(100) ; Give it a moment to activate
    Send("^r") ; Send Ctrl+R to reload
    Sleep(100)
}

; Restore the original window
if originalWindow {
    WinActivate(originalWindow)
}