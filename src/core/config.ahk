global CFG := {
  ; Deadlock
  deadlock_root: "C:\Program Files (x86)\Steam\steamapps\common\Deadlock",
  ; Deadlock hotkeys
  mark_pos: "o",
  teleport: "h",
  noclip: "u",
  load_practice_map: "8",
  swap_team: "9",
  setup_practice: "0",
  mvtrack_internal: "'",
  enable_fast_stamina: "k",
  disable_fast_stamina: "l",
  set_host_timescale_fast: ",",
  set_host_timescale_normal: ".",
  ; Tracker hotkeys
  fail: "F1",
  success: "F2",
  switch: "F3",
  new: "F4",
  forget: "F5",
  rename: "F6",
  reposition: "F7",
  delete: "F8",
  exit: "F9",
  ; Flags
  logging_level: "debug",
  include_bro_settings: false,
  ; Settings
  target_success_streak: 3,
  practice_without_infinite_stamina: true,
  reset_position_duration: 350,
  host_timescale_factor: 10
}

ReadBoolIni(ini, section, key, defaultBool) {
  v := StrLower(Trim(IniRead(ini, section, key, defaultBool ? "true" : "false")))
  return (v = "true")
}

ReadIntIni(ini, section, key, defaultInt) {
  return IniRead(ini, section, key, defaultInt) + 0
}

LoadUserConfigFromIni() {
  base := A_ScriptDir "\..\user_settings.ini"
  override := A_ScriptDir "\..\user_settings.local.ini"

  if !FileExist(base) {
    MsgBox "Missing config: " base, "Movement Tracker", 0x30
    return false
  }

  ini := FileExist(override) ? override : base

  ; Deadlock
  CFG.deadlock_root := IniRead(ini, "deadlock", "root", CFG.deadlock_root)

  ; Deadlock hotkeys
  CFG.mark_pos := IniRead(ini, "deadlock_hotkeys", "mark_pos", CFG.mark_pos)
  CFG.teleport := IniRead(ini, "deadlock_hotkeys", "teleport", CFG.teleport)
  CFG.noclip := IniRead(ini, "deadlock_hotkeys", "noclip", CFG.noclip)
  CFG.load_practice_map := IniRead(ini, "deadlock_hotkeys", "load_practice_map", CFG.load_practice_map)
  CFG.swap_team := IniRead(ini, "deadlock_hotkeys", "swap_team", CFG.swap_team)
  CFG.setup_practice := IniRead(ini, "deadlock_hotkeys", "setup_practice", CFG.setup_practice)
  CFG.mvtrack_internal := IniRead(ini, "deadlock_hotkeys", "mvtrack_internal", CFG.mvtrack_internal)
  CFG.enable_fast_stamina := IniRead(ini, "deadlock_hotkeys", "enable_fast_stamina", CFG.enable_fast_stamina)
  CFG.disable_fast_stamina := IniRead(ini, "deadlock_hotkeys", "disable_fast_stamina", CFG.disable_fast_stamina)
  CFG.set_host_timescale_fast := IniRead(ini, "deadlock_hotkeys", "set_host_timescale_fast", CFG.set_host_timescale_fast)
  CFG.set_host_timescale_normal := IniRead(ini, "deadlock_hotkeys", "set_host_timescale_normal", CFG.set_host_timescale_normal)

  ; Tracker hotkeys
  CFG.fail := IniRead(ini, "tracker_hotkeys", "fail", CFG.fail)
  CFG.success := IniRead(ini, "tracker_hotkeys", "success", CFG.success)
  CFG.switch := IniRead(ini, "tracker_hotkeys", "switch", CFG.switch)
  CFG.new := IniRead(ini, "tracker_hotkeys", "new", CFG.new)
  CFG.forget := IniRead(ini, "tracker_hotkeys", "forget", CFG.forget)
  CFG.rename := IniRead(ini, "tracker_hotkeys", "rename", CFG.rename)
  CFG.reposition := IniRead(ini, "tracker_hotkeys", "reposition", CFG.reposition)
  CFG.delete := IniRead(ini, "tracker_hotkeys", "delete", CFG.delete)
  CFG.exit := IniRead(ini, "tracker_hotkeys", "exit", CFG.exit)

  ; Settings
  CFG.target_success_streak := ReadIntIni(ini, "tracker_settings", "target_success_streak", CFG.target_success_streak)
  CFG.practice_without_infinite_stamina := ReadBoolIni(ini, "tracker_settings", "practice_without_infinite_stamina", CFG.practice_without_infinite_stamina)
  CFG.reset_position_duration := ReadIntIni(ini, "tracker_settings", "reset_position_duration", CFG.reset_position_duration)
  CFG.host_timescale_factor := 3500 / CFG.reset_position_duration

  ; Dev
  CFG.include_bro_settings := ReadBoolIni(ini, "dev", "include_bro_settings", CFG.include_bro_settings)

  ; Dev: Logging
  CFG.logging_level := IniRead(ini, "dev", "logging_level", CFG.logging_level)
  CFG.logging_level := StrUpper(CFG.logging_level)
  validLevels := Map("DEBUG", 1, "INFO", 1, "WARN", 1, "ERROR", 1, "FATAL", 1)
  if !validLevels.Has(CFG.logging_level) {
    CFG.logging_level := "DEBUG"
  }

  return true
}
