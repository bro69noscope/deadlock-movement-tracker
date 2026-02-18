#Include ..\paths.ahk
#Include ..\helpers.ahk

ListInstances(variationSeparator) {
  txt := ""
  try {
    txt := IniRead(INSTANCES_INI)
  } catch {
    txt := ""
  }

  all := []
  for _, raw in StrSplit(txt, "`n", "`r") {
    s := Trim(raw)
    if s = "" || s = "__global__"
      continue
    if InStr(s, variationSeparator)
      continue

    all.Push(s)
  }

  if all.Length = 0 {
    MsgBox(
      "No instances found.`nPress " CFG.new
      " to create a new instance.",
      "Instance Picker",
      0x30
    )
    return ""
  }

  ; Sort (provided by vendor/ahk-v2-libraries/Lib/Array.ahk)
  all.Sort((a, b) => (
    StrCompare(GetDisplayName(a), GetDisplayName(b), true)
  ))

  g := Gui("+AlwaysOnTop +ToolWindow -MinimizeBox", "Instances")
  g.MarginX := 12
  g.MarginY := 10
  g.__picked := ""
  g.__all := all

  g.AddText(, "Search:")
  ed := g.AddEdit("w380")
  g.AddText("y+6", "Instances (Enter = select, Esc = cancel):")

  display := []
  for _, key in all
    display.Push(GetDisplayName(key))

  g.__keys := all

  lb := g.AddListBox("w380 r14", display)
  lb.Choose(1)

  g.__lbCount := display.Length
  g.__ed := ed
  g.__lb := lb

  ok := g.AddButton("xm w120 Default", "Select")
  cancel := g.AddButton("x+10 w120", "Cancel")

  ; --- handlers as plain functions using g as state ---
  ApplyFilterGui(guiObj) {
    ed2 := guiObj.__ed
    lb2 := guiObj.__lb
    all2 := guiObj.__all

    q := Trim(ed2.Value)
    q := RegExReplace(q, "\s+")
    q := StrLower(q)

    pairsOut := []

    if q = "" {
      for _, key in all2
        pairsOut.Push({ key: key, label: GetDisplayName(key) })
    } else {
      scored := []
      for _, key in all2 {
        label := GetDisplayName(key)
        sc := FuzzyScore(q, StrLower(label))
        if sc != ""
          scored.Push({ score: sc, key: key, label: label })
      }

      scored.Sort((a, b) => (
        a.score > b.score ? -1
        : a.score < b.score ? 1
        : StrCompare(a.label, b.label, true)
      ))

      for _, it in scored
        pairsOut.Push({ key: it.key, label: it.label })
    }

    ; update listbox + keys mapping
    newLabels := []
    newKeys := []
    for _, it in pairsOut {
      newLabels.Push(it.label)
      newKeys.Push(it.key)
    }

    lb2.Delete()
    guiObj.__keys := newKeys
    if newLabels.Length {
      lb2.Add(newLabels)
      lb2.Choose(1)
    }
    guiObj.__lbCount := newLabels.Length
  }

  ComparePairs(a, b) {
    if a.score > b.score
      return -1
    if a.score < b.score
      return 1
    return StrCompare(a.name, b.name, true)
  }

  ; returns integer score (higher better) or "" for no match
  FuzzyScore(needle, hay) {
    nLen := StrLen(needle)
    hLen := StrLen(hay)
    if nLen = 0
      return 0
    if hLen = 0
      return ""
    nIdx := 1
    score := 0
    consec := 0
    firstPos := 0
    lastPos := 0

    Loop hLen {
      cH := SubStr(hay, A_Index, 1)
      cN := SubStr(needle, nIdx, 1)

      if cH = cN {
        if firstPos = 0
          firstPos := A_Index

        if lastPos = A_Index - 1 {
          consec += 1
          score += 25 + (consec * 10)
        } else {
          consec := 0
          score += 10
        }

        ; earlier starts are better
        score += Max(0, 30 - firstPos)

        lastPos := A_Index
        nIdx += 1
        if nIdx > nLen
          break
      }
    }

    if nIdx <= nLen
      return ""  ; didn't match all chars in order

    ; prefer tighter/shorter names a bit
    score -= Floor(hLen / 2)

    return score
  }


  SelectCurrentGui(guiObj) {
    idx := guiObj.__lb.Value
    if idx <= 0
      return
    guiObj.__picked := guiObj.__keys[idx]
    guiObj.Destroy()
  }

  CancelGui(guiObj) {
    guiObj.__picked := ""
    guiObj.Destroy()
  }

  ; wire events
  ed.OnEvent("Change", (*) => ApplyFilterGui(g))
  ok.OnEvent("Click", (*) => SelectCurrentGui(g))
  cancel.OnEvent("Click", (*) => CancelGui(g))
  lb.OnEvent("DoubleClick", (*) => SelectCurrentGui(g))
  g.OnEvent("Close", (*) => CancelGui(g))
  g.OnEvent("Escape", (*) => CancelGui(g))

  g.Show()
  ed.Focus()

  hwnd := g.Hwnd

  hotIfFn := (*) => WinActive("ahk_id " hwnd)

  HotIf(hotIfFn)
  Hotkey("Enter", (*) => SelectCurrentGui(g), "On")
  Hotkey("Escape", (*) => CancelGui(g), "On")
  Hotkey("Up", (*) => (
    g.__lbCount > 0 ? g.__lb.Choose(Max(1, g.__lb.Value - 1)) : 0
  ), "On")
  Hotkey("Down", (*) => (
    g.__lbCount > 0 ? g.__lb.Choose(Min(g.__lbCount, g.__lb.Value + 1)) : 0
  ), "On")
  HotIf()

  try {
    WinWaitClose("ahk_id " hwnd)
  } finally {
    HotIf(hotIfFn)
    Hotkey("Enter", "Off")
    Hotkey("Escape", "Off")
    Hotkey("Up", "Off")
    Hotkey("Down", "Off")
    HotIf()
  }

  return Trim(g.__picked)
}
