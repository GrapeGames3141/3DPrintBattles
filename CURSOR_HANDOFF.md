# PrintForge Legends — Master Development Handoff
# The Complete Guide for Cursor to Build This Game

## HOW TO USE THIS DOCUMENT

This file is the single source of truth for building PrintForge Legends.
It is written so that Cursor can read it and know exactly what to do,
in what order, and when to stop and ask you (the developer) to do something
that requires a human — like setting up accounts or reviewing art.

Cursor should:
- Work through phases in strict order (Phase 0 → 1 → 2 → 3 → 4)
- Complete every checklist item before moving to the next
- STOP and display a "⏸ ACTION NEEDED" block whenever human input is required
- NEVER skip a phase or assume a previous step is done

You (the developer) should:
- Follow each "⏸ ACTION NEEDED" prompt when it appears
- Confirm completion so Cursor can continue
- Do nothing else — Cursor handles everything between prompts

---

## ▶ CURRENT BUILD STATUS
_Last updated by Cursor. This section is the live progress log — keep it current._

**Active phase: Phase 4 — Steam Launch**

Phase 0 (environment) — partial:
- [x] `.gitignore` and `.github/workflows/build.yml` present
- [x] Node.js installed (v20)
- [x] Godot 4.7 installed and project runs
- [x] git repo on branch `phase1-build` at `git@github.com:PatGuettler/3DPrintBattles.git`
- [x] PixelLab MCP connected in Cursor (HTTP — pixellab enabled)
- [ ] Other API keys (AutoSprite, Scenario, ElevenLabs) — later phases

Phase 1 (core loop, placeholder art) — **complete**:
- [x] All core scenes + PrintYard + global theme
- [x] Godot 4.7 parse-error fixes (`:=` → `=`)
- [x] SceneTransition null-scene crash fix
- [x] UI polish pass (UIStyle.gd, starter cards, workshop hub)
- [x] Playable through starter selection (user tested)

Phase 2 (starter art) — **complete**:
- [x] All art from existing PixelLab library (6 characters + 9 dragon objects)
- [x] Wired into all scenes
- [x] Hit animations for starters (+ aliased hits for other creatures)

Phase 3 — **complete**:
- [x] All 14 creature idle sprites mapped in `data/pixellab_sprite_map.json`
- [x] `tools/sync_all_sprites.py` — re-download all art from CDN
- [x] Gear Locker, Settings, Academy (5 quests), Print Yard
- [x] Equipment blueprint scroll cards in Shop (procedural)
- [x] Trainer Select team picker uses real sprites + checkbox fix
- [x] Placeholder audio (13 WAV files) + AudioManager autoload

Phase 4 — in progress:
- [x] Steam achievement hooks wired (`SaveManager`, `BattleManager` → `SteamManager`)
- [x] `assets/steam/ACHIEVEMENTS.md` — Steamworks API name reference
- [x] `assets/steam/STORE_PAGE.md` — store copy draft
- [x] `steam_appid.txt.example` — template for local Steam testing
- [x] CI updated to Godot 4.7
- [x] **Gameplay hardening pass** — battle loop, gear, summon UI, combat fixes
- [ ] Scene music + gameplay SFX (explicit scene hooks added; verify in editor)
- [ ] Replace placeholder WAV with ElevenLabs audio (optional)
- [ ] Steam developer account + GodotSteam + `steam_appid.txt` (human setup)
- [ ] Store page art (`assets/steam/` screenshots)
- [ ] Final QA pass

Notes / decisions made by Cursor:
- The theme is applied globally via `project.godot` (`gui/theme/custom`) instead of
  per-scene, which is more robust and equivalent in effect.
- Battle.tscn follows the `@onready` node paths inside `Battle.gd` (the script is the
  real contract), which differ slightly from the tree sketched later in this doc.
- Forgedex lightning filter binds element `"lightning"` (the value in GameData), not "light".
- Blueprint scroll art uses procedural UIStyle cards until Scenario API key is set.
- **All 15 creatures** use existing PixelLab art: 6 characters + 9 dragon objects (see `data/pixellab_sprite_map.json`). No upgrade required.
- Dragon review batch (13 frames) split into 6 objects; 3 pre-existing dragons used for the other uncommons/rares.
- Hit animations aliased from nearest starter (cinderpaw/aquafin/voltwig) for creatures without own anims.
- Audio: Settings → Test Sound works; all scenes now call `AudioManager.play_for_scene()` in `_ready()`.
- **Gameplay hardening (2025-06):** Starter grants 3 prints; dynamic team size; equipment instance ID fix; bench summon buttons; stun/charge/card fixes.
- Steam achievements log to console when GodotSteam is not installed (dev-safe).

---

## PHASE 0 — ENVIRONMENT SETUP
### Complete this before writing a single line of game code.

---

### STEP 0.1 — Install Required Software

⏸ ACTION NEEDED — Cursor: Display this message first

```
==========================================================
PRINTFORGE LEGENDS — ENVIRONMENT SETUP
==========================================================
Before I can build anything, I need you to install 3 tools.
This is the only time you will need to do manual installs.
Please complete each step and confirm when done.

STEP 1 OF 3 — Install Godot 4
1. Go to: https://godotengine.org/download
2. Download "Godot Engine — .NET" version 4.x for your OS
   (Windows: .exe installer / Mac: .dmg / Linux: .x86_64)
3. Run the installer / drag to Applications
4. Open Godot once to confirm it launches — then close it
✅ Reply "godot done" when complete

STEP 2 OF 3 — Install Cursor
1. Go to: https://cursor.com
2. Click Download
3. Run the installer
4. Open Cursor and sign in with your email
5. When it asks about AI model — select Claude
✅ Reply "cursor done" when complete
(If you are already reading this inside Cursor, skip this step)

STEP 3 OF 3 — Install Node.js (required for PixelLab MCP)
1. Go to: https://nodejs.org
2. Download the LTS version (green button)
3. Run the installer with all default settings
4. Open a Terminal (Mac/Linux) or Command Prompt (Windows) and run:
   node --version
   It should print something like v20.x.x
✅ Reply "node done" when complete
==========================================================
```

---

### STEP 0.2 — Project Folder Setup

⏸ ACTION NEEDED — Cursor: Display this message

```
==========================================================
STEP 4 — Open Your Project in Cursor and Godot
==========================================================
1. Unzip the PrintForge_Phase1_Code.zip file you downloaded
2. You should see a folder called "printforge" containing:
   - project.godot
   - data/
   - scripts/
   - assets/
   - CURSOR_HANDOFF.md (this file)

3. Open Godot 4
   - Click "Import"
   - Navigate to the printforge folder
   - Select project.godot
   - Click "Import & Edit"
   - Godot will import the project — this takes ~30 seconds
   - You should see an empty editor with no errors in the Output panel

4. Open Cursor
   - File → Open Folder
   - Select the same printforge folder
   - You should see all the files in Cursor's left sidebar

✅ Reply "project open" when complete
==========================================================
```

---

### STEP 0.3 — Master Environment Variable Setup

This is the most important setup step. Environment variables let all tools
(Cursor, Godot, GitHub Actions) access your API keys securely without
ever putting them in code. Set up ALL variables now — even ones you won't
use until Phase 4 — so there are zero blockers later.

⏸ ACTION NEEDED — Cursor: Display this message

```
==========================================================
STEP 5 — ENVIRONMENT VARIABLES (Do All of These Now)
==========================================================
You need 5 API keys total. Get them in this order.
Each account is free to create. You only pay when you use credits.

--- KEY 1: PixelLab (creature sprites) ---
1. Go to: https://pixellab.ai
2. Click Sign Up — use your email, no credit card needed
3. Once logged in: click your profile icon → Settings → API
4. Click "Create API Key"
5. COPY THE KEY IMMEDIATELY — you only see it once
   It looks like: plk_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
6. Keep it somewhere safe (notes app / password manager)
✅ Got your PixelLab key? Good. Don't set it yet — do all 5 first.

--- KEY 2: AutoSprite (creature animations) ---
1. Go to: https://autosprite.io
2. Click Sign Up — free account
3. Once logged in: Account → API Keys → Create Key
4. Copy the key
✅ Got it? Continue.

--- KEY 3: Scenario (blueprint scroll art) ---
1. Go to: https://scenario.com
2. Click Get Started — free account
3. Once logged in: Settings → API → Generate Key
4. Copy the key
✅ Got it? Continue.

--- KEY 4: ElevenLabs (music + sound effects) ---
1. Go to: https://elevenlabs.io
2. Click Sign Up — free account
3. Once logged in: click your profile icon → Profile + API Key
4. Copy the API key shown on that page
✅ Got it? Continue.

--- KEY 5: GitHub Token (for saving your code safely) ---
1. Go to: https://github.com and create a free account if needed
2. Click your profile icon → Settings
3. Scroll to "Developer settings" (bottom of left sidebar)
4. Click "Personal access tokens" → "Tokens (classic)"
5. Click "Generate new token (classic)"
6. Name it: printforge-dev
7. Expiration: No expiration
8. Check these boxes: ✅ repo  ✅ workflow
9. Click "Generate token"
10. COPY IT IMMEDIATELY — starts with ghp_
✅ Got all 5 keys? Now set them as environment variables below.
==========================================================
```

⏸ ACTION NEEDED — Cursor: Detect the OS and show the correct instructions

**FOR WINDOWS USERS — Cursor show this block:**
```
==========================================================
SETTING ENVIRONMENT VARIABLES ON WINDOWS
==========================================================
1. Press Windows Key + R
2. Type: sysdm.cpl
3. Press Enter
4. Click the "Advanced" tab
5. Click "Environment Variables" button at the bottom

In the TOP section (User variables), click "New" for each one:

  Variable name: PIXELLAB_API_KEY
  Variable value: [paste your PixelLab key]
  → Click OK

  Variable name: AUTOSPRITE_API_KEY
  Variable value: [paste your AutoSprite key]
  → Click OK

  Variable name: SCENARIO_API_KEY
  Variable value: [paste your Scenario key]
  → Click OK

  Variable name: ELEVENLABS_API_KEY
  Variable value: [paste your ElevenLabs key]
  → Click OK

  Variable name: GITHUB_TOKEN
  Variable value: [paste your GitHub token]
  → Click OK

  Variable name: PRINTFORGE_ENV
  Variable value: development
  → Click OK

6. Click OK on all windows to close them
7. FULLY QUIT AND REOPEN CURSOR (not just reload)
   Right-click Cursor in taskbar → Quit, then reopen

VERIFY they worked — in Cursor's terminal panel (Ctrl+`) run:
  echo %PIXELLAB_API_KEY%
  echo %AUTOSPRITE_API_KEY%
  echo %ELEVENLABS_API_KEY%
  echo %GITHUB_TOKEN%

Each line should print your key. If any line is blank:
  → That variable isn't set. Go back and add it.

✅ Reply "env done windows" when all 6 print correctly
==========================================================
```

**FOR MAC USERS — Cursor show this block:**
```
==========================================================
SETTING ENVIRONMENT VARIABLES ON MAC
==========================================================
1. Open Terminal (press Cmd+Space, type Terminal, press Enter)
2. Run these commands one at a time.
   Replace each YOUR_KEY_HERE with your actual key.

echo 'export PIXELLAB_API_KEY="YOUR_KEY_HERE"' >> ~/.zshrc
echo 'export AUTOSPRITE_API_KEY="YOUR_KEY_HERE"' >> ~/.zshrc
echo 'export SCENARIO_API_KEY="YOUR_KEY_HERE"' >> ~/.zshrc
echo 'export ELEVENLABS_API_KEY="YOUR_KEY_HERE"' >> ~/.zshrc
echo 'export GITHUB_TOKEN="YOUR_KEY_HERE"' >> ~/.zshrc
echo 'export PRINTFORGE_ENV="development"' >> ~/.zshrc
source ~/.zshrc

3. FULLY QUIT AND REOPEN CURSOR

VERIFY in Cursor's terminal panel (Ctrl+`):
  echo $PIXELLAB_API_KEY
  echo $AUTOSPRITE_API_KEY
  echo $ELEVENLABS_API_KEY
  echo $GITHUB_TOKEN

Each should print your key. If blank → re-run the export command
for that variable and source ~/.zshrc again.

Note: If you use bash instead of zsh, replace ~/.zshrc with ~/.bashrc

✅ Reply "env done mac" when all 4 print correctly
==========================================================
```

**FOR LINUX USERS — Cursor show this block:**
```
==========================================================
SETTING ENVIRONMENT VARIABLES ON LINUX
==========================================================
1. Open Terminal
2. Run these commands (replace each YOUR_KEY_HERE):

echo 'export PIXELLAB_API_KEY="YOUR_KEY_HERE"' >> ~/.bashrc
echo 'export AUTOSPRITE_API_KEY="YOUR_KEY_HERE"' >> ~/.bashrc
echo 'export SCENARIO_API_KEY="YOUR_KEY_HERE"' >> ~/.bashrc
echo 'export ELEVENLABS_API_KEY="YOUR_KEY_HERE"' >> ~/.bashrc
echo 'export GITHUB_TOKEN="YOUR_KEY_HERE"' >> ~/.bashrc
echo 'export PRINTFORGE_ENV="development"' >> ~/.bashrc
source ~/.bashrc

3. FULLY QUIT AND REOPEN CURSOR

VERIFY in Cursor's terminal:
  echo $PIXELLAB_API_KEY
  echo $AUTOSPRITE_API_KEY
  echo $ELEVENLABS_API_KEY
  echo $GITHUB_TOKEN

✅ Reply "env done linux" when all print correctly
==========================================================
```

---

### STEP 0.4 — Connect PixelLab MCP to Cursor

⏸ ACTION NEEDED — Cursor: Display this message after env vars confirmed

```
==========================================================
STEP 6 — CONNECT PIXELLAB TO CURSOR (HTTP MCP — preferred)
==========================================================
PixelLab now uses a hosted HTTP MCP server (simpler than npx).

OPTION A — Cursor MCP Settings UI (easiest):
1. Go to https://pixellab.ai → API → copy your key
2. In Cursor: Ctrl+Shift+P → "Open MCP Settings"
3. Click "Add Custom MCP" (or edit JSON)
4. Add this block (paste YOUR key where shown):

{
  "mcpServers": {
    "pixellab": {
      "url": "https://api.pixellab.ai/mcp",
      "headers": {
        "Authorization": "Bearer YOUR_PIXELLAB_KEY_HERE"
      }
    }
  }
}

5. Save, fully quit and reopen Cursor
6. MCP settings should show a green dot next to "pixellab"

OPTION B — Project file (already gitignored):
  Copy mcp.json.example → .cursor/mcp.json in this project folder.
  Set PIXELLAB_API_KEY in ~/.bashrc and use ${PIXELLAB_API_KEY} in the Bearer header,
  OR paste your key directly into .cursor/mcp.json (never commit it).

Docs: https://api.pixellab.ai/mcp/docs

✅ Reply "mcp connected" when you see the green dot
==========================================================
```

Later phases add AutoSprite, Scenario, ElevenLabs the same way (HTTP + Bearer token).
Old npx pixellab-mcp method is deprecated — use the HTTP URL above instead.

⏸ LEGACY — full multi-tool MCP block (Phase 2+ only needs PixelLab first):
      "type": "http",
      "url": "https://www.autosprite.io/api/mcp",
      "headers": {
        "Authorization": "Bearer ${AUTOSPRITE_API_KEY}"
      }
    },
    "scenario": {
      "url": "https://api.scenario.com/mcp",
      "headers": {
        "Authorization": "Bearer ${SCENARIO_API_KEY}"
      }
    },
    "elevenlabs": {
      "url": "https://api.elevenlabs.io/mcp",
      "headers": {
        "Authorization": "Bearer ${ELEVENLABS_API_KEY}"
      }
    }
  }
}

5. Save the file
6. Restart Cursor completely
7. Go back to MCP settings — you should see green dots next to
   pixellab, autosprite, scenario, and elevenlabs
   Red dot = that tool's key isn't loading. Re-check env vars.

✅ Reply "mcp connected" when you see green dots
==========================================================
```

---

### STEP 0.5 — GitHub Repository Setup

⏸ ACTION NEEDED — Cursor: Display this after MCP confirmed, then execute the git commands automatically

```
==========================================================
STEP 7 — SET UP GITHUB (Save Your Work Safely)
==========================================================
This creates a private repository for your game code so your
work is never lost and Cursor can push changes automatically.

1. Go to: https://github.com/new
2. Repository name: printforge-legends
3. Set to: Private ✅
4. Do NOT initialize with README (we'll push existing code)
5. Click "Create repository"
6. Copy the repository URL — looks like:
   https://github.com/YOUR_USERNAME/printforge-legends.git

✅ Reply with your repository URL when created
   Example: "repo https://github.com/johndoe/printforge-legends.git"
==========================================================
```

Cursor: After the developer provides the repo URL, run these commands automatically in the terminal:

```bash
cd [project folder path]
git init
git add .
git commit -m "Initial commit — Phase 0 setup complete"
git branch -M main
git remote add origin [THE URL THE DEVELOPER PROVIDED]
git push -u origin main
```

Then create this `.gitignore` file to keep keys and local files out of GitHub:

```
# Environment and secrets — NEVER commit these
.env
*.env
.env.local
.env.*.local

# Godot auto-generated files
.godot/
*.import
*.translation

# OS files
.DS_Store
Thumbs.db
desktop.ini

# Build output
export/
builds/

# Logs
*.log
```

Then commit the gitignore:
```bash
git add .gitignore
git commit -m "Add gitignore — protect env vars and build files"
git push
```

⏸ ACTION NEEDED — Cursor: Display this after push succeeds

```
==========================================================
STEP 8 — ADD GITHUB SECRETS (for future CI/CD)
==========================================================
This stores your API keys in GitHub so automated builds
can access them without you hardcoding anything.

1. Go to your repository on GitHub
2. Click Settings → Secrets and variables → Actions
3. Click "New repository secret" for each one:

   Name: PIXELLAB_API_KEY
   Value: [your PixelLab key]
   → Click "Add secret"

   Name: AUTOSPRITE_API_KEY
   Value: [your AutoSprite key]
   → Click "Add secret"

   Name: SCENARIO_API_KEY
   Value: [your Scenario key]
   → Click "Add secret"

   Name: ELEVENLABS_API_KEY
   Value: [your ElevenLabs key]
   → Click "Add secret"

These secrets will be used in Phase 4 when we set up
automated Steam builds via GitHub Actions.

✅ Reply "secrets added" when all 4 are added
==========================================================
```

Cursor: After secrets confirmed, create `.github/workflows/build.yml`:

```yaml
# .github/workflows/build.yml
# Automated Godot build — runs on every push to main
# Exports a Steam-ready PC build and saves it as a build artifact

name: Build PrintForge Legends

on:
  push:
    branches: [main]
  workflow_dispatch:  # Allow manual trigger from GitHub UI

env:
  GODOT_VERSION: 4.3
  EXPORT_NAME: PrintForgeLegends
  PIXELLAB_API_KEY: ${{ secrets.PIXELLAB_API_KEY }}
  AUTOSPRITE_API_KEY: ${{ secrets.AUTOSPRITE_API_KEY }}
  SCENARIO_API_KEY: ${{ secrets.SCENARIO_API_KEY }}
  ELEVENLABS_API_KEY: ${{ secrets.ELEVENLABS_API_KEY }}

jobs:
  build-windows:
    name: Build Windows (Steam)
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Setup Godot
        uses: chickensoft-games/setup-godot@v2
        with:
          version: ${{ env.GODOT_VERSION }}
          use-dotnet: false
          include-templates: true

      - name: Create export directories
        run: mkdir -v -p builds/windows

      - name: Export Windows build
        run: |
          godot --headless --export-release "Windows Desktop" \
            builds/windows/${{ env.EXPORT_NAME }}.exe

      - name: Upload build artifact
        uses: actions/upload-artifact@v4
        with:
          name: ${{ env.EXPORT_NAME }}-Windows
          path: builds/windows/
          retention-days: 30
```

Then commit and push:
```bash
git add .github/
git commit -m "Add GitHub Actions automated build pipeline"
git push
```

⏸ ACTION NEEDED — Cursor: Display this

```
==========================================================
✅ PHASE 0 COMPLETE — ENVIRONMENT READY
==========================================================
Here is what is now set up:

✅ Godot 4 installed
✅ Cursor installed with Claude
✅ Node.js installed (for MCP tools)
✅ Project folder open in both Godot and Cursor
✅ All 5 environment variables set and verified
✅ All 4 art tools connected via MCP (green dots)
✅ GitHub repository created and code pushed
✅ GitHub Secrets added for CI/CD
✅ Automated build pipeline ready

Your work is now saved to GitHub automatically on every push.
Your API keys are never in any code file.
All art tools are ready to generate on demand.

Type "start phase 1" to begin building the game.
==========================================================
```

---

## PHASE 1 — CORE GAME LOOP (No Art Needed Yet)
### Goal: A fully playable battle from start to finish with placeholder colors.

All GDScript logic files are already written. Cursor only needs to build
the .tscn scene files and wire everything together.

Cursor: Work through these tasks autonomously. Commit to GitHub after
each scene is complete using: git commit -m "Phase 1: Add [SceneName].tscn"

---

### TASK 1.1 — Main Entry Scene

Create `scenes/Main.tscn` and `scripts/Main.gd`:
- Node2D root named Main
- Script checks `SaveManager.has_chosen_starter()`
- If false → `SceneTransition.go_to("res://scenes/StarterSelection.tscn")`
- If true → `SceneTransition.go_to("res://scenes/Workshop.tscn")`
- Set as run/main_scene in project.godot

---

### TASK 1.2 — Starter Selection Scene

Create `scenes/StarterSelection.tscn` to match `scripts/StarterSelection.gd`.

Scene tree:
```
StarterSelection (Node2D)
├── Background (ColorRect) — color #1A1A2E, full screen
├── UI (CanvasLayer)
│   ├── TitleLabel (Label) — "Choose Your First Print"
│   │   center top, font size 32, color #E8A020
│   ├── SubtitleLabel (Label) — "Your starter stays with you forever."
│   │   center, below title, font size 18, color #AAAAAA
│   ├── StarterCards (HBoxContainer)
│   │   center screen, separation 40
│   │   [Script builds cards dynamically — no children needed here]
│   ├── SelectedLabel (Label) — hidden by default
│   │   center, below cards, font size 22, color #FFFFFF
│   └── ConfirmBtn (Button) — "Begin Forging!" — hidden by default
│       center, below SelectedLabel, min size 200x60
```
Wire: ConfirmBtn.pressed → _on_confirm_btn_pressed

---

### TASK 1.3 — Workshop Hub Scene

Create `scenes/Workshop.tscn` to match `scripts/Workshop.gd`.

Scene tree:
```
Workshop (Node2D)
├── Background (ColorRect) — color #1A1A2E, full screen
├── UI (CanvasLayer)
│   ├── TopBar (HBoxContainer)
│   │   anchored: top full width, height 60, color #0D0D1A
│   │   ├── SpoolIcon (Label) — "🧵" font size 28
│   │   ├── LevelLabel (Label) — "Lv. 1" font size 22
│   │   ├── XPBar (ProgressBar) — min 0, min size 200x20
│   │   ├── CoinIcon (Label) — "🪙" font size 28
│   │   └── CoinLabel (Label) — "100" font size 22 color #E8A020
│   ├── LocationButtons (VBoxContainer)
│   │   center screen, separation 16
│   │   ├── BattleBtn (Button) — "⚔ Proving Grounds"
│   │   ├── ShopBtn (Button) — "🛒 Filament Market"
│   │   ├── AcademyBtn (Button) — "🎓 The Academy"
│   │   ├── ForgedexBtn (Button) — "📖 Forgedex"
│   │   └── PrintYardBtn (Button) — "🐾 Print Yard"
│   │   [All buttons: min size 280x55, font size 20]
│   └── DailyLoginPopup (Panel)
│       centered, size 400x200, hidden by default, color #2A1A4E
│       ├── Label — "Daily Login Bonus!" font size 24 color #E8A020
│       └── CloseBtn (Button) — "Collect!" min size 160x44
```
Wire all buttons to their _on_*_pressed methods.
Wire DailyLoginPopup CloseBtn → _on_daily_popup_close_pressed

---

### TASK 1.4 — Trainer Select Scene

Create `scenes/TrainerSelect.tscn` to match `scripts/TrainerSelect.gd`.

Scene tree:
```
TrainerSelect (Node2D)
├── Background (ColorRect) — color #1A1A2E full screen
├── UI (CanvasLayer)
│   ├── TitleLabel (Label) — "⚔ Proving Grounds" top center, size 28
│   ├── BackBtn (Button) — "← Workshop" top left, min 120x44
│   ├── TrainerList (VBoxContainer)
│   │   left half of screen, top-anchored, separation 12
│   │   [Script populates dynamically]
│   └── TeamSelectPanel (Panel)
│       right half of screen, full height, color #0D0D1A, hidden default
│       ├── TeamLabel (Label) — "Select 3 Prints for battle" size 20
│       ├── PrintList (VBoxContainer) — separation 8, scrollable
│       ├── SelectedTeamLabel (Label) — "Team: 0 / 3 selected"
│       └── FightBtn (Button) — "Enter the Forge! ⚙"
│           color #7B2FBE, min 220x55, hidden default
```
Wire: BackBtn → _on_back_btn_pressed, FightBtn → _on_fight_btn_pressed

---

### TASK 1.5 — Battle Scene (Most Complex)

Create `scenes/Battle.tscn` to match `scripts/Battle.gd`.

Scene tree:
```
Battle (Node2D)
├── Background (ColorRect) — color #0A0A1A full screen
├── UI (CanvasLayer)
│   │
│   ├── ── AI SIDE (top third of screen) ──
│   ├── AISide (VBoxContainer)
│   │   anchored: top, left 40px, right 640px, height 240px
│   │   ├── AIHeader (HBoxContainer)
│   │   │   ├── ai_name_lbl (Label) — "???" size 22 color #FF6B6B
│   │   │   └── AIForgeLabel (Label) — ai_forge_lbl "Forge: 0/10" size 18
│   │   ├── ai_hp_bar (ProgressBar) — min 0 max 100 color #E8A020
│   │   │   custom fill color: #E8A020 (amber)
│   │   ├── ai_hp_lbl (Label) — "0 / 0" size 16 color #AAAAAA
│   │   ├── ai_forge_bar (ProgressBar) — min 0 max 10 color #7B2FBE
│   │   └── AIBenchPanel (ai_bench_panel, HBoxContainer) — separation 8
│   │
│   ├── ── ARENA CENTER ──
│   ├── ArenaCenter (HBoxContainer)
│   │   anchored: center, width 800, height 300
│   │   ├── PlayerPrintArea (VBoxContainer) — left half
│   │   │   ├── player_sprite (ColorRect) — 200x200 color #444444
│   │   │   └── SummonLabel (Label) — "Waiting to summon..." size 16
│   │   └── AIPrintArea (VBoxContainer) — right half
│   │       └── ai_sprite (ColorRect) — 200x200 color #444444
│   │
│   ├── ── COIN FLIP PANEL (center popup) ──
│   ├── CoinFlipPanel (coin_flip_panel, Panel)
│   │   anchored center, size 400x200, color #2A1A4E, VISIBLE at start
│   │   ├── Label — "Flipping for first turn..." size 22 color #E8A020
│   │   └── flip_result_label (Label) — "" size 28 color #FFFFFF
│   │
│   ├── ── PLAYER SIDE (bottom third) ──
│   ├── PlayerSide (VBoxContainer)
│   │   anchored: bottom, left 40px, right 640px, height 280px
│   │   ├── PlayerHeader (HBoxContainer)
│   │   │   ├── player_name_lbl (Label) — "Your Print" size 22 color #6BFF6B
│   │   │   └── ForgeLabel (Label) — player_forge_lbl "Forge: 0/10" size 18
│   │   ├── player_hp_bar (ProgressBar) — min 0 max 100
│   │   │   custom fill: #6BFF6B (green)
│   │   ├── player_hp_lbl (Label) — "0 / 0" size 16 color #AAAAAA
│   │   ├── player_forge_bar (ProgressBar) — min 0 max 10
│   │   │   custom fill: #7B2FBE (purple)
│   │   ├── BenchPanel (bench_panel, HBoxContainer) — separation 8
│   │   ├── TurnTimer (turn_timer, ProgressBar)
│   │   │   min 0 max 15, custom fill #FF4444 (red urgency bar)
│   │   │   min size full width x 12px
│   │   ├── AbilityBtn (ability_btn, Button)
│   │   │   "Use Ability" color #7B2FBE min 200x50
│   │   ├── CardHand (card_hand, HBoxContainer) — separation 8
│   │   │   [Cards built dynamically by script]
│   │   └── EndTurnBtn (end_turn_btn, Button)
│   │       "End Turn →" color #E8A020 min 160x50
│   │
│   ├── ── BATTLE LOG (right side) ──
│   ├── BattleLog (battle_log, RichTextLabel)
│   │   anchored: right side, full height, width 360px
│   │   background color #050510, scroll active, bbcode enabled
│   │   font size 16, color #CCCCCC
│   │
│   └── ── RESULT PANEL (center popup, hidden) ──
│       ResultPanel (result_panel, Panel)
│       anchored center, size 500x300, color #1A0A2E, HIDDEN at start
│       ├── result_label (Label) — "" size 36 center color #E8A020
│       ├── rewards_label (Label) — "" size 20 center color #FFFFFF
│       └── ContinueBtn (Button) — "Return to Workshop"
│           min 220x55 color #7B2FBE
```

Wire:
- ability_btn.pressed → _on_ability_btn_pressed
- end_turn_btn.pressed → _on_end_turn_btn_pressed
- ContinueBtn.pressed → _on_continue_btn_pressed

Script is attached to Battle (Node2D) root. The receive_data() method
is called by SceneTransition after the scene loads.

---

### TASK 1.6 — Shop Scene

Create `scenes/Shop.tscn` to match `scripts/Shop.gd`.

Scene tree:
```
Shop (Node2D)
├── Background (ColorRect) — #1A1A2E full screen
├── UI (CanvasLayer)
│   ├── TopBar (HBoxContainer) — top full width height 60 bg #0D0D1A
│   │   ├── TitleLabel (Label) — "🛒 Filament Market" size 24
│   │   ├── CoinLabel (Label) — coin_label "🪙 100" size 22 color #E8A020
│   │   │   size_flags_horizontal: EXPAND_FILL
│   │   └── BackBtn (Button) — "← Workshop" min 120x44
│   ├── TabBar (HBoxContainer) — below TopBar, separation 0
│   │   ├── CreaturesTab (Button) — "🐾 Creatures" min 200x44
│   │   └── EquipmentTab (Button) — "⚙ Equipment" min 200x44
│   ├── RefreshLabel (Label) — refresh_label
│   │   "Shop refreshes in: 23h 59m" size 16 color #888888, below tabs
│   ├── ShopGrid (GridContainer) — shop_grid
│   │   columns 4, below refresh label, fills most of screen
│   │   [Cards built dynamically by script]
│   └── ItemDetailPanel (Panel) — detail_panel
│       right side overlay, width 320px full height, bg #0D0D1A, HIDDEN
│       ├── DetailSprite (ColorRect) — detail_sprite 120x120
│       ├── DetailName (Label) — detail_name size 22 color #FFFFFF
│       ├── DetailRarity (Label) — detail_rarity size 18
│       ├── DetailStats (Label) — detail_stats size 16 color #CCCCCC
│       ├── DetailLore (Label) — detail_lore size 14 color #888888
│       │   autowrap on
│       ├── BlueprintCostLabel (Label) — blueprint_cost_lbl size 18
│       ├── PrintCostLabel (Label) — print_cost_lbl size 16 color #AAAAAA
│       ├── OwnedLabel (Label) — owned_label "✓ Blueprint Owned"
│       │   size 18 color #22CC22, HIDDEN
│       ├── BuyBlueprintBtn (Button) — buy_blueprint_btn
│       │   "Buy Blueprint" color #7B2FBE min 200x50
│       └── PrintBtn (Button) — print_btn
│           "⚙ Print It!" color #E8A020 min 200x50, HIDDEN
```

Wire:
- BackBtn → _on_back_btn_pressed
- CreaturesTab → _on_creatures_tab_pressed
- EquipmentTab → _on_equipment_tab_pressed
- BuyBlueprintBtn → _on_buy_blueprint_btn_pressed
- PrintBtn → _on_print_btn_pressed

---

### TASK 1.7 — Academy Scene

Create `scenes/Academy.tscn` to match `scripts/Academy.gd`.

Scene tree:
```
Academy (Node2D)
├── Background (ColorRect) — #1A1A2E full screen
├── UI (CanvasLayer)
│   ├── TopBar (HBoxContainer) — top full width height 60 bg #0D0D1A
│   │   ├── TitleLabel (Label) — "🎓 The Academy" size 24
│   │   ├── CoinLabel (coin_label) — "🪙 100" size 22 color #E8A020
│   │   └── BackBtn (Button) — "← Workshop" min 120x44
│   ├── QuestMenu (VBoxContainer) — quest_menu
│   │   center screen, separation 20, VISIBLE at start
│   │   [Built dynamically by script]
│   └── QuestPanel (Panel) — quest_panel
│       full screen overlay, bg #0D0D1A, HIDDEN at start
│       ├── QuestTitle (quest_title, Label) — size 28 color #E8A020 center
│       ├── GizmoLabel (gizmo_label, Label)
│       │   "Gizmo says: Ready!" size 18 color #7B2FBE center
│       ├── QuestionLabel (question_label, Label)
│       │   size 24 color #FFFFFF center, min height 80px
│       ├── TimerBar (timer_bar, ProgressBar)
│       │   min 0 max 30, fill color #FF4444, full width
│       ├── AnswerGrid (answer_grid, GridContainer)
│       │   columns 2, separation 16, center screen
│       │   [Built dynamically by script]
│       ├── FeedbackLabel (feedback_label, Label)
│       │   size 20 center, min height 40px
│       ├── ScoreLabel (score_label, Label)
│       │   "Score: 0 / 0" size 18 color #AAAAAA center
│       └── ExitQuestBtn (Button)
│           "Quit Quest" color #444444 min 140x40 top-right of panel
```

Wire:
- BackBtn → _on_back_btn_pressed
- ExitQuestBtn → _on_exit_quest_btn_pressed

---

### TASK 1.8 — Forgedex Scene

Create `scenes/Forgedex.tscn` to match `scripts/Forgedex.gd`.

Scene tree:
```
Forgedex (Node2D)
├── Background (ColorRect) — #1A1A2E full screen
├── UI (CanvasLayer)
│   ├── TopBar (HBoxContainer) — top full width height 60 bg #0D0D1A
│   │   ├── TitleLabel (Label) — "📖 Forgedex" size 24
│   │   ├── CountLabel (count_label) — "Discovered: 0 of ???"
│   │   │   size 18 color #888888, EXPAND_FILL
│   │   └── BackBtn (Button) — "← Workshop" min 120x44
│   ├── FilterBar (HBoxContainer) — below TopBar, separation 8
│   │   Add one Button per element + "All":
│   │   AllBtn "All", FireBtn "🔥", WaterBtn "💧", LightBtn "⚡",
│   │   NatureBtn "🌿", IceBtn "❄", StoneBtn "🪨", WindBtn "🌬", ArcaneBtn "✨"
│   │   [All min 80x36, small font size 16]
│   ├── EntryGrid (entry_grid, GridContainer)
│   │   columns 6, fills screen below filter bar
│   │   [Built dynamically by script]
│   └── DetailPanel (detail_panel, Panel)
│       right-side overlay, width 300px full height, bg #0D0D1A, HIDDEN
│       ├── DetailSprite (detail_sprite, ColorRect) — 120x120
│       ├── DetailName (detail_name, Label) — size 22 color #FFFFFF
│       ├── DetailElement (detail_element, Label) — size 16
│       ├── DetailRarity (detail_rarity, Label) — size 16
│       ├── DetailBend (detail_bend, Label) — size 16 color #CCCCCC
│       ├── DetailAbility (detail_ability, Label) — size 14 color #AAAAAA
│       │   autowrap on
│       └── DetailLore (detail_lore, Label) — size 13 color #888888
│           autowrap on
```

Wire:
- BackBtn → _on_back_btn_pressed
- AllBtn.pressed → _on_filter_pressed.bind("all")
- FireBtn.pressed → _on_filter_pressed.bind("fire")
- [etc. for each element]

---

### TASK 1.9 — Apply Global Theme

Create `assets/ui/PrintForgeTheme.tres` — a Godot Theme resource:

```
Colors:
  Background dark:   #1A1A2E
  Background darker: #0D0D1A
  Accent purple:     #7B2FBE
  Accent amber:      #E8A020
  Text white:        #FFFFFF
  Text muted:        #AAAAAA
  Success green:     #22CC22
  Danger red:        #FF4444

Button (Normal):    bg #7B2FBE, text #FFFFFF, border none, corner radius 6
Button (Hover):     bg #9B4FDE, text #FFFFFF
Button (Pressed):   bg #5B1F9E, text #FFFFFF
Button (Disabled):  bg #333355, text #666666

Panel:              bg #0D0D1A, border 1px #7B2FBE22
ProgressBar:        bg #1A1A3E, fill #7B2FBE (override per bar in scene)
Label:              font color #FFFFFF, font size 18
```

Apply this theme to the root node of every scene.

---

### TASK 1.10 — Phase 1 Test & Commit

Cursor: Run through this test checklist and fix any issues found:

```
TEST CHECKLIST — Phase 1

□ Game launches without errors (F5 in Godot)
□ Starter selection appears on first run
□ All 3 starter cards display with colored placeholders
□ Choosing a starter and clicking Confirm reaches Workshop
□ Workshop shows correct coin/XP values
□ All 5 navigation buttons work (reach their scenes)
□ Trainer Select shows all 5 trainers
□ Selecting 3 prints enables the Fight button
□ Battle scene loads with coin flip animation
□ Both sides show colored rectangles for prints
□ HP bars and forge bars update during battle
□ Turn timer counts down
□ End Turn button triggers AI response
□ Ability button triggers ability
□ Cards appear in hand and can be played
□ Win/Loss screen appears when battle ends
□ Return to Workshop button works
□ Shop shows items in grid
□ Academy shows quest menu
□ Forgedex shows discovered creatures
□ Save data persists after closing and reopening the game
```

After all tests pass:
```bash
git add .
git commit -m "Phase 1 complete — full game loop playable with placeholder art"
git push
```

⏸ ACTION NEEDED — Cursor: Display this

```
==========================================================
✅ PHASE 1 COMPLETE
==========================================================
The core game loop is fully playable.

What works right now:
✅ Starter selection
✅ Workshop hub navigation
✅ Trainer select + team picker
✅ Full battle system with AI opponent
✅ Forge bar, filament cards, abilities
✅ Win/loss flow with XP and coin rewards
✅ Shop (placeholder art)
✅ Academy math quests
✅ Forgedex discovery log
✅ Local save file — progress persists

Everything uses placeholder colored rectangles for art.
The game is fully functional — it just doesn't look pretty yet.

BEFORE STARTING PHASE 2:
Play at least 3 full battles. Note anything that feels wrong:
  - Is the turn timer too fast or too slow?
  - Do the coins/XP rewards feel satisfying?
  - Does the AI feel too easy or too hard?

Tell me what to adjust, then type "start phase 2" to begin art.
==========================================================
```

---

## PHASE 2 — ART GENERATION (Starters + Shop)
### Goal: Replace all placeholder colors with real sprites for the 3 starters.

⏸ ACTION NEEDED — Cursor: Check PixelLab credits before starting

```
==========================================================
PHASE 2 — ART GENERATION STARTING
==========================================================
I'm about to use your PixelLab free credits to generate
the 3 starter creature sprites.

Free tier gives you 20–40 generations.
We need approximately 9 generations for the 3 starters
(3 idle sprites + 3 attack + 3 hit animations via AutoSprite).

This is within your free tier limit.

⚠️  I will NOT generate all 15 creatures yet.
    That requires the $9/month plan.
    I will tell you when to upgrade.

Type "generate starters" to begin.
==========================================================
```

Cursor: After confirmation, use PixelLab MCP to generate in this order:

**Batch 1 — Idle sprites (3 credits)**
Generate and save to `assets/sprites/`:
- `cinderpaw_idle.png` — "small fox with flame-tipped tails, 3D printed PLA plastic figurine, visible layer lines, orange and red fire colors, chibi proportions, idle standing pose, transparent background, pixel art style, 128x128"
- `aquafin_idle.png` — "dolphin-shark hybrid with wave-ridged fins, 3D printed PLA figurine, visible layer lines, blue and teal water colors, chibi proportions, idle standing pose, transparent background, pixel art, 128x128"
- `voltwig_idle.png` — "hedgehog-bird hybrid with spiky quill wings and coiled tail, 3D printed PLA figurine, visible layer lines, yellow and white lightning colors, chibi proportions, idle pose, transparent background, pixel art, 128x128"

**Batch 2 — Blueprint scroll art via Scenario (3 credits)**
Generate:
- `assets/ui/blueprint_scroll_template.png` — "holographic magical scroll, glowing arcane rune border, dark workshop background, amber and purple glow, fantasy tech aesthetic, game UI card art, 256x384"
- `assets/ui/blueprint_cinderpaw.png` — same style, cinderpaw silhouette in center
- `assets/ui/blueprint_aquafin.png` — same style, aquafin silhouette
- `assets/ui/blueprint_voltwig.png` — same style, voltwig silhouette

**Batch 3 — Animations via AutoSprite (3 credits)**
For each starter, generate hit animation sheet:
- `assets/sprites/cinderpaw_hit.png`
- `assets/sprites/aquafin_hit.png`
- `assets/sprites/voltwig_hit.png`

After all generated, replace ColorRect nodes in StarterSelection.tscn
and Battle.tscn with TextureRect nodes loading the new sprites.

Then commit:
```bash
git add assets/
git commit -m "Phase 2: Add starter creature sprites and blueprint art"
git push
```

⏸ ACTION NEEDED — Cursor: Display after art generation

```
==========================================================
STARTER ART GENERATED — REVIEW NEEDED
==========================================================
I've generated sprites for all 3 starters and saved them to
assets/sprites/ and assets/ui/.

Please review the art now:
1. Open the printforge/assets/sprites/ folder
2. Look at each PNG:
   - cinderpaw_idle.png
   - aquafin_idle.png
   - voltwig_idle.png

If any look wrong (bad style, wrong colors, ugly):
  Tell me which one and describe what's wrong.
  I'll regenerate it with an adjusted prompt.
  Note: each regeneration uses 1 free credit.

If they all look good:
  Type "art approved" and I'll wire them into the game.
==========================================================
```

---

## PHASE 3 — CONTENT EXPANSION
### Goal: All 15 creatures, all equipment, all academy quests, Print Yard.

⏸ ACTION NEEDED — Cursor: Display at Phase 3 start

```
==========================================================
PHASE 3 — UPGRADING PIXELLAB FOR FULL CONTENT
==========================================================
Generating all 15 creatures + equipment needs approximately
50–60 PixelLab generations — more than the free tier allows.

Please upgrade to the $9/month PixelLab plan:
1. Go to: https://pixellab.ai/pricing
2. Select the $9/month plan
3. Enter your payment details
4. You can cancel after we finish generating all art
   (usually takes 1–2 months of casual use)

✅ Reply "pixellab upgraded" when done
==========================================================
```

Cursor tasks after upgrade confirmed:

**3.1** — Generate idle sprites for all 12 remaining creatures using
GameData.gd lore and placeholder_color as style guide. Save to assets/sprites/.

**3.2** — Generate AutoSprite animation frames (hit, attack) for all 12.

**3.3** — Generate Scenario blueprint scroll art for all 12 creatures
and all 13 equipment items.

**3.4** — Create `scenes/PrintYard.tscn` + `scripts/PrintYard.gd`:
- Shows all owned prints wandering a small diorama area
- Prints use idle sprites and a slow random-walk behavior
- Tapping a print shows its stats in a popup panel
- Back button returns to Workshop

**3.5** — Create Gear Locker scene for equipping armor/weapons/accessories
to specific prints.

**3.6** — Implement all 5 Academy quest difficulty levels.

**3.7** — Wire all real sprites into every scene (replace remaining ColorRects).

Then commit:
```bash
git add .
git commit -m "Phase 3 complete — full content, all 15 creatures, Print Yard"
git push
```

---

## PHASE 4 — STEAM LAUNCH
### Goal: A shippable Steam build with audio and achievements.

---

### TASK 4.1 — Audio Generation

⏸ ACTION NEEDED — Cursor: Display at Phase 4 start

```
==========================================================
PHASE 4 — AUDIO SETUP
==========================================================
I'll use ElevenLabs to generate all game audio.
Your ELEVENLABS_API_KEY is already set.

ElevenLabs uses commercially licensed training data,
which means you can sell this game on Steam safely.
Do NOT use Suno or Udio — their licenses have legal risk
for commercial Steam releases.

Generating audio now... (this may take 2–3 minutes)
==========================================================
```

Cursor: Use ElevenLabs MCP to generate and save to `assets/audio/`:
- `music_workshop.ogg` — "warm ambient workshop music, gentle mechanical sounds, magical tones, cozy whimsical, slow tempo, game hub screen, no vocals, loops cleanly, 2 minutes"
- `music_battle.ogg` — "intense battle music for a card game, arcane electronic beats, urgent driving rhythm, no vocals, loops cleanly, 90 seconds"
- `music_academy.ogg` — "cheerful educational music, playful and encouraging, warm tones, suitable for children's learning, loops cleanly, 2 minutes"
- `sfx_summon.ogg` — "3D printer whirring then magical pop, satisfying completion sound, 2 seconds"
- `sfx_hit.ogg` — "plastic wobble impact, hard plastic being struck, punchy, 0.5 seconds"
- `sfx_victory.ogg` — "triumphant magical fanfare, sparkle and bells, 4 seconds"
- `sfx_defeat.ogg` — "mechanical breakdown sound, sad printer noise, 3 seconds"
- `sfx_coin.ogg` — "bright magical coin chime, short positive sound, 0.8 seconds"
- `sfx_levelup.ogg` — "ascending magical chime, spool growing sound, satisfying, 2 seconds"

Then create `scripts/AudioManager.gd` autoload to handle all audio.

---

### TASK 4.2 — Steam Setup

⏸ ACTION NEEDED — Cursor: Display this

```
==========================================================
STEAM DEVELOPER SETUP REQUIRED
==========================================================
Publishing to Steam requires a one-time $100 registration fee
and a Steamworks developer account.

STEP 1 — Register as a Steam developer
1. Go to: https://partner.steamgames.com
2. Click "Join Steamworks"
3. Sign in with your Steam account (create one if needed)
4. Pay the $100 app deposit fee
   (This fee is returned to you once your game earns $1,000)
5. Fill out your company/individual info
6. Wait for approval email (usually same day to 48 hours)

STEP 2 — Create your app
1. Once approved, go to Steamworks dashboard
2. Click "Create New App"
3. Select "Game"
4. Name: PrintForge Legends
5. Note your App ID (a 7-digit number)

STEP 3 — Download GodotSteam
1. Go to: https://godotsteam.com
2. Download the version matching Godot 4.x
3. Extract — you'll see a modified godot editor executable
4. Use THIS editor for all future work on the project
   (replace your regular Godot with this one)

STEP 4 — Create steam_appid.txt
In your project root folder, create a file named: steam_appid.txt
Contents: just your App ID number, nothing else. Example: 2847391

✅ Reply "steam setup done [YOUR APP ID]" when complete
   Example: "steam setup done 2847391"
==========================================================
```

Cursor: After App ID received, automatically:
- Create `steam_appid.txt` with the App ID
- Add GodotSteam autoload to project.godot
- Create `scripts/SteamManager.gd` with achievement definitions
- Update GitHub Actions build.yml with the App ID
- Add Steam achievements: first_win, first_rare, forgedex_complete, battles_100

---

### TASK 4.3 — Store Page Assets

⏸ ACTION NEEDED — Cursor: Generate store page copy, then prompt for art

Cursor: Write the Steam store page content automatically:

**Short description (30 words):**
"Collect magical 3D-printed creatures, battle AI trainers, and grow your Forge in this unique creature collector with educational mini-games built right in."

**Long description:** [Cursor generates 300-word description from GDD]

**Tags to use:** Card Game, Creature Collector, Turn-Based, Family Friendly, Singleplayer, 2D, Colorful, Casual, Strategy, Educational

Then display:

```
==========================================================
STEAM STORE ART NEEDED
==========================================================
Steam requires these images for your store page.
Use Midjourney to generate them at midjourney.com
(you can do this manually in 15 minutes)

1. CAPSULE IMAGE (460x215px) — Main store card
   Prompt: "PrintForge Legends game logo art, magical 3D printer
   with glowing creatures emerging, workshop aesthetic, warm amber
   and neon purple lighting, game key art style --ar 2:1"

2. HERO IMAGE (1920x620px) — Top of store page
   Prompt: "wide cinematic game banner, magical workshop with floating
   3D printed creatures, forge machines with arcane energy, dramatic
   lighting, PrintForge Legends title space on left --ar 3:1"

3. SCREENSHOTS (1280x720px) — Take 5 in-game screenshots:
   - Starter selection screen
   - Workshop hub
   - Battle in progress (mid-fight)
   - Shop with items
   - Forgedex partially filled

Save all images to: assets/steam/
✅ Reply "store art done" when complete
==========================================================
```

---

### TASK 4.4 — Final QA Pass

Cursor: Run through complete QA checklist and fix every issue found:

```
FINAL QA CHECKLIST

SAVE SYSTEM
□ New game starts at Workshop/StarterSelection correctly
□ Progress saves after every battle
□ Shop refresh timer persists after closing game
□ Academy daily limits reset at midnight
□ Equipment equip/unequip saves correctly

BATTLE SYSTEM
□ All 14 abilities resolve correctly
□ Elemental type chart gives correct multipliers
□ Forge bar fills +1 per turn automatically
□ Filament cards work (all 5 types)
□ 15-second timer auto-ends turn when expired
□ AI uses ability when appropriate
□ Battle drop gives blueprint when won
□ Win/loss rewards applied correctly to save

ECONOMY
□ Blueprints persist after purchase (can re-print anytime)
□ Shop rotation refreshes every 24 hours
□ Academy diminishing returns after 3 plays
□ Daily login bonus fires once per day
□ Coins can never go below 0

AUDIO
□ Workshop music plays on Workshop scene
□ Battle music plays in battle, stops on return
□ All SFX trigger at correct moments
□ Audio doesn't stack when scene reloads

PERFORMANCE
□ Game runs at stable 60fps in battle
□ No memory leaks after 10 battles in a row
□ Load time under 3 seconds

STEAM
□ GodotSteam initializes without errors
□ Achievements trigger correctly
□ Build exports without errors
□ Exported .exe launches outside Godot editor
```

After QA passes:
```bash
git add .
git commit -m "Phase 4: QA pass complete — ready for Steam submission"
git push
```

---

### TASK 4.5 — Steam Submission

⏸ ACTION NEEDED — Cursor: Display final submission guide

```
==========================================================
READY FOR STEAM SUBMISSION
==========================================================
The game is complete. Here is how to submit it to Steam.

STEP 1 — Export the final build
In Godot (GodotSteam version):
1. Project → Export
2. Select "Windows Desktop"
3. Export path: builds/windows/PrintForgeLegends.exe
4. Click "Export Project" (NOT "Export PCK/Zip")

STEP 2 — Upload to Steam
1. Go to: https://partner.steamgames.com
2. Select your app → SteamPipe → Builds
3. Download SteamCmd from the page
4. Follow Valve's upload guide with your build folder

STEP 3 — Fill out store page
1. Steamworks → Store Page → Edit Store Page
2. Paste the short and long descriptions I generated
3. Upload all images from assets/steam/
4. Set tags (list is in TASK 4.3 above)
5. Set price: $9.99 USD

STEP 4 — Set rating
1. Steamworks → Store Page → Content Survey
2. Answer questions — PrintForge should be rated "E for Everyone"
   (cartoon violence — plastic shattering only)

STEP 5 — Submit for review
1. Steamworks → Review and Publish
2. Click "Submit for Review"
3. Valve reviews within 3–5 business days
4. You will get an email when approved

STEP 6 — Set release date
Once approved, set your launch date in Steamworks.
You can create a "Coming Soon" page immediately after approval
to start collecting wishlists before launch.

🎉 That's it. PrintForge Legends ships on Steam.
==========================================================
```

---

## PHASE 5 — POST-LAUNCH (Future Updates)

These are NOT built at launch. Add them after the game is stable on Steam.

```
MULTIPLAYER UPDATE
□ Set up Supabase backend (see GDD Section 19)
□ Migrate local save to cloud accounts (via Steam ID)
□ Online PvP matchmaking
□ Trade Hall with preset offer templates
□ ELO rating and leaderboards

MOBILE UPDATE
□ Godot Android export template
□ Touch input handling (replace mouse clicks)
□ iOS export template and Apple Developer account ($99/year)
□ App Store and Google Play submissions

CONTENT UPDATE 1
□ 15 additional creatures (Mythic and Prismatic tiers)
□ Seasonal shop event system
□ New Academy quest types

IN-APP PURCHASES
□ Steam Microtransaction API
□ Coin pack products (already stubbed in GameData.gd)
□ Cosmetic forge room skins
```

---

## QUICK REFERENCE

| Thing | Value |
|-------|-------|
| Starting coins | 100 |
| Daily login bonus | 10 coins |
| Battle win reward | 25 coins + 50 XP |
| Battle loss reward | 5 coins + 15 XP |
| Turn timer | 15 seconds |
| Forge bar max | 10 units |
| Auto-fill per turn | +1 unit |
| Team size | 3 prints |
| Prints on field at once | 1 per side |
| Base damage formula | ceil(bend_score ÷ 4) |
| Base HP formula | bend_score × 3 |
| Super effective | 1.5× damage |
| Not very effective | 0.6× damage |
| Battle drop chance | 15% base (scales with difficulty) |
| Shop refresh | Every 24 hours (local timer) |
| Shop slots | 12 |
| Quest questions | 10 per quest |
| Time per question | 30 seconds |
| 3-star threshold | 90% correct |
| 2-star threshold | 70% correct |
| 1-star threshold | 50% correct |

## ENVIRONMENT VARIABLES REFERENCE

| Variable | Tool | Phase Needed |
|----------|------|-------------|
| PIXELLAB_API_KEY | PixelLab sprites | Phase 2 |
| AUTOSPRITE_API_KEY | Creature animations | Phase 2 |
| SCENARIO_API_KEY | Blueprint scroll art | Phase 2 |
| ELEVENLABS_API_KEY | Music + SFX | Phase 4 |
| GITHUB_TOKEN | Code backup | Phase 0 |
| PRINTFORGE_ENV | Build flag | Phase 0 |

## FILES BUILT BY CLAUDE (Already In This ZIP)

| File | Purpose |
|------|---------|
| project.godot | Godot config + autoloads |
| data/GameData.gd | All 15 creatures, abilities, equipment, trainers |
| scripts/SaveManager.gd | Local save/load system |
| scripts/BattleManager.gd | Complete battle engine |
| scripts/SceneTransition.gd | Fade transitions |
| scripts/Workshop.gd | Hub scene logic |
| scripts/StarterSelection.gd | Starter pick logic |
| scripts/TrainerSelect.gd | Trainer + team picker |
| scripts/Battle.gd | Battle UI + signal wiring |
| scripts/Shop.gd | Shop browse/buy logic |
| scripts/Academy.gd | Math quest engine |
| scripts/Forgedex.gd | Discovery log |

## FILES CURSOR BUILDS

| File | Phase |
|------|-------|
| scripts/Main.gd + scenes/Main.tscn | Phase 1 |
| scenes/StarterSelection.tscn | Phase 1 |
| scenes/Workshop.tscn | Phase 1 |
| scenes/TrainerSelect.tscn | Phase 1 |
| scenes/Battle.tscn | Phase 1 |
| scenes/Shop.tscn | Phase 1 |
| scenes/Academy.tscn | Phase 1 |
| scenes/Forgedex.tscn | Phase 1 |
| assets/ui/PrintForgeTheme.tres | Phase 1 |
| assets/sprites/*.png (3 starters) | Phase 2 |
| assets/ui/blueprint_*.png | Phase 2 |
| scripts/PrintYard.gd + scene | Phase 3 |
| assets/sprites/*.png (12 remaining) | Phase 3 |
| scripts/AudioManager.gd | Phase 4 |
| assets/audio/*.ogg | Phase 4 |
| scripts/SteamManager.gd | Phase 4 |
| steam_appid.txt | Phase 4 |
| .github/workflows/build.yml | Phase 0 |
