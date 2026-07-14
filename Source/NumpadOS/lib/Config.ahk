; ============================================================================
; Config.ahk
; ----------------------------------------------------------------------------
; Owns config.json: loading, saving, validating, and exposing an in-memory
; representation shared by the Configurator and the Launcher.
;
; File location: <script folder>\data\config.json  (created on first run)
;
; Schema (see /config/config.default.json for a literal example):
; {
;   "settings": {
;     "runAtStartup": bool,
;     "startMinimized": bool,
;     "runLauncherAfterLogin": bool,
;     "showTrayIcon": bool,
;     "checkForUpdates": bool,
;     "runAsAdmin": bool,
;     "launcherNumLockMode": "on"|"off"   ; which NumLock state activates the launcher (default "off")
;   },
;   "shortcuts": [
;     {
;       "key": "Numpad1",              ; one of Config.ValidKeys
;       "type": "program|folder|website|keyboard",
;       "name": "Display Name",
;       "target": "path, url, or key combo string",
;       "args": "",                    ; optional, program only
;       "iconPath": "",                ; optional, cached icon file
;       "matchExe": "",                ; optional, smart-launch override (program only)
;       "matchTitle": "",              ; optional, smart-launch override
;       "matchClass": "",              ; optional, smart-launch override
;       "enabled": true
;     }
;   ]
; }
; ============================================================================

class Config
{
    static ValidKeys := [
        "Numpad0", "Numpad1", "Numpad2", "Numpad3", "Numpad4",
        "Numpad5", "Numpad6", "Numpad7", "Numpad8", "Numpad9",
        "NumpadDiv", "NumpadMult", "NumpadSub", "NumpadAdd",
        "NumpadDot", "NumpadEnter"
    ]

    static ValidTypes := ["program", "folder", "website", "keyboard"]

    static DataDir  := A_ScriptDir . "\data"
    static FilePath := Config.DataDir . "\config.json"

    static Data := ""   ; in-memory Map, populated by Load()

    ; ---- Public API ----

    static Load()
    {
        try DirCreate(Config.DataDir)

        if !FileExist(Config.FilePath)
        {
            Logger.Info("No config.json found - creating default config.")
            Config.Data := Config._DefaultConfig()
            Config.Save()
            return Config.Data
        }

        try
        {
            raw := FileRead(Config.FilePath, "UTF-8")
            parsed := JSON.Load(raw)
            Config.Data := Config._Validate(parsed)
            Logger.Info("config.json loaded (" . Config.Data["shortcuts"].Length . " shortcut(s)).")
        }
        catch as e
        {
            Logger.Error("Failed to parse config.json: " . e.Message . " - backing up and resetting to defaults.")
            try FileMove(Config.FilePath, Config.FilePath . ".corrupt-" . A_Now, 1)
            Config.Data := Config._DefaultConfig()
            Config.Save()
        }
        return Config.Data
    }

    static Save()
    {
        try DirCreate(Config.DataDir)
        text := JSON.Dump(Config.Data, true)
        tempFile := Config.FilePath . ".tmp"
        try FileDelete(tempFile)
        FileAppend(text, tempFile, "UTF-8")
        try FileDelete(Config.FilePath)
        FileMove(tempFile, Config.FilePath)
        Logger.Info("config.json saved.")
    }

    static GetShortcuts()
    {
        return Config.Data["shortcuts"]
    }

    static GetShortcutForKey(key)
    {
        for sc in Config.Data["shortcuts"]
            if (sc["key"] = key)
                return sc
        return ""
    }

    static IsKeyInUse(key, excludeShortcut := "")
    {
        for sc in Config.Data["shortcuts"]
        {
            if (sc["key"] = key && sc != excludeShortcut)
                return true
        }
        return false
    }

    static AddShortcut(shortcut)
    {
        Config.Data["shortcuts"].Push(shortcut)
        Config.Save()
    }

    static RemoveShortcut(shortcut)
    {
        arr := Config.Data["shortcuts"]
        for i, sc in arr
        {
            if (sc = shortcut)
            {
                arr.RemoveAt(i)
                break
            }
        }
        Config.Save()
    }

    static GetSetting(name)
    {
        return Config.Data["settings"][name]
    }

    static SetSetting(name, value)
    {
        Config.Data["settings"][name] := value
        Config.Save()
    }

    static Export(destPath)
    {
        text := JSON.Dump(Config.Data, true)
        try FileDelete(destPath)
        FileAppend(text, destPath, "UTF-8")
    }

    static Import(srcPath)
    {
        raw := FileRead(srcPath, "UTF-8")
        parsed := JSON.Load(raw)
        Config.Data := Config._Validate(parsed)
        Config.Save()
        return Config.Data
    }

    ; ---- Internal ----

    static _DefaultConfig()
    {
        cfg := Map()
        settings := Map(
            "runAtStartup", false,
            "startMinimized", false,
            "runLauncherAfterLogin", false,
            "showTrayIcon", true,
            "checkForUpdates", true,
            "runAsAdmin", false,
            "launcherNumLockMode", "off"
        )
        cfg["settings"] := settings
        cfg["shortcuts"] := Array()   ; empty by design - no example shortcuts
        return cfg
    }

    ; Ensures a parsed config has every expected field, filling in defaults
    ; for anything missing so older/partial config files still load.
    static _Validate(parsed)
    {
        cfg := Config._DefaultConfig()

        if (parsed.Has("settings") && parsed["settings"] is Map)
        {
            for k, v in parsed["settings"]
                cfg["settings"][k] := v
        }

        ; Older config.json files won't have this key at all, and anything
        ; other than "on"/"off" is treated as invalid - both cases fall back
        ; to "on" so existing users keep their current behavior.
        if (cfg["settings"]["launcherNumLockMode"] != "on" && cfg["settings"]["launcherNumLockMode"] != "off")
            cfg["settings"]["launcherNumLockMode"] := "off"

        if (parsed.Has("shortcuts") && parsed["shortcuts"] is Array)
        {
            clean := Array()
            for sc in parsed["shortcuts"]
            {
                if !(sc is Map)
                    continue
                if !sc.Has("key") || !sc.Has("type") || !sc.Has("name") || !sc.Has("target")
                {
                    Logger.Warn("Skipping malformed shortcut entry in config.json.")
                    continue
                }
                sc["enabled"] := sc.Has("enabled") ? sc["enabled"] : true
                sc["args"] := sc.Has("args") ? sc["args"] : ""
                sc["iconPath"] := sc.Has("iconPath") ? sc["iconPath"] : ""
                sc["matchExe"] := sc.Has("matchExe") ? sc["matchExe"] : ""
                sc["matchTitle"] := sc.Has("matchTitle") ? sc["matchTitle"] : ""
                sc["matchClass"] := sc.Has("matchClass") ? sc["matchClass"] : ""
                clean.Push(sc)
            }
            cfg["shortcuts"] := clean
        }

        return cfg
    }
}
