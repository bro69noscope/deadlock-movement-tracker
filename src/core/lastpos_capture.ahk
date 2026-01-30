#Include paths.ahk
ReadLastPosAfterMTime(prevMTime, timeoutMs := 1500) {
  start := A_TickCount

  while (A_TickCount - start) <= timeoutMs {
    if FileExist(LASTPOS_PATH) {
      try {
        mt := FileGetTime(LASTPOS_PATH, "M")
        if (prevMTime = "" || mt != prevMTime) {
          s := Trim(FileRead(LASTPOS_PATH))
          if RegExMatch(s, "i)^\s*setpos\b")
            return s
        }
      }
    }
    Sleep 50
  }
  return ""
}

ReadLastPosWithRetry(timeoutMs := 600) {
  start := A_TickCount

  while (A_TickCount - start) <= timeoutMs {
    if FileExist(LASTPOS_PATH) {
      try {
        s := Trim(FileRead(LASTPOS_PATH))
        if RegExMatch(s, "i)^\s*setpos\b")
          return s
      }
    }
    Sleep 50
  }
  return ""
}
