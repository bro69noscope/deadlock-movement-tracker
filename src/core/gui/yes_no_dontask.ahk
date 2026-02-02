ConfirmWithDontAskAgain(title, message) {
  g := Gui("+AlwaysOnTop +ToolWindow -MinimizeBox", title)
  g.MarginX := 12
  g.MarginY := 10
  g.__result := "No"
  g.__dontAsk := false

  g.AddText("w420", message)

  cb := g.AddCheckbox("xm y+10", "Don't ask me again")
  ok := g.AddButton("xm y+10 w120 Default", "Yes")
  cancel := g.AddButton("x+10 w120", "No")

  ok.OnEvent("Click", (*) => (
    g.__dontAsk := cb.Value,
    g.__result := "Yes",
    g.Destroy()
  ))

  cancel.OnEvent("Click", (*) => (
    g.__dontAsk := cb.Value,
    g.__result := "No",
    g.Destroy()
  ))

  g.Show()
  WinWaitClose("ahk_id " g.Hwnd)

  return { result: g.__result, dontAsk: g.__dontAsk }
}
