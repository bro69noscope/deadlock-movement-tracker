#Include paths.ahk
#Include helpers.ahk

ExportPrettyIniSnapshot(outPath := "") {
  if (outPath = "")
    outPath := DATA_DIR "\instances.pretty.ini"
  ini := INSTANCES_INI

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
    "display_name",
    "pos_line",
    "created_at",
    "pos_saved_at",
    "last_switch",
    "last_event",
    "variations",
    "success",
    "fail",
    "success_pct",
    "streak_current",
    "streak_best",
  ]
  out := "; pretty snapshot (read-only)`n"
  out .= "; generated: " NowStamp() "`n"
  out .= "; source: " ini "`n`n"

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
    statsStarted := false
    ; Write preferred order fields (main data)
    for _, k in preferredOrder {
      if kv.Has(k) {
        out .= k "=" kv[k] "`n"
        written[k] := true
      }
    }

    ; Separate main fields from % fields
    hasPercentFields := false
    for k, _ in kv {
      if !written.Has(k) && InStr(k, "%") {
        hasPercentFields := true
        break
      }
    }

    ; Collect non-% fields that weren't in preferred order
    restNonPercent := []
    restPercent := []
    for k, _ in kv {
      if !written.Has(k) {
        if InStr(k, "%")
          restPercent.Push(k)
        else
          restNonPercent.Push(k)
      }
    }

    ; Write remaining non-% fields
    restNonPercent.Sort((a, b) => StrCompare(a, b, true))
    for _, k in restNonPercent {
      out .= k "=" kv[k] "`n"
      written[k] := true
    }

    ; Add blank line before % fields if they exist
    if (restPercent.Length > 0)
      out .= "#`n"

    ; Write % fields with stats in preferred order
    statOrder := ["success", "fail", "success_pct", "streak_current", "streak_best"]

    ; Group by prefix
    prefixGroups := Map()
    for _, k in restPercent {
      if RegExMatch(k, "^(\d+)%(.+)$", &m) {
        prefix := m[1]
        stat := m[2]
        if !prefixGroups.Has(prefix)
          prefixGroups[prefix] := []
        prefixGroups[prefix].Push({ key: k, stat: stat })
      }
    }

    ; Sort prefixes numerically
    prefixes := []
    for prefix, _ in prefixGroups
      prefixes.Push(prefix)
    prefixes.Sort((a, b) => Integer(a) - Integer(b))

    ; Write each prefix group
    firstGroup := true
    for _, prefix in prefixes {
      if !firstGroup
        out .= "#`n"
      firstGroup := false

      group := prefixGroups[prefix]
      ; Write in stat order
      for _, stat in statOrder {
        for _, item in group {
          if (item.stat = stat)
            out .= item.key "=" kv[item.key] "`n"
        }
      }
    }

    out .= "`n"
  }

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
