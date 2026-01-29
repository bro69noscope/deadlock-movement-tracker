; - Rewrites INI with stable section + key ordering
; - Drops comments/blank-line formatting (values preserved)

NormalizeIni(path) {
  if !FileExist(path)
    return false

  text := FileRead(path)
  lines := StrSplit(text, "`n", "`r")

  ; data: Map(section => Map(key => value))
  sections := Map()
  cur := ""

  for _, raw in lines {
    line := Trim(raw)

    if (line = "")
      continue

    ; ignore comment-only lines
    if RegExMatch(line, "^\s*[;#]")
      continue

    ; [section]
    if RegExMatch(line, "^\s*\[([^\]]+)\]\s*$", &m) {
      cur := m[1]
      if !sections.Has(cur)
        sections[cur] := Map()
      continue
    }

    ; key=value
    if (cur != "" && RegExMatch(line, "^\s*([^=]+?)\s*=\s*(.*)\s*$", &m2)) {
      k := Trim(m2[1])
      v := m2[2]  ; keep as-is (could contain spaces)
      sections[cur][k] := v
    }
  }

  ; -------- ordering rules --------
  sectionNames := []
  for s, _ in sections
    sectionNames.Push(s)

  sectionNames := SortArray(sectionNames)

  ; put __global__ first if present
  if (IdxOf(sectionNames, "__global__") != 0) {
    sectionNames.RemoveAt(IdxOf(sectionNames, "__global__"))
    sectionNames.InsertAt(1, "__global__")
  }

  ; preferred key order for instance sections
  preferred := [
    "created_at",
    "pos_line",
    "pos_saved_at",
    "last_switch",
    "success",
    "fail",
    "success_pct",
    "last_event"
  ]

  out := ""

  for _, sName in sectionNames {
    kv := sections[sName]

    out .= "[" sName "]`n"

    ; __global__ usually small
    if (sName = "__global__") {
      keys := []
      for k, _ in kv
        keys.Push(k)
      keys := SortArray(keys)
      for _, k in keys
        out .= k "=" kv[k] "`n"
      out .= "`n"
      continue
    }

    ; write preferred keys first
    written := Map()
    for _, k in preferred {
      if kv.Has(k) {
        out .= k "=" kv[k] "`n"
        written[k] := true
      }
    }

    ; write remaining keys sorted
    rest := []
    for k, _ in kv {
      if !written.Has(k)
        rest.Push(k)
    }
    rest := SortArray(rest)
    for _, k in rest
      out .= k "=" kv[k] "`n"

    out .= "`n"
  }

  ; atomic-ish rewrite
  tmp := path ".tmp"
  try FileDelete(tmp)
  FileAppend(out, tmp, "UTF-8")

  try FileDelete(path)
  FileMove(tmp, path, 1)
  return true
}

SortArray(arr) {
  if (arr.Length = 0)
    return []

  s := ""
  for _, v in arr
    s .= v "`n"

  s := RTrim(s, "`n")

  ; split back into array
  out := []
  for _, v in StrSplit(s, "`n")
    out.Push(v)

  return out
}


IdxOf(arr, needle) {
  for i, v in arr
    if (v = needle)
      return i
  return 0
}
