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
  slowStam := CFG.practice_without_infinite_stamina
  WinActivate("ahk_exe  deadlock.exe")
  if slowStam {
    Send CFG.enable_fast_stamina
    Send CFG.set_host_timescale_fast
  }
  Send CFG.noclip
  Sleep sleepTime
  WinActivate("ahk_exe  deadlock.exe")
  Send CFG.noclip
  Send CFG.mvtrack_internal

  if slowStam {
    Send CFG.disable_fast_stamina
    Send CFG.set_host_timescale_normal
  }
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
