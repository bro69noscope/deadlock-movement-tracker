#Include paths.ahk
#Include helpers.ahk
#Include debug.ahk

; Directory for per-instance logs
global INSTANCE_HISTORY_DIR := DATA_DIR "\instances_history"
global GLOBAL_HISTORY := DATA_DIR "\history_all.csv"
DirCreate(INSTANCE_HISTORY_DIR)

CopyIniSection(ini, from, to) {
  secText := IniRead(ini, from)
  for _, raw in StrSplit(secText, "`n", "`r") {
    if RegExMatch(raw, "^\s*([^=]+?)\s*=\s*(.*)\s*$", &m)
      IniWrite m[2], ini, to, Trim(m[1])
  }
}

MoveHistory(from, to) {
  hFrom := HistoryPath(from)
  hTo := HistoryPath(to)
  if FileExist(hFrom)
    FileMove(hFrom, hTo, 1)
}

EscapeCsv(s) {
  ; minimal CSV escaping: quote if contains comma/quote/newline
  if InStr(s, ",") || InStr(s, '"') || InStr(s, "`n") || InStr(s, "`r") {
    s := StrReplace(s, '"', '""')
    return '"' s '"'
  }
  return s
}

Safe(s) {
  return RegExReplace(s, "[^\w\-. @]", "_")
}

HistoryPath(instanceName, timeScale := 1) {
  name := Safe(CanonKey(instanceName))
  path := INSTANCE_HISTORY_DIR "\" name
  pct := Round(timeScale * 100)
  if pct != 100
    path .= "_" pct "pct"
  return path ".csv"
}

AppendHistory(instanceName, result, timeScale := 1) {
  instancePath := HistoryPath(instanceName, timeScale)
  ts := NowStamp()
  line := ts "," EscapeCsv(instanceName) "," result "`n"
  FileAppend(line, instancePath, "UTF-8")
  FileAppend(line, GLOBAL_HISTORY, "UTF-8")
  Debug(A_ThisFunc ": Appended '" line "' to '" instancePath "'")
}

AppendGlobalEvent(eventType, instanceName) {
  ts := NowStamp()
  line := ts "," EscapeCsv(instanceName) "," eventType "`n"
  FileAppend(line, GLOBAL_HISTORY, "UTF-8")
}

DeleteHistoryFiles(instanceName) {
  name := Safe(CanonKey(instanceName))
  base := INSTANCE_HISTORY_DIR "\" name

  try if FileExist(base ".csv")
    FileDelete(base ".csv")

  Loop Files, base "_*pct.csv"
    try FileDelete(A_LoopFileFullPath)
}

UndoHistory(instanceName, timeScale := 1) {
  path := HistoryPath(instanceName, timeScale)
  if !FileExist(path) {
    MsgBox "No history found for '" instanceName "'.", "Tracker", 48
    return false
  }

  text := FileRead(path, "UTF-8")
  lines := []
  for _, raw in StrSplit(text, "`n", "`r") {
    v := Trim(raw)
    if v != ""
      lines.Push(v)
  }

  if lines.Length = 0 {
    MsgBox "Reached end of sucess history to forget for '" instanceName "'.",
      "Tracker", 48
    return false
  }

  lines.Pop()

  out := ""
  for _, v in lines
    out .= v "`n"

  try FileDelete(path)
  if out != ""
    FileAppend(out, path, "UTF-8")

  return true
}

RebuildStatsFromHistory(instanceName, timeScale := 1) {
  path := HistoryPath(instanceName, timeScale)
  ini := INSTANCES_INI

  success := 0, fail := 0
  streakCur := 0, streakBest := 0

  if FileExist(path) {
    text := FileRead(path, "UTF-8")
    for _, raw in StrSplit(text, "`n", "`r") {
      rline := Trim(raw)
      if rline = ""
        continue

      parts := StrSplit(rline, ",")
      r := Trim(parts[parts.Length])

      if r = "success" {
        success += 1
        streakCur += 1
        if streakCur > streakBest
          streakBest := streakCur
      } else if r = "fail" {
        fail += 1
        streakCur := 0
      }
    }
  }

  total := success + fail
  pct := (total > 0) ? Round((success / total) * 100, 2) : 0

  tsPct := Round(timeScale * 100)

  if tsPct = 100 {
    IniWrite success, ini, instanceName, "success"
    IniWrite fail, ini, instanceName, "fail"
    IniWrite pct, ini, instanceName, "success_pct"
    IniWrite streakCur, ini, instanceName, "streak_current"
    IniWrite streakBest, ini, instanceName, "streak_best"
  } else {
    prefix := tsPct "%"
    IniWrite success, ini, instanceName, prefix "success"
    IniWrite fail, ini, instanceName, prefix "fail"
    IniWrite pct, ini, instanceName, prefix "success_pct"
    IniWrite streakCur, ini, instanceName, prefix "streak_current"
    IniWrite streakBest, ini, instanceName, prefix "streak_best"
  }

  IniWrite NowStamp(), ini, instanceName, "last_event"
  return { success: success, fail: fail, pct: pct, streakCur: streakCur, streakBest:
    streakBest }
}
