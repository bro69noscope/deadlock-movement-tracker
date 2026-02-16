#Include config.ahk

global PROJECT_ROOT := A_ScriptDir "\.."
global SRC_ROOT := A_ScriptDir
global DATA_DIR := SRC_ROOT "\tracker_data"
global GUI_DIR := SRC_ROOT "\core\gui"

global INSTANCES_INI := DATA_DIR "\instances.ini"
global STATE_INI := DATA_DIR "\state.ini"

global DEADLOCK_CFG_DIR := CFG.deadlock_root "\game\citadel\cfg"
global MVTRACK_PS1_PATH := CFG.deadlock_root "\mvtrack.ps1"

global LASTPOS_CFG_PATH := DEADLOCK_CFG_DIR "\lastpos.cfg"
global MVTRACK_CFG_POS_PATH := DEADLOCK_CFG_DIR "\mvtrack_pos.cfg"
global MVTRACK_CFG_TEMP_POS_PATH := DEADLOCK_CFG_DIR "\mvtrack_pos_temp.cfg"
global MVTRACK_CFG_TIMESCALE_PATH := DEADLOCK_CFG_DIR "\mvtrack_timescale.cfg"
global MVTRACK_CFG_EXEC_PATH := DEADLOCK_CFG_DIR "\mvtrack.cfg"
