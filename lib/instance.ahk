#include helpers.ahk
#include debug.ahk
#include paths.ahk
#include mvpos_writer.ahk
#include lastpos_capture.ahk
#include gui\prompt.ahk
global CURRENT_INSTANCE := ""

InstanceExists(name) {
  return (IniRead(INI_PATH, name, "created_at", "") != "")
}

NewInstance() {
  name := PromptName("New instance name:")
  if (name = "")
    return

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
  name := PromptName("Switch to instance name:", CURRENT_INSTANCE)
  if (name = "")
    return

  if !InstanceExists(name) {
    MsgBox "No such instance: " name "`n`nCreate it first with F4 (New).", "Tracker", 48
    return
  }

  SetCurrentInstance(name)
  LoadInstancePos(name)
}

LoadInstancePos(instanceName) {
  pos := IniRead(INI_PATH, instanceName, "pos_line", "")
  Debug("LoadInstancePos: instance=" instanceName " pos=" pos)

  if (pos = "") {
    Debug("LoadInstancePos: no saved pos -> abort")
    return false
  }

  ok := WriteMvposCfg(pos)
  Debug("LoadInstancePos: wrote cfg ok=" (ok ? "true" : "false"))

  Send DEADLOCK_MVTRACK_POS_TP_HOTKEY
  Debug("Sent TP hotkey=" DEADLOCK_MVTRACK_POS_TP_HOTKEY)
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

  Debug("SaveCurrentInstancePos: instance=" CURRENT_INSTANCE)
  DebugFile("LASTPOS before", LASTPOS_PATH)

  before := GetFileMTime(LASTPOS_PATH)
  Debug("LASTPOS mtime before=" before)

  Send DEADLOCK_MARK_POS_HOTKEY
  Debug("Sent MARK_POS_HOTKEY=" DEADLOCK_MARK_POS_HOTKEY)

  line := ReadLastPosAfterMTime(before, 1500)
  Debug("Captured lastpos line=" line)

  if (line = "") {
    Debug("SaveCurrentInstancePos: FAILED to capture fresh lastpos")
    return false
  }

  IniWrite line, INI_PATH, CURRENT_INSTANCE, "pos_line"
  IniWrite NowStamp(), INI_PATH, CURRENT_INSTANCE, "pos_saved_at"
  Debug("Wrote INI pos_line for " CURRENT_INSTANCE)

  ; keep mvtrack_pos.cfg synced to the last captured position
  ok := WriteMvposCfg(line)
  Debug("WriteMvposCfg returned " (ok ? "true" : "false"))
  return ok
}
