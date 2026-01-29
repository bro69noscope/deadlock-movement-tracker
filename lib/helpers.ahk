#Include ..\settings\user_config.ahk

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
  ; Toggle noclip off and on to kill velocity
  Send DEADLOCK_NOCLIP_HOTKEY
  Sleep 350
  Send DEADLOCK_NOCLIP_HOTKEY
  Send DEADLOCK_MVTRACK_POS_TP_HOTKEY
}
