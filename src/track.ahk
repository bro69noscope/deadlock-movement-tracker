#Requires AutoHotkey v2.0
#SingleInstance Force

#Include ..\vendor\ahk-v2-libraries\Lib\Array.ahk
#Include core\ini_normalizer.ahk
#Include core\instance.ahk
#Include core\result.ahk

if INCLUDE_PERSONAL_SETTINGS {
  #Include settings\bros_settings.ahk
}

; Define hotkeys
#HotIf WinActive("ahk_exe deadlock.exe")
HotKey TRACKER_FAIL_KEY, (*) => MarkResult("fail")
HotKey TRACKER_SUCCESS_KEY, (*) => MarkResult("success")
HotKey TRACKER_SWITCH_POS_KEY, (*) => SwitchInstance()
HotKey TRACKER_CREATE_POS_KEY, (*) => NewInstance()
HotKey NORMALIZE_INI_KEY, (*) => NormalizeIni(INI_PATH)
HotKey TRACKER_FORGET_LAST_KEY, (*) => ForgetLastResult()
#HotIf
