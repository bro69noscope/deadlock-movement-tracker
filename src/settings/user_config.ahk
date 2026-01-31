; Deadlock console hotkeys
global DEADLOCK_MARK_POS_HOTKEY := "o"
global DEADLOCK_TELEPORT_HOTKEY := "h"
global DEADLOCK_NOCLIP_HOTKEY := "l"
global DEADLOCK_LOAD_MAP_HOTKEY := "8"
global DEADLOCK_SWAP_TEAM_HOTKEY := "9"
global DEADLOCK_SETUP_PRACTICE_HOTKEY := "0"
global DEADLOCK_MVTRACK_INTERNAL_HOTKEY := "i"

; Possible different DeadLock install path (Don't change if default)
global DEADLOCK_ROOT := "C:\Program Files (x86)\Steam\steamapps\common\Deadlock"

; Tracker hotkeys
global TRACKER_FAIL_KEY := "F1"        ; failed the route, reset pos
global TRACKER_SUCCESS_KEY := "F2"     ; succeeded the route, reset pos
global TRACKER_SWITCH_POS_KEY := "F3"  ; switch to existing route start
global TRACKER_CREATE_POS_KEY := "F4"  ; save new route start
global TRACKER_FORGET_LAST_KEY := "F5" ; forget the last fail/success stat entry
global TRACKER_RENAME_INSTANCE_KEY := "F6" ; rename current instance
global TRACKER_REPOSITION_INSTANCE_KEY := "F7" ; reposition current instance to current pos
global TRACKER_DELETE_INSTANCE_KEY := "F8"    ; delete current instance
global TRACKER_EXIT_KEY := "F12"

; Developer hotkeys
global EXPORT_PRETTY_INI_KEY := "F11"       ; make readable data file
global RELOAD_SCRIPT_KEY := "F10"      ; reload script

; Set to true to include personal settings from settings\bros_settings.ahk
global INCLUDE_PERSONAL_SETTINGS := true

; Set to true to enable debugging logs if encoutering issues
global ENABLE_DEBUG := true

; Target success streak to reach, set to 0 to disable;
global TARGET_SUCCESS_STREAK := 3
