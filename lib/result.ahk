#Include instance.ahk
#Include helpers.ahk
#Include history.ahk
#Include gui\streak_popup.ahk

MarkResult(result) {
  if (CURRENT_INSTANCE = "")
    return

  AppendHistory(CURRENT_INSTANCE, result)

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

  ResetInGamePos()
  if (TARGET_SUCCESS_STREAK > 0 && streakCur == TARGET_SUCCESS_STREAK) {
    ShowStreakPopup(streakCur)
  }
}

ForgetLastResult() {
  if (CURRENT_INSTANCE = "")
    return

  if !UndoHistory(CURRENT_INSTANCE) {
    MsgBox "Nothing to forget for '" CURRENT_INSTANCE "'.", "Tracker", 48
    return
  }

  rebuilt := RebuildStatsFromHistory(CURRENT_INSTANCE)
  ResetInGamePos()
}
