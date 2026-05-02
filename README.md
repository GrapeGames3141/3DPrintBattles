## 3D Print Battles (Godot 4)

Kid-safe collectible creature battler inspired by 3D printing + STEM.

**Current focus:** development and playtesting are **Windows-only** for now (Godot editor + run from `Main.tscn`). Android / Steam / Linux notes below stay as **future** shipping reference, not what we validate every change against.

**Roadmap:** Phases 1–5 are documented under `Docs/plan-phase-1.md`–`plan-phase-5.md`. The game includes a **256-id roster pool** (JSON + synthetic fill), **24h shop rotation**, **Terrarium / Archive / Quests**, and **Overworld / Trade** stubs; deeper shaders, export passes, and Steam/Android are still future work (see `DEVELOPMENT_PLAN.md`).

### Run on Windows (recommended for dev)
- Install **Godot 4.3+** (matches `project.godot` → `config/features`; standard `.exe` build is easiest on Windows)
- Launch Godot and **Import** this folder (it contains `project.godot`)
- Press **Play** (main scene: `Main.tscn`)

Saves use **`user://Saves/`** (Godot maps this under your Windows user app-data). The MVP uses a **single profile** file, **`profile.json`**, plus **`local_settings.json`** for title-screen audio preferences. If you had an old dev build, legacy **`slot_1.json`** is **migrated once** to `profile.json` on first launch and then removed.

If the editor reports **Could not resolve script** / preload errors on the title screen, ensure `res://UI/TitleScreen.tscn` and `res://UI/TitleScreen.gd` exist (the game loads the title from the `.tscn`). Also use **Godot 4.3+** per `project.godot` → `config/features`; scripts use **untyped** `signal` args for compatibility across patch releases.

**Unrecognized UID** on a `.tscn`: open the scene once and save (Godot rewrites UIDs), or remove the `uid="..."` attribute from the scene header if it was copied from another machine. **`Could not create child process`** with a path like `...\Godot_....exe\Godot_....exe`: **Editor → Editor Settings** → search **exec** / **custom** and fix or clear any **custom Godot / run executable** so it is a **single** path to `Godot_*_win64.exe` (not a folder with the same name as the exe). Prefer launching the editor from a stable install folder (e.g. `C:\Godot\`) instead of nested Downloads paths.

### Headless unit tests (Windows)
Tests live in `res://Tests/unit_tests.gd` ([member UnitTests.run_all]) and run through **`res://Tests/TestRunner.tscn`** so autoloads (`SaveSystem`, `GameState`, …) exist (running `--script` alone skips normal project boot and breaks those globals). **Add or extend a test for every new gameplay rule or balance knob**, then run:

```powershell
Set-Location "D:\dev\3DPrintBattles"   # or your clone path
& "C:\Godot\Godot_v4.6.2-stable_win64_console.exe" --path "D:\dev\3DPrintBattles" --headless --quit-after 120 "res://Tests/TestRunner.tscn"
```

Use the `*_console.exe` build on Windows for readable output. Adjust the Godot folder if yours differs.

### Build/export on Windows (optional)
- In Godot: **Project → Export…**
- Add a **Windows Desktop** preset and export

For command-line export you can use:

```powershell
& "C:\Path\To\Godot_v4.x-stable_win64.exe" --headless --quit --export-release "Windows Desktop" ".\build\3d-print-battles.exe"
```

### Steam (PC) — shipping checklist (high level, not in daily Windows test loop yet)
- Register as a Steamworks partner and pay the **Steam Direct** fee for the app.
- Export a **release** Windows build; upload to a **depot** with SteamCMD / Steamworks tools.
- Optional: integrate **Steamworks** (overlay, achievements, cloud saves) via a Godot addon or GDExtension — plan this before relying on Steam-only APIs in gameplay code.

### Android — dev setup (high level, future)
- Install **Godot Android export templates** matching your editor version (**Editor → Manage Export Templates**).
- Install **Android SDK** / command-line tools (Godot docs: Android export prerequisites).
- Create an **Android** export preset; set package name, version, min SDK, and **release keystore** for Play uploads.
- Google Play uses **AAB** for new listings; use **internal testing** before production.

Touch: the project enables **emulate touch from mouse** so you can sanity-check tap UI on desktop.

### Linux note (Ubuntu 24.04 AppImage, optional / future)
If you use the Godot **AppImage** and it won’t run, install the FUSE compatibility package:

```bash
sudo apt update
sudo apt install -y libfuse2t64
```


