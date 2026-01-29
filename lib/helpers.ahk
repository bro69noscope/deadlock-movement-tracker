PromptName(promptText, defaultValue := "") {
  ib := InputBox(promptText, "Tracker", "w360", defaultValue)
  if (ib.Result != "OK")
    return ""
  return Trim(ib.Value)
}

NowStamp() {
  t := A_Now
  return SubStr(t, 1, 4) "-" SubStr(t, 5, 2) "-" SubStr(t, 7, 2)
    . " " SubStr(t, 9, 2) ":" SubStr(t, 11, 2) ":" SubStr(t, 13, 2)
}
