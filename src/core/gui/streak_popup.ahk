global __streakGui := 0
global __streakGuiHwnd := 0
global __streakSpaceBound := false

ShowStreakPopup(streakCur) {
  global __streakGui, __streakGuiHwnd, __streakSpaceBound

  ; Close previous popup if any
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

  ; Bind SPACE only while popup exists
  Hotkey "Space", TryDismissStreakBySpace, "On"
  __streakSpaceBound := true
}

TryDismissStreakBySpace(*) {
  global __streakGuiHwnd

  if (__streakGuiHwnd && WinExist("ahk_id " __streakGuiHwnd))
    DismissStreakPopup(true)
}

DismissStreakPopup(focusBack := true) {
  global __streakGui, __streakGuiHwnd, __streakSpaceBound

  ; Stop intercepting SPACE
  if (__streakSpaceBound) {
    Hotkey "Space", "Off"
    __streakSpaceBound := false
  }

  if IsObject(__streakGui) {
    try {
      __streakGui.Destroy()
    }
  }

  __streakGui := 0
  __streakGuiHwnd := 0

  if (focusBack)
    WinActivate("ahk_exe deadlock.exe")
}
