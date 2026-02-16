#Include paths.ahk
#Include debug.ahk

DeleteOldLastPos() {
  lastpos := LASTPOS_CFG_PATH
  SplitPath lastpos, &fileName
  try {
    if FileExist(lastpos)
      FileDelete(lastpos)
    return true
  }
  catch as e {
    Debug(A_ThisFunc ": FAILED to delete " fileName " err=" e.Message)
    return false
  }
}

ReadLastPosUntilValid(timeoutMs) {
  lastpos := LASTPOS_CFG_PATH
  SplitPath lastpos, &fileName
  start := A_TickCount
  err := ""

  while (A_TickCount - start) <= timeoutMs {
    if FileExist(lastpos) {
      try {
        txt := Trim(FileRead(lastpos))
        if RegExMatch(txt, "i)^\s*setpos\b")
          return txt
      } catch as e {
        ; silent retry
        err := e.Message
      }
    }
    Sleep 25
  }

  Debug(A_ThisFunc ": timed out trying to read valid setpos from " lastpos
    err ? " read err=" err : "")

  MsgBox(
    "Timed out trying to read: " fileName "`n"
    "This can typically happens if '-condebug' is not set",
    "Movement Tracker",
    0x30
  )

  return ""
}
