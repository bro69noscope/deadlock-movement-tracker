#Include config.ahk
#Include ../settings/user_config.ahk
global DEBUG_LOG := DATA_DIR "\debug.log"
Debug(msg) {
  if (!ENABLE_DEBUG)
    return
  global DEBUG_LOG
  ts := A_Now
  line := SubStr(ts, 1, 4) "-" SubStr(ts, 5, 2) "-" SubStr(ts, 7, 2)
    . " " SubStr(ts, 9, 2) ":" SubStr(ts, 11, 2) ":" SubStr(ts, 13, 2)
    . " | " msg "`n"
  ; UTF-8 is fine for our own logs
  FileAppend(line, DEBUG_LOG, "UTF-8")
}

; Logs a file's existence + size + mtime (helps detect wrong paths)
DebugFile(label, path) {
  if (!ENABLE_DEBUG)
    return
  exists := FileExist(path) ? "yes" : "no"
  size := ""
  mt := ""
  try size := FileGetSize(path)
  try mt := FileGetTime(path, "M")
  Debug(label ": exists=" exists " size=" size " mtime=" mt " path=" path)
}
