#Requires AutoHotkey v2.0
#SingleInstance Force

; =========================
; Includes
; =========================
#Include settings\user_config.ahk
#Include lib\config.ahk
#Include lib\debug.ahk
#Include lib\helpers.ahk
#Include lib\ini_normalizer.ahk
#Include lib\gui_popup.ahk

if INCLUDE_PERSONAL_SETTINGS {
  #Include settings\bros_settings.ahk
}

; =========================
; Globals
; =========================
global INI_PATH := DATA_DIR "\instances.ini"
DirCreate(DATA_DIR)

global DEADLOCK_CFG_DIR := DEADLOCK_ROOT "\game\citadel\cfg"
global LASTPOS_PATH := DEADLOCK_CFG_DIR "\lastpos.cfg"
global MVTRACK_POS_PATH := DEADLOCK_CFG_DIR "\mvtrack_pos.cfg"

global CURRENT_INSTANCE := ""

; =========================
; Hotkeys
; =========================
#HotIf WinActive("ahk_exe deadlock.exe")
HotKey TRACKER_FAIL_KEY, (*) => MarkResult("fail")
HotKey TRACKER_SUCCESS_KEY, (*) => MarkResult("success")
HotKey TRACKER_SWITCH_POS_KEY, (*) => SwitchInstance()
HotKey TRACKER_CREATE_POS_KEY, (*) => NewInstance()
HotKey NORMALIZE_INI_KEY, (*) => NormalizeIni(INI_PATH)
#HotIf

; =========================
; Game actions
; =========================
ResetPos() {
  Send DEADLOCK_NOCLIP_HOTKEY
  Sleep 350
  Send DEADLOCK_NOCLIP_HOTKEY
  Send DEADLOCK_MVTRACK_POS_TP_HOTKEY
}

; =========================
; Core: file/time helpers
; =========================
GetFileMTime(path) {
  try {
    return FileGetTime(path, "M")
  } catch {
    return ""  ; file missing
  }
}

ReadLastPosAfterMTime(prevMTime, timeoutMs := 1500) {
  global LASTPOS_PATH
  start := A_TickCount

  while (A_TickCount - start) <= timeoutMs {
    if FileExist(LASTPOS_PATH) {
      try {
        mt := FileGetTime(LASTPOS_PATH, "M")
        if (prevMTime = "" || mt != prevMTime) {
          s := Trim(FileRead(LASTPOS_PATH))
          if RegExMatch(s, "i)^\s*setpos\b")
            return s
        }
      }
    }
    Sleep 50
  }
  return ""
}

ReadLastPosWithRetry(timeoutMs := 600) {
  global LASTPOS_PATH
  start := A_TickCount

  while (A_TickCount - start) <= timeoutMs {
    if FileExist(LASTPOS_PATH) {
      try {
        s := Trim(FileRead(LASTPOS_PATH))
        if RegExMatch(s, "i)^\s*setpos\b")
          return s
      }
    }
    Sleep 50
  }
  return ""
}

WriteMvposCfg(posLine) {
  global MVTRACK_POS_PATH

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
    verify := Trim(FileRead(MVTRACK_POS_PATH))
    Debug("WriteMvposCfg WROTE: " verify)
    DebugFile("WriteMvposCfg AFTER", MVTRACK_POS_PATH)
    return true
  } catch as e {
    Debug("WriteMvposCfg ERROR: " e.Message)
    DebugFile("WriteMvposCfg ERROR PATH", MVTRACK_POS_PATH)
    return false
  }
}

; =========================
; Core: Save / Load position
; =========================
SaveCurrentInstancePos() {
  global CURRENT_INSTANCE, DEADLOCK_MARK_POS_HOTKEY, LASTPOS_PATH, INI_PATH

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

LoadInstancePos(instanceName) {
  global INI_PATH, DEADLOCK_MVTRACK_POS_TP_HOTKEY

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

; =========================
; Instance management
; =========================
InstanceExists(name) {
  global INI_PATH
  return (IniRead(INI_PATH, name, "created_at", "") != "")
}

SetCurrentInstance(name) {
  global CURRENT_INSTANCE, INI_PATH
  CURRENT_INSTANCE := name
  IniWrite name, INI_PATH, "__global__", "current_instance"
  IniWrite NowStamp(), INI_PATH, name, "last_switch"
}

NewInstance() {
  global CURRENT_INSTANCE, INI_PATH
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
  global CURRENT_INSTANCE, INI_PATH
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

; =========================
; Tracking counts
; =========================
MarkResult(result) {
  global CURRENT_INSTANCE, INI_PATH
  if (CURRENT_INSTANCE = "")
    return

  s := IniRead(INI_PATH, CURRENT_INSTANCE, "success", "0") + 0
  f := IniRead(INI_PATH, CURRENT_INSTANCE, "fail", "0") + 0

  streakCur := IniRead(INI_PATH, CURRENT_INSTANCE, "streak_current", "0") + 0
  streakBest := IniRead(INI_PATH, CURRENT_INSTANCE, "streak_best", "0") + 0

  if (result = "success") {
    s += 1

    streakCur += 1
    if (streakCur > streakBest)
      streakBest := streakCur
  } else {
    f += 1
    streakCur := 0
  }

  total := s + f
  pct := (total > 0) ? Round((s / total) * 100, 2) : 0

  IniWrite s, INI_PATH, CURRENT_INSTANCE, "success"
  IniWrite f, INI_PATH, CURRENT_INSTANCE, "fail"
  IniWrite pct, INI_PATH, CURRENT_INSTANCE, "success_pct"

  IniWrite streakCur, INI_PATH, CURRENT_INSTANCE, "streak_current"
  IniWrite streakBest, INI_PATH, CURRENT_INSTANCE, "streak_best"

  IniWrite NowStamp(), INI_PATH, CURRENT_INSTANCE, "last_event"

  ResetPos()
  if (TARGET_SUCCESS_STREAK > 0 && streakCur == TARGET_SUCCESS_STREAK) {
    ShowStreakPopup(streakCur)
  }
}
