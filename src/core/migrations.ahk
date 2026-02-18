#Include paths.ahk
#Include helpers.ahk
#Include history.ahk
#Include debug.ahk
#Include state.ahk

global DATA_SCHEMA_VERSION := 1

RunMigrations() {
  state := STATE_INI
  cur := IniRead(state, "meta", "data_version", "0") + 0

  if cur < 1 {
    Migration_1_AddDisplayName_NormalizeHistoryFiles()
    cur := 1
  }

  IniWrite cur, state, "meta", "data_version"
}

DirOf(path) {
  SplitPath path, , &dir
  return dir
}

DisplayFromSectionKey(sec) {
  ; For variations, store only the variation portion as display_name
  if InStr(sec, VARIATION_SEPARATOR) {
    parts := StrSplit(sec, VARIATION_SEPARATOR)
    return Trim(parts.Length >= 2 ? parts[2] : sec)
  }
  ; For base sections, display is the full section name
  return sec
}

LegacyHistoryPath(instanceName) {
  safe := RegExReplace(instanceName, "[^\w\-. @]", "_")
  return INSTANCE_HISTORY_DIR "\" safe ".csv"
}

TempHopMove(oldPath, newPath) {
  if !FileExist(oldPath)
    return true

  if StrCompare(oldPath, newPath, 1) = 0
    return true

  Debug(A_ThisFunc ": migrating: " oldPath " -> " newPath)

  dir := DirOf(oldPath)
  tmp := dir "\__mvtrack_tmp__" A_TickCount ".csv"
  try FileDelete(tmp)

  ; hop to a different name to force Windows to apply casing changes
  FileMove(oldPath, tmp, 1)

  try {
    if !FileExist(newPath) {
      FileMove(tmp, newPath, 1)
      return true
    }

    oldTxt := FileRead(tmp, "UTF-8")
    newTxt := FileRead(newPath, "UTF-8")

    merged := ""
    if Trim(newTxt) != ""
      merged .= RTrim(newTxt, "`r`n") "`n"
    if Trim(oldTxt) != ""
      merged .= RTrim(oldTxt, "`r`n") "`n"

    outTmp := dir "\__mvtrack_merge__" A_TickCount ".csv"
    try FileDelete(outTmp)
    FileAppend(merged, outTmp, "UTF-8")

    FileDelete(newPath)
    FileMove(outTmp, newPath, 1)
    FileDelete(tmp)
    return true

  } catch as e {
    Debug(A_ThisFunc
      " FAILED: " e.Message " old='" oldPath "' new='" newPath "' tmp='" tmp "'")
    return false
  }
}

Migration_1_AddDisplayName_NormalizeHistoryFiles() {
  ini := INSTANCES_INI

  txt := ""
  try txt := IniRead(ini)
  catch
    return

  for _, raw in StrSplit(txt, "`n", "`r") {
    sec := Trim(raw)
    if sec = "" || sec = "__global__"
      continue

    ; 1) ensure display_name exists (only add if missing)
    dn := ""
    try dn := Trim(IniRead(ini, sec, "display_name", ""))
    catch
      dn := ""

    if dn = "" {
      name := sec

      if InStr(sec, VARIATION_SEPARATOR) {
        parts := StrSplit(sec, VARIATION_SEPARATOR)
        if parts.Length >= 2 {
          baseKey := Trim(parts[1])
          varKey := Trim(parts[2])

          ; try preserve original casing from base's variations= list
          rawVars := IniRead(ini, baseKey, "variations", "")
          m := Map()
          for _, idx in StrSplit(rawVars, "|") {
            idx := Trim(idx)
            if idx != ""
              m[CanonKey(idx)] := idx
          }

          name := m.Has(varKey) ? m[varKey] : varKey
        }
      }
      IniWrite name, ini, sec, "display_name"
    }

    ; 2) migrate history filename to canonical HistoryPath()
    oldPath := LegacyHistoryPath(sec)
    newPath := HistoryPath(sec)

    if StrCompare(oldPath, newPath, 1) != 0 && FileExist(oldPath) {
      TempHopMove(oldPath, newPath)
    }
  }
}
