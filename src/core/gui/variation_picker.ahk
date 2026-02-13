; variations are stored in base section as: v1|v2|v3
#Include ..\paths.ahk
#Include ..\helpers.ahk
#Include ..\state.ahk

ReadVariations(baseName) {
  ini := INSTANCES_INI
  raw := IniRead(ini, baseName, "variations", "")
  raw := Trim(raw)
  if (raw = "")
    return []

  out := []
  for _, v in StrSplit(raw, "|") {
    v := Trim(v)
    if (v != "")
      out.Push(v)
  }
  return out
}

PickVariationForBase(baseName) {
  BTN_WIDTH := 220
  vars := ReadVariations(baseName)
  if (vars.Length = 0)
    return ""

  shownKeys := []
  shownLabels := []

  Loop Min(9, vars.Length) {
    varKey := vars[A_Index]
    shownKeys.Push(varKey)

    routeKey := baseName VARIATION_SEPARATOR varKey
    varLabel := GetDisplayName(routeKey)
    shownLabels.Push(varLabel)
  }

  msg := "Select variation for:`n`n " baseName

  g := Gui("+AlwaysOnTop +ToolWindow -MinimizeBox", "Variation")
  g.MarginX := 12
  g.MarginY := 10
  g.__picked := "__cancel__"
  g.__shownKeys := shownKeys
  g.__shownLabels := shownLabels

  g.AddText("w360", msg)
  g.SetFont("s9")
  g.AddText("y+20", "Press 0-9 (or Esc to cancel)")

  g.SetFont("s10")
  g.AddButton("xm w" BTN_WIDTH, "0: Main (" baseName ")")
    .OnEvent("Click", (*) => (g.__picked := "__main__", g.Destroy()))

  PickIdx(guiObj, idx, *) {
    keys := guiObj.__shownKeys
    guiObj.__picked := keys[idx]
    guiObj.Destroy()
  }

  Loop shownLabels.Length {
    idx := A_Index
    label := idx ": " shownLabels[idx]
    b := g.AddButton("xm y+6 w" BTN_WIDTH, label)
    b.OnEvent("Click", PickIdx.Bind(g, idx))
  }

  g.OnEvent("Escape", (*) => (g.__picked := "__cancel__", g.Destroy()))
  g.OnEvent("Close", (*) => (g.__picked := "__cancel__", g.Destroy()))

  g.Show("AutoSize")
  hwnd := g.Hwnd

  hotIfFn := (*) => WinActive("ahk_id " hwnd)

  HotIf(hotIfFn)
  Hotkey("0", (*) => (g.__picked := "__main__", g.Destroy()), "On")
  Loop shownKeys.Length {
    idx := A_Index
    Hotkey("" idx, PickIdx.Bind(g, idx), "On")
  }
  Hotkey("Escape", (*) => (g.__picked := "__cancel__", g.Destroy()), "On")
  HotIf()

  try {
    WinWaitClose("ahk_id " hwnd)
  } finally {
    HotIf(hotIfFn)
    Hotkey("0", "Off")
    Loop shownKeys.Length
      Hotkey("" A_Index, "Off")
    Hotkey("Escape", "Off")
    HotIf()
  }

  return (g.__picked = "__cancel__") ? "__cancel__" : g.__picked
}
