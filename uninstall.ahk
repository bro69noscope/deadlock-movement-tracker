#Requires AutoHotkey v2.0
#SingleInstance Force
SetWorkingDir(A_ScriptDir)

#Include src\core\uninstaller.ahk

if WinExist("ahk_exe deadlock.exe") {
  MsgBox(
    "Please close Deadlock before uninstalling.",
    "Movement Tracker",
    0x30
  )
  ExitApp
}

Run('"' A_AhkPath '" "' A_ScriptDir '\src\track.ahk" --uninstall')
ExitApp
