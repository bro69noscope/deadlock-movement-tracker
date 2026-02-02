#Include helpers.ahk
#Include debug.ahk
#Include paths.ahk
#Include mvpos_writer.ahk
#Include lastpos_capture.ahk
#Include history.ahk
#Include gui\prompt.ahk
#Include gui\instance_picker.ahk
global CURRENT_INSTANCE := ""

InstanceExists(name) {
  return (IniRead(INI_PATH, name, "created_at", "") != "")
}

NewInstance() {
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
    IniDelete INI_PATH, name
  }

  ; (Re)create baseline fields
  IniWrite "0", INI_PATH, name, "success"
  IniWrite "0", INI_PATH, name, "fail"
  IniWrite "0", INI_PATH, name, "success_pct"
  IniWrite "0", INI_PATH, name, "streak_current"
  IniWrite "0", INI_PATH, name, "streak_best"
  IniWrite NowStamp(), INI_PATH, name, "created_at"

  SetCurrentInstance(name)
  SaveCurrentInstancePos()
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
  IniWrite "", INI_PATH, "__global__", "current_instance"

  try IniDelete INI_PATH, name

  AppendGlobalEvent("delete_instance", name)

  h := HistoryPath(name)
  if FileExist(h) {
    try {
      FileDelete(h)
    } catch as e {
      Debug("DeleteInstance: FAILED to delete history file: " h " | " e.Message)
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
    MsgBox "That name is reserved.", "Tracker", 48
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

    try IniDelete INI_PATH, newName
    hist := HistoryPath(newName)
    if FileExist(hist) {
      try FileDelete(hist)
    }
  }

  secText := ""
  try {
    secText := IniRead(INI_PATH, oldName)
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
      IniWrite v, INI_PATH, newName, k
    }
  }

  ; ensure last_event bump
  IniWrite NowStamp(), INI_PATH, newName, "last_event"

  try IniDelete INI_PATH, oldName

  hOld := HistoryPath(oldName)
  hNew := HistoryPath(newName)
  if FileExist(hOld) {
    try {
      FileMove(hOld, hNew, 1)
    } catch as e {
      Debug("RenameInstance: FAILED to move history file: " hOld " -> " hNew " | " e.Message)
    }
  }

  CURRENT_INSTANCE := newName
  IniWrite newName, INI_PATH, "__global__", "current_instance"
  IniWrite NowStamp(), INI_PATH, newName, "last_switch"

  AppendGlobalEvent("rename_instance:" oldName "->" newName, newName)

  return true
}


LoadInstancePos(instanceName) {
  pos := ""
  hasKey := false

  try {
    secText := IniRead(INI_PATH, instanceName)
    if RegExMatch(secText, "im)^\s*pos_line\s*=")
      hasKey := true
    pos := IniRead(INI_PATH, instanceName, "pos_line", "")
  } catch as e {
    Debug(A_ThisFunc ": FAILED to read ini. instance=" instanceName " err=" e.Message " path=" INI_PATH)
    if (ENABLE_DEBUG)
      MsgBox("Failed to read instances.ini.`n`n" INI_PATH "`n`n" e.Message, "Movement Tracker", 0x30)
    return false
  }

  pos := StrReplace(pos, "`r", "")
  pos := StrReplace(pos, "`n", "")
  pos := Trim(pos)

  if (pos = "") {
    reason := hasKey ? "pos_line_empty" : "pos_line_missing"
    Debug(A_ThisFunc ": NO POS. instance=" instanceName " reason=" reason " path=" INI_PATH)

    if (ENABLE_DEBUG) {
      MsgBox(
        "No saved position for '" instanceName "'.`n`n"
        . "Reason: " reason "`n"
        . "Fix: reposition it with " TRACKER_REPOSITION_INSTANCE_KEY
        . " (or recreate with " TRACKER_CREATE_POS_KEY ").",
        "Movement Tracker",
        0x30
      )
    }
    return false
  }

  Debug(A_ThisFunc ": instance=" instanceName " pos=" pos)

  ok := WriteMvposCfg(pos)
  ResetInGamePos(100)
  return ok
}


SetCurrentInstance(name) {
  global CURRENT_INSTANCE
  CURRENT_INSTANCE := name
  IniWrite name, INI_PATH, "__global__", "current_instance"
  IniWrite NowStamp(), INI_PATH, name, "last_switch"
}

SaveCurrentInstancePos() {
  if (CURRENT_INSTANCE = "") {
    Debug("SaveCurrentInstancePos: no current instance -> abort")
    return false
  }

  before := GetFileMTime(LASTPOS_PATH)
  Debug("LASTPOS mtime before=" before)

  ; WinActivate("ahk_exe deadlock.exe") ;NOTE: potentially needed to uncomment to ensure Deadlock is focused
  Send DEADLOCK_MARK_POS_HOTKEY

  r := ReadLastPosAfterMTime(before, 1500)
  if (!r.ok) {
    snippet := ""
    if r.HasOwnProp("text")
      snippet := SubStr(r.text, 1, 80)

    seen := r.HasOwnProp("mtime") ? r.mtime : ""
    err := r.HasOwnProp("err") ? r.err : ""

    Debug(A_ThisFunc ": FAILED"
      " reason=" r.reason " before=" before " seen=" seen " err=" err " text='" snippet "'")

    if (ENABLE_DEBUG) {
      MsgBox(
        "Failed to capture position.`n`n"
        . "Reason: " r.reason "`n"
        . "Before mtime: " before "`n"
        . "Seen mtime: " seen "`n"
        . "Seen text: " snippet,
        "Movement Tracker",
        0x30
      )
    }
    return false
  }

  line := r.line

  IniWrite line, INI_PATH, CURRENT_INSTANCE, "pos_line"
  IniWrite NowStamp(), INI_PATH, CURRENT_INSTANCE, "pos_saved_at"
  ok := WriteMvposCfg(line)
  return ok
}
