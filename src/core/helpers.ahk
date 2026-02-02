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

ResetInGamePos(sleepTime := 350) {
  ; Toggle noclip off and on to kill velocity
  WinActivate("ahk_exe  deadlock.exe")
  Send CFG.noclip
  Sleep sleepTime
  Send CFG.noclip
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
