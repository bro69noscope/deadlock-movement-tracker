#Include ..\instance.ahk
global __streakGui := 0
global __streakGuiHwnd := 0
global __streakSpaceBound := false

StreakSpaceHotIf(*) {
  return WinActive("ahk_exe deadlock.exe")
    || (__streakGuiHwnd && WinActive("ahk_id " __streakGuiHwnd))
}

_CountSuccessInLastN(csvPath, n) {
  if !FileExist(csvPath)
    return [0, 0]

  lines := []
  try {
    f := FileOpen(csvPath, "r")
    content := f.Read()
    f.Close()
  } catch
    return [0, 0]

  split := StrSplit(Trim(content), "`n")

  start := (split.Length > n) ? split.Length - n + 1 : 1
  successes := 0
  total := 0
  Loop split.Length - start + 1
  {
    line := Trim(split[start + A_Index - 1])
    if (line = "")
      continue
    total++
    if line ~= ",success$"
      successes++
  }
  return [successes, total]
}

ShowStreakPopup(streakCur) {
  global __streakGui, __streakGuiHwnd, __streakSpaceBound
  DismissStreakPopup(false)
  ini := INSTANCES_INI
  cur := CURRENT_INSTANCE
  csvPath := INSTANCE_HISTORY_DIR "\" cur ".csv"

  s := IniRead(ini, cur, "success", "0") + 0
  f := IniRead(ini, cur, "fail", "0") + 0
  total := s + f
  pct := (total > 0) ? Round((s / total) * 100, 0) : 0
  bestStr := IniRead(ini, cur, "streak_best", "0") + 0

  r20 := _CountSuccessInLastN(csvPath, 20)
  r50 := _CountSuccessInLastN(csvPath, 50)
  pct20 := (r20[2] > 0) ? Round((r20[1] / r20[2]) * 100, 0) : 0
  pct50 := (r50[2] > 0) ? Round((r50[1] / r50[2]) * 100, 0) : 0

  g := Gui("+AlwaysOnTop +ToolWindow -MinimizeBox", "Tracker")
  g.MarginX := 16
  g.MarginY := 10
  g.SetFont("s14")
  g.AddText(, "Success streak: " streakCur)
  g.SetFont("s11")
  g.AddText("y+7", "Highest streak: " bestStr)
  g.SetFont("s8")
  g.AddText("y+4", "Accuracy: " pct "%")
  g.AddText("y+6", "Last 20: " pct20 "%")
  g.AddText("y+6", "Last 50: " pct50 "%")
  g.SetFont("s10")
  g.AddText("y+10", "Press SPACE to dismiss")

  __streakGui := g
  g.Show("AutoSize NA")
  __streakGuiHwnd := g.Hwnd
  g.OnEvent("Close", (*) => DismissStreakPopup(true))

  HotIf(StreakSpaceHotIf)
  Hotkey "Space", TryDismissStreakBySpace, "On"
  HotIf()

  __streakSpaceBound := true
}

TryDismissStreakBySpace(*) {
  if (__streakGuiHwnd && WinExist("ahk_id " __streakGuiHwnd))
    DismissStreakPopup(true)
}

DismissStreakPopup(focusBack := true) {
  global __streakGui, __streakGuiHwnd, __streakSpaceBound

  if (__streakSpaceBound) {
    HotIf(StreakSpaceHotIf)
    Hotkey "Space", TryDismissStreakBySpace, "Off"
    HotIf()
    __streakSpaceBound := false
  }

  if IsObject(__streakGui) {
    try __streakGui.Destroy()
  }

  __streakGui := 0
  __streakGuiHwnd := 0
  if (focusBack)
    WinActivate("ahk_exe deadlock.exe")
}
