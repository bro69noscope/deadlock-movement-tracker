#Requires AutoHotkey v2.0
#SingleInstance Force
A_MaxHotkeysPerInterval := 1000
SetWorkingDir(A_ScriptDir)

appName := "deadlock-movement-tracker"
A_IconTip := appName
iconPath := A_ScriptDir "\..\assets\icon.png"
if FileExist(iconPath)
  TraySetIcon(iconPath)

tray := A_TrayMenu
tray.Delete()
tray.Add(appName, (*) => 0)
tray.Disable(appName)
tray.Add()

tray.Add("Open user_settings.ini", (*) => Run(
  '"' A_ScriptDir '\..\user_settings.ini"'))

tray.Add("Reload", (*) => Reload())
tray.Add()
tray.Add("Exit", (*) => ConfirmExit())
tray.Add("Force Exit", (*) => ExitApp())

#Include ..\vendor\ahk-v2-libraries\Lib\Array.ahk
#Include core\ini_export.ahk
#Include core\instance.ahk
#Include core\result.ahk
#Include core\ps1_installer.ahk
#Include core\cfg_installer.ahk
#Include core\ps1_launcher.ahk
#Include core\autoexec_installer.ahk
#Include core\uninstaller.ahk
#Include core\route_timer.ahk
#Include core\migrations.ahk
#Include core\timescale.ahk
#Include core\gui\graph_daemon.ahk
#Include core\gui\graph_popup.ahk

ExitHandler(ExitReason, ExitCode) {
  try ExportPrettyIniSnapshot()
  try StopPoswatch()
  try StopGraphDaemon()
}

OnExit(ExitHandler)

if A_Args.Length >= 1 && A_Args[1] = "--uninstall" {
  Uninstall()
  ExitApp()
}

DirCreate(DATA_DIR)

LoadUserConfigFromIni()

DebugBlank
Debug("===Tracker start===")
if CFG.throttle_timescale
  Debug("Currently using slow repostion speed due to apparent inGame limitation")
RunMigrations()

HotIf (*) => WinActive("ahk_exe deadlock.exe")
HotKey(CFG.fail, (*) => MarkResult("fail"))
HotKey(CFG.success, (*) => MarkResult("success"))
HotKey(CFG.switch, (*) => SwitchInstance())
HotKey(CFG.new, (*) => NewInstance())
HotKey(CFG.forget, (*) => ForgetLastResult())
HotKey(CFG.delete, (*) => DeleteInstance())
HotKey(CFG.reposition, (*) => RepositionInstance())
HotKey(CFG.rename, (*) => RenameInstance())
HotKey(CFG.exit, (*) => ConfirmExit(focusback := true))
HotKey(CFG.flush_logs, (*) => FlushLog())
HotKey(CFG.graph, (*) => GraphPopup.Show())
HotKey(CFG.inc_host_timescale, (*) => Timescale_UP())
Hotkey(CFG.inc_host_timescale_big, (*) => Timescale_UP(0.1))
HotKey(CFG.dec_host_timescale, (*) => Timescale_DOWN())
HotKey(CFG.dec_host_timescale_big, (*) => Timescale_DOWN(0.1))
Hotkey(CFG.norm_host_timescale, (*) => Timescale_Reset())
HotKey(CFG.new_variation, (*) => NewVariation())
HotKey(CFG.switch_variation, (*) => SwitchVariation())
HotKey(CFG.mark_temp_pos, (*) => SetTemporaryInstancePos())
HotKey(CFG.temp_pos_teleport, (*) => TeleportToTemporaryInstance())
HotKey(CFG.toggle_temp_pos_randomize, (*) => ToggleTemporaryInstanceRandomize())

HotIf (*) => WinActive("ahk_exe deadlock.exe") && INPUT_BLOCK_WASD
for _, k in MOVEMENT_KEYS {
  HotKey("$*" k, (*) => 0)
  HotKey("$*" k " up", (*) => 0)
}

HotIf

EnsurePs1Installed()
EnsureCfgInstalled()
EnsureAutoexecConfigured()
StartPoswatch()
RouteTimer.StartVisibilityWatcher()
EnsureGraphDaemon()
GraphDaemon_Warmup()
