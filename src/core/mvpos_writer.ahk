#Include debug.ahk
#Include paths.ahk
#include perf.ahk

WriteMvposCfg(posLine) {
  Perf.Step(A_ThisFunc ": init")
  mvtrackPos := MVTRACK_CFG_POS_PATH
  posLine := Trim(posLine)
  if (posLine = "") {
    Debug(A_ThisFunc ": posLine empty -> abort")
    return false
  }

  if !RegExMatch(posLine, ";\s*$")
    posLine .= ";"

  try {
    ; overwrite directly, BOM-free
    f := FileOpen(mvtrackPos, "w", "UTF-8-RAW")
    f.Write(posLine "`n")
    f.Close()
    Perf.Step(A_ThisFunc ": wrote posLine")
    return true
  } catch as e {
    Debug(A_ThisFunc ": ERROR: " e.Message)
    return false
  }
}
