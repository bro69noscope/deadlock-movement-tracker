#Include debug.ahk
#Include state.ahk
#Include perf.ahk

class RouteTimer {

  static armed := false
  static running := false
  static startTick := 0
  static lastMs := 0
  static keysOn := false

  static gui := 0
  static timeTxt := 0
  static timeScaleTxt := 0
  static visTimerOn := false
  static coord := "x55 y-2 NA"

  static cbTick := 0
  static cbVis := 0

  static _InitCallbacks() {
    if !RouteTimer.cbTick
      RouteTimer.cbTick := ObjBindMethod(RouteTimer, "_Tick")
    if !RouteTimer.cbVis
      RouteTimer.cbVis := ObjBindMethod(RouteTimer, "_VisibilityTick")
  }

  static _EnableMoveKeys() {
    if RouteTimer.keysOn
      return
    RouteTimer.keysOn := true
    Debug("RouteTimer: listening for move keys")

    Perf.Step("RouteTimer:" A_ThisFunc " before registering hotkeys")
    HotKey("~w", RouteTimer._OnMoveKey, "On")
    HotKey("~a", RouteTimer._OnMoveKey, "On")
    HotKey("~s", RouteTimer._OnMoveKey, "On")
    HotKey("~d", RouteTimer._OnMoveKey, "On")
    Perf.Step("RouteTimer:" A_ThisFunc " after registering hotkeys")
  }

  static _DisableMoveKeys() {
    if !RouteTimer.keysOn
      return
    RouteTimer.keysOn := false
    Debug("RouteTimer: stop listening for move keys")

    Perf.Step("RouteTimer:" A_ThisFunc " before unregistering hotkeys")
    HotKey("~w", RouteTimer._OnMoveKey, "Off")
    HotKey("~a", RouteTimer._OnMoveKey, "Off")
    HotKey("~s", RouteTimer._OnMoveKey, "Off")
    HotKey("~d", RouteTimer._OnMoveKey, "Off")
    Perf.Step("RouteTimer:" A_ThisFunc " after unregistering hotkeys")
  }

  static _OnMoveKey(*) {
    Critical "On"

    if !WinActive("ahk_exe deadlock.exe")
      return

    if !RouteTimer.armed || RouteTimer.running
      return

    RouteTimer.armed := false
    RouteTimer._DisableMoveKeys()
    RouteTimer._Start()
  }

  static _VisibilityTick(*) {
    RouteTimer._EnsureGui()
    if WinActive("ahk_exe deadlock.exe")
      RouteTimer.gui.Show(RouteTimer.coord)
    else
      RouteTimer.gui.Hide()
  }

  static _TimeScaleString() {
    ts := (CURRENT_TIMESCALE = "" ? 1 : CURRENT_TIMESCALE + 0)
    if ts = 1
      return ""
    return Round(ts * 100) "%"
  }

  static _EnsureGui() {
    if IsObject(RouteTimer.gui)
      return

    g := Gui("+AlwaysOnTop +ToolWindow -Caption +E0x20 +E0x80000", "Route Timer")
    g.BackColor := "Black"
    g.MarginX := 6
    g.MarginY := 4
    g.SetFont("s14 cb0b0b0", "Segoe UI Semibold")

    timeW := 90
    tsW := 46
    gap := 6

    RouteTimer.timeTxt := g.AddText("BackgroundTrans w" timeW " Right", "0.000s")
    RouteTimer.timeScaleTxt := g.AddText("x+" gap " BackgroundTrans w" tsW " Left",
      RouteTimer._TimeScaleString())

    RouteTimer.gui := g
    g.Show(RouteTimer.coord)
    WinSetTransColor("Black", g.Hwnd)
  }

  static _SetText(text) {
    RouteTimer._EnsureGui()
    RouteTimer.timeTxt.Text := text
    RouteTimer.timeScaleTxt.Text := RouteTimer._TimeScaleString()
  }

  static _Tick(*) {
    if !RouteTimer.running
      return
    ms := A_TickCount - RouteTimer.startTick
    RouteTimer._SetText(RouteTimer._Format(ms))
  }

  static _Start() {
    if RouteTimer.running
      return
    RouteTimer.running := true
    RouteTimer.startTick := A_TickCount
    SetTimer(RouteTimer.cbTick, 30)
  }

  static _Format(ms) {
    if ms < 0
      ms := 0

    totalSec := Floor(ms / 1000)
    m := Floor(totalSec / 60)
    s := Mod(totalSec, 60)
    milli := Mod(ms, 1000)

    if m > 0
      return Format("{1:02d}:{2:02d}.{3:03d}", m, s, milli)
    else
      return Format("{1}.{2:03d}s", s, milli)
  }

  static StartVisibilityWatcher() {
    RouteTimer._InitCallbacks()
    if RouteTimer.visTimerOn
      return
    RouteTimer.visTimerOn := true
    RouteTimer._VisibilityTick()
    SetTimer(RouteTimer.cbVis, 150)
  }

  static RefreshOverlay() {
    RouteTimer._EnsureGui()

    if RouteTimer.running {
      ms := A_TickCount - RouteTimer.startTick
      RouteTimer._SetText(RouteTimer._Format(ms))
    } else if RouteTimer.lastMs > 0 {
      RouteTimer._SetText(RouteTimer._Format(RouteTimer.lastMs))
    } else {
      RouteTimer._SetText("0.000s")
    }
  }

  static Arm() {
    Perf.Step("RouteTimer: " A_ThisFunc " init")
    RouteTimer._EnsureGui()
    Perf.Step("RouteTimer: " A_ThisFunc " ensure GUI")

    if RouteTimer.running {
      RouteTimer.running := false
      SetTimer(RouteTimer.cbTick, 0)
    }

    RouteTimer.armed := true
    RouteTimer.lastMs := 0
    RouteTimer._SetText("0.000s")
    RouteTimer._EnableMoveKeys()
    Perf.Step("RouteTimer: " A_ThisFunc " done")
  }

  static Disarm() {
    RouteTimer.armed := false
    RouteTimer._DisableMoveKeys()
  }

  static Stop() {
    if !RouteTimer.running
      return 0

    RouteTimer.lastMs := A_TickCount - RouteTimer.startTick
    RouteTimer.running := false
    SetTimer(RouteTimer.cbTick, 0)

    RouteTimer._DisableMoveKeys()
    RouteTimer._SetText(RouteTimer._Format(RouteTimer.lastMs))
    return RouteTimer.lastMs
  }

  static IsRunning() {
    return RouteTimer.running
  }
}
