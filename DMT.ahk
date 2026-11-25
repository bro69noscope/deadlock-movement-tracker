#Requires AutoHotkey v2.0
#SingleInstance Force

; Ensure stable paths no matter how launched
SetWorkingDir(A_ScriptDir)

; Launch the real entrypoint
Run('"' A_AhkPath '" "' A_ScriptDir '\src\track.ahk"')

ExitApp
