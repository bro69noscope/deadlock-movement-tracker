#Include config.ahk
ResetInGamePos() {
  sleepTime := CFG.reset_position_duration
  limitStam := CFG.practice_without_infinite_stamina
  noclip := CFG.noclip

  WinActivate("ahk_exe  deadlock.exe")
  Send CFG.set_host_timescale_fast
  if limitStam
    Send CFG.enable_fast_stamina

  ; kill momentum
  Send noclip
  Sleep sleepTime

  WinActivate("ahk_exe  deadlock.exe")
  if limitStam
    Send CFG.disable_fast_stamina
  Send CFG.set_host_timescale_normal
  Send noclip
  Send CFG.mvtrack_internal
}
