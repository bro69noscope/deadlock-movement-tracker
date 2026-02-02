#Include instance.ahk
#Include helpers.ahk
#Include history.ahk
#Include gui\streak_popup.ahk

MarkResult(result) {
  name := CURRENT_INSTANCE
  if (name = "") {
    WarnNoInstanceSelected()
    return
  }

  AppendHistory(name, result)

  s := IniRead(INI_PATH, name, "success", "0") + 0
  f := IniRead(INI_PATH, name, "fail", "0") + 0

  streakCur := IniRead(INI_PATH, name, "streak_current", "0") + 0
  streakBest := IniRead(INI_PATH, name, "streak_best", "0") + 0

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

  IniWrite s, INI_PATH, name, "success"
  IniWrite f, INI_PATH, name, "fail"
  IniWrite pct, INI_PATH, name, "success_pct"

  IniWrite streakCur, INI_PATH, name, "streak_current"
  IniWrite streakBest, INI_PATH, name, "streak_best"
  IniWrite NowStamp(), INI_PATH, name, "last_event"

  ResetInGamePos()
  if (CFG.target_success_streak > 0 && streakCur == CFG.target_success_streak) {
    ShowStreakPopup(streakCur)
  }
}

ForgetLastResult() {
  name := CURRENT_INSTANCE
  if (name = "")
    return

  UndoHistory(name)

  rebuilt := RebuildStatsFromHistory(name)
  ResetInGamePos()
}
