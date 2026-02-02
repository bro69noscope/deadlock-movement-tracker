#Include ..\paths.ahk

ListInstances() {
  txt := ""
  try {
    txt := IniRead(INSTANCES_INI)
  } catch {
    txt := ""
  }

  all := []
  for _, raw in StrSplit(txt, "`n", "`r") {
    s := Trim(raw)
    if (s = "" || s = "__global__")
      continue
    all.Push(s)
  }

  if (all.Length = 0) {
    MsgBox(
      "No instances found.`nPress " CFG.new
      " to create a new instance.",
      "Instance Picker",
      0x30
    )
    return ""
  }

  ; Sort (provided by vendor/ahk-v2-libraries/Lib/Array.ahk)
  all.Sort((a, b) => StrCompare(a, b, true))

  g := Gui("+AlwaysOnTop +ToolWindow -MinimizeBox", "Instances")
  g.MarginX := 12
  g.MarginY := 10

  ; stash state on the gui object (no closure capture needed)
  g.__picked := ""
  g.__all := all

  g.AddText(, "Search:")
  ed := g.AddEdit("w380")
  g.AddText("y+6", "Instances (Enter = select, Esc = cancel):")
  lb := g.AddListBox("w380 r14", all)
  lb.Choose(1)

  g.__lbCount := all.Length
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

    matches := []

    if (q = "") {
      ; no filter -> show original list (already sorted)
      for _, name in all2
        matches.Push(name)
    } else {
      pairs := []

      for _, name in all2 {
        sc := FuzzyScore(q, StrLower(name))
        if (sc != "")
          pairs.Push({ score: sc, name: name })
      }

      ; sort by score desc, then name asc
      pairs.Sort(ComparePairs)

      for _, p in pairs
        matches.Push(p.name)
    }

    lb2.Delete()
    if (matches.Length) {
      lb2.Add(matches)
      lb2.Choose(1)
    }
    guiObj.__lbCount := matches.Length
  }

  ComparePairs(a, b) {
    if (a.score > b.score)
      return -1
    if (a.score < b.score)
      return 1
    return StrCompare(a.name, b.name, true)
  }

  ; returns integer score (higher better) or "" for no match
  FuzzyScore(needle, hay) {
    nLen := StrLen(needle)
    hLen := StrLen(hay)
    if (nLen = 0)
      return 0
    if (hLen = 0)
      return ""
    nIdx := 1
    score := 0
    consec := 0
    firstPos := 0
    lastPos := 0

    Loop hLen {
      cH := SubStr(hay, A_Index, 1)
      cN := SubStr(needle, nIdx, 1)

      if (cH = cN) {
        if (firstPos = 0)
          firstPos := A_Index

        if (lastPos = A_Index - 1) {
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
        if (nIdx > nLen)
          break
      }
    }

    if (nIdx <= nLen)
      return ""  ; didn't match all chars in order

    ; prefer tighter/shorter names a bit
    score -= Floor(hLen / 2)

    return score
  }


  SelectCurrentGui(guiObj) {
    lb2 := guiObj.__lb
    t := lb2.Text
    if (t = "")
      return
    guiObj.__picked := t
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

  hwnd := g.Hwnd  ; valid now

  ; hotkeys active only when this gui is active
  HotIf((*) => WinActive("ahk_id " hwnd))
  Hotkey("Enter", (*) => SelectCurrentGui(g), "On")
  Hotkey("Escape", (*) => CancelGui(g), "On")
  Hotkey("Up", (*) => (
    g.__lbCount > 0 ? g.__lb.Choose(Max(1, g.__lb.Value - 1)) : 0
  ), "On")
  Hotkey("Down", (*) => (
    g.__lbCount > 0 ? g.__lb.Choose(Min(g.__lbCount, g.__lb.Value + 1)) : 0
  ), "On")
  HotIf()

  WinWaitClose("ahk_id " hwnd)
  return Trim(g.__picked)
}
