global __streakGui := 0
global __streakGuiHwnd := 0
global __streakSpaceBound := false

StreakSpaceHotIf(*) {
  global __streakGuiHwnd
  return WinActive("ahk_exe deadlock.exe")
    || (__streakGuiHwnd && WinActive("ahk_id " __streakGuiHwnd))
}

ShowStreakPopup(streakCur) {
  global __streakGui, __streakGuiHwnd, __streakSpaceBound

  DismissStreakPopup(false)

  g := Gui("+AlwaysOnTop +ToolWindow -MinimizeBox", "Tracker")
  g.MarginX := 16
  g.MarginY := 12
  g.SetFont("s11")
  g.AddText(, "Success streak: " streakCur "`n`nPress SPACE to dismiss")

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
  global __streakGuiHwnd

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
