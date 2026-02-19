#Include route_timer.ahk
#Include config.ahk
#Include mvpos_writer.ahk
#Include timescale.ahk
#Include perf.ahk

ShouldSkipRandomize(instanceName) {
  raw := CFG.no_randomize_prefixes
  if raw = ""
    return false

  prefixes := []
  for _, p in StrSplit(raw, ",") {
    p := Trim(p)
    if p != ""
      prefixes.Push(p)
  }

  if prefixes.Length = 0
    return false

  for _, p in prefixes {
    esc := RegExReplace(p, "([.^$*+?()[\]{}|\\])", "\$1")
    if RegExMatch(instanceName, "i)^" esc) {
      Debug(A_ThisFunc
        ": instanceName='" instanceName "' matches no-randomize prefix='" p "'")
      return true
    }
  }
  return false
}

RandomizeResetPos(instanceName) {
  Perf.Step(A_ThisFunc ": init")
  if instanceName = ""
    return
  if ShouldSkipRandomize(instanceName)
    return

  base := IniRead(INSTANCES_INI, instanceName, "pos_line", "")
  base := Trim(StrReplace(StrReplace(base, "`r", ""), "`n", ""))
  if base = ""
    return

  delta := Max(0, CFG.randomize_reset_units)
  if delta <= 0
    return

  line := Trim(base)
  line := RegExReplace(line, ";\s*$")
  line := RegExReplace(line, "\s+", " ")
  parts := StrSplit(line, A_Space)
  Perf.Step(A_ThisFunc ": parsed pos_line")

  if parts.Length < 4 {
    Debug(A_ThisFunc
      ": expected 'setpos x y ...' but got parts.Length=" parts.Length
      " line='" line "'")
    return
  }

  if StrLower(parts[1]) != "setpos" {
    Debug(A_ThisFunc ": expected 'setpos' but got '" parts[1] "'")
    return
  }

  if !RegExMatch(parts[2], "^-?\d+(\.\d+)?$")
    || !RegExMatch(parts[3], "^-?\d+(\.\d+)?$") {
    Debug(A_ThisFunc ": expected numeric X/Y but got '" parts[2] "', '" parts[3] "'")
    return
  }

  x := parts[2] + 0
  y := parts[3] + 0

  dx := Random(-delta, delta)
  dy := Random(-delta, delta)

  parts[2] := x + dx
  parts[3] := y + dy

  rnd := ""
  for i, p in parts
    rnd .= (i > 1 ? " " : "") p
  rnd := rnd ";"

  Perf.Step(A_ThisFunc ": did pos_line randomization maths")
  WriteMvposCfg(rnd)
  Debug(A_ThisFunc
    ": randomized pos_line for instance=" instanceName " base=" base " rnd=" rnd)
}

ResetInGamePos(current_instance) {
  sleepTime := CFG.throttle_timescale ? CFG.host_timescale_factor * 25 :
    CFG.reset_position_duration
  noclipKey := CFG.noclip
  randomize := CFG.randomize_reset_pos
  resetStamina := CFG.practice_without_infinite_stamina
  resetCooldowns := CFG.practice_without_fast_cooldowns

  Perf.Step(A_ThisFunc ": init")

  if !WinActive("ahk_exe deadlock.exe") {
    WinActivate("ahk_exe deadlock.exe")
    Perf.Step(A_ThisFunc ": WinActivate deadlock")
  } else {
    Perf.Step(A_ThisFunc ": already active deadlock")
  }

  Send CFG.set_host_timescale_fast

  if resetStamina
    Send CFG.enable_fast_stamina
  if resetCooldowns
    Send CFG.enable_fast_cooldowns

  ; kill momentum
  Send noclipKey
  Perf.Step(A_ThisFunc ": 2~3 sends done")
  Sleep sleepTime
  Perf.Step(A_ThisFunc ": Sleep " sleepTime " done")

  if resetStamina
    Send CFG.disable_fast_stamina
  if resetCooldowns
    Send CFG.disable_fast_cooldowns

  if randomize {
    RandomizeResetPos(current_instance)
    Perf.Step(A_ThisFunc ": RandomizePos done")
  }

  Send CFG.set_host_timescale_normal
  Send noclipKey

  if current_instance = "__temp__"
    SendSmartKey(CFG.mvtrack_teleport_temp)
  else
    SendSmartKey(CFG.mvtrack_teleport)
  Perf.Step(A_ThisFunc ": 3 sends done")

  if !Timescale_IsNormal() {
    Timescale_Apply(CURRENT_TIMESCALE)
    Perf.Step(A_ThisFunc ": Timescale_Apply")
  }

  RouteTimer.Arm()
  Perf.Step(A_ThisFunc ": done")
}
