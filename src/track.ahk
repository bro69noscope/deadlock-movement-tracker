#Requires AutoHotkey v2.0
#SingleInstance Force
SetWorkingDir(A_ScriptDir)

#Include ..\vendor\ahk-v2-libraries\Lib\Array.ahk
#Include core\ini_export.ahk
#Include core\instance.ahk
#Include core\result.ahk
#Include core\ps1_installer.ahk
#Include core\cfg_installer.ahk
#Include core\ps1_launcher.ahk
#Include core\autoexec_installer.ahk
#Include core\uninstaller.ahk

if INCLUDE_PERSONAL_SETTINGS {
  #Include settings\bros_settings.ahk
}

if (A_Args.Length >= 1 && A_Args[1] = "--uninstall") {
  Uninstall()
  ExitApp()
}

DirCreate(DATA_DIR)

DebugBlank
Debug("===Tracker started===")
; Define hotkeys
HotIf (*) => WinActive("ahk_exe deadlock.exe")
HotKey(TRACKER_FAIL_KEY, (*) => MarkResult("fail"))
HotKey(TRACKER_SUCCESS_KEY, (*) => MarkResult("success"))
HotKey(TRACKER_SWITCH_POS_KEY, (*) => SwitchInstance())
HotKey(TRACKER_CREATE_POS_KEY, (*) => NewInstance())
HotKey(TRACKER_FORGET_LAST_KEY, (*) => ForgetLastResult())
HotKey(TRACKER_DELETE_INSTANCE_KEY, (*) => DeleteInstance())
HotKey(TRACKER_REPOSITION_INSTANCE_KEY, (*) => RepositionInstance())
HotKey(TRACKER_RENAME_INSTANCE_KEY, (*) => RenameInstance())
HotKey(TRACKER_EXIT_KEY, (*) => ConfirmExit())
; Dev
HotKey(RELOAD_SCRIPT_KEY, (*) => Reload())
HotKey(EXPORT_PRETTY_INI_KEY, (*) => ExportPrettyIniSnapshot())
HotIf

ExitHandler(ExitReason, ExitCode) {
  try ExportPrettyIniSnapshot()
  try StopPoswatch()
}

EnsurePs1Installed()
EnsureCfgInstalled()
EnsureAutoexecConfigured()
OnExit(ExitHandler)
StartPoswatch()
