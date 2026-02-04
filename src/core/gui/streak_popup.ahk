#Include ..\instance.ahk

class StreakPopup {
  static gui := 0
  static hwnd := 0
  static spaceBound := false

  ; HotIf predicate: active in Deadlock OR while this popup is focused
  static SpaceHotIf(*) {
    return WinActive("ahk_exe deadlock.exe")
      || (StreakPopup.hwnd && WinActive("ahk_id " StreakPopup.hwnd))
  }

  static _CountSuccessInLastN(csvPath, n) {
    if !FileExist(csvPath)
      return [0, 0]

    try {
      f := FileOpen(csvPath, "r")
      content := f.Read()
      f.Close()
    } catch {
      return [0, 0]
    }

    split := StrSplit(Trim(content), "`n")
    start := (split.Length > n) ? split.Length - n + 1 : 1

    successes := 0
    total := 0

    Loop split.Length - start + 1 {
      line := Trim(split[start + A_Index - 1])
      if (line = "")
        continue
      total++

      if RegExMatch(line, ",success$")
        successes++
    }
    return [successes, total]
  }

  static Show(streakCur) {
    StreakPopup.Dismiss(false)

    ini := INSTANCES_INI
    cur := CURRENT_INSTANCE
    csvPath := INSTANCE_HISTORY_DIR "\" cur ".csv"

    s := IniRead(ini, cur, "success", "0") + 0
    f := IniRead(ini, cur, "fail", "0") + 0
    total := s + f
    pct := (total > 0) ? Round((s / total) * 100, 0) : 0
    bestStr := IniRead(ini, cur, "streak_best", "0") + 0

    r20 := StreakPopup._CountSuccessInLastN(csvPath, 20)
    r50 := StreakPopup._CountSuccessInLastN(csvPath, 50)
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

    StreakPopup.gui := g
    g.Show("AutoSize NA")
    StreakPopup.hwnd := g.Hwnd
    g.OnEvent("Close", (*) => StreakPopup.Dismiss(true))

    ; Stable HotIf + one hotkey
    HotIf(StreakPopup.SpaceHotIf)
    Hotkey("Space", StreakPopup.TryDismissBySpace, "On")
    HotIf()

    StreakPopup.spaceBound := true
  }

  static TryDismissBySpace(*) {
    if (StreakPopup.hwnd && WinExist("ahk_id " StreakPopup.hwnd))
      StreakPopup.Dismiss(true)
  }

  static Dismiss(focusBack := true) {
    if (StreakPopup.spaceBound) {
      HotIf(StreakPopup.SpaceHotIf)
      Hotkey("Space", StreakPopup.TryDismissBySpace, "Off")
      HotIf()
      StreakPopup.spaceBound := false
    }

    if IsObject(StreakPopup.gui) {
      try StreakPopup.gui.Destroy()
    }

    StreakPopup.gui := 0
    StreakPopup.hwnd := 0

    if (focusBack)
      WinActivate("ahk_exe deadlock.exe")
  }
}
