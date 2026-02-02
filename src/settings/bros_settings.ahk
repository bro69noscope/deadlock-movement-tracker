#Include user_config.ahk
; Just some of my custom rebinds I use for Deadlock when running this script
ApplyBroSettings() {
  HotIf (*) => WinActive("ahk_exe deadlock.exe")
  Hotkey("``", (*) => Send(DEADLOCK_MARK_POS_HOTKEY), "On")
  HotIf
}
