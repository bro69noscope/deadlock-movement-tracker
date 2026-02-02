#Include debug.ahk
#Include paths.ahk

WriteMvposCfg(posLine) {
  posLine := Trim(posLine)
  if (posLine = "") {
    Debug(A_ThisFunc ": posLine empty -> abort")
    return false
  }

  if !RegExMatch(posLine, ";\s*$")
    posLine .= ";"

  try {
    DebugFile(A_ThisFunc ": BEFORE", MVTRACK_POS_PATH)

    if FileExist(MVTRACK_POS_PATH)
      FileDelete(MVTRACK_POS_PATH)

    ; BOM-free (critical for Deadlock)
    FileAppend(posLine "`n", MVTRACK_POS_PATH)

    ; verify immediately by reading back the same path
    verify := Trim(FileRead(MVTRACK_POS_PATH), " `t`r`n")
    Debug(A_ThisFunc ": WROTE: " verify)
    DebugFile(A_ThisFunc ": AFTER", MVTRACK_POS_PATH)
    return true
  } catch as e {
    Debug(A_ThisFunc ": ERROR: " e.Message)
    DebugFile(A_ThisFunc ": ERROR PATH", MVTRACK_POS_PATH)
    return false
  }
}
