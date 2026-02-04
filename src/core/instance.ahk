#Include helpers.ahk
#Include debug.ahk
#Include paths.ahk
#Include mvpos_writer.ahk
#Include lastpos_capture.ahk
#Include history.ahk
#Include reset_pos.ahk
#Include gui\prompt.ahk
#Include gui\instance_picker.ahk

global CURRENT_INSTANCE := ""


InstanceExists(name) {
  return (IniRead(INSTANCES_INI, name, "created_at", "") != "")
}

NewInstance() {
  ini := INSTANCES_INI
  name := PromptName("New instance name:")
  if (name = "")
    return

  if (name = "__global__") {
    MsgBox "That name is reserved.", "Tracker", 48
    return false
  }

  if InstanceExists(name) {
    choice := MsgBox(
      "Instance '" name "' already exists.`n`n"
      . "Replace it? This will overwrite/reset its stats and saved position.",
      "Tracker",
      "YesNo Icon!"
    )
    if (choice = "No")
      return

    ; Overwrite/reset the instance section
    IniDelete ini, name
  }

  ; (Re)create baseline fields
  IniWrite "0", ini, name, "success"
  IniWrite "0", ini, name, "fail"
  IniWrite "0", ini, name, "success_pct"
  IniWrite "0", ini, name, "streak_current"
  IniWrite "0", ini, name, "streak_best"
  IniWrite NowStamp(), ini, name, "created_at"

  SetCurrentInstance(name)
  SaveCurrentInstancePos()
  ; resetpos for visual feedback + stamina reset when infinite stam is off
  ResetInGamePos()
}

SwitchInstance() {
  name := ListInstances()
  if (name = "")
    return

  if !InstanceExists(name) {
    MsgBox "No such instance: " name "`n`nCreate it first with F4 (New).", "Tracker", 48
    return
  }

  SetCurrentInstance(name)
  LoadInstancePos(name)
}

DeleteInstance() {
  global CURRENT_INSTANCE
  name := CURRENT_INSTANCE
  ini := INSTANCES_INI
  if name = "" {
    WarnNoInstanceSelected()
    return false
  }

  if !InstanceExists(name) {
    MsgBox "No such instance: " name, "Tracker", 48
    return false
  }

  choice := MsgBox(
    "Delete '" name "'?`n`n"
    . "This will remove it from instances.ini"
    . (FileExist(HistoryPath(name)) ? " and delete its history log." : "."),
    "Tracker",
    "YesNo Icon!"
  )
  if (choice = "No")
    return false

  CURRENT_INSTANCE := ""
  IniWrite "", ini, "__global__", "current_instance"

  try IniDelete ini, name

  AppendGlobalEvent("delete_instance", name)

  h := HistoryPath(name)
  if FileExist(h) {
    try {
      FileDelete(h)
    } catch as e {
      Debug(A_thisFunc ": FAILED to delete history file: " h " | " e.Message)
    }
  }

  return true
}

RepositionInstance() {
  name := CURRENT_INSTANCE
  if (name = "") {
    WarnNoInstanceSelected()
    return false
  }

  choice := MsgBox(
    "Move '" name "' to current pos ?`n`n",
    "Tracker",
    "YesNo Icon!"
  )
  if (choice = "No")
    return false

  SaveCurrentInstancePos()
}

RenameInstance() {
  global CURRENT_INSTANCE
  ini := INSTANCES_INI

  oldName := CURRENT_INSTANCE
  if oldName = "" {
    WarnNoInstanceSelected()
    return false
  }

  if !InstanceExists(oldName) {
    MsgBox "No such instance: " oldName, "Tracker", 48
    return false
  }

  newName := PromptName("Rename instance:`n`nOld: " oldName "`nNew:", oldName)
  newName := Trim(newName)

  if (newName = "" || newName = oldName)
    return false

  if (newName = "__global__") {
    MsgBox "That name is reserved:." newName, "Tracker", 48
    return false
  }

  if InstanceExists(newName) {
    choice := MsgBox(
      "Instance '" newName "' already exists.`n`n"
      . "Replace it? This will overwrite its stats/pos (and its history file if any).",
      "Tracker",
      "YesNo Icon!"
    )
    if (choice = "No")
      return false

    try IniDelete ini, newName
    hist := HistoryPath(newName)
    if FileExist(hist) {
      try FileDelete(hist)
    }
  }

  secText := ""
  try {
    secText := IniRead(ini, oldName)
  } catch {
    secText := ""
  }
  for _, rawLine in StrSplit(secText, "`n", "`r") {
    line := Trim(rawLine)
    if (line = "")
      continue
    if RegExMatch(line, "^\s*[;#]")
      continue
    if RegExMatch(line, "^\s*([^=]+?)\s*=\s*(.*)\s*$", &m) {
      k := Trim(m[1])
      v := m[2]
      IniWrite v, ini, newName, k
    }
  }

  ; ensure last_event bump
  IniWrite NowStamp(), ini, newName, "last_event"

  try IniDelete ini, oldName

  hOld := HistoryPath(oldName)
  hNew := HistoryPath(newName)
  if FileExist(hOld) {
    try {
      FileMove(hOld, hNew, 1)
    } catch as e {
      Debug(A_ThisFunc ": FAILED to move history file: " hOld " -> " hNew " | " e.Message)
    }
  }

  CURRENT_INSTANCE := newName
  IniWrite newName, ini, "__global__", "current_instance"
  IniWrite NowStamp(), ini, newName, "last_switch"

  AppendGlobalEvent("rename_instance:" oldName "->" newName, newName)

  return true
}


LoadInstancePos(instanceName) {
  ini := INSTANCES_INI
  pos := ""
  hasKey := false

  try {
    secText := IniRead(ini, instanceName)
    if RegExMatch(secText, "im)^\s*pos_line\s*=")
      hasKey := true
    pos := IniRead(ini, instanceName, "pos_line", "")
  } catch as e {
    Debug(A_ThisFunc ": FAILED to read ini. instance=" instanceName " err=" e.Message " path=" ini)
    MsgBox("Failed to read instances.ini.`n`n" ini "`n`n" e.Message, "Movement Tracker", 0x30)
    return false
  }

  pos := StrReplace(pos, "`r", "")
  pos := StrReplace(pos, "`n", "")
  pos := Trim(pos)

  if (pos = "") {
    reason := hasKey ? "pos_line_empty" : "pos_line_missing"
    Debug(A_ThisFunc ": NO POS. instance=" instanceName " reason=" reason " path=" ini)

    MsgBox(
      "No saved position for '" instanceName "'.`n`n"
      . "Reason: " reason "`n"
      . "Fix: reposition it with " CFG.reposition
      . " (or recreate with " CFG.new ").",
      "Movement Tracker",
      0x30
    )
    return false
  }

  Debug(A_ThisFunc ": instance=" instanceName " pos=" pos)

  ok := WriteMvposCfg(pos)
  ResetInGamePos()
  return ok
}


SetCurrentInstance(name) {
  global CURRENT_INSTANCE
  CURRENT_INSTANCE := name
  ini := INSTANCES_INI
  IniWrite name, ini, "__global__", "current_instance"
  IniWrite NowStamp(), ini, name, "last_switch"
}

SaveCurrentInstancePos() {
  ini := INSTANCES_INI
  if (CURRENT_INSTANCE = "") {
    Debug(A_thisFunc ": no current instance -> abort")
    return false
  }

  before := GetFileMTime(LASTPOS_CFG_PATH)
  Debug(A_ThisFunc ": LASTPOS mtime before=" before)

  WinActivate("ahk_exe deadlock.exe")
  Send CFG.mark_pos

  r := ReadLastPosAfterMTime(before, 2000)
  if (!r.ok) {
    snippet := ""
    if r.HasOwnProp("text")
      snippet := SubStr(r.text, 1, 80)

    seen := r.HasOwnProp("mtime") ? r.mtime : ""
    err := r.HasOwnProp("err") ? r.err : ""

    Debug(A_ThisFunc ": FAILED"
      " reason=" r.reason " before=" before " seen=" seen " err=" err " text='" snippet "'")

    MsgBox(
      "Failed to capture position.`n`n"
      . "Reason: " r.reason "`n"
      . "Before mtime: " before "`n"
      . "Seen mtime: " seen "`n"
      . "Seen text: " snippet "`n"
      . (r.reason == "timeout_no_mtime_change"
        ? "This usually happens if you don't have the '-condebug' DeadLock launch option set"
        : ""),
      "Movement Tracker",
      0x30
    )
    return false
  }

  line := r.line

  IniWrite line, ini, CURRENT_INSTANCE, "pos_line"
  IniWrite NowStamp(), ini, CURRENT_INSTANCE, "pos_saved_at"
  ok := WriteMvposCfg(line)
  return ok
}
