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
  mvtrack_ts_internal: "/",
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
  exit: "F12",
  new_variation: "F9",
  switch_variation: "F10",
  graph: "F11",
  inc_host_timescale: "!Up",
  inc_host_timescale_big: "+!Up",
  dec_host_timescale: "!Down",
  dec_host_timescale_big: "+!Down",
  norm_host_timescale: "!Left",
  ; Flags
  logging_level: "debug",
  include_bro_settings: false,
  ; Settings
  target_success_streak: 3,
  practice_without_infinite_stamina: true,
  reset_position_duration: 350,
  host_timescale_factor: 10,
  throttle_timescale: true,
  randomize_reset_pos: true,
  randomize_reset_units: 20,
  no_randomize_prefixes: ""
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
  CFG.mvtrack_internal := IniRead(ini, "deadlock_hotkeys", "mvtrack_internal", CFG.mvtrack_internal)

  CFG.load_practice_map := IniRead(ini, "deadlock_hotkeys", "load_practice_map", CFG.load_practice_map)
  CFG.swap_team := IniRead(ini, "deadlock_hotkeys", "swap_team", CFG.swap_team)
  CFG.setup_practice := IniRead(ini, "deadlock_hotkeys", "setup_practice", CFG.setup_practice)

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

  CFG.graph := IniRead(ini, "tracker_hotkeys", "graph", CFG.graph)
  CFG.new_variation := IniRead(ini, "tracker_hotkeys", "new_variation", CFG.new_variation)
  CFG.switch_variation := IniRead(ini, "tracker_hotkeys", "switch_variation", CFG.switch_variation)

  CFG.inc_host_timescale := IniRead(ini, "tracker_hotkeys", "inc_host_timescale", CFG.inc_host_timescale)
  CFG.inc_host_timescale_big := IniRead(ini, "tracker_hotkeys", "inc_host_timescale_big", CFG.inc_host_timescale_big)
  CFG.dec_host_timescale := IniRead(ini, "tracker_hotkeys", "dec_host_timescale", CFG.dec_host_timescale)
  CFG.dec_host_timescale_big := IniRead(ini, "tracker_hotkeys", "dec_host_timescale_big", CFG.dec_host_timescale_big)
  CFG.norm_host_timescale := IniRead(ini, "tracker_hotkeys", "norm_host_timescale", CFG.norm_host_timescale)

  ; Settings
  CFG.target_success_streak := ReadIntIni(ini, "tracker_settings", "target_success_streak", CFG.target_success_streak)
  CFG.practice_without_infinite_stamina := ReadBoolIni(ini, "tracker_settings", "practice_without_infinite_stamina", CFG.practice_without_infinite_stamina)
  CFG.reset_position_duration := ReadIntIni(ini, "tracker_settings", "reset_position_duration", CFG.reset_position_duration)

  ;NOTE:host_timescale higher than 10 doesnt seem to benefit stamina regen at all currently
  dynamicFactor := 5000 / CFG.reset_position_duration
  CFG.host_timescale_factor := CFG.throttle_timescale ? Min(10, dynamicFactor) : dynamicFactor

  CFG.randomize_reset_pos := ReadBoolIni(ini, "tracker_settings", "randomize_reset_pos", CFG.randomize_reset_pos)
  CFG.randomize_reset_units := ReadIntIni(ini, "tracker_settings", "randomize_reset_units", CFG.randomize_reset_units)
  CFG.no_randomize_prefixes := IniRead(ini, "tracker_settings", "no_randomize_prefixes", CFG.no_randomize_prefixes)

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
