#Include paths.ahk
#Include debug.ahk
#Include gui\yes_no_dontask.ahk

NormalizeCfgText(text) {
  if (SubStr(text, 1, 1) = Chr(0xFEFF))
    text := SubStr(text, 2)
  text := StrReplace(text, "`r`n", "`n")
  text := StrReplace(text, "`r", "`n")
  return text
}

CfgHasLine(text, pattern) {
  text := NormalizeCfgText(text)
  cmt := "(?:\s*(?://).*)?$"
  return RegExMatch(text, "im)^\s*" pattern "\s*" cmt)
}

HasSvCheats1(text) {
  return CfgHasLine(text, "sv_cheats\s+1")
}

HasExecMvtrack(text) {
  ; accept exec mvtrack.cfg (optionally quoted)
  ; exec "mvtrack.cfg"
  return CfgHasLine(text, 'exec\s+"?mvtrack\.cfg"?')
}

EnsureAutoexecConfigured() {
  autoexec := DEADLOCK_CFG_DIR "\autoexec.cfg"
  state := STATE_INI

  txt := ""
  if FileExist(autoexec) {
    try txt := FileRead(autoexec, "UTF-8")
    catch as e {
      Debug(A_ThisFunc ": couldn't read autoexec: " e.Message " path=" autoexec)
      txt := ""
    }
  }

  hasCheats := (txt != "") ? HasSvCheats1(txt) : false
  hasExec := (txt != "") ? HasExecMvtrack(txt) : false

  missingLines := []

  if (!hasCheats)
    missingLines.Push("sv_cheats 1")
  if (!hasExec)
    missingLines.Push("exec mvtrack.cfg")

  if (missingLines.Length = 0) {
    Debug(A_ThisFunc ": autoexec already contains required lines: " autoexec)
    return true
  }

  missingText := ""
  for _, line in missingLines
    missingText .= line "  // added by deadlock-movement-tracker`n"

  pretty := ""
  for _, line in missingLines
    pretty .= "  " line "`n"

  skip := IniRead(state, "ui", "skip_autoexec_prompt", "0")
  if (skip = "1") {
    Debug(A_ThisFunc ": skipped (dont ask again)")
    return false
  }

  res := ConfirmWithDontAskAgain(
    "Movement Tracker",
    "Your Deadlock autoexec.cfg is missing some lines required for the tracker to run:`n`n"
    . pretty
    . "`nAutomatically add the required line(s) now?`n`n"
    . autoexec
  )

  if (res.result = "No") {
    if (res.dontAsk) {
      IniWrite "1", state, "ui", "skip_autoexec_prompt"
      Debug(A_ThisFunc ": user declined + dont ask again")
    }
    MsgBox(
      "If you are sure that autoexec.cfg already contains the required lines,"
      . " it would be appreciated if you report this false positive.`n`n"
      . "TY!",
      "Movement Tracker",
      0x30
    )
    Debug(A_ThisFunc ": user declined autoexec change: " autoexec)
    return false
  }

  try {
    if !FileExist(autoexec) {
      FileAppend("// autoexec.cfg (created by deadlock-movement-tracker)`n"
        "// you can edit this file to add your own commands as needed`n"
        , autoexec, "UTF-8-RAW")
      Debug(A_ThisFunc ": created " autoexec)

    } else {

      norm := NormalizeCfgText(txt)
      if (norm != "" && SubStr(norm, -1) != "`n")
        FileAppend("`n", autoexec, "UTF-8-RAW")
      if (Trim(norm) != "")
        FileAppend("`n", autoexec, "UTF-8-RAW")
    }

    FileAppend(missingText, autoexec, "UTF-8-RAW")
    Debug(A_ThisFunc ": appended missing lines to " autoexec)
    return true

  } catch as e {
    err := ""
    try err := "Message: " e.Message "`nWhat: " e.What "`nExtra: " e.Extra "`nFile: " e.File "`nLine: " e.Line
    Debug(A_ThisFunc ": FAILED`n" err)
    MsgBox(
      "Failed to update autoexec.cfg.`n`n"
      . autoexec "`n`n"
      . err,
      "Movement Tracker",
      0x30
    )
    return false
  }
}
