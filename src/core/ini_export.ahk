#Include paths.ahk
#Include helpers.ahk

ExportPrettyIniSnapshot(outPath := "") {
  if (outPath = "")
    outPath := DATA_DIR "\instances.pretty.ini"
  ini := INSTANCES_INI

  ; -------- read section list --------
  sectionsText := ""
  try {
    sectionsText := IniRead(ini)
  } catch {
    sectionsText := ""
  }

  sections := []
  for _, raw in StrSplit(sectionsText, "`n", "`r") {
    s := Trim(raw)
    if (s != "")
      sections.Push(s)
  }

  ; __global__ first, rest sorted
  ordered := []
  if HasSection(ini, "__global__")
    ordered.Push("__global__")

  others := []
  for _, s in sections {
    if (s != "__global__")
      others.Push(s)
  }
  others.Sort((a, b) => StrCompare(a, b, true))

  for _, s in others
    ordered.Push(s)

  preferredOrder := [
    "created_at",
    "pos_line",
    "pos_saved_at",
    "last_switch",
    "success",
    "fail",
    "success_pct",
    "streak_current",
    "streak_best",
    "last_event"
  ]

  out := "; pretty snapshot (read-only)`n"
  out .= "; generated: " NowStamp() "`n"
  out .= "; source: " ini "`n`n"

  ; -------- per section --------
  for _, section in ordered {
    out .= "[" section "]`n"

    secText := ""
    try {
      secText := IniRead(ini, section)
    } catch {
      secText := ""
    }

    kv := Map()
    for _, rawLine in StrSplit(secText, "`n", "`r") {
      line := Trim(rawLine)
      if (line = "")
        continue
      if RegExMatch(line, "^\s*[;#]")
        continue
      if RegExMatch(line, "^\s*([^=]+?)\s*=\s*(.*)\s*$", &m) {
        kv[Trim(m[1])] := m[2]
      }
    }

    written := Map()

    for _, k in preferredOrder {
      if kv.Has(k) {
        out .= k "=" kv[k] "`n"
        written[k] := true
      }
    }

    rest := []
    for k, _ in kv {
      if !written.Has(k)
        rest.Push(k)
    }
    rest.Sort((a, b) => StrCompare(a, b, true))

    for _, k in rest
      out .= k "=" kv[k] "`n"

    out .= "`n"
  }

  ; -------- atomic UTF-8 write --------
  tmp := outPath ".tmp"
  try {
    FileDelete(tmp)
  }

  FileAppend(out, tmp, "UTF-8")

  try {
    FileDelete(outPath)
  }

  FileMove(tmp, outPath, 1)

  return outPath
}

HasSection(path, section) {
  try {
    IniRead(path, section)
    return true
  } catch {
    return false
  }
}
