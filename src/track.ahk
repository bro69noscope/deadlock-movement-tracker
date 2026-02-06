#Requires AutoHotkey v2.0
#SingleInstance Force
SetWorkingDir(A_ScriptDir)

appName := "deadlock-movement-tracker"
A_IconTip := appName
iconPath := A_ScriptDir "\..\assets\icon.png"
if FileExist(iconPath)
  TraySetIcon(iconPath)

tray := A_TrayMenu
tray.Delete()
tray.Add(appName, (*) => 0)  ; a non-clickable title line (still clickable but does nothing)
tray.Disable(appName)
tray.Add()
tray.Add("Open user_settings.ini", (*) => Run('"' A_ScriptDir '\..\user_settings.ini"'))
tray.Add("Reload", (*) => Reload())
tray.Add()
tray.Add("Exit", (*) => ExitApp())

#Include ..\vendor\ahk-v2-libraries\Lib\Array.ahk
#Include core\ini_export.ahk
#Include core\instance.ahk
#Include core\result.ahk
#Include core\ps1_installer.ahk
#Include core\cfg_installer.ahk
#Include core\ps1_launcher.ahk
#Include core\autoexec_installer.ahk
#Include core\uninstaller.ahk
#Include settings\bros_settings.ahk

if (A_Args.Length >= 1 && A_Args[1] = "--uninstall") {
  Uninstall()
  ExitApp()
}

DirCreate(DATA_DIR)

; Load custom user config from ini
LoadUserConfigFromIni()

DebugBlank
Debug("===Tracker start===")

if CFG.include_bro_settings {
  ApplyBroSettings()
}

; Define hotkeys
HotIf (*) => WinActive("ahk_exe deadlock.exe")
HotKey(CFG.fail, (*) => MarkResult("fail"))
HotKey(CFG.success, (*) => MarkResult("success"))
HotKey(CFG.switch, (*) => SwitchInstance())
HotKey(CFG.new, (*) => NewInstance())
HotKey(CFG.forget, (*) => ForgetLastResult())
HotKey(CFG.delete, (*) => DeleteInstance())
HotKey(CFG.reposition, (*) => RepositionInstance())
HotKey(CFG.rename, (*) => RenameInstance())
HotKey(CFG.exit, (*) => ConfirmExit())
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
