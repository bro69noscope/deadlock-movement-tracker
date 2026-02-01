#Include ..\settings\user_config.ahk
#Include config.ahk

global INI_PATH := DATA_DIR "\instances.ini"
DirCreate(DATA_DIR)

global DEADLOCK_CFG_DIR := DEADLOCK_ROOT "\game\citadel\cfg"
global LASTPOS_PATH := DEADLOCK_CFG_DIR "\lastpos.cfg"

global MVTRACK_POS_PATH := DEADLOCK_CFG_DIR "\mvtrack_pos.cfg"
global MVTRACK_PS1_PATH := DEADLOCK_ROOT "\mvtrack.ps1"
global MVTRACK_CFG_PATH := DEADLOCK_CFG_DIR "\mvtrack.cfg"
