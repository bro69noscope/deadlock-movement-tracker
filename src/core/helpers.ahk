#Include config.ahk

NowStamp() {
  t := A_Now
  return SubStr(t, 1, 4) "-" SubStr(t, 5, 2) "-" SubStr(t, 7, 2)
    . " " SubStr(t, 9, 2) ":" SubStr(t, 11, 2) ":" SubStr(t, 13, 2)
}

GetFileMTime(path) {
  try {
    return FileGetTime(path, "M")
  } catch {
    return ""  ; file missing
  }
}

ResetInGamePos() {
  sleepTime := CFG.reset_position_duration
  limitStam := CFG.practice_without_infinite_stamina
  noclip := CFG.noclip

  WinActivate("ahk_exe  deadlock.exe")
  Send CFG.set_host_timescale_fast
  if limitStam
    Send CFG.enable_fast_stamina

  ; kill momentum
  Send noclip
  Sleep sleepTime

  WinActivate("ahk_exe  deadlock.exe")
  if limitStam
    Send CFG.disable_fast_stamina
  Send CFG.set_host_timescale_normal
  Send noclip
  Send CFG.mvtrack_internal
}

WarnNoInstanceSelected() {
  MsgBox(
    "No current instance selected. `nPress " CFG.new
    " to select one.",
    "Movement Tracker",
    0x30
  )
}

ConfirmExit() {
  choice := MsgBox(
    "Exit Movement Tracker?",
    "Movement Tracker",
    "YesNo Icon!"
  )
  if (choice = "Yes")
    ExitApp()
}
