#Include paths.ahk
#Include debug.ahk
#Include ps1_launcher.ahk
#Include autoexec_installer.ahk
#Include helpers.ahk

SafeDelete(path) {
  if !FileExist(path)
    return true
  try {
    FileDelete(path)
    Debug(A_ThisFunc ": deleted " path)
    return true
  } catch as e {
    Debug(A_ThisFunc ": FAILED delete " path " | " e.Message)
    return false
  }
}

SafeDirDelete(dir) {
  if !DirExist(dir)
    return true
  try {
    DirDelete(dir, 1)
    Debug(A_ThisFunc ": deleted dir " dir)
    return true
  } catch as e {
    Debug(A_ThisFunc ": FAILED delete dir " dir " | " e.Message)
    return false
  }
}

RemoveAutoexecLines(&removedLines := "", &autoexecPath := "") {
  autoexec := DEADLOCK_CFG_DIR "\autoexec.cfg"
  autoexecPath := autoexec
  removedLines := ""

  if !FileExist(autoexec) {
    Debug(A_ThisFunc ": no autoexec.cfg found -> skip")
    return true
  }

  txt := ""
  try txt := FileRead(autoexec, "UTF-8")
  catch as e {
    Debug(A_ThisFunc ": couldn't read autoexec: " e.Message " path=" autoexec)
    return false
  }

  norm := NormalizeCfgText(txt)
  lines := StrSplit(norm, "`n", "`r")

  outLines := []
  removed := 0

  for _, line in lines {
    original := line
    l := Trim(line)

    if (l = "") {
      outLines.Push(original)
      continue
    }

    if RegExMatch(l, 'i)^\s*exec\s+"?mvtrack\.cfg"?\b') {
      removed += 1
      removedLines .= "  - " original "`n"
      continue
    }

    outLines.Push(original)
  }

  if (removed = 0) {
    Debug(A_ThisFunc ": nothing to remove in autoexec.cfg")
    return true
  }

  out := ""
  for _, l2 in outLines
    out .= l2 "`n"

  try {
    tmp := autoexec ".tmp"
    try FileDelete(tmp)
    FileAppend(out, tmp, "UTF-8-RAW")
    try FileDelete(autoexec)
    FileMove(tmp, autoexec, 1)

    Debug(A_ThisFunc ": removed " removed " line(s) from " autoexec)
    Debug(A_ThisFunc ": removed lines:`n" removedLines)
    return true
  } catch as e {
    Debug(A_ThisFunc ": FAILED write autoexec: " e.Message " path=" autoexec)
    return false
  }
}


Uninstall() {
  title := "Movement Tracker Uninstall"
  SplitPath MVTRACK_CFG_EXEC_PATH, &mvTrackCfgFile
  SplitPath MVTRACK_CFG_POS_PATH, &mvTrackPosFile
  SplitPath MVTRACK_PS1_PATH, &mvTrackPs1File
  SplitPath LASTPOS_CFG_PATH, &lastPosFile

  choice := MsgBox(
    "This will uninstall Movement Tracker files:" "`n"
    "- " mvTrackCfgFile "`n"
    "- " mvTrackPosFile "`n"
    "- " mvTrackPs1File "`n"
    "- " lastPosFile "`n"
    "- stop the poswatch process" "`n"
    "`nContinue?",
    title,
    "YesNo Icon!"
  )
  if (choice = "No")
    return false


  wipeData := (MsgBox(
    "Wipe instances and their history too ?" "`n`n",
    title,
    "YesNo Icon!"
  ) = "Yes")

  global DEBUG_UNINSTALL := true
  DebugBlank()
  Debug("=== " A_ThisFunc ": starting uninstall; wipeData=" wipeData " ===")
  try StopPoswatch()

  SafeDelete(MVTRACK_CFG_EXEC_PATH)
  SafeDelete(MVTRACK_CFG_POS_PATH)
  SafeDelete(MVTRACK_PS1_PATH)
  SafeDelete(LASTPOS_CFG_PATH)
  SafeDelete(RegExReplace(MVTRACK_PS1_PATH, "\.ps1$", ".log"))
  SafeDelete(DATA_DIR "\poswatch.pid")

  removedText := ""
  autoexecPath := ""
  okAuto := RemoveAutoexecLines(&removedText, &autoexecPath)

  if (!okAuto) {
    MsgBox("Failed to edit autoexec.cfg:" "`n" autoexecPath, title, 0x30)
  } else if (removedText != "") {
    MsgBox(
      "Automatically removed these lines from autoexec.cfg ✓:" "`n"
      removedText,
      title,
      0x40
    )
  }


  if (wipeData) {
    SafeDirDelete(DATA_DIR)
  }

  MsgBox("Uninstall complete.", title, 0x40)
  return true
}
