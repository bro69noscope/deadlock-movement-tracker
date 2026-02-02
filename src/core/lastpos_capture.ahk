#Include paths.ahk
ReadLastPosAfterMTime(prevMTime, timeoutMs := 1500) {
  start := A_TickCount
  lastSeenMTime := ""
  lastSeenText := ""
  lastError := ""

  while (A_TickCount - start) <= timeoutMs {
    if !FileExist(LASTPOS_PATH) {
      lastError := "missing " LASTPOS_PATH
      Sleep 50
      continue
    }

    try {
      lastSeenMTime := FileGetTime(LASTPOS_PATH, "M")
      lastSeenText := Trim(FileRead(LASTPOS_PATH))
    } catch as e {
      lastError := "read error: " e.Message
      Sleep 50
      continue
    }

    changed := (prevMTime = "" || lastSeenMTime != prevMTime)
    if (changed) {
      if RegExMatch(lastSeenText, "i)^\s*setpos\b") {
        return { ok: true, line: lastSeenText, reason: "changed+valid" }
      } else {
        ; file changed but content isn't a setpos line
        return { ok: false, line: "", reason: "changed_but_invalid", mtime: lastSeenMTime, text: lastSeenText }
      }
    }

    Sleep 50
  }

  ; timeout
  if (prevMTime != "" && lastSeenMTime = prevMTime)
    return { ok: false, line: "", reason: "timeout_no_mtime_change", mtime: lastSeenMTime, text: lastSeenText, err: lastError }

  return { ok: false, line: "", reason: "timeout_unknown", mtime: lastSeenMTime, text: lastSeenText, err: lastError }
}
