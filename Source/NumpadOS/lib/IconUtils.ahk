; ============================================================================
; IconUtils.ahk
; ----------------------------------------------------------------------------
; Handles icon acquisition for shortcuts:
;   - Program  -> icon embedded in the target .exe
;   - Folder   -> the standard Windows folder icon
;   - Website  -> the site's favicon (downloaded to a local cache), with a
;                 generic "globe" icon as fallback if the download fails
;   - Keyboard -> a generic keyboard icon
;
; Icons are loaded into a shared ImageList (see CreateImageList) for display
; in the ListView on the main window. This avoids manually decoding .ico
; files - IL_Add() can pull icons directly out of .exe/.dll files.
; ============================================================================

class IconUtils
{
    static CacheDir := A_ScriptDir . "\data\icon_cache"

    static Shell32 := A_WinDir . "\System32\shell32.dll"
    static ImageRes := A_WinDir . "\System32\imageres.dll"

    ; Classic shell32.dll icon indices used as fallbacks.
    static FALLBACK_FOLDER_ICON := 3
    static FALLBACK_GLOBE_ICON := 13
    static FALLBACK_KEYBOARD_ICON := 21
    static FALLBACK_PROGRAM_ICON := 2

    static CreateImageList()
    {
        ; false = small (16x16) icons, matching the ListView's small-icon
        ; slot used to render row icons in report view.
        return IL_Create(8, 8, false)
    }

    ; Returns the 1-based icon index within the image list for this shortcut,
    ; acquiring/caching the icon as needed. Never throws - falls back to a
    ; generic icon on any failure so the UI never breaks over a bad icon.
    static IconIndexForShortcut(imageList, shortcut)
    {
        try
        {
            switch shortcut["type"]
            {
                case "program": return IconUtils._ProgramIcon(imageList, shortcut["target"])
                case "folder":  return IconUtils._FolderIcon(imageList)
                case "website": return IconUtils._WebsiteIcon(imageList, shortcut["target"], shortcut["name"])
                case "keyboard": return IconUtils._KeyboardIcon(imageList)
            }
        }
        catch as e
        {
            Logger.Warn("Icon lookup failed, using fallback: " . e.Message)
        }
        return IL_Add(imageList, IconUtils.Shell32, IconUtils.FALLBACK_PROGRAM_ICON)
    }

    static _ProgramIcon(imageList, exePath)
    {
        if FileExist(exePath)
        {
            idx := IL_Add(imageList, exePath, 1)
            if (idx)
                return idx
        }
        return IL_Add(imageList, IconUtils.Shell32, IconUtils.FALLBACK_PROGRAM_ICON)
    }

    static _FolderIcon(imageList)
    {
        return IL_Add(imageList, IconUtils.Shell32, IconUtils.FALLBACK_FOLDER_ICON)
    }

    static _KeyboardIcon(imageList)
    {
        return IL_Add(imageList, IconUtils.Shell32, IconUtils.FALLBACK_KEYBOARD_ICON)
    }

    static _WebsiteIcon(imageList, url, name)
    {
        try DirCreate(IconUtils.CacheDir)
        safeName := RegExReplace(name, "[^A-Za-z0-9_\-]", "_")
        destPath := IconUtils.CacheDir . "\" . safeName . ".ico"

        if !FileExist(destPath)
        {
            if !IconUtils.DownloadFavicon(url, destPath)
                return IL_Add(imageList, IconUtils.Shell32, IconUtils.FALLBACK_GLOBE_ICON)
        }

        idx := 0
        try idx := IL_Add(imageList, destPath)
        if (idx)
            return idx
        return IL_Add(imageList, IconUtils.Shell32, IconUtils.FALLBACK_GLOBE_ICON)
    }

    ; Attempts to download <origin>/favicon.ico. Returns true on success.
    ; This is a best-effort convenience feature, not guaranteed to work for
    ; every site (many sites use non-standard favicon locations/formats).
    static DownloadFavicon(url, destPath)
    {
        try
        {
            origin := RegExReplace(url, "^(https?://[^/]+).*$", "$1")
            faviconUrl := origin . "/favicon.ico"
            Download(faviconUrl, destPath)
            return FileExist(destPath) ? true : false
        }
        catch as e
        {
            Logger.Warn("Favicon download failed for " . url . ": " . e.Message)
            return false
        }
    }
}
