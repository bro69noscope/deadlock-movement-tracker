#Include helpers.ahk
#Include debug.ahk
#Include paths.ahk
#Include mvpos_writer.ahk
#Include lastpos_capture.ahk
#Include history.ahk
#Include reset_pos.ahk
#Include gui\prompt.ahk
#Include gui\instance_picker.ahk
#Include gui\variation_picker.ahk
#Include state.ahk

RenameBaseAndVariations(oldBase, newBase) {
  ini := INSTANCES_INI

  vars := ReadVariations(oldBase)

  CopyIniSection(ini, oldBase, newBase)
  SetDisplayName(newBase, newBase)

  IniWrite NowStamp(), ini, newBase, "last_event"
  IniDelete ini, oldBase

  MoveHistory(oldBase, newBase)

  for _, v in vars {
    oldKey := oldBase VARIATION_SEPARATOR v
    newKey := newBase VARIATION_SEPARATOR v

    if InstanceExists(oldKey) {
      CopyIniSection(ini, oldKey, newKey)
      IniDelete ini, oldKey
      MoveHistory(oldKey, newKey)
    }
  }
}


InitRouteStats(routeKey) {
  ini := INSTANCES_INI

  if (routeKey = "")
    return false

  IniWrite "0", ini, routeKey, "success"
  IniWrite "0", ini, routeKey, "fail"
  IniWrite "0", ini, routeKey, "success_pct"
  IniWrite "0", ini, routeKey, "streak_current"
  IniWrite "0", ini, routeKey, "streak_best"

  ts := NowStamp()
  IniWrite ts, ini, routeKey, "created_at"
  IniWrite ts, ini, routeKey, "last_event"

  Debug(A_ThisFunc ": initialized stats for routeKey=" routeKey " created_at=" ts)
  return true
}

ValidateInstanceName(name) {
  name := Trim(name)

  if (name = "__global__")
    return { ok: false, reason: "reserved_name (__global__)" }

  if InStr(name, "|")
    return { ok: false, reason: "contains_pipe (|)" }

  if InStr(name, VARIATION_SEPARATOR)
    return { ok: false, reason: "contains_variation_separator (" VARIATION_SEPARATOR ")"
    }

  return { ok: true, name: name }
}

SplitRouteKey(routeKey) {
  if InStr(routeKey, VARIATION_SEPARATOR) {
    parts := StrSplit(routeKey, VARIATION_SEPARATOR)
    return { base: Trim(parts[1]), variation: Trim(parts[2]) }
  }
  return { base: Trim(routeKey), variation: "" }
}

GetCurrentRouteKey() {
  base := Trim(CURRENT_INSTANCE)
  variation := Trim(CURRENT_VARIATION)
  return (variation = "") ? base : (base VARIATION_SEPARATOR variation)
}

WriteVariations(baseName, vars) {
  ini := INSTANCES_INI

  seen := Map()
  cleaned := []

  for _, v in vars {
    v := CanonKey(v)
    if (v = "")
      continue
    if !seen.Has(v) {
      seen[v] := true
      cleaned.Push(v)
    }
  }

  s := ""
  for i, v in cleaned
    s .= (i > 1 ? "|" : "") v

  IniWrite s, ini, baseName, "variations"
}

NewVariation() {
  base := Trim(CURRENT_INSTANCE)
  if (base = "") {
    WarnNoInstanceSelected()
    return false
  }
  baseName := GetDisplayName(base)

  ini := INSTANCES_INI

  while true {
    name := PromptName(
      "Add new variation for:`n`n " baseName,
    )
    name := Trim(name)

    if (name = "")
      return false

    defaultVal := name

    v := ValidateInstanceName(name)
    if (!v.ok) {
      MsgBox("Invalid name (" v.reason ").`n`nTry again.", "Tracker", 48)
      continue
    }

    varKey := CanonKey(v.name)
    routeKey := base VARIATION_SEPARATOR varKey

    if InstanceExists(routeKey) {
      MsgBox("Variation already exists: " routeKey "`n`nPick a different name.",
        "Tracker", 48)
      continue
    }

    break
  }

  vars := ReadVariations(base)
  vars.Push(varKey)
  WriteVariations(base, vars)

  InitRouteStats(routeKey)
  SetDisplayName(routeKey, name)
  SetCurrentInstance(base, varKey)
  SaveCurrentInstancePos()
  return true
}

SwitchVariation() {
  base := CURRENT_INSTANCE
  if (base = "") {
    WarnNoInstanceSelected()
    return false
  }
  baseName := GetDisplayName(base)

  pickedVar := PickVariationForBase(base)
  if (pickedVar = "__cancel__")
    return false

  if pickedVar == "" {
    MsgBox "No variation for: '" baseName "'`nCreate one with " CFG.new_variation,
      "Tracker", 48
    return false
  }

  if pickedVar == "__main__"
    SetCurrentInstance(base)
  else
    SetCurrentInstance(base, pickedVar)

  LoadInstancePos(GetCurrentRouteKey())
  return true
}

InstanceExists(name) {
  try {
    IniRead(INSTANCES_INI, name)
    return true
  } catch {
    return false
  }
}

RenameVariation(base, oldVar, newVar) {
  ini := INSTANCES_INI

  oldKey := base VARIATION_SEPARATOR oldVar
  newKey := base VARIATION_SEPARATOR newVar

  if !InstanceExists(oldKey) {
    MsgBox("No such variation: " oldKey, "Tracker", 48)
    return false
  }

  if InstanceExists(newKey) {
    choice := MsgBox(
      "Variation '" newKey "' already exists.`n`n"
      . "Replace it? This will overwrite its stats/pos (and its history file if any).",
      "Tracker",
      "YesNo Icon!"
    )
    if (choice = "No")
      return false

    try IniDelete(ini, newKey)
    hist := HistoryPath(newKey)
    if FileExist(hist) {
      try FileDelete(hist)
    }
  }

  CopyIniSection(ini, oldKey, newKey)
  SetDisplayName(newKey, newVar)
  IniWrite NowStamp(), ini, newKey, "last_event"
  try IniDelete(ini, oldKey)
  MoveHistory(oldKey, newKey)

  vars := ReadVariations(base)
  kept := []
  for _, v in vars {
    if (StrLower(Trim(v)) = StrLower(oldVar))
      kept.Push(newVar)
    else
      kept.Push(v)
  }
  WriteVariations(base, kept)

  SetCurrentInstance(base, newVar)
  IniWrite NowStamp(), ini, newKey, "last_switch"

  AppendGlobalEvent("rename_variation:" base "->" oldVar "->" newVar, newKey)
  return true
}

NewInstance() {
  ini := INSTANCES_INI

  while true {
    name := PromptName("New instance name:")
    name := Trim(name)

    if (name = "")
      return

    v := ValidateInstanceName(name)
    if (!v.ok) {
      MsgBox("Invalid name (" v.reason ").`n`nTry again.", "Tracker", 48)
      continue
    }

    display := v.name
    key := CanonKey(display)

    if InstanceExists(name) {
      choice := MsgBox(
        "Instance '" name "' already exists.`n`n"
        . "Replace it? This will overwrite/reset its stats and saved position.",
        "Tracker",
        "YesNo Icon!"
      )

      if (choice = "No")
        continue

      IniDelete ini, name
    }

    break
  }

  InitRouteStats(key)
  SetDisplayName(key, display)
  SetCurrentInstance(key)
  SaveCurrentInstancePos()
  RouteTimer.Arm()
}

SwitchInstance() {
  base := ListInstances(VARIATION_SEPARATOR)
  if (base = "")
    return

  if !InstanceExists(base) {
    MsgBox "No such instance: " base "`n`nCreate it first with " CFG.new, "Tracker", 48
    return
  }

  pickedVar := PickVariationForBase(base)
  if (pickedVar = "__cancel__")
    return

  Perf.Start(A_ThisFunc)
  if (pickedVar = "__main__")
    SetCurrentInstance(base)
  else
    SetCurrentInstance(base, pickedVar)

  LoadInstancePos(GetCurrentRouteKey())
  Perf.End("SwitchInstance")
}

DeleteInstance() {
  global CURRENT_INSTANCE, CURRENT_VARIATION, VARIATION_SEPARATOR
  ini := INSTANCES_INI

  base := Trim(CURRENT_INSTANCE)
  var := Trim(CURRENT_VARIATION)
  baseName := GetDisplayName(base)

  if (base = "") {
    WarnNoInstanceSelected()
    return false
  }

  ; If on a variation: delete only that variation
  if (var != "") {
    routeKey := base VARIATION_SEPARATOR var
    varName := GetDisplayName(routeKey)

    if !InstanceExists(routeKey) {
      MsgBox("No such variation: '" routeKey "'", "Tracker", 48)
      return false
    }

    choice := MsgBox(
      "Delete variation?`n`n"
      . "Base: " baseName "`n"
      . "Variation: " varName "`n`n"
      . "This will delete its stats, saved position, and its history log.",
      "Tracker",
      "YesNo Icon!"
    )
    if (choice = "No")
      return false

    vars := ReadVariations(base)
    kept := []
    for _, v in vars {
      if (StrLower(Trim(v)) != StrLower(var))
        kept.Push(v)
    }
    WriteVariations(base, kept)

    try IniDelete(ini, routeKey)

    try DeleteHistoryFiles(routeKey)
    catch as e
      Debug(A_ThisFunc
        ": FAILED to delete variation history files: " routeKey " | " e.Message)

    AppendGlobalEvent("delete_variation:" baseName "->" varName, routeKey)

    CURRENT_VARIATION := ""
    if vars.Length > 1
      SwitchVariation()
    return true
  }

  ; Otherwise: on base -> delete base + all variations
  if !InstanceExists(base) {
    MsgBox "No such instance: " base, "Tracker", 48
    return false
  }

  vars := ReadVariations(base)

  extra := ""
  if (vars.Length > 0) {
    extra .= "`n`nThis will also delete variations:`n"
    for _, v in vars
      extra .= "  - " GetDisplayName(v) "`n"
  }

  choice := MsgBox(
    "Delete '" baseName "'?`n`n"
    . "This will remove it from instances.ini"
    . (FileExist(HistoryPath(base)) ? " and delete its history log." : ".")
    . extra,
    "Tracker",
    "YesNo Icon!"
  )
  if (choice = "No")
    return false

  CURRENT_INSTANCE := ""
  CURRENT_VARIATION := ""
  IniWrite "", ini, "__global__", "current_instance"
  IniWrite "", ini, "__global__", "current_variation"

  for _, v in vars {
    routeKey := base VARIATION_SEPARATOR v

    if InstanceExists(routeKey) {
      try IniDelete(ini, routeKey)
    }

    try DeleteHistoryFiles(routeKey)
    catch as e
      Debug(A_ThisFunc
        ": FAILED to delete variation history files: " routeKey " | " e.Message)
  }

  try IniDelete(ini, base)

  try DeleteHistoryFiles(base)
  catch as e
    Debug(A_ThisFunc ": FAILED to delete base history files: " base " | " e.Message)

  AppendGlobalEvent("delete_instance_with_variations", base)
  return true
}

RepositionInstance() {
  name := GetDisplayName(GetCurrentRouteKey())
  if (name = "") {
    WarnNoInstanceSelected()
    return false
  }

  choice := MsgBox(
    "Move '" name "' to current pos ?`n`n",
    "Tracker",
    "YesNo Icon!"
  )
  if (choice = "No")
    return false

  SaveCurrentInstancePos()
}

RenameInstance() {
  global CURRENT_INSTANCE
  ini := INSTANCES_INI

  base := Trim(CURRENT_INSTANCE)
  var := Trim(CURRENT_VARIATION)

  if (base = "") {
    WarnNoInstanceSelected()
    return false
  }

  if (var != "") {
    full := base VARIATION_SEPARATOR var
    varName := GetDisplayName(full)
    baseName := GetDisplayName(base)

    while true {
      newVar := PromptName(
        "Rename variation:"
        "`n`nBase: " baseName VARIATION_SEPARATOR
        "`nOld: " varName
        "`nNew:",
        varName
      )
      newVar := Trim(newVar)

      if (newVar = "" || newVar == varName)
        return false

      if (StrLower(newVar) = StrLower(varName)) {
        SetDisplayName(base VARIATION_SEPARATOR var, newVar)
        return true
      }

      v := ValidateInstanceName(newVar)
      if (!v.ok) {
        MsgBox("Invalid name (" v.reason ").`n`nTry again.", "Tracker", 48)
        continue
      }

      newVar := v.name
      break
    }

    return RenameVariation(base, var, newVar)
  }

  oldName := GetDisplayName(base)

  if !InstanceExists(base) {
    MsgBox "No such instance: " base, "Tracker", 48
    return false
  }

  while true {
    newName := PromptName("Rename instance:`n`nOld: " oldName "`nNew:", oldName)
    newName := Trim(newName)

    if (newName = "" || newName == oldName)
      return false

    if (StrLower(newName) = StrLower(oldName)) {
      SetDisplayName(base, newName)
      return true
    }

    v := ValidateInstanceName(newName)
    if (!v.ok) {
      MsgBox("Invalid name (" v.reason ").`n`nTry again.", "Tracker", 48)
      continue
    }
    newName := v.name

    if InstanceExists(newName) {
      choice := MsgBox(
        "Instance '" newName "' already exists.`n`n"
        "Replace it? This will overwrite its stats/pos (and its history file if any).",
        "Tracker",
        "YesNo Icon!"
      )
      if (choice = "No")
        continue

      try IniDelete ini, newName
      hist := HistoryPath(newName)
      if FileExist(hist) {
        try FileDelete(hist)
      }
    }

    break
  }

  RenameBaseAndVariations(oldName, newName)

  CURRENT_INSTANCE := newName
  IniWrite newName, ini, "__global__", "current_instance"
  IniWrite NowStamp(), ini, newName, "last_switch"

  AppendGlobalEvent("rename_instance:" oldName "->" newName, newName)
  return true
}

LoadInstancePos(instanceName) {
  Perf.Step(A_ThisFunc ": init")
  ini := INSTANCES_INI
  pos := ""
  hasKey := false
  name := instanceName

  try {
    secText := IniRead(ini, name)
    if RegExMatch(secText, "im)^\s*pos_line\s*=")
      hasKey := true
    pos := IniRead(ini, name, "pos_line", "")
  } catch as e {
    Debug(A_ThisFunc
      ": FAILED to read ini. instance=" name " err=" e.Message " path=" ini)

    MsgBox("Failed to read instances.ini.`n`n" ini "`n`n" e.Message,
      "Movement Tracker", 0x30)

    return false
  }
  Perf.Step(A_ThisFunc ": read ini pos_line")

  pos := StrReplace(pos, "`r", "")
  pos := StrReplace(pos, "`n", "")
  pos := Trim(pos)

  if (pos = "") {
    reason := hasKey ? "pos_line_empty" : "pos_line_missing"
    Debug(A_ThisFunc ": NO POS. instance=" name " reason=" reason " path=" ini)

    MsgBox(
      "No saved position for '" GetDisplayName(name) "'.`n`n"
      . "Reason: " reason "`n"
      . "Fix: reposition it with " CFG.reposition
      . " (or recreate with " CFG.new ").",
      "Movement Tracker",
      0x30
    )
    return false
  }

  Debug(A_ThisFunc ": instance=" instanceName " pos=" pos)

  ok := WriteMvposCfg(pos)
  ResetInGamePos(name)
  return ok
}

SetCurrentInstance(baseName, variation := "") {
  Perf.Step(A_ThisFunc ": init")
  global CURRENT_INSTANCE, CURRENT_VARIATION
  ini := INSTANCES_INI

  CURRENT_INSTANCE := baseName
  CURRENT_VARIATION := StrLower(Trim(variation))

  IniWrite baseName, ini, "__global__", "current_instance"
  IniWrite CURRENT_VARIATION, ini, "__global__", "current_variation"
  Perf.Step(A_ThisFunc ": ini writes")

  rk := GetCurrentRouteKey()
  Perf.Step(A_ThisFunc ": GetCurrentRouteKey")
  if (rk != "")
    IniWrite NowStamp(), ini, rk, "last_switch"
  Perf.Step(A_ThisFunc ": NowStamp write")
}

SaveCurrentInstancePos() {
  ini := INSTANCES_INI
  if (CURRENT_INSTANCE = "") {
    Debug(A_thisFunc ": no current instance -> abort")
    return false
  }

  DeleteOldLastPos()
  WinActivate("ahk_exe deadlock.exe")
  SendSmartKey(CFG.mvtrack_mark_pos)

  posline := ReadLastPosUntilValid(2000)
  if !posline
    return false

  IniWrite posline, ini, GetCurrentRouteKey(), "pos_line"
  IniWrite NowStamp(), ini, GetCurrentRouteKey(), "pos_saved_at"
  ok := WriteMvposCfg(posline)
  return ok
}

SetTemporaryInstancePos() {
  DeleteOldLastPos()
  WinActivate("ahk_exe deadlock.exe")
  SendSmartKey(CFG.mvtrack_mark_pos)

  posline := ReadLastPosUntilValid(2000)
  if !posline
    return false

  WriteMvposCfg(posline, true)
}

TeleportToTemporaryInstance() {
  ResetInGamePos("__temp__")
}
