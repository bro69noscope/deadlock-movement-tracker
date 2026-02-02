LoadUserConfigFromIni() {
  base := A_ScriptDir "\..\user_settings.ini"
  override := A_ScriptDir "\..\user_settings.local.ini"

  if !FileExist(base) {
    MsgBox "Missing config: " base, "Movement Tracker", 0x30
    return false
  }

  ini := base
  if FileExist(override)
    ini := override

  ; --- Deadlock root ---
  global DEADLOCK_ROOT
  DEADLOCK_ROOT := IniRead(ini, "deadlock", "root", DEADLOCK_ROOT)

  ; --- Deadlock hotkeys ---
  global DEADLOCK_MARK_POS_HOTKEY, DEADLOCK_TELEPORT_HOTKEY, DEADLOCK_NOCLIP_HOTKEY
  global DEADLOCK_LOAD_PRACTICE_MAP_HOTKEY, DEADLOCK_SWAP_TEAM_HOTKEY, DEADLOCK_SETUP_PRACTICE_HOTKEY
  global DEADLOCK_MVTRACK_INTERNAL_HOTKEY

  DEADLOCK_MARK_POS_HOTKEY := IniRead(ini, "deadlock_hotkeys", "mark_pos", DEADLOCK_MARK_POS_HOTKEY)
  DEADLOCK_TELEPORT_HOTKEY := IniRead(ini, "deadlock_hotkeys", "teleport", DEADLOCK_TELEPORT_HOTKEY)
  DEADLOCK_NOCLIP_HOTKEY := IniRead(ini, "deadlock_hotkeys", "noclip", DEADLOCK_NOCLIP_HOTKEY)
  DEADLOCK_LOAD_PRACTICE_MAP_HOTKEY := IniRead(ini, "deadlock_hotkeys", "load_practice_map", DEADLOCK_LOAD_PRACTICE_MAP_HOTKEY)
  DEADLOCK_SWAP_TEAM_HOTKEY := IniRead(ini, "deadlock_hotkeys", "swap_team", DEADLOCK_SWAP_TEAM_HOTKEY)
  DEADLOCK_SETUP_PRACTICE_HOTKEY := IniRead(ini, "deadlock_hotkeys", "setup_practice", DEADLOCK_SETUP_PRACTICE_HOTKEY)
  DEADLOCK_MVTRACK_INTERNAL_HOTKEY := IniRead(ini, "deadlock_hotkeys", "mvtrack_internal", DEADLOCK_MVTRACK_INTERNAL_HOTKEY)

  ; --- Tracker hotkeys ---
  global TRACKER_FAIL_KEY, TRACKER_SUCCESS_KEY, TRACKER_SWITCH_POS_KEY, TRACKER_CREATE_POS_KEY
  global TRACKER_FORGET_LAST_KEY, TRACKER_RENAME_INSTANCE_KEY, TRACKER_REPOSITION_INSTANCE_KEY
  global TRACKER_DELETE_INSTANCE_KEY, TRACKER_EXIT_KEY

  TRACKER_FAIL_KEY := IniRead(ini, "tracker_hotkeys", "fail", TRACKER_FAIL_KEY)
  TRACKER_SUCCESS_KEY := IniRead(ini, "tracker_hotkeys", "success", TRACKER_SUCCESS_KEY)
  TRACKER_SWITCH_POS_KEY := IniRead(ini, "tracker_hotkeys", "switch", TRACKER_SWITCH_POS_KEY)
  TRACKER_CREATE_POS_KEY := IniRead(ini, "tracker_hotkeys", "new", TRACKER_CREATE_POS_KEY)
  TRACKER_FORGET_LAST_KEY := IniRead(ini, "tracker_hotkeys", "forget", TRACKER_FORGET_LAST_KEY)
  TRACKER_RENAME_INSTANCE_KEY := IniRead(ini, "tracker_hotkeys", "rename", TRACKER_RENAME_INSTANCE_KEY)
  TRACKER_REPOSITION_INSTANCE_KEY := IniRead(ini, "tracker_hotkeys", "reposition", TRACKER_REPOSITION_INSTANCE_KEY)
  TRACKER_DELETE_INSTANCE_KEY := IniRead(ini, "tracker_hotkeys", "delete", TRACKER_DELETE_INSTANCE_KEY)
  TRACKER_EXIT_KEY := IniRead(ini, "tracker_hotkeys", "exit", TRACKER_EXIT_KEY)

  ; --- Flags ---
  global ENABLE_DEBUG, TARGET_SUCCESS_STREAK, INCLUDE_PERSONAL_SETTINGS
  TARGET_SUCCESS_STREAK := IniRead(ini, "tracker_settings", "target_success_streak", TARGET_SUCCESS_STREAK) + 0
  ENABLE_DEBUG := StrLower((IniRead(ini, "dev", "enable_debug", ENABLE_DEBUG ? "true" : "false") = "true"))
  INCLUDE_BRO_SETTINGS := (IniRead(ini, "dev", "include_bro_settings", INCLUDE_BRO_SETTINGS ? "true" : "false") = "true")

  return true
}
