#Include paths.ahk
#Include helpers.ahk

; Directory for per-instance logs
global INSTANCE_HISTORY_DIR := DATA_DIR "\history"
global GLOBAL_HISTORY := DATA_DIR "\history_all.csv"
DirCreate(INSTANCE_HISTORY_DIR)

EscapeCsv(s) {
  ; minimal CSV escaping: quote if contains comma/quote/newline
  if InStr(s, ",") || InStr(s, '"') || InStr(s, "`n") || InStr(s, "`r") {
    s := StrReplace(s, '"', '""')
    return '"' s '"'
  }
  return s
}

HistoryPath(instanceName) {
  safe := RegExReplace(instanceName, "[^\w\-. ]", "_")
  return INSTANCE_HISTORY_DIR "\" safe ".csv"
}

AppendHistory(instanceName, result) {
  instancePath := HistoryPath(instanceName)
  ts := NowStamp()
  line := ts "," EscapeCsv(instanceName) "," result "`n"
  FileAppend(line, instancePath, "UTF-8")
  FileAppend(line, GLOBAL_HISTORY, "UTF-8")
}

AppendGlobalEvent(eventType, instanceName) {
  ts := NowStamp()
  line := ts "," EscapeCsv(instanceName) "," eventType "`n"
  FileAppend(line, GLOBAL_HISTORY, "UTF-8")
}


UndoHistory(instanceName) {
  path := HistoryPath(instanceName)
  if !FileExist(path) {
    MsgBox "No history found for '" instanceName "'.", "Tracker", 48
    return false
  }

  text := FileRead(path, "UTF-8")
  ; split into non-empty lines
  lines := []
  for _, raw in StrSplit(text, "`n", "`r") {
    v := Trim(raw)
    if (v != "")
      lines.Push(v)
  }

  if (lines.Length = 0) {
    MsgBox "Reached end of sucess history to forget for '" instanceName "'.", "Tracker", 48
    return true
  }

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
      rline := Trim(raw)
      if (rline = "")
        continue
      r := ""

      parts := StrSplit(rline, ",")
      r := Trim(parts[parts.Length])

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
