#Include config.ahk
#Include paths.ahk

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

WarnNoInstanceSelected() {
  MsgBox(
    "No current instance selected. `nPress " CFG.new " to create one / "
    CFG.switch " to select one.",
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

JsonEscape(s) {
  s := StrReplace(s, "\", "\\")
  s := StrReplace(s, '"', '\"')
  s := StrReplace(s, "`r", "\r")
  s := StrReplace(s, "`n", "\n")
  s := StrReplace(s, "`t", "\t")
  return s
}

NormalizeNewlines(s) {
  s := StrReplace(s, "`r`n", "`n")
  s := StrReplace(s, "`r", "`n")
  return s
}

CanonKey(name) {
  return StrLower(Trim(name))
}

GetDisplayName(sectionName) {
  try {
    dn := Trim(IniRead(INSTANCES_INI, sectionName, "display_name", ""))
    return (dn != "") ? dn : sectionName
  } catch {
    return sectionName
  }
}

SetDisplayName(sectionName, displayName) {
  IniWrite displayName, INSTANCES_INI, sectionName, "display_name"
}
