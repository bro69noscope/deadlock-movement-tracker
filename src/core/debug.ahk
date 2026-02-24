#Include config.ahk
#Include paths.ahk

global DEBUG_LOG_PATH := PROJECT_ROOT "\logs\debug.log"
global UNINSTALL_LOG_PATH := PROJECT_ROOT "\logs\uninstall.log"
global DEBUG_UNINSTALL := false

global MAX_LOG_BYTES := 3 * 1024 * 1024
global MAX_LOG_BACKUPS := 3

global CUR_LOG_FILE := 0
global CUR_LOG_PATH := ""

GetLogPath() {
  return DEBUG_UNINSTALL ? UNINSTALL_LOG_PATH : DEBUG_LOG_PATH
}

EnsureLogDirExists() {
  logPath := GetLogPath()
  SplitPath logPath, , &dir
  if !DirExist(dir)
    DirCreate(dir)

  RotateLogIfTooBig(logPath)
}

GetLogFile() {
  global CUR_LOG_FILE, CUR_LOG_PATH
  path := GetLogPath()

  if (!CUR_LOG_FILE || CUR_LOG_PATH != path) {
    ; switch log target if DEBUG_UNINSTALL toggles
    try CUR_LOG_FILE.Close()
    EnsureLogDirExists()
    CUR_LOG_FILE := FileOpen(path, "a", "UTF-8")
    CUR_LOG_PATH := path
  }
  return CUR_LOG_FILE
}

FlushLog() {
  global CUR_LOG_FILE
  if CUR_LOG_FILE
    DllCall("FlushFileBuffers", "ptr", CUR_LOG_FILE.Handle)
}

RotateLogIfTooBig(logPath) {
  global MAX_LOG_BYTES, MAX_LOG_BACKUPS

  if !FileExist(logPath)
    return

  size := 0
  try size := FileGetSize(logPath)
  catch
    return

  if size <= MAX_LOG_BYTES
    return

  Loop MAX_LOG_BACKUPS - 1 {
    n := (MAX_LOG_BACKUPS - A_Index)
    older := logPath "." n
    newer := logPath "." (n + 1)
    if FileExist(older) {
      try {
        if FileExist(newer)
          FileDelete(newer)
        FileMove(older, newer, 1)
      }
    }
  }

  try {
    first := logPath ".1"
    if FileExist(first)
      FileDelete(first)
    FileMove(logPath, first, 1)
  } catch {
    return
  }

  try FileAppend("---- log rotated at " FormatTs() " ----`n", logPath, "UTF-8")
}

FormatTs() {
  ts := A_Now
  return SubStr(ts, 1, 4) "-" SubStr(ts, 5, 2) "-" SubStr(ts, 7, 2)
    . " " SubStr(ts, 9, 2) ":" SubStr(ts, 11, 2) ":" SubStr(ts, 13, 2)
}

FormatTsMs() {
  ts := A_Now
  return SubStr(ts, 1, 4) "-" SubStr(ts, 5, 2) "-" SubStr(ts, 7, 2)
    . " " SubStr(ts, 9, 2) ":" SubStr(ts, 11, 2) ":" SubStr(ts, 13, 2)
    . "." Format("{:03}", A_MSec)
}


Debug(msg) {
  f := GetLogFile()
  f.Write(FormatTsMs() " | " msg "`n")
}

; Logs a file's existence + size + mtime (helps detect wrong paths)
DebugFile(label, path) {
  exists := FileExist(path) ? "yes" : "no"
  size := ""
  mt := ""
  try size := FileGetSize(path)
  try mt := FileGetTime(path, "M")
  Debug(label ": exists=" exists " size=" size " mtime=" mt " path=" path)
}

DebugBlank() {
  EnsureLogDirExists()
  FileAppend("`n", GetLogPath(), "UTF-8")
}
