#Include paths.ahk
#Include debug.ahk

GetPoswatchPidPath() {
  return DATA_DIR "\poswatch.pid"
}

IsPidRunning(pidText) {
  pid := Integer(Trim(pidText))
  if (pid <= 0)
    return false
  return ProcessExist(pid) != 0
}

StopPoswatch() {
  pidFile := GetPoswatchPidPath()
  if !FileExist(pidFile)
    return

  pidText := ""
  try pidText := FileRead(pidFile, "UTF-8")

  pid := Integer(Trim(pidText))
  if (pid > 0 && ProcessExist(pid)) {
    try {
      ProcessClose(pid)
      Debug(A_ThisFunc ": terminated pid=" pid)
    }
  }

  try FileDelete(pidFile)
}


StartPoswatch() {
  ; TODO: make this path a variable, we use it in multiple places
  ps1 := DEADLOCK_ROOT "\dl-move-tracker.ps1"
  pidFile := GetPoswatchPidPath()

  if !FileExist(ps1) {
    Debug(A_ThisFunc ": missing " ps1)
    return false
  }

  if FileExist(pidFile) {
    oldPidText := FileRead(pidFile, "UTF-8")
    if (IsPidRunning(oldPidText)) {
      Debug(A_ThisFunc ": already running pid=" Trim(oldPidText))
      return true
    } else {
      try FileDelete(pidFile)
      Debug(A_ThisFunc ": stale pid file -> removed (" Trim(oldPidText) ")")
    }
  }


  exe := FindPowerShellExe()
  if (exe = "") {
    MsgBox "Couldn't find PowerShell (pwsh/powershell.exe).", "Movement Tracker", 48
    return false
  }

  args := Format(
    '-NoProfile -ExecutionPolicy Bypass -File "{1}" *> "{2}"',
    ps1,
    DEADLOCK_ROOT "\dl-move-tracker.stdout.log"
  )


  cmd := Format('"{1}" {2}', exe, args)

  try {
    Run(cmd, DEADLOCK_ROOT, "Hide", &pid)
    if FileExist(pidFile)
      FileDelete(pidFile)
    FileAppend(pid, pidFile, "UTF-8")
    Debug(A_ThisFunc ": started pid=" pid " cmd=" cmd)
    return true
  } catch as e {
    Debug(A_ThisFunc ": FAILED " e.Message " cmd=" cmd)
    MsgBox(
      "Failed to start poswatch.`n`n" cmd "`n`n" e.Message,
      "Movement Tracker",
      0x30
    )
    return false
  }
}

FindPowerShellExe() {
  tmp := A_Temp "\dlmvtrack_where_pwsh.txt"
  try FileDelete(tmp)

  cmd := A_ComSpec ' /c where.exe pwsh > "' tmp '" 2>nul'
  RunWait(cmd, , "Hide")

  if FileExist(tmp) {
    p := Trim(FileRead(tmp, "UTF-8"))
    ; where can return multiple lines; take first (NOTE: not sure abt that)
    p := StrSplit(p, "`n", "`r")[1]
    if (p != "" && FileExist(p))
      return p
  }

  p1 := A_WinDir "\System32\WindowsPowerShell\v1.0\powershell.exe"
  if FileExist(p1)
    return p1

  return ""
}
