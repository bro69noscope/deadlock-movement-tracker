#Include debug.ahk

global CURRENT_INSTANCE := ""
global VARIATION_SEPARATOR := " @ "
global CURRENT_VARIATION := ""
global CURRENT_TIMESCALE := 1.0
global INPUT_BLOCK_WASD := false

class StatusTip {
  static saveBusy := false
  static _cbClear := 0

  static Show(text) {
    ToolTip(text)
  }

  static _Clear(*) {
    ToolTip()
  }

  static ClearAfter(ms := 700) {
    if !StatusTip._cbClear
      StatusTip._cbClear := ObjBindMethod(StatusTip, "_Clear")

    SetTimer(StatusTip._cbClear, -ms)
  }

  static Saving(text := "Saving pos...") {
    StatusTip.saveBusy := true
    StatusTip.Show(text)
  }

  static Saved(text := "Saved pos ✓", ms := 700) {
    StatusTip.saveBusy := false
    StatusTip.Show(text)
    StatusTip.ClearAfter(ms)
  }

  static FailedSave(text := "Failed saving pos ✗", ms := 1200) {
    StatusTip.saveBusy := false
    StatusTip.Show(text)
    StatusTip.ClearAfter(ms)
  }
}

CurrentlySavingPosition(caller) {
  if StatusTip.saveBusy {
    StatusTip.Show("Not done saving!")
    Debug(A_ThisFunc ": save is busy. Caller:" caller)
    return true
  }
  return false
}
