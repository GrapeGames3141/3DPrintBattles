## 3D Print Battles (Godot 4)

Kid-safe collectible creature battler inspired by 3D printing + STEM.

### Run on Windows (recommended for dev)
- Install **Godot 4.x** (standard `.exe` build is easiest on Windows)
- Launch Godot and **Import** this folder (it contains `project.godot`)
- Press **Play** (main scene: `Main.tscn`)

Save files are written to `user://Saves/` (Godot maps this to your Windows user app-data location).

### Headless unit tests (Windows)
This repo includes a tiny built-in test runner at `res://Tests/run_tests.gd`.

From PowerShell, run (replace the path to your Godot executable as needed):

```powershell
& "C:\Path\To\Godot_v4.x-stable_win64.exe" --headless --quit --script "res://Tests/run_tests.gd"
```

### Build/export on Windows (optional)
- In Godot: **Project → Export…**
- Add a **Windows Desktop** preset and export

For command-line export you can use:

```powershell
& "C:\Path\To\Godot_v4.x-stable_win64.exe" --headless --quit --export-release "Windows Desktop" ".\build\3d-print-battles.exe"
```

### Steam (PC) — shipping checklist (high level)
- Register as a Steamworks partner and pay the **Steam Direct** fee for the app.
- Export a **release** Windows build; upload to a **depot** with SteamCMD / Steamworks tools.
- Optional: integrate **Steamworks** (overlay, achievements, cloud saves) via a Godot addon or GDExtension — plan this before relying on Steam-only APIs in gameplay code.

### Android — dev setup (high level)
- Install **Godot Android export templates** matching your editor version (**Editor → Manage Export Templates**).
- Install **Android SDK** / command-line tools (Godot docs: Android export prerequisites).
- Create an **Android** export preset; set package name, version, min SDK, and **release keystore** for Play uploads.
- Google Play uses **AAB** for new listings; use **internal testing** before production.

Touch: the project enables **emulate touch from mouse** so you can sanity-check tap UI on desktop.

### Linux note (Ubuntu 24.04 AppImage)
If you use the Godot **AppImage** and it won’t run, install the FUSE compatibility package:

```bash
sudo apt update
sudo apt install -y libfuse2t64
```


