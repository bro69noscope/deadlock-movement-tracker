#Include ..\core\config.ahk
; Just some of my custom rebinds I use for Deadlock when running this script
ApplyBroSettings() {
  HotIf (*) => WinActive("ahk_exe deadlock.exe")
  Hotkey("``", (*) => Send(CFG.mark_pos), "On")
  HotIf
}
