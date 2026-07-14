; ============================================================================
; Gui_Wizard.ahk
; ----------------------------------------------------------------------------
; The "Add Shortcut" / "Edit Shortcut" wizard.
;   Step 1 - choose a numpad key (keys already in use are disabled)
;   Step 2 - choose a shortcut type: Program / Folder / Website / Keyboard
;   Step 3 - type-specific fields + shortcut name
;
; Editing reuses the exact same wizard, pre-filled with the shortcut's
; current values, so every field (key, path, URL, combo, name) stays
; editable per the spec.
; ============================================================================

class ShortcutWizard
{
    static gui := ""
    static step := 1
    static editing := ""      ; the shortcut Map being edited, or "" for new
    static onDone := ""       ; callback invoked after a successful save

    static chosenKey := ""
    static chosenType := ""

    ; step panels (arrays of controls, shown/hidden together)
    static panel1 := ""
    static panel2 := ""
    static panel3 := ""

    static keyRadios := Map()
    static typeRadios := Map()

    ; type-3 controls, created dynamically per type
    static fieldControls := Map()

    ; ---- Keyboard shortcut editor option lists ----
    ; Box 1 is always a modifier. Box 2 may be a second modifier or the
    ; final key. Box 3 (optional) is only used - and only offered - when
    ; Box 2 holds a modifier, and always holds the final key in that case.
    static ModifierChoices := ["(choose)", "Ctrl", "Alt", "Shift", "Win"]
    static KeyChoices := [
        "A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M",
        "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z",
        "0", "1", "2", "3", "4", "5", "6", "7", "8", "9",
        "F1", "F2", "F3", "F4", "F5", "F6", "F7", "F8", "F9", "F10", "F11", "F12",
        "Esc", "Tab", "Enter", "Space", "Backspace", "Delete", "Insert",
        "Home", "End", "PgUp", "PgDn", "Up", "Down", "Left", "Right",
        "PrintScreen", "CapsLock", "NumLock", "ScrollLock", "Pause", "AppsKey"
    ]

    static lblTitle := ""
    static btnBack := ""
    static btnNext := ""

    ; ---- Public entry points ----

    static ShowNew(onDone)
    {
        ShortcutWizard._Cleanup() ; ensure no stale controls/GUI survive from a previous session
        ShortcutWizard.editing := ""
        ShortcutWizard.onDone := onDone
        ShortcutWizard.chosenKey := ""
        ShortcutWizard.chosenType := ""
        ShortcutWizard._Build()
    }

    static ShowEdit(shortcut, onDone)
    {
        ShortcutWizard._Cleanup() ; ensure no stale controls/GUI survive from a previous session
        ShortcutWizard.editing := shortcut
        ShortcutWizard.onDone := onDone
        ShortcutWizard.chosenKey := shortcut["key"]
        ShortcutWizard.chosenType := shortcut["type"]
        ShortcutWizard._Build()
        ShortcutWizard._GoToStep(3) ; editing jumps straight to details; Back is still available
    }

    ; Destroys the current wizard Gui (if any) and clears every static
    ; reference to its controls. Without this, closing one wizard (via
    ; Save, Cancel, or the window's X button) left panel1/panel2/panel3,
    ; keyRadios/typeRadios/fieldControls, and the Back/Next/title labels
    ; all pointing at now-destroyed controls. The next ShowNew()/ShowEdit()
    ; call rebuilds panel1/panel2 fine, but _GoToStep(1) still looped over
    ; the *old* panel3 (never reset) and tried to touch its destroyed
    ; controls, throwing "The control is destroyed." This makes every
    ; wizard session start from a completely clean slate.
    static _Cleanup()
    {
        if (ShortcutWizard.gui != "")
        {
            try ShortcutWizard.gui.Destroy()
        }
        ShortcutWizard.gui := ""
        ShortcutWizard.panel1 := ""
        ShortcutWizard.panel2 := ""
        ShortcutWizard.panel3 := ""
        ShortcutWizard.keyRadios := Map()
        ShortcutWizard.typeRadios := Map()
        ShortcutWizard.fieldControls := Map()
        ShortcutWizard.lblTitle := ""
        ShortcutWizard.btnBack := ""
        ShortcutWizard.btnNext := ""
    }

    ; ---- Build ----

    static _Build()
    {
        g := Gui("+Owner" . MainWindow.gui.Hwnd . " -MinimizeBox -MaximizeBox", ShortcutWizard.editing ? "Edit Shortcut" : "Add Shortcut")
        ShortcutWizard.gui := g
        Utils.ApplyStandardTheme(g)
        g.OnEvent("Close", (*) => ShortcutWizard._Cleanup())

        lblTitle := g.Add("Text", "x16 y14 w468 vTitle", "Step 1 of 3: Choose a Numpad Key")
        lblTitle.SetFont("s12 bold")
        ShortcutWizard.lblTitle := lblTitle

        ShortcutWizard._BuildStep1(g)
        ShortcutWizard._BuildStep2(g)
        ; Step 3 is built dynamically once a type is known (_BuildStep3)

        btnBack := g.Add("Button", "x16 y400 w90 h32", "< Back")
        btnBack.OnEvent("Click", (*) => ShortcutWizard._Back())
        ShortcutWizard.btnBack := btnBack

        btnCancel := g.Add("Button", "x306 y400 w90 h32", "Cancel")
        btnCancel.OnEvent("Click", (*) => ShortcutWizard._Cleanup())

        btnNext := g.Add("Button", "x396 y400 w90 h32 Default", "Next >")
        btnNext.OnEvent("Click", (*) => ShortcutWizard._Next())
        ShortcutWizard.btnNext := btnNext

        for c in [btnBack, btnCancel, btnNext]
            Utils.ApplyControlTheme(c)

        ShortcutWizard._GoToStep(1)
        g.Show("w500 h450")
    }

    ; ---- Step 1: key picker ----

    static _BuildStep1(g)
    {
        panel := []
        y := 56
        col := 0
        ShortcutWizard.keyRadios := Map()
        first := true
        for key in Config.ValidKeys
        {
            x := 16 + Mod(col, 4) * 118
            if (Mod(col, 4) = 0 && col > 0)
                y += 36

            inUse := Config.IsKeyInUse(key, ShortcutWizard.editing)
            opts := "x" . x . " y" . y . " w110"
            opts .= first ? " Group" : ""
            label := Utils.KeyLabel(key) . (inUse ? " (in use)" : "")
            radio := g.Add("Radio", opts, label)
            if (inUse)
                radio.Enabled := false
            if (ShortcutWizard.chosenKey = key)
                radio.Value := true
            radio.OnEvent("Click", ((k) => (*) => ShortcutWizard.chosenKey := k)(key))
            Utils.ApplyControlTheme(radio)
            ShortcutWizard.keyRadios[key] := radio
            panel.Push(radio)
            col++
            first := false
        }
        ShortcutWizard.panel1 := panel
    }

    ; ---- Step 2: type picker ----

    static _BuildStep2(g)
    {
        panel := []
        types := [
            ["program", "Program (.exe)", "Launch an application"],
            ["folder", "Folder", "Open a folder in Explorer"],
            ["website", "Website", "Open a URL in your browser"],
            ["keyboard", "Keyboard Shortcut", "Send a key combination"]
        ]
        y := 60
        first := true
        ShortcutWizard.typeRadios := Map()
        for t in types
        {
            opts := "x16 y" . y . " w468"
            opts .= first ? " Group" : ""
            radio := g.Add("Radio", opts, t[2] . "  -  " . t[3])
            if (ShortcutWizard.chosenType = t[1])
                radio.Value := true
            radio.OnEvent("Click", ((typ) => (*) => ShortcutWizard.chosenType := typ)(t[1]))
            Utils.ApplyControlTheme(radio)
            ShortcutWizard.typeRadios[t[1]] := radio
            panel.Push(radio)
            y += 40
            first := false
        }
        ShortcutWizard.panel2 := panel
    }

    ; ---- Step 3: type-specific fields (built fresh each time a type is chosen) ----

    static _BuildStep3(g)
    {
        ; Tear down any previous step-3 controls first.
        if (ShortcutWizard.panel3 != "")
        {
            for c in ShortcutWizard.panel3
                c.Visible := false
        }

        panel := []
        controls := Map()
        y := 60
        sc := ShortcutWizard.editing

        switch ShortcutWizard.chosenType
        {
            case "program":
                panel.Push(g.Add("Text", "x16 y" . y, "Executable path:"))
                pathEdit := g.Add("Edit", "x16 y" . (y + 20) . " w370 vProgramPath", sc ? sc["target"] : "")
                browseBtn := g.Add("Button", "x392 y" . (y + 19) . " w94 h24", "Browse...")
                browseBtn.OnEvent("Click", (*) => ShortcutWizard._BrowseExe(pathEdit))
                panel.Push(pathEdit)
                panel.Push(browseBtn)
                controls["path"] := pathEdit
                y += 56

            case "folder":
                panel.Push(g.Add("Text", "x16 y" . y, "Folder path:"))
                pathEdit := g.Add("Edit", "x16 y" . (y + 20) . " w370 vFolderPath", sc ? sc["target"] : "")
                browseBtn := g.Add("Button", "x392 y" . (y + 19) . " w94 h24", "Browse...")
                browseBtn.OnEvent("Click", (*) => ShortcutWizard._BrowseFolder(pathEdit))
                panel.Push(pathEdit)
                panel.Push(browseBtn)
                controls["path"] := pathEdit
                y += 56

            case "website":
                panel.Push(g.Add("Text", "x16 y" . y, "Website URL:"))
                urlEdit := g.Add("Edit", "x16 y" . (y + 20) . " w470 vWebsiteUrl", sc ? sc["target"] : "https://")
                panel.Push(urlEdit)
                controls["url"] := urlEdit
                y += 56

            case "keyboard":
                panel.Push(g.Add("Text", "x16 y" . y, "Keyboard shortcut:"))
                yRow := y + 20

                comboParts := ShortcutWizard._ParseComboParts(sc ? sc["target"] : "")

                ddl1 := g.Add("DropDownList", "x16 y" . yRow . " w130 vCombo1", ShortcutWizard.ModifierChoices)
                ShortcutWizard._ChooseIfPresent(ddl1, ShortcutWizard.ModifierChoices, comboParts[1])
                if (ddl1.Value = 0)
                    ddl1.Choose(1)

                plus1 := g.Add("Text", "x150 y" . (yRow + 4) . " w16", "+")

                box2Choices := ShortcutWizard._Box2Choices()
                ddl2 := g.Add("DropDownList", "x170 y" . yRow . " w130 vCombo2", box2Choices)
                ShortcutWizard._ChooseIfPresent(ddl2, box2Choices, comboParts[2])
                if (ddl2.Value = 0)
                    ddl2.Choose(1)

                plus2 := g.Add("Text", "x304 y" . (yRow + 4) . " w16", "+")

                box3Choices := ShortcutWizard._Box3Choices()
                ddl3 := g.Add("DropDownList", "x324 y" . yRow . " w130 vCombo3", box3Choices)
                ShortcutWizard._ChooseIfPresent(ddl3, box3Choices, comboParts[3])
                if (ddl3.Value = 0)
                    ddl3.Choose(1)

                panel.Push(ddl1)
                panel.Push(plus1)
                panel.Push(ddl2)
                panel.Push(plus2)
                panel.Push(ddl3)
                controls["combo1"] := ddl1
                controls["combo2"] := ddl2
                controls["combo3"] := ddl3

                ddl2.OnEvent("Change", (*) => ShortcutWizard._OnCombo2Changed())
                ShortcutWizard._OnCombo2Changed() ; sync Box 3's enabled state for the pre-filled value

                y += 56

                panel.Push(g.Add("Text", "x16 y" . y . " w470 c" . Utils.Colors["accent"],
                    'The last box is optional - leave it on "(none)" for a 2-key shortcut like Ctrl+C.'))
                y += 24
        }

        panel.Push(g.Add("Text", "x16 y" . y, "Shortcut name:"))
        defaultName := sc ? sc["name"] : ""
        nameEdit := g.Add("Edit", "x16 y" . (y + 20) . " w470 vShortcutName", defaultName)
        panel.Push(nameEdit)
        controls["name"] := nameEdit
        y += 56

        if (sc)
        {
            enabledChk := g.Add("Checkbox", "x16 y" . y . " vEnabledChk Checked" . (sc["enabled"] ? 1 : 0), "Enabled")
            panel.Push(enabledChk)
            controls["enabled"] := enabledChk
        }

        for c in panel
            Utils.ApplyControlTheme(c)

        ShortcutWizard.panel3 := panel
        ShortcutWizard.fieldControls := controls
    }

    ; Box 2 offers either a second modifier or any final key.
    static _Box2Choices()
    {
        choices := ["(choose)", "Ctrl", "Alt", "Shift", "Win"]
        for k in ShortcutWizard.KeyChoices
            choices.Push(k)
        return choices
    }

    ; Box 3 (optional final key) never offers modifiers.
    static _Box3Choices()
    {
        choices := ["(none)"]
        for k in ShortcutWizard.KeyChoices
            choices.Push(k)
        return choices
    }

    static _IsModifier(text) => (text = "Ctrl" || text = "Alt" || text = "Shift" || text = "Win")

    ; Selects list[i] in a DropDownList if value matches one of its entries;
    ; leaves the default selection otherwise.
    static _ChooseIfPresent(ddl, list, value)
    {
        if (value = "")
            return
        for i, v in list
        {
            if (v = value)
            {
                ddl.Choose(i)
                return
            }
        }
    }

    ; Splits a stored combo string like "Ctrl+Shift+Esc" into up to 3 parts,
    ; padding with "" so callers can always index [1], [2], [3].
    static _ParseComboParts(combo)
    {
        parts := combo != "" ? StrSplit(combo, "+") : []
        return [
            parts.Length >= 1 ? Trim(parts[1]) : "",
            parts.Length >= 2 ? Trim(parts[2]) : "",
            parts.Length >= 3 ? Trim(parts[3]) : ""
        ]
    }

    ; Box 3 only makes sense (and is only enabled) once Box 2 holds a
    ; modifier - if Box 2 holds a plain key, the combo is already complete.
    static _OnCombo2Changed()
    {
        fc := ShortcutWizard.fieldControls
        if !fc.Has("combo2") || !fc.Has("combo3")
            return
        combo3 := fc["combo3"]
        if ShortcutWizard._IsModifier(fc["combo2"].Text)
        {
            combo3.Enabled := true
        }
        else
        {
            combo3.Choose(1) ; "(none)"
            combo3.Enabled := false
        }
    }

    static _BrowseExe(pathEdit)
    {
        file := FileSelect(1, , "Select an executable", "Programs (*.exe)")
        if (file != "")
        {
            pathEdit.Value := file
            nameCtrl := ShortcutWizard.fieldControls["name"]
            if (nameCtrl.Value = "")
                nameCtrl.Value := Utils.SuggestNameFromPath(file)
        }
    }

    static _BrowseFolder(pathEdit)
    {
        folder := FileSelect("D")
        if (folder != "")
        {
            pathEdit.Value := folder
            nameCtrl := ShortcutWizard.fieldControls["name"]
            if (nameCtrl.Value = "")
                nameCtrl.Value := Utils.SuggestNameFromPath(folder)
        }
    }

    ; ---- Navigation ----

    static _GoToStep(n)
    {
        ShortcutWizard.step := n

        for c in ShortcutWizard.panel1
            c.Visible := (n = 1)
        for c in ShortcutWizard.panel2
            c.Visible := (n = 2)

        if (n = 3)
            ShortcutWizard._BuildStep3(ShortcutWizard.gui)
        else if (ShortcutWizard.panel3 != "")
            for c in ShortcutWizard.panel3
                c.Visible := false

        titles := Map(1, "Step 1 of 3: Choose a Numpad Key", 2, "Step 2 of 3: Choose Shortcut Type", 3, "Step 3 of 3: Shortcut Details")
        ShortcutWizard.lblTitle.Text := titles[n]

        ShortcutWizard.btnBack.Enabled := (n > 1)
        ShortcutWizard.btnNext.Text := (n = 3) ? "Save" : "Next >"
    }

    static _Back()
    {
        if (ShortcutWizard.step > 1)
            ShortcutWizard._GoToStep(ShortcutWizard.step - 1)
    }

    static _Next()
    {
        if (ShortcutWizard.step = 1)
        {
            if (ShortcutWizard.chosenKey = "")
            {
                MsgBox("Please choose a numpad key.", "NumpadOS", "Icon!")
                return
            }
            ShortcutWizard._GoToStep(2)
        }
        else if (ShortcutWizard.step = 2)
        {
            if (ShortcutWizard.chosenType = "")
            {
                MsgBox("Please choose a shortcut type.", "NumpadOS", "Icon!")
                return
            }
            ShortcutWizard._GoToStep(3)
        }
        else
        {
            ShortcutWizard._Finish()
        }
    }

    static _Finish()
    {
        fc := ShortcutWizard.fieldControls
        name := Trim(fc["name"].Value)
        if (name = "")
        {
            MsgBox("Please enter a shortcut name.", "NumpadOS", "Icon!")
            return
        }

        target := ""
        switch ShortcutWizard.chosenType
        {
            case "program":
                target := Trim(fc["path"].Value)
                if !FileExist(target)
                {
                    MsgBox("That executable path doesn't exist. Please check it and try again.", "NumpadOS", "Icon!")
                    return
                }
            case "folder":
                target := Trim(fc["path"].Value)
                if !DirExist(target)
                {
                    MsgBox("That folder doesn't exist. Please check it and try again.", "NumpadOS", "Icon!")
                    return
                }
            case "website":
                target := Trim(fc["url"].Value)
                if !Utils.IsPlausibleUrl(target)
                {
                    MsgBox("Please enter a valid website URL (e.g. https://example.com).", "NumpadOS", "Icon!")
                    return
                }
            case "keyboard":
                m1 := fc["combo1"].Text
                m2 := fc["combo2"].Text
                m3 := fc["combo3"].Text

                if (m1 = "(choose)" || m1 = "")
                {
                    MsgBox("Please choose the first modifier key (e.g. Ctrl).", "NumpadOS", "Icon!")
                    return
                }
                if (m2 = "(choose)" || m2 = "")
                {
                    MsgBox("Please choose the second key.", "NumpadOS", "Icon!")
                    return
                }
                if (ShortcutWizard._IsModifier(m2) && m1 = m2)
                {
                    MsgBox("Please choose two different modifier keys.", "NumpadOS", "Icon!")
                    return
                }

                parts := [m1, m2]
                if (ShortcutWizard._IsModifier(m2))
                {
                    if (m3 = "" || m3 = "(none)")
                    {
                        MsgBox("Please choose a final key to complete the shortcut (e.g. Esc, C, F1).", "NumpadOS", "Icon!")
                        return
                    }
                    parts.Push(m3)
                }

                target := ""
                for i, p in parts
                    target .= (i = 1 ? "" : "+") . p

                err := Utils.ValidateHotkeyCombo(target)
                if (err != "")
                {
                    MsgBox(err, "NumpadOS", "Icon!")
                    return
                }
        }

        if (ShortcutWizard.editing)
        {
            sc := ShortcutWizard.editing
            sc["key"] := ShortcutWizard.chosenKey
            sc["type"] := ShortcutWizard.chosenType
            sc["name"] := name
            sc["target"] := target
            sc["iconPath"] := "" ; force icon re-resolution
            if (fc.Has("enabled"))
                sc["enabled"] := fc["enabled"].Value ? true : false
            Config.Save()
        }
        else
        {
            sc := Map(
                "key", ShortcutWizard.chosenKey,
                "type", ShortcutWizard.chosenType,
                "name", name,
                "target", target,
                "args", "",
                "iconPath", "",
                "matchExe", "",
                "matchTitle", "",
                "matchClass", "",
                "enabled", true
            )
            Config.AddShortcut(sc)
        }

        callback := ShortcutWizard.onDone
        ShortcutWizard._Cleanup()
        if (callback)
            callback.Call()
        Utils.ShowSavedReloadPrompt()
    }
}
