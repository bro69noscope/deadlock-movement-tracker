#Include instance.ahk
#Include helpers.ahk
#Include history.ahk
#Include gui\streak_popup.ahk

MarkResult(result) {
  ini := INSTANCES_INI
  name := CURRENT_INSTANCE
  if (name = "") {
    WarnNoInstanceSelected()
    return
  }

  AppendHistory(name, result)

  s := IniRead(ini, name, "success", "0") + 0
  f := IniRead(ini, name, "fail", "0") + 0

  streakCur := IniRead(ini, name, "streak_current", "0") + 0
  streakBest := IniRead(ini, name, "streak_best", "0") + 0

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

  IniWrite s, ini, name, "success"
  IniWrite f, ini, name, "fail"
  IniWrite pct, ini, name, "success_pct"

  IniWrite streakCur, ini, name, "streak_current"
  IniWrite streakBest, ini, name, "streak_best"
  IniWrite NowStamp(), ini, name, "last_event"

  ResetInGamePos(name)
  if (CFG.target_success_streak > 0 && streakCur >= CFG.target_success_streak) {
    StreakPopup.Show(streakCur)
  }
}

ForgetLastResult() {
  name := CURRENT_INSTANCE
  if (name = "") {
    WarnNoInstanceSelected()
    return
  }

  UndoHistory(name)

  rebuilt := RebuildStatsFromHistory(name)
  ResetInGamePos(name)
}
