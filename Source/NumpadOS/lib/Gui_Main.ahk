; ============================================================================
; Gui_Main.ahk
; ----------------------------------------------------------------------------
; The Configurator's main window: shortcut list + Add/Edit/Delete/Test/
; Import/Export/Settings actions. On first run this list is empty by design
; - NumpadOS never pre-populates example shortcuts.
; ============================================================================

class MainWindow
{
    static gui := ""
    static lv := ""
    static imageList := ""
    static emptyText := ""
    static btnEdit := ""
    static btnDelete := ""
    static btnTest := ""

    static Show()
    {
        g := Gui("+Resize +MinSize640x420", "NumpadOS Configurator")
        MainWindow.gui := g
        Utils.ApplyStandardTheme(g)

        g.OnEvent("Close", (*) => MainWindow.OnClose())
        g.OnEvent("Size", (*) => MainWindow.OnResize())

        ; ---- Shortcut list ----
        lv := g.Add("ListView", "x16 y16 w608 h300 vShortcutList -Multi", ["Key", "Name", "Type", "Enabled"])
        lv.OnEvent("ItemSelect", (*) => MainWindow.UpdateButtonStates())
        lv.OnEvent("DoubleClick", (*) => MainWindow.OnEdit())
        Utils.ApplyControlTheme(lv)
        MainWindow.lv := lv

        MainWindow.imageList := IconUtils.CreateImageList()
        lv.SetImageList(MainWindow.imageList, 1) ; 1 = small-icon list, used by report-view rows

        lv.ModifyCol(1, 90)
        lv.ModifyCol(2, 260)
        lv.ModifyCol(3, 140)
        lv.ModifyCol(4, 90)

        emptyText := g.Add("Text", "x16 y140 w608 Center vEmptyText c" . Utils.Colors["text"],
            "No shortcuts configured.`n`nClick '+ Add Shortcut' below to get started.")
        emptyText.SetFont("s11")
        MainWindow.emptyText := emptyText

        ; ---- Action buttons (left column: list management) ----
        g.Add("Button", "x16 y326 w110 h32 vBtnAdd", "+ Add Shortcut").OnEvent("Click", (*) => MainWindow.OnAdd())
        btnEdit := g.Add("Button", "x132 y326 w90 h32 vBtnEdit Disabled", "Edit")
        btnEdit.OnEvent("Click", (*) => MainWindow.OnEdit())
        MainWindow.btnEdit := btnEdit

        btnDelete := g.Add("Button", "x228 y326 w90 h32 vBtnDelete Disabled", "Delete")
        btnDelete.OnEvent("Click", (*) => MainWindow.OnDelete())
        MainWindow.btnDelete := btnDelete

        btnTest := g.Add("Button", "x324 y326 w90 h32 vBtnTest Disabled", "Test")
        btnTest.OnEvent("Click", (*) => MainWindow.OnTest())
        MainWindow.btnTest := btnTest

        g.Add("Button", "x444 y326 w90 h32", "Import").OnEvent("Click", (*) => MainWindow.OnImport())
        g.Add("Button", "x534 y326 w90 h32", "Export").OnEvent("Click", (*) => MainWindow.OnExport())

        g.Add("Button", "x16 y368 w608 h32", "Settings").OnEvent("Click", (*) => MainWindow.OnSettings())

        for btn in [btnEdit, btnDelete, btnTest]
            Utils.ApplyControlTheme(btn)

        MainWindow.Refresh()
        g.Show("w640 h420")
    }

    static OnResize()
    {
        ; Keep it simple and robust across DPI/resizes: re-anchor the list
        ; and buttons proportionally to the window size.
        try
        {
            g := MainWindow.gui
            g.GetClientPos(, , &w, &h)
            MainWindow.lv.Move(16, 16, w - 32, h - 104)
            MainWindow.emptyText.Move(16, Integer(h / 2) - 30, w - 32)
        }
    }

    ; Repopulates the ListView from Config.Data and toggles the empty-state message.
    static Refresh()
    {
        lv := MainWindow.lv
        lv.Delete()

        shortcuts := Config.GetShortcuts()

        if (shortcuts.Length = 0)
        {
            lv.Visible := false
            MainWindow.emptyText.Visible := true
            MainWindow.UpdateButtonStates()
            return
        }

        lv.Visible := true
        MainWindow.emptyText.Visible := false

        ; Sort a display copy by numpad key for a predictable, tidy list.
        sorted := MainWindow._SortedShortcuts(shortcuts)

        for sc in sorted
        {
            iconIdx := IconUtils.IconIndexForShortcut(MainWindow.imageList, sc)
            enabledText := sc["enabled"] ? "Yes" : "No"
            row := lv.Add("Icon" . iconIdx, Utils.KeyLabel(sc["key"]), sc["name"], Utils.TypeLabel(sc["type"]), enabledText)
        }

        MainWindow.UpdateButtonStates()
    }

    static _SortedShortcuts(shortcuts)
    {
        order := Config.ValidKeys
        indexOf := Map()
        for i, k in order
            indexOf[k] := i

        arr := []
        for sc in shortcuts
            arr.Push(sc)

        ; simple insertion sort - shortcut lists are tiny (max 16 entries)
        loop arr.Length - 1
        {
            i := A_Index + 1
            key := arr[i]
            j := i - 1
            while (j >= 1 && indexOf[arr[j]["key"]] > indexOf[key["key"]])
            {
                arr[j + 1] := arr[j]
                j--
            }
            arr[j + 1] := key
        }
        return arr
    }

    static SelectedShortcut()
    {
        row := MainWindow.lv.GetNext()
        if !row
            return ""
        sorted := MainWindow._SortedShortcuts(Config.GetShortcuts())
        return sorted[row]
    }

    static UpdateButtonStates()
    {
        hasSelection := MainWindow.lv.GetNext() != 0
        MainWindow.btnEdit.Enabled := hasSelection
        MainWindow.btnDelete.Enabled := hasSelection
        MainWindow.btnTest.Enabled := hasSelection
    }

    ; ---- Actions ----

    static OnAdd()
    {
        ShortcutWizard.ShowNew((*) => MainWindow.Refresh())
    }

    static OnEdit()
    {
        sc := MainWindow.SelectedShortcut()
        if !sc
            return
        ShortcutWizard.ShowEdit(sc, (*) => MainWindow.Refresh())
    }

    static OnDelete()
    {
        sc := MainWindow.SelectedShortcut()
        if !sc
            return
        result := MsgBox("Delete the shortcut '" . sc["name"] . "'?", "Confirm Delete", "YesNo Icon!")
        if (result = "Yes")
        {
            Config.RemoveShortcut(sc)
            MainWindow.Refresh()
            Utils.ShowSavedReloadPrompt()
        }
    }

    static OnTest()
    {
        sc := MainWindow.SelectedShortcut()
        if !sc
            return
        try
        {
            SmartLaunch.Launch(sc)
        }
        catch as e
        {
            MsgBox("Couldn't launch '" . sc["name"] . "':`n`n" . e.Message, "Test Failed", "Icon!")
        }
    }

    static OnImport()
    {
        file := FileSelect(1, , "Import NumpadOS Configuration", "JSON Files (*.json)")
        if (file = "")
            return
        try
        {
            Config.Import(file)
            MainWindow.Refresh()
            MsgBox("Configuration imported successfully.", "Import Complete", "Iconi")
        }
        catch as e
        {
            MsgBox("Import failed:`n`n" . e.Message, "Import Error", "Icon!")
        }
    }

    static OnExport()
    {
        file := FileSelect("S16", "NumpadOS-config.json", "Export NumpadOS Configuration", "JSON Files (*.json)")
        if (file = "")
            return
        if !RegExMatch(file, "\.json$")
            file .= ".json"
        try
        {
            Config.Export(file)
            MsgBox("Configuration exported to:`n" . file, "Export Complete", "Iconi")
        }
        catch as e
        {
            MsgBox("Export failed:`n`n" . e.Message, "Export Error", "Icon!")
        }
    }

    static OnSettings()
    {
        SettingsWindow.Show()
    }

    static OnClose()
    {
        MainWindow.gui.Hide()
        if !Config.GetSetting("showTrayIcon")
            ExitApp()
        ; If a tray icon is enabled, closing the window just hides it -
        ; the app keeps running so the tray menu remains available.
    }
}
