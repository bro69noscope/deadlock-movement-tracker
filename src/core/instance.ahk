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
    MsgBox "No current instance selected.", "Tracker", 48
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
    MsgBox "No current instance selected.", "Tracker", 48
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
    MsgBox "No current instance selected.", "Tracker", 48
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
  pos := IniRead(INI_PATH, instanceName, "pos_line", "")
  Debug("LoadInstancePos: instance=" instanceName " pos=" pos)

  if (pos = "")
    return false

  ok := WriteMvposCfg(pos)
  Send DEADLOCK_MVTRACK_POS_TP_HOTKEY

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

  Send DEADLOCK_MARK_POS_HOTKEY

  line := ReadLastPosAfterMTime(before, 1500)
  Debug("Captured lastpos line=" line)

  if (line = "")
    return false


  IniWrite line, INI_PATH, CURRENT_INSTANCE, "pos_line"
  IniWrite NowStamp(), INI_PATH, CURRENT_INSTANCE, "pos_saved_at"

  ; keep mvtrack_pos.cfg synced to the last captured position
  ok := WriteMvposCfg(line)
  return ok
}
