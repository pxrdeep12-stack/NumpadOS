; ============================================================================
; Logger.ahk
; ----------------------------------------------------------------------------
; Simple rolling file logger shared by Configurator.ahk and Launcher.ahk.
; Never throws - logging must never crash the host application.
; ============================================================================

class Logger
{
    static LogDir := A_ScriptDir . "\logs"
    static MaxSizeBytes := 1024 * 1024 ; 1 MB before rotating

    static Init(fileName)
    {
        this._file := this.LogDir . "\" . fileName
        try DirCreate(this.LogDir)
        this._Rotate()
    }

    static Info(msg)  => this._Write("INFO ", msg)
    static Warn(msg)  => this._Write("WARN ", msg)
    static Error(msg) => this._Write("ERROR", msg)
    static Debug(msg) => this._Write("DEBUG", msg)

    static _Write(level, msg)
    {
        try
        {
            timestamp := FormatTime(, "yyyy-MM-dd HH:mm:ss")
            line := "[" . timestamp . "] [" . level . "] " . msg . "`n"
            FileAppend(line, this._file, "UTF-8")
        }
        ; Swallow any logging failure (e.g. locked file, missing dir) -
        ; the calling application should keep running regardless.
    }

    static _Rotate()
    {
        try
        {
            if FileExist(this._file)
            {
                size := FileGetSize(this._file)
                if (size > this.MaxSizeBytes)
                {
                    bakFile := this._file . ".old"
                    if FileExist(bakFile)
                        FileDelete(bakFile)
                    FileMove(this._file, bakFile)
                }
            }
        }
    }
}
