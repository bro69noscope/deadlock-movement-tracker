#Include graph_daemon.ahk
#Include ..\instance.ahk

class GraphPopup {
  static gui := 0
  static hwnd := 0
  static spaceBound := false

  static _SpaceHotIf(*) {
    return WinActive("ahk_exe deadlock.exe")
      || (GraphPopup.hwnd && WinActive("ahk_id " GraphPopup.hwnd))
  }

  static _TryDismissBySpace(*) {
    if (GraphPopup.hwnd && WinExist("ahk_id " GraphPopup.hwnd))
      GraphPopup.Dismiss(true)
  }

  static Show() {
    ; close existing popup
    if (GraphPopup.hwnd && WinExist("ahk_id " GraphPopup.hwnd))
      GraphPopup.Dismiss(false)

    cur := GetCurrentRouteKey()
    if (cur = "") {
      WarnNoInstanceSelected()
      return false
    }

    csv := HistoryPath(cur)
    png := A_Temp "\mvtrack_graph.png"
    err := A_Temp "\graph_stderr.txt"
    Debug("GraphPopup: cur='" cur "' csv='" csv "' global='" GLOBAL_HISTORY "'")

    resp := GraphDaemon_Render(csv, png, err, cur, 5000)
    if (resp = "")
      return false

    if !InStr(resp, '"ok": true') {
      if FileExist(err) {
        stderrText := Trim(FileRead(err, "UTF-8"))
        if (stderrText != "") {
          stderrText := NormalizeNewlines(stderrText)
          Debug("GraphPopup: python:`n" stderrText)
        }
      }
      return false
    }
    Debug("GraphPopup: daemon resp=" resp)


    if !FileExist(png) || (FileGetSize(png) = 0)
      return false

    g := Gui("+AlwaysOnTop -Caption +ToolWindow")
    g.BackColor := "FFFFFF"
    g.MarginX := 10
    g.MarginY := 10

    g.AddPicture("w600 h300", png)
    g.AddText("y+8 Center w600", "Press SPACE to dismiss")

    GraphPopup.gui := g
    GraphPopup.hwnd := g.Hwnd

    g.OnEvent("Escape", (*) => GraphPopup.Dismiss(true))
    g.OnEvent("Close", (*) => GraphPopup.Dismiss(true))

    g.Show("xCenter y100 NoActivate")

    HotIf(GraphPopup._SpaceHotIf)
    Hotkey("Space", GraphPopup._TryDismissBySpace, "On")
    HotIf()
    GraphPopup.spaceBound := true

    return true
  }

  static Dismiss(focusBack := true) {
    if (GraphPopup.spaceBound) {
      HotIf(GraphPopup._SpaceHotIf)
      Hotkey("Space", GraphPopup._TryDismissBySpace, "Off")
      HotIf()
      GraphPopup.spaceBound := false
    }

    if IsObject(GraphPopup.gui) {
      try GraphPopup.gui.Destroy()
    }

    GraphPopup.gui := 0
    GraphPopup.hwnd := 0

    if (focusBack)
      WinActivate("ahk_exe deadlock.exe")
  }
}
