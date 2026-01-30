; Hotkeys used inside the game
global DEADLOCK_MARK_POS_HOTKEY := "o"       ; needs to match postools.cfg, lowercase
global DEADLOCK_MVTRACK_POS_TP_HOTKEY := "i" ; needs to match postools.cfg, lowercase
global DEADLOCK_NOCLIP_HOTKEY := "y"         ; needs to match the noclip bind in deadlock, lowercase

; Possible different DeadLock install path (Don't change if default)
global DEADLOCK_ROOT := "C:\Program Files (x86)\Steam\steamapps\common\Deadlock"

; Tracker hotkeys (F-keys)
global TRACKER_FAIL_KEY := "F1"        ; failed the route, reset pos
global TRACKER_SUCCESS_KEY := "F2"     ; succeeded the route, reset pos
global TRACKER_SWITCH_POS_KEY := "F3"  ; switch to existing route start
global TRACKER_CREATE_POS_KEY := "F4"  ; save new route start
global TRACKER_FORGET_LAST_KEY := "F5" ; forget the last fail/success stat entry
global NORMALIZE_INI_KEY := "F6"       ; make readable data file

; Set to true to include personal settings from settings\bros_settings.ahk
global INCLUDE_PERSONAL_SETTINGS := true

; Set to true to enable debugging logs if encoutering issues
global ENABLE_DEBUG := true

; Target success streak to reach, set to 0 to disable;
global TARGET_SUCCESS_STREAK := 2
