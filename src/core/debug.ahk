#Include config.ahk
global DEBUG_LOG := A_ScriptDir "\logs\debug.log"
global UNINSTALL_LOG := A_ScriptDir "\logs\uninstall.log"
global DEBUG_UNINSTALL := false

GetLogPath() {
  global DEBUG_UNINSTALL, DEBUG_LOG, UNINSTALL_LOG
  return DEBUG_UNINSTALL ? UNINSTALL_LOG : DEBUG_LOG
}

EnsureLogDirExists() {
  logPath := GetLogPath()
  SplitPath logPath, , &dir
  if !DirExist(dir)
    DirCreate(dir)
}

Debug(msg) {
  if (!DEBUG_UNINSTALL && !CFG.enable_debug)
    return

  EnsureLogDirExists()
  logPath := GetLogPath()

  ts := A_Now
  line := SubStr(ts, 1, 4) "-" SubStr(ts, 5, 2) "-" SubStr(ts, 7, 2)
    . " " SubStr(ts, 9, 2) ":" SubStr(ts, 11, 2) ":" SubStr(ts, 13, 2)
    . " | " msg "`n"

  FileAppend(line, logPath, "UTF-8")
}

; Logs a file's existence + size + mtime (helps detect wrong paths)
DebugFile(label, path) {
  if (!CFG.enable_debug)
    return
  exists := FileExist(path) ? "yes" : "no"
  size := ""
  mt := ""
  try size := FileGetSize(path)
  try mt := FileGetTime(path, "M")
  Debug(label ": exists=" exists " size=" size " mtime=" mt " path=" path)
}


DebugBlank() {
  if (!DEBUG_UNINSTALL && !CFG.enable_debug)
    return

  EnsureLogDirExists()
  FileAppend("`n", GetLogPath(), "UTF-8")
}
