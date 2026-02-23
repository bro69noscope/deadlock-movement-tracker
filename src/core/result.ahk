#Include instance.ahk
#Include helpers.ahk
#Include history.ahk
#Include route_timer.ahk
#Include gui\streak_popup.ahk
#Include timescale.ahk
#Include perf.ahk

TSKey(ts, field) {
  return Timescale_Prefix(ts) field
}

IniReadTS(ini, section, ts, field, default := "0") {
  return IniRead(ini, section, TSKey(ts, field), default)
}

IniWriteTS(ini, section, ts, field, value) {
  IniWrite value, ini, section, TSKey(ts, field)
}

MarkResult(result) {
  if CurrentlySavingPosition()
    return false

  Perf.Start(A_ThisFunc ": MarkResult:" result)

  ini := INSTANCES_INI

  durMs := RouteTimer.Stop()
  Perf.Step(A_ThisFunc ": RouteTimer.Stop")

  name := GetCurrentRouteKey()
  Perf.Step(A_ThisFunc ": GetCurrentRouteKey")

  if name = "" {
    WarnNoInstanceSelected()
    Perf.End("early-exit")
    return
  }

  ts := CURRENT_TIMESCALE
  Perf.Step(A_ThisFunc ": read CURRENT_TIMESCALE")

  ; Decide where to store history + which counters to touch
  if Timescale_IsNormal() {
    AppendHistory(name, result)
    Perf.Step(A_ThisFunc ": AppendHistory (normal)")

    s := IniRead(ini, name, "success", "0") + 0
    f := IniRead(ini, name, "fail", "0") + 0
    streakCur := IniRead(ini, name, "streak_current", "0") + 0
    streakBest := IniRead(ini, name, "streak_best", "0") + 0
    Perf.Step(A_ThisFunc ": IniRead stats (normal)")

    if result = "success" {
      s += 1
      streakCur += 1
      if streakCur > streakBest
        streakBest := streakCur
    } else {
      f += 1
      streakCur := 0
    }

    total := s + f
    pct := (total > 0) ? Round((s / total) * 100, 2) : 0

    IniWrite s, ini, name, "success"
    IniWrite f, ini, name, "fail"
    IniWrite pct, ini, name, "success_pct"
    IniWrite streakCur, ini, name, "streak_current"
    IniWrite streakBest, ini, name, "streak_best"
    IniWrite NowStamp(), ini, name, "last_event"
    Perf.Step(A_ThisFunc ": IniWrite stats (normal)")

    ResetInGamePos(name)

    if CFG.target_success_streak > 0 && streakCur >= CFG.target_success_streak {
      StreakPopup.Show(streakCur)
      Perf.Step(A_ThisFunc ": StreakPopup.Show")
    }

    Perf.End()
    return
  }

  ; ---- Timescale-specific behavior ----
  AppendHistory(name, result, ts)
  Perf.Step(A_ThisFunc ": AppendHistory (ts)")

  ; read TS-specific keys under SAME section [name]
  s := IniReadTS(ini, name, ts, "success", "0") + 0
  f := IniReadTS(ini, name, ts, "fail", "0") + 0
  streakCur := IniReadTS(ini, name, ts, "streak_current", "0") + 0
  streakBest := IniReadTS(ini, name, ts, "streak_best", "0") + 0
  Perf.Step(A_ThisFunc ": IniReadTS stats")

  if result = "success" {
    s += 1
    streakCur += 1
    if streakCur > streakBest
      streakBest := streakCur
  } else {
    f += 1
    streakCur := 0
  }

  total := s + f
  pct := (total > 0) ? Round((s / total) * 100, 2) : 0

  IniWriteTS(ini, name, ts, "success", s)
  IniWriteTS(ini, name, ts, "fail", f)
  IniWriteTS(ini, name, ts, "success_pct", pct)
  IniWriteTS(ini, name, ts, "streak_current", streakCur)
  IniWriteTS(ini, name, ts, "streak_best", streakBest)
  IniWrite NowStamp(), ini, name, "last_event"
  Perf.Step(A_ThisFunc ": IniWriteTS stats")

  ResetInGamePos(name)
  Perf.Step(A_ThisFunc ": ResetInGamePos returned (ts)")

  if CFG.target_success_streak > 0 && streakCur >= CFG.target_success_streak {
    StreakPopup.Show(streakCur)
    Perf.Step(A_ThisFunc ": StreakPopup.Show (ts)")
  }

  Perf.End()
}

ForgetLastResult() {
  if CurrentlySavingPosition()
    return false

  Perf.Start("ForgetLastResult")

  name := GetCurrentRouteKey()
  Perf.Step(A_ThisFunc ": GetCurrentRouteKey")

  if name = "" {
    WarnNoInstanceSelected()
    Perf.End("early-exit")
    return
  }

  ts := CURRENT_TIMESCALE

  didForget := UndoHistory(name, ts)
  Perf.Step(A_ThisFunc ": UndoHistory")

  rebuilt := RebuildStatsFromHistory(name, ts)
  Perf.Step(A_ThisFunc ": RebuildStatsFromHistory")

  if didForget
    ResetInGamePos(name)

  Perf.End()
}
