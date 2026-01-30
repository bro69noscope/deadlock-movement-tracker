PromptName(promptText, defaultValue := "") {
  ib := InputBox(promptText, "Tracker", "w360", defaultValue)
  if (ib.Result != "OK")
    return ""
  return Trim(ib.Value)
}
