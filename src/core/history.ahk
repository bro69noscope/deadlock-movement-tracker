#Include paths.ahk
#Include helpers.ahk

; Directory for per-instance logs
global HISTORY_DIR := DATA_DIR "\history"
DirCreate(HISTORY_DIR)

HistoryPath(instanceName) {
  ; sanitize a bit for filenames
  safe := RegExReplace(instanceName, "[^\w\-. ]", "_")
  return HISTORY_DIR "\" safe ".log"
}

AppendHistory(instanceName, result) {
  path := HistoryPath(instanceName)
  ; One entry per line (easy to trim / replay)
  FileAppend(result "`n", path, "UTF-8")
}

UndoHistory(instanceName) {
  path := HistoryPath(instanceName)
  if !FileExist(path)
    return false

  text := FileRead(path, "UTF-8")
  ; split into non-empty lines
  lines := []
  for _, raw in StrSplit(text, "`n", "`r") {
    v := Trim(raw)
    if (v != "")
      lines.Push(v)
  }

  if (lines.Length = 0)
    return false

  lines.Pop()

  ; rewrite file
  out := ""
  for _, v in lines
    out .= v "`n"

  try FileDelete(path)
  if (out != "")
    FileAppend(out, path, "UTF-8")

  return true
}

RebuildStatsFromHistory(instanceName) {
  path := HistoryPath(instanceName)

  success := 0, fail := 0
  streakCur := 0, streakBest := 0

  if FileExist(path) {
    text := FileRead(path, "UTF-8")
    for _, raw in StrSplit(text, "`n", "`r") {
      r := Trim(raw)
      if (r = "")
        continue

      if (r = "success") {
        success += 1
        streakCur += 1
        if (streakCur > streakBest)
          streakBest := streakCur
      } else if (r = "fail") {
        fail += 1
        streakCur := 0
      }
    }
  }

  total := success + fail
  pct := (total > 0) ? Round((success / total) * 100, 2) : 0

  IniWrite success, INI_PATH, instanceName, "success"
  IniWrite fail, INI_PATH, instanceName, "fail"
  IniWrite pct, INI_PATH, instanceName, "success_pct"
  IniWrite streakCur, INI_PATH, instanceName, "streak_current"
  IniWrite streakBest, INI_PATH, instanceName, "streak_best"

  IniWrite NowStamp(), INI_PATH, instanceName, "last_event"

  return { success: success, fail: fail, pct: pct, streakCur: streakCur, streakBest: streakBest }
}
