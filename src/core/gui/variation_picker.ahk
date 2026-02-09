; variations are stored in base section as: v1|v2|v3
#Include ..\paths.ahk

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

  shown := []
  Loop Min(9, vars.Length)
    shown.Push(vars[A_Index])

  msg := "Select variation for:`n`n " baseName

  g := Gui("+AlwaysOnTop +ToolWindow -MinimizeBox", "Variation")
  g.MarginX := 12
  g.MarginY := 10
  g.__picked := "__cancel__"
  g.__shown := shown

  g.AddText("w360", msg)
  g.SetFont("s9")
  g.AddText("y+20", "Press 0-9 (or Esc to cancel)")

  g.SetFont("s10")
  g.AddButton("xm w" BTN_WIDTH, "0: Main (" baseName ")")
    .OnEvent("Click", (*) => (g.__picked := "__main__", g.Destroy()))

  PickIdx(guiObj, idx, *) {
    arr := guiObj.__shown
    guiObj.__picked := arr[idx]
    guiObj.Destroy()
  }

  Loop shown.Length {
    idx := A_Index
    label := idx ": " shown[idx]
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
  Loop shown.Length {
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
    Loop shown.Length
      Hotkey("" A_Index, "Off")
    Hotkey("Escape", "Off")
    HotIf()
  }

  return (g.__picked = "__cancel__") ? "__cancel__" : g.__picked
}
