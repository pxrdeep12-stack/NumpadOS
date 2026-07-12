#Requires AutoHotkey v2.0

; ============================================================================
; NumpadOS - Helper Functions
; ============================================================================
; Utilities for configuration, logging, environment variables, and safe execution.
;
; Exports:
;   - LoadConfig()
;   - LogMessage()
;   - ReadConfigValue()
;   - ExpandEnvironmentVariables()
;   - TryRun()
;   - EnsureDirectoryExists()
; ============================================================================

; ============================================================================
; LOGGING SYSTEM
; ============================================================================

LogMessage(message, level := "INFO") {
    static logPath := ""
    static logDir := ""
    
    ; Initialize log path on first call
    if (!logPath) {
        logDir := ExpandEnvironmentVariables(ReadConfigValue("Logging", "LogDir", A_ScriptDir . "\Logs"))
        if (!InStr(logDir, ":") && !InStr(logDir, "\\")) {
            logDir := A_ScriptDir . "\" . logDir
        }
        EnsureDirectoryExists(logDir)
        logPath := logDir . "\NumpadOS.log"
    }
    
    try {
        ; Format: [YYYY-MM-DD HH:MM:SS] [LEVEL] Message
        timestamp := FormatTime(, "yyyy-MM-dd HH:mm:ss")
        logEntry := "[" . timestamp . "] [" . level . "] " . message . "`n"
        FileAppend(logEntry, logPath, "UTF-8")
        
        ; Also output to debug if debug mode enabled
        if (DEBUG_MODE && level = "DEBUG") {
            OutputDebug(message)
        }
    } catch as err {
        ; Fail silently - logging errors shouldn't break the app
        OutputDebug("LogMessage error: " . err.Message)
    }
}

; ============================================================================
; CONFIGURATION SYSTEM
; ============================================================================

LoadConfig() {
    global CONFIG
    
    configFile := A_ScriptDir . "\Config.ini"
    
    ; Create default config if not exists
    if (!FileExist(configFile)) {
        CreateDefaultConfig(configFile)
    }
    
    ; Read all sections and keys
    try {
        ; Read Logging section
        CONFIG["LogDir"] := ReadConfigValue("Logging", "LogDir", A_ScriptDir . "\Logs")
        CONFIG["DebugMode"] := ReadConfigValue("Logging", "DebugMode", 0)
        
        ; Read Applications section
        ; NOTE: ChatGPT, Claude, and YouTube are Brave PWAs (launched via .lnk
        ; shortcuts), NOT desktop executables. Do not add *.exe search paths
        ; for them here.
        CONFIG["ChatGPTShortcut"] := ReadConfigValue("Applications", "ChatGPTShortcut", "")
        CONFIG["ClaudeShortcut"] := ReadConfigValue("Applications", "ClaudeShortcut", "")
        CONFIG["YouTubeShortcut"] := ReadConfigValue("Applications", "YouTubeShortcut", "")
        CONFIG["HarmonoidPath"] := ReadConfigValue("Applications", "HarmonoidPath", "C:\Harmonoid\harmonoid.exe")
        CONFIG["ObsidianPath"] := ReadConfigValue("Applications", "ObsidianPath", "C:\Program Files\Obsidian\Obsidian.exe")
        CONFIG["VSCodePath"] := ReadConfigValue("Applications", "VSCodePath", "code")
        CONFIG["CommandPromptPath"] := ReadConfigValue("Applications", "CommandPromptPath", "cmd.exe")
        CONFIG["NotepadPath"] := ReadConfigValue("Applications", "NotepadPath", "notepad.exe")
        CONFIG["BravePath"] := ReadConfigValue("Applications", "BravePath", "C:\Program Files\BraveSoftware\Brave-Browser\Application\brave.exe")
        CONFIG["TaskManagerPath"] := ReadConfigValue("Applications", "TaskManagerPath", "taskmgr.exe")
        
        ; Read UI section
        CONFIG["ShowToasts"] := ReadConfigValue("UI", "ShowToasts", 1)
        CONFIG["ToastDuration"] := ReadConfigValue("UI", "ToastDuration", 800)
        
        ; Read Startup section
        CONFIG["LaunchOnStartup"] := ReadConfigValue("Startup", "LaunchOnStartup", 0)
        CONFIG["OneInstanceOnly"] := ReadConfigValue("Startup", "OneInstanceOnly", 1)
        
        LogMessage("Configuration loaded successfully", "INFO")
        return true
    } catch as err {
        LogMessage("Failed to load configuration: " . err.Message, "ERROR")
        return false
    }
}

ReadConfigValue(section, key, defaultValue := "") {
    configFile := A_ScriptDir . "\Config.ini"
    
    try {
        value := IniRead(configFile, section, key, defaultValue)
        return ExpandEnvironmentVariables(value)
    } catch as err {
        LogMessage("Failed to read config [" . section . "] " . key . ": " . err.Message, "ERROR")
        return defaultValue
    }
}

CreateDefaultConfig(filePath) {
    try {
        configContent := "; NumpadOS Configuration File`n"
        configContent .= "; Generated automatically on first run`n`n"
        
        configContent .= "[Logging]`n"
        configContent .= "LogDir=Logs`n"
        configContent .= "DebugMode=0`n`n"
        
        configContent .= "[Applications]`n"
        configContent .= "; ChatGPT, Claude and YouTube are Brave PWAs - shortcut paths, not exe names.`n"
        configContent .= "ChatGPTShortcut=%AppData%\Microsoft\Windows\Start Menu\Programs\Brave Apps\ChatGPT.lnk`n"
        configContent .= "ClaudeShortcut=%AppData%\Microsoft\Windows\Start Menu\Programs\Brave Apps\Claude.lnk`n"
        configContent .= "YouTubeShortcut=%AppData%\Microsoft\Windows\Start Menu\Programs\Brave Apps\YouTube.lnk`n"
        configContent .= "; Harmonoid, Obsidian, and Brave Browser use fixed, known install paths -`n"
        configContent .= "; NumpadOS does not guess/search for these. Update the paths below if your`n"
        configContent .= "; install location differs.`n"
        configContent .= "HarmonoidPath=C:\Harmonoid\harmonoid.exe`n"
        configContent .= "ObsidianPath=C:\Program Files\Obsidian\Obsidian.exe`n"
        configContent .= "VSCodePath=code`n"
        configContent .= "CommandPromptPath=cmd.exe`n"
        configContent .= "NotepadPath=notepad.exe`n"
        configContent .= "BravePath=C:\Program Files\BraveSoftware\Brave-Browser\Application\brave.exe`n"
        configContent .= "TaskManagerPath=taskmgr.exe`n`n"
        
        configContent .= "[UI]`n"
        configContent .= "ShowToasts=1`n"
        configContent .= "ToastDuration=800`n`n"
        
        configContent .= "[Startup]`n"
        configContent .= "LaunchOnStartup=0`n"
        configContent .= "OneInstanceOnly=1`n"
        
        FileAppend(configContent, filePath, "UTF-8")
        LogMessage("Default configuration created: " . filePath, "INFO")
        return true
    } catch as err {
        LogMessage("Failed to create default config: " . err.Message, "ERROR")
        return false
    }
}

; ============================================================================
; ENVIRONMENT VARIABLE EXPANSION
; ============================================================================

ExpandEnvironmentVariables(value) {
    if (!IsSet(value) || value = "") {
        return ""
    }
    
    expanded := value
    
    ; Standard Windows environment variables
    expanded := StrReplace(expanded, "%AppData%", A_AppData)
    expanded := StrReplace(expanded, "%LOCALAPPDATA%", EnvGet("LOCALAPPDATA"))
    expanded := StrReplace(expanded, "%USERPROFILE%", EnvGet("USERPROFILE"))
    expanded := StrReplace(expanded, "%ProgramFiles%", EnvGet("ProgramFiles"))
    expanded := StrReplace(expanded, "%ProgramFiles(x86)%", EnvGet("ProgramFiles(x86)"))
    expanded := StrReplace(expanded, "%TEMP%", EnvGet("TEMP"))
    expanded := StrReplace(expanded, "%TMP%", EnvGet("TMP"))
    expanded := StrReplace(expanded, "%WINDIR%", EnvGet("WINDIR"))
    expanded := StrReplace(expanded, "%SystemRoot%", EnvGet("SystemRoot"))
    expanded := StrReplace(expanded, "%OneDrive%", EnvGet("OneDrive"))
    
    return expanded
}

; ============================================================================
; COMMAND EXECUTION
; ============================================================================

TryRun(command, workingDir := "", args := "") {
    if (!command) {
        LogMessage("TryRun: Empty command provided", "ERROR")
        return 0
    }
    
    try {
        ; Build command line
        commandLine := command
        if (args != "") {
            commandLine := commandLine . " " . args
        }
        
        ; Quote if contains spaces
        if (InStr(commandLine, A_Space)) {
            commandLine := '"' . commandLine . '"'
        }
        
        ; Execute
        pid := 0
        Run(commandLine, workingDir, , &pid)
        
        if (DEBUG_MODE) {
            LogMessage("TryRun executed: " . command . " (PID: " . pid . ")", "DEBUG")
        }
        
        return pid
    } catch as err {
        LogMessage("TryRun failed for '" . command . "': " . err.Message, "ERROR")
        return 0
    }
}

; ============================================================================
; FILE SYSTEM UTILITIES
; ============================================================================

EnsureDirectoryExists(dirPath) {
    if (!DirExist(dirPath)) {
        try {
            DirCreate(dirPath)
            LogMessage("Created directory: " . dirPath, "INFO")
            return true
        } catch as err {
            LogMessage("Failed to create directory '" . dirPath . "': " . err.Message, "ERROR")
            return false
        }
    }
    return true
}

; ============================================================================
; MISC UTILITIES
; ============================================================================

ArrayJoin(arr, sep := ", ")
{
    result := ""

    for i, item in arr
    {
        if (i > 1)
            result .= sep

        result .= item
    }

    return result
}