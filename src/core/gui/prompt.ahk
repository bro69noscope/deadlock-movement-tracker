PromptName(promptText, defaultValue := "") {
  g := Gui("+AlwaysOnTop +ToolWindow -MinimizeBox", "Tracker")
  g.MarginX := 12
  g.MarginY := 10
  g.__picked := ""

  g.AddText(, promptText)
  ed := g.AddEdit("w280", defaultValue)

  ok := g.AddButton("xm w120 Default", "OK")
  cancel := g.AddButton("x+10 w120", "Cancel")

  ok.OnEvent("Click", (*) => (g.__picked := Trim(ed.Value), g.Destroy()))
  cancel.OnEvent("Click", (*) => (g.__picked := "", g.Destroy()))
  g.OnEvent("Close", (*) => (g.__picked := "", g.Destroy()))
  g.OnEvent("Escape", (*) => (g.__picked := "", g.Destroy()))

  g.Show()
  WinActivate("ahk_id " g.Hwnd)
  WinWaitClose("ahk_id " g.Hwnd)

  return g.__picked
}
