<p align="center">
  <img src="Assets/Banner.png" alt="NumpadOS Banner">
</p>

# NumpadOS

> Turn your unused numpad into a multitasking powerhouse.
# NumpadOS

<div align="center">

# ⌨️ NumpadOS

### Turn your unused numpad into a multitasking powerhouse.

A lightweight Windows productivity launcher built with **AutoHotkey v2**.

Launch applications, Brave PWAs, manage windows, and access your favorite tools directly from your numpad.

> **Version:** v1.0.0

</div>

---

# ✨ Features

- 🚀 Launch desktop applications instantly
- 🌐 Launch Brave Progressive Web Apps (PWAs)
- 🪟 Automatically activate existing windows instead of opening duplicates
- 📋 Clipboard History shortcut
- ⚙️ Windows Settings shortcut
- 🖥 Window management shortcuts
- 🔔 Optional toast notifications
- 📝 Debug logging
- ⚡ Lightweight
- 💾 Portable
- 🛠 Easy to configure using `Config.ini`

---

# 📸 Screenshots

> Screenshots will be added soon.

```
Screenshots/
├── Desktop.png
├── Toast.png
├── Config.png
└── GitHub.png
```

---

# 📦 Requirements

- Windows 10 or Windows 11
- AutoHotkey v2.x
- Brave Browser (only if using Brave PWAs)

---

# 🚀 Installation

1. Download the latest release.
2. Extract the ZIP file.
3. Install **AutoHotkey v2**.
4. Open the extracted folder.
5. Double-click:

```
Launcher.ahk
```

NumpadOS will start and remain in the system tray.

---

# 🛠 First-Time Setup

Before using NumpadOS, configure the paths inside `Config.ini`.

Every computer is different, so you may need to update the default paths.

---

## Finding an application's `.exe` path

### Method 1 (Recommended)

1. Open the Start Menu.
2. Search for the application.
3. Right-click it.
4. Select **Open file location**.
5. Right-click the shortcut.
6. Select **Properties**.
7. Click **Open File Location** (if available).
8. Copy the full path to the executable.

Example:

```text
C:\Program Files\Microsoft VS Code\Code.exe
```

Paste that path into `Config.ini`.

---

### Method 2

If the application is already running:

1. Press **Ctrl + Shift + Esc**
2. Open **Task Manager**
3. Right-click the application
4. Click **Open file location**

---

# 🌐 Finding Brave PWA Shortcuts

ChatGPT, Claude, YouTube and other web apps are launched using **Brave App shortcuts (.lnk files)**.

### Method 1

Install the website as a Brave App.

Then:

1. Press **Win + R**
2. Type

```text
shell:programs
```

3. Press Enter.
4. Open the **Brave Apps** folder.
5. Locate your application.

Example:

```
ChatGPT.lnk
Claude.lnk
YouTube.lnk
```

Right-click the shortcut.

Choose:

```
Properties
```

Copy its location.

Example:

```text
C:\Users\YourName\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Brave Apps\ChatGPT.lnk
```

Paste it into `Config.ini`.

---

# ⚙️ Configuration

Open

```
Config.ini
```

and edit the application paths.

Example:

```ini
HarmonoidPath=C:\Program Files\Harmonoid\harmonoid.exe

ObsidianPath=C:\Program Files\Obsidian\Obsidian.exe

VSCodePath=code

CommandPromptPath=cmd.exe

NotepadPath=notepad.exe

BravePath=C:\Program Files\BraveSoftware\Brave-Browser\Application\brave.exe

TaskManagerPath=taskmgr.exe
```

---

## Configure Brave PWAs

Example:

```ini
ChatGPTShortcut=C:\Users\YourName\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Brave Apps\ChatGPT.lnk

ClaudeShortcut=C:\Users\YourName\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Brave Apps\Claude.lnk

YouTubeShortcut=C:\Users\YourName\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Brave Apps\YouTube.lnk
```

Simply replace the paths with your own.

---

# 🔄 Reload After Editing

Whenever you edit `Config.ini` you must reload NumpadOS.

You can reload by:

- Pressing **Ctrl + Num Lock**

or

- Right-click the AutoHotkey tray icon
- Select **Reload Script**

---

# 🔁 After Restarting Windows

If Windows restarts or your computer reboots:

- Double-click `Launcher.ahk` again to start NumpadOS.

If you have enabled automatic startup in your configuration, NumpadOS will launch automatically when you sign in.

---

# ⌨️ Default Hotkeys

Version **1.0.0** includes a fixed hotkey layout.

Examples include launching:

- ChatGPT
- Claude
- Harmonoid
- Obsidian
- VS Code
- Calculator

and shortcuts for:

- Clipboard History
- Windows Settings
- Window management

> **Note:** The hotkey layout is fixed in v1.0.0. Future versions will allow users to customize key assignments without editing the source code.

---

# 💡 Tips

- Keep **Num Lock OFF** to use NumpadOS shortcuts.
- Turn **Num Lock ON** to use the numpad normally.
- Reload the script after editing `Config.ini`.
- Enable `DebugMode=1` if something is not working.

---

# 📝 Logging

NumpadOS can create log files for troubleshooting.

Enable:

```ini
DebugMode=1
```

Then reproduce the issue and inspect the generated log.

---

# ❓ Troubleshooting

## Nothing happens when pressing a hotkey

- Verify AutoHotkey v2 is installed.
- Make sure `Launcher.ahk` is running.
- Check the tray icon.
- Verify the application path in `Config.ini`.

---

## ChatGPT or Claude won't open

Verify the `.lnk` shortcut exists and points to the correct Brave App.

---

## Wrong application launches

Double-check the configured path in `Config.ini`.

---

## Changes don't apply

Reload the script:

- **Ctrl + Num Lock**

or

- Tray Icon → Reload Script

---

# 🚧 Current Limitations

- Windows only
- Requires AutoHotkey v2
- Fixed hotkey layout
- Brave PWAs must already be installed

---

# 🗺 Roadmap

## ✅ v1.0.0

- Desktop application launcher
- Brave PWA launcher
- Window management
- Config.ini support
- Logging
- Toast notifications

## 🚀 Future

- Custom hotkey mapping
- Graphical settings window
- Additional launcher modules
- Plugin support
- Themes
- Automatic updater

---

# 🤝 Contributing

Bug reports, feature requests and pull requests are welcome.

If you discover a bug or have an idea to improve NumpadOS, please open an Issue on GitHub.

---

# 📜 License

This project is licensed under the MIT License.

See the `LICENSE` file for details.

---

<div align="center">

Made with ❤️ using AutoHotkey v2

If you like this project, consider giving it a ⭐ on GitHub!

</div>
