#Include debug.ahk
#Include paths.ahk

WriteMvposCfg(posLine) {
  posLine := Trim(posLine)
  if (posLine = "") {
    Debug("WriteMvposCfg: posLine empty -> abort")
    return false
  }

  if !RegExMatch(posLine, ";\s*$")
    posLine .= ";"

  try {
    DebugFile("WriteMvposCfg BEFORE", MVTRACK_POS_PATH)

    if FileExist(MVTRACK_POS_PATH)
      FileDelete(MVTRACK_POS_PATH)

    ; BOM-free (critical for Deadlock)
    FileAppend(posLine "`n", MVTRACK_POS_PATH)

    ; verify immediately by reading back the same path
    verify := Trim(FileRead(MVTRACK_POS_PATH), " `t`r`n")
    Debug("WriteMvposCfg WROTE: " verify)
    DebugFile("WriteMvposCfg AFTER", MVTRACK_POS_PATH)
    return true
  } catch as e {
    Debug("WriteMvposCfg ERROR: " e.Message)
    DebugFile("WriteMvposCfg ERROR PATH", MVTRACK_POS_PATH)
    return false
  }
}
