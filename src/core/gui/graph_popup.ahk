#Include graph_daemon.ahk
#Include ..\instance.ahk
#Include ..\..\..\vendor\JXON_ahk2\_JXON.ahk

class GraphPopup {
  static gui := 0
  static hwnd := 0
  static spaceBound := false
  static pic := 0

  static _SpaceHotIf(*) {
    return WinActive("ahk_exe deadlock.exe")
      || (GraphPopup.hwnd && WinActive("ahk_id " GraphPopup.hwnd))
  }

  static _TryDismissBySpace(*) {
    if GraphPopup.hwnd && WinExist("ahk_id " GraphPopup.hwnd)
      GraphPopup.Dismiss(true)
  }

  static _Render(&pngOut, &csvOut, &titleOut, timeoutMs := 5000) {
    cur := GetCurrentRouteKey()
    if cur = ""
      return false

    ts := CURRENT_TIMESCALE

    csv := HistoryPath(cur)
    titleSuffix := ""
    if !Timescale_IsNormal() {
      csv := HistoryPath(cur, ts)
      tsPct := Round(ts * 100)
      titleSuffix := " (" tsPct "%)"
    }

    title := GetDisplayName(CURRENT_INSTANCE)
    if CURRENT_VARIATION != ""
      title .= VARIATION_SEPARATOR GetDisplayName(cur)
    title .= titleSuffix

    ; unique png every time to avoid caching
    png := A_Temp "\mvtrack_graph_" A_TickCount ".png"

    Debug("GraphPopup: cur='" cur "' csv='" csv "' ts=" ts " png='" png "' title='"
      title "'")

    respJson := GraphDaemon_Render(csv, png, title, timeoutMs)
    if respJson = ""
      return false

    try resp := Jxon_Load(&respJson)
    catch {
      Debug("Invalid JSON from daemon:")
      Debug(respJson)
      return false
    }

    error := resp.Has("error") && resp["error"] != ""
    Debug(
      "GraphPopup: daemon resp ok=" resp["ok"]
      " code=" resp["code"]
      (error ? " got error" : "")
    )

    if error {
      for _, line in StrSplit(resp["error"], "`n")
        Debug("python | " line)
    } else if resp.Has("stderr") && resp["stderr"] != "" {
      for _, line in StrSplit(resp["stderr"], "`n")
        Debug("python stderr | " line)
    }

    if !FileExist(png) || (FileGetSize(png) = 0)
      return false

    ; return values
    pngOut := png
    csvOut := csv
    titleOut := title
    return true
  }

  static Refresh() {
    if !(GraphPopup.hwnd && WinExist("ahk_id " GraphPopup.hwnd))
      return false
    if !IsObject(GraphPopup.gui) || !IsObject(GraphPopup.pic)
      return false

    png := "", csv := "", title := ""
    if !GraphPopup._Render(&png, &csv, &title, 5000)
      return false

    GraphPopup.pic.Value := png
    return true
  }

  static Show() {
    if GraphPopup.hwnd && WinExist("ahk_id " GraphPopup.hwnd)
      GraphPopup.Dismiss(false)

    cur := GetCurrentRouteKey()
    if cur = "" {
      WarnNoInstanceSelected()
      return false
    }

    png := "", csv := "", title := ""
    if !GraphPopup._Render(&png, &csv, &title, 5000)
      return false

    g := Gui("+AlwaysOnTop -Caption +ToolWindow")
    g.BackColor := "FFFFFF"
    g.MarginX := 10
    g.MarginY := 10

    GraphPopup.pic := g.AddPicture("w600 h300", png)
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
    if GraphPopup.spaceBound {
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
    GraphPopup.pic := 0

    if focusBack
      WinActivate("ahk_exe deadlock.exe")
  }
}
