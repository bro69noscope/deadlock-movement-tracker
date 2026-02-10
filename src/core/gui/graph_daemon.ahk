#Include ..\paths.ahk
#Include ..\debug.ahk
#Include ..\helpers.ahk

global GRAPH_DAEMON_DIR := A_Temp "\mvtrack_graph"
global GRAPH_REQ_DIR := GRAPH_DAEMON_DIR "\req"
global GRAPH_RES_DIR := GRAPH_DAEMON_DIR "\res"
global GRAPH_PID_PATH := GRAPH_DAEMON_DIR "\daemon.pid"
global GRAPH_STOP_PATH := GRAPH_DAEMON_DIR "\STOP"

GraphDaemon_Warmup() {
  dummyDir := GRAPH_DAEMON_DIR "\warmup"
  DirCreate(dummyDir)

  csv := dummyDir "\warmup.csv"
  png := dummyDir "\warmup.png"
  err := dummyDir "\warmup.err"

  ; tiny valid CSV
  if !FileExist(csv) {
    FileAppend(
      "0,init,success`n"
      . "1,init,fail`n",
      csv,
      "UTF-8"
    )
  }

  GraphDaemon_Render(csv, png, err, "warmup", 5000)

  ; cleanup (best-effort)
  try FileDelete(csv)
  try FileDelete(png)
  try FileDelete(err)
}

GraphDaemon_Render(csv, png, errOut, title := "", timeoutMs := 3000) {
  id := A_NowUTC "_" A_TickCount
  reqPath := GRAPH_REQ_DIR "\" id ".json"
  resPath := GRAPH_RES_DIR "\" id ".json"

  try FileDelete(resPath)
  try FileDelete(errOut)
  try FileDelete(png)

  json :=
    "{"
    . '"csv":"' JsonEscape(csv) '",'
    . '"png":"' JsonEscape(png) '",'
    . '"err":"' JsonEscape(errOut) '",'
    . '"title":"' JsonEscape(title) '"'
    . "}"

  Debug(A_ThisFunc ": req json=" json)
  FileAppend(json, reqPath, "UTF-8")

  t0 := A_TickCount
  while (A_TickCount - t0 < timeoutMs) {
    if FileExist(resPath) {
      txt := FileRead(resPath, "UTF-8")
      try FileDelete(resPath)
      return txt
    }
    Sleep 5
  }
  return ""
}

StopGraphDaemon(timeoutMs := 1000) {
  pid := 0
  try pid := Integer(Trim(FileRead(GRAPH_PID_PATH, "UTF-8")))

  ; Signal stop (create/overwrite STOP)
  try FileDelete(GRAPH_STOP_PATH)
  try FileAppend("1", GRAPH_STOP_PATH, "UTF-8")

  ; Wait a bit for graceful exit
  t0 := A_TickCount
  while (A_TickCount - t0 < timeoutMs) {
    if !(pid && ProcessExist(pid)) {
      break
    }
    Sleep 25
  }

  ; Hard kill if still alive
  if (pid && ProcessExist(pid)) {
    try ProcessClose(pid)
  }

  ; Cleanup
  try FileDelete(GRAPH_PID_PATH)
  try FileDelete(GRAPH_STOP_PATH)
}

EnsureGraphDaemon() {
  pythonExe := PROJECT_ROOT "\.venv\Scripts\python.exe"
  if !FileExist(pythonExe)
    return false

  ; Ensure dirs
  DirCreate(GRAPH_REQ_DIR)  ; creates parents too
  DirCreate(GRAPH_RES_DIR)

  ; If STOP file was left behind, remove it or daemon will exit immediately
  try FileDelete(GRAPH_STOP_PATH)

  ; Fast path: daemon already running
  pid := 0
  try pid := Integer(Trim(FileRead(GRAPH_PID_PATH, "UTF-8")))
  if (pid && ProcessExist(pid))
    return true

  daemon := GUI_DIR "\graph_daemon.py"
  render := GUI_DIR "\render_graph.py"

  cmd := Format('"{1}" "{2}" "{3}" "{4}"', pythonExe, daemon, GRAPH_DAEMON_DIR, render)
  Run(cmd, , "Hide")

  ; Wait for daemon.pid
  t0 := A_TickCount
  while (A_TickCount - t0 < 2000) {
    if FileExist(GRAPH_PID_PATH) {
      try pid := Integer(Trim(FileRead(GRAPH_PID_PATH, "UTF-8")))
      if (pid && ProcessExist(pid))
        return true
    }
    Sleep 25
  }
  return false
}
