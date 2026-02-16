#Include debug.ahk

class Perf {
  static on := true
  static label := ""
  static freq := 0
  static t0 := 0
  static last := 0

  static buffered := true
  static lines := ""

  static _Init() {
    if (Perf.freq != 0)
      return

    f := 0
    if !DllCall("QueryPerformanceFrequency", "Int64*", &f) || (f <= 0) {
      Perf.freq := 0
      return
    }
    Perf.freq := f
  }

  static _Now() {
    c := 0
    DllCall("QueryPerformanceCounter", "Int64*", &c)
    return c
  }

  static _Ms(dtCounts) {
    if (Perf.freq = 0)
      return 0.0
    return (dtCounts * 1000.0) / Perf.freq
  }

  static _Log(line) {
    if !Perf.on
      return

    if Perf.buffered
      Perf.lines .= line "`n"
    else
      Debug(line)
  }

  static Start(label := "") {
    if !Perf.on
      return

    Perf._Init()

    Perf.label := label
    Perf.lines := ""

    now := Perf._Now()
    Perf.t0 := now
    Perf.last := now

    Perf._Log("perf START" (label != "" ? " [" label "]" : ""))
  }

  static Step(name) {
    if !Perf.on
      return

    now := Perf._Now()
    dt := now - Perf.last
    Perf.last := now

    Perf._Log("perf +" Format("{:0.3f}", Perf._Ms(dt)) "ms " name)
  }

  static End(label := "") {
    if !Perf.on
      return

    now := Perf._Now()
    total := now - Perf.t0

    if (label = "")
      label := Perf.label

    Perf._Log("perf END" (label != "" ? " [" label "]" : "") ": total="
      Format("{:0.3f}", Perf._Ms(total)) "ms")

    if Perf.buffered {
      Debug(RTrim(Perf.lines, "`n"))
    }
  }
}

BenchDebug(n := 200) {
  Perf.Start("BenchDebug x" n)

  Loop n
    Debug("bench line " A_Index)

  Perf.Step("writes done")

  Perf.End()
  Debug("bench END marker " A_TickCount)
  MsgBox "bench finished"
}
