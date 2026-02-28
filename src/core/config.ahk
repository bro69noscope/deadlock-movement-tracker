global CFG := {
  ; Deadlock
  deadlock_root: "C:\Program Files (x86)\Steam\steamapps\common\Deadlock",
  ; Deadlock hotkeys
  noclip: "u",
  load_practice_map: "8",
  swap_team: "9",
  setup_practice: "0",
  enable_fast_stamina: "k",
  disable_fast_stamina: "l",
  enable_fast_cooldowns: "i",
  disable_fast_cooldowns: "o",
  set_host_timescale_fast: ",",
  set_host_timescale_normal: ".",
  mvtrack_mark_pos: "F13",
  mvtrack_teleport: "F14",
  mvtrack_teleport_temp: "F15",
  mvtrack_set_timescale: "F16",
  ; Tracker hotkeys
  mark_temp_pos: "``",
  temp_pos_teleport: "h",
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
  flush_logs: "^!F12",
  inc_host_timescale: "!Up",
  inc_host_timescale_big: "+!Up",
  dec_host_timescale: "!Down",
  dec_host_timescale_big: "+!Down",
  norm_host_timescale: "!Left",
  ; Flags
  logging_level: "debug",
  ; Settings
  target_success_streak: 3,
  use_regular_stamina: true,
  use_regular_cooldowns: true,
  reset_position_duration: 350,
  host_timescale_factor: 10,
  randomize_reset_pos: true,
  randomize_reset_units: 20,
  no_randomize_prefixes: "",
  movement_keys: "w,a,s,d",
  ; Dev settings
  throttle_timescale: true,
  throttled_timescale_factor: 10
}

ReadBoolIni(ini, section, key, defaultBool) {
  v := StrLower(Trim(IniRead(ini, section, key, defaultBool ? "true" : "false")))
  return (v = "true")
}

ReadIntIni(ini, section, key, defaultInt) {
  return IniRead(ini, section, key, defaultInt) + 0
}

InitMovementKeys() {
  global MOVEMENT_KEYS := []
  for _, k in StrSplit(CFG.movement_keys, ",") {
    k := StrLower(Trim(k))
    if k != ""
      MOVEMENT_KEYS.Push(k)
  }
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
  CFG.noclip := IniRead(ini, "deadlock_hotkeys", "noclip", CFG.noclip)

  CFG.load_practice_map :=
    IniRead(ini, "deadlock_hotkeys", "load_practice_map", CFG.load_practice_map)

  CFG.swap_team := IniRead(ini, "deadlock_hotkeys", "swap_team", CFG.swap_team)

  CFG.setup_practice :=
    IniRead(ini, "deadlock_hotkeys", "setup_practice", CFG.setup_practice)

  CFG.enable_fast_stamina :=
    IniRead(ini, "deadlock_hotkeys", "enable_fast_stamina", CFG.enable_fast_stamina)

  CFG.disable_fast_stamina :=
    IniRead(ini, "deadlock_hotkeys", "disable_fast_stamina", CFG.disable_fast_stamina)

  CFG.enable_fast_cooldowns :=
    IniRead(
      ini, "deadlock_hotkeys", "enable_fast_cooldowns", CFG.enable_fast_cooldowns
    )

  CFG.disable_fast_cooldowns :=
    IniRead(
      ini, "deadlock_hotkeys", "disable_fast_cooldowns", CFG.disable_fast_cooldowns
    )

  CFG.set_host_timescale_fast :=
    IniRead(
      ini, "deadlock_hotkeys", "set_host_timescale_fast", CFG.set_host_timescale_fast
    )

  CFG.set_host_timescale_normal :=
    IniRead(
      ini, "deadlock_hotkeys", "set_host_timescale_normal", CFG.set_host_timescale_normal
    )

  ; Tracker hotkeys
  CFG.temp_pos_teleport :=
    IniRead(ini, "tracker_hotkeys", "temp_pos_teleport", CFG.temp_pos_teleport)

  CFG.mark_temp_pos :=
    IniRead(ini, "tracker_hotkeys", "mark_temp_pos", CFG.mark_temp_pos)

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
  CfG.flush_logs := IniRead(ini, "tracker_hotkeys", "flush_logs", CFG.flush_logs)

  CFG.new_variation :=
    IniRead(ini, "tracker_hotkeys", "new_variation", CFG.new_variation)

  CFG.switch_variation :=
    IniRead(ini, "tracker_hotkeys", "switch_variation", CFG.switch_variation)

  CFG.inc_host_timescale :=
    IniRead(ini, "tracker_hotkeys", "inc_host_timescale", CFG.inc_host_timescale)

  CFG.inc_host_timescale_big :=
    IniRead(
      ini, "tracker_hotkeys", "inc_host_timescale_big", CFG.inc_host_timescale_big
    )

  CFG.dec_host_timescale :=
    IniRead(ini, "tracker_hotkeys", "dec_host_timescale", CFG.dec_host_timescale)

  CFG.dec_host_timescale_big :=
    IniRead(
      ini, "tracker_hotkeys", "dec_host_timescale_big", CFG.dec_host_timescale_big
    )

  CFG.norm_host_timescale :=
    IniRead(ini, "tracker_hotkeys", "norm_host_timescale", CFG.norm_host_timescale)

  ; Settings
  CFG.target_success_streak :=
    ReadIntIni(
      ini, "tracker_settings", "target_success_streak", CFG.target_success_streak
    )

  CFG.use_regular_stamina :=
    ReadBoolIni(
      ini, "tracker_settings", "use_regular_stamina", CFG.use_regular_stamina
    )

  CFG.use_regular_cooldowns :=
    ReadBoolIni(
      ini, "tracker_settings", "use_regular_cooldowns", CFG.use_regular_cooldowns
    )

  CFG.reset_position_duration :=
    ReadIntIni(
      ini, "tracker_settings", "reset_position_duration", CFG.reset_position_duration
    )

  CFG.movement_keys :=
    IniRead(ini, "tracker_settings", "movement_keys", CFG.movement_keys)


  ; NOTE:host_timescale higher than 10 doesn't seem to benefit stamina regen at all
  ; currently (Feb 2026), so we limit it to a maximum since there is no point in having
  ; it very high. We use whatever value allows us to reset cooldowns/state quickly
  ; without loosing on too much on bridge buff durations

  dynamicFactor := 5000 / CFG.reset_position_duration ; will usually be between 5 and 200
  throttle := CFG.throttle_timescale
  throttledFactor := CFG.throttled_timescale_factor

  CFG.host_timescale_factor :=
    throttle ? Min(throttledFactor, dynamicFactor) : dynamicFactor

  CFG.randomize_reset_pos :=
    ReadBoolIni(
      ini, "tracker_settings", "randomize_reset_pos", CFG.randomize_reset_pos
    )

  CFG.randomize_reset_units :=
    ReadIntIni(
      ini, "tracker_settings", "randomize_reset_units", CFG.randomize_reset_units
    )

  CFG.no_randomize_prefixes :=
    IniRead(
      ini, "tracker_settings", "no_randomize_prefixes", CFG.no_randomize_prefixes
    )


  ; Logging
  CFG.logging_level := IniRead(ini, "dev", "logging_level", CFG.logging_level)
  CFG.logging_level := StrUpper(CFG.logging_level)

  validLevels := Map("DEBUG", 1, "INFO", 1, "WARN", 1, "ERROR", 1, "FATAL", 1)

  if !validLevels.Has(CFG.logging_level)
    CFG.logging_level := "DEBUG"

  InitMovementKeys()
  return true
}
