#Include config.ahk
#Include paths.ahk
#Include helpers.ahk
#Include debug.ahk
#Include state.ahk
#Include route_timer.ahk
#Include perf.ahk

Timescale_Load() {
  global CURRENT_TIMESCALE
  ts := IniRead(STATE_INI, "timescale", "value", "1") + 0.0
  if ts <= 0
    ts := 1.0
  CURRENT_TIMESCALE := ts
  return ts
}

Timescale_Save(ts) {
  IniWrite ts, STATE_INI, "timescale", "value"
}

Timescale_FormatPercent(ts) {
  ; 0.8 -> 80, 1.0 -> 100
  return Round(ts * 100)
}

Timescale_Prefix(ts) {
  return Timescale_FormatPercent(ts) "%"
}

Timescale_WriteCfg(ts) {
  try {
    if FileExist(MVTRACK_CFG_TIMESCALE_PATH)
      FileDelete(MVTRACK_CFG_TIMESCALE_PATH)
    ; BOM-free matters in your project; keep it simple
    FileAppend("host_timescale " ts "`n", MVTRACK_CFG_TIMESCALE_PATH, "UTF-8-RAW")
    return true

  } catch as e {
    Debug("Timescale_WriteCfg FAILED: " e.Message)
    return false
  }
}

Timescale_Apply(ts) {
  Perf.Step(A_ThisFunc ": start")
  global CURRENT_TIMESCALE

  ; clamp (tweak as you like)
  if ts < 0.1
    ts := 0.1
  if ts > 2.0
    ts := 2.0

  ; avoid tiny float drift
  ts := Round(ts, 2)

  if !Timescale_WriteCfg(ts)
    return false

  ; apply in-game by exec’ing the cfg
  WinActivate("ahk_exe deadlock.exe")
  SendSmartKey(CFG.mvtrack_set_timescale)

  CURRENT_TIMESCALE := ts
  try RouteTimer.RefreshOverlay()
  Timescale_Save(ts)

  if IsSet(GraphPopup)
    GraphPopup.Refresh()

  Debug("Timescale_Apply: ts=" ts)
  Perf.Step(A_ThisFunc ": done")
  return true
}

Timescale_Reset() {
  return Timescale_Apply(1.0)
}

Timescale_Up(n := 0.05) {
  return Timescale_Apply(CURRENT_TIMESCALE + n)
}

Timescale_Down(n := 0.05) {
  return Timescale_Apply(CURRENT_TIMESCALE - n)
}

Timescale_IsNormal() {
  return Abs(CURRENT_TIMESCALE - 1.0) < 0.0001
}
