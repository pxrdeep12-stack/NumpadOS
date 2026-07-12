# NumpadOS

> **Turn your unused numpad into a multitasking powerhouse.**

NumpadOS is a lightweight Windows productivity launcher built with **AutoHotkey v2**. It transforms an unused numpad into a powerful command center for launching applications, Brave PWAs, managing windows, and accessing frequently used tools—all with a single key press.

---

## ✨ Features

- 🚀 Launch desktop applications instantly
- 🌐 Launch Brave Progressive Web Apps (PWAs)
- 🪟 Activate existing windows instead of opening duplicates
- 📂 Open frequently used folders and tools
- 🖥️ Window management shortcuts
- 📋 Clipboard History shortcut
- ⚙️ Windows Settings shortcut
- 🔔 Optional toast notifications
- 📝 Built-in logging for troubleshooting
- ⚡ Lightweight and fast
- 🛠️ Easy to customize using `Config.ini`

---

## 📸 Screenshots

> Screenshots will be added in a future update.

---

# 📦 Requirements

- Windows 10 or Windows 11
- AutoHotkey v2.x
- Brave Browser (only if using Brave PWAs)

---

# 🚀 Installation

1. Download the latest release.
2. Extract the ZIP file.
3. Install **AutoHotkey v2** if it is not already installed.
4. Open the project folder.
5. Double-click `Launcher.ahk`.

NumpadOS will start and remain in the system tray.

---

# ⚙️ Configuration

Most settings can be changed by editing **Config.ini**.

After changing the configuration, reload the script by:

- Pressing **Ctrl + Num Lock**
- or right-clicking the AutoHotkey tray icon → **Reload Script**

---

## 🖥️ Configure Desktop Applications

Open `Config.ini`.

Edit the application paths under the **Applications** section.

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

If an application is installed elsewhere, simply replace the path.

---

## 🌐 Configure Brave PWAs

ChatGPT, Claude and YouTube are launched using **Brave App shortcuts (.lnk files)**.

Edit these values inside `Config.ini`:

```ini
ChatGPTShortcut=
ClaudeShortcut=
YouTubeShortcut=
```

Example:

```ini
ChatGPTShortcut=C:\Users\YourName\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Brave Apps\ChatGPT.lnk

ClaudeShortcut=C:\Users\YourName\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Brave Apps\Claude.lnk

YouTubeShortcut=C:\Users\YourName\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Brave Apps\YouTube.lnk
```

If your shortcut names are different, simply point them to the correct `.lnk` files.

---

## 🔔 Toast Notifications

```ini
ShowToasts=1
ToastDuration=800
```

Set:

```ini
ShowToasts=0
```

to disable notifications.

---

## 📝 Debug Logging

Enable detailed logging by changing:

```ini
DebugMode=1
```

Logs are saved automatically and can help diagnose problems.

---

## 🚀 Launch on Startup

To automatically launch NumpadOS when Windows starts:

```ini
LaunchOnStartup=1
```

---

# ⌨️ Default Numpad Layout

The default key assignments are configured for productivity.

Examples include:

- ChatGPT
- Claude
- Harmonoid
- Obsidian
- VS Code
- Calculator
- Windows Settings
- Clipboard History
- Window management

The application paths can be changed through **Config.ini**.

> **Note:** In **v1.0.0**, the key layout itself is fixed. A future version will allow users to customize key assignments without editing the source code.

---

# 📄 Logging

NumpadOS automatically creates log files for debugging.

If something is not working:

1. Enable

```ini
DebugMode=1
```

2. Reproduce the issue.
3. Check the generated log file.

---

# 🚧 Current Limitations

- Windows only
- Requires AutoHotkey v2
- Hotkey layout is fixed in v1.0.0
- Brave PWAs must already be installed

---

# 🗺️ Roadmap

## v1.0.0

- ✅ Desktop application launcher
- ✅ Brave PWA launcher
- ✅ Window management
- ✅ Config.ini support
- ✅ Logging
- ✅ Toast notifications

## Future

- Custom hotkey mapping
- Graphical configuration tool
- More launcher modules
- Better startup integration
- Plugin support

---

# 🤝 Contributing

Contributions, bug reports and feature requests are welcome.

If you find a bug or have an idea for improving NumpadOS, please open an Issue or submit a Pull Request.

---

# 📜 License

This project is licensed under the MIT License.

See the `LICENSE` file for details.
