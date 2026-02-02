#Include debug.ahk
#Include paths.ahk

WriteMvposCfg(posLine) {
  mvtrackPos := MVTRACK_CFG_POS_PATH
  posLine := Trim(posLine)
  if (posLine = "") {
    Debug(A_ThisFunc ": posLine empty -> abort")
    return false
  }

  if !RegExMatch(posLine, ";\s*$")
    posLine .= ";"

  try {
    DebugFile(A_ThisFunc ": BEFORE", mvtrackPos)

    if FileExist(mvtrackPos)
      FileDelete(mvtrackPos)

    ; BOM-free (critical for Deadlock)
    FileAppend(posLine "`n", mvtrackPos)

    ; verify immediately by reading back the same path
    verify := Trim(FileRead(mvtrackPos), " `t`r`n")
    Debug(A_ThisFunc ": WROTE: " verify)
    DebugFile(A_ThisFunc ": AFTER", mvtrackPos)
    return true
  } catch as e {
    Debug(A_ThisFunc ": ERROR: " e.Message)
    DebugFile(A_ThisFunc ": ERROR PATH", mvtrackPos)
    return false
  }
}
