# Veo/Sora Import - Quick Start Guide

## ✅ IMPLEMENTATION COMPLETE!

The Veo/Sora Import feature has been fully integrated into your FilmManager app at the CORRECT location:
**`/Users/ingthor/Documents/stories/App/App/FilmManager/`**

---

## 📁 Files Created

### Core Implementation (6 files):
1. **VeoImportManager.swift** - Main coordinator for import workflow
2. **DownloadMonitor.swift** - Monitors Downloads folder for new Veo/Sora files
3. **PromptParser.swift** - Extracts ACTION, SCENE, DIALOGUE, STYLE from clipboard
4. **ShotMatcher.swift** - Fuzzy matches prompts to shots
5. **NotificationManager.swift** - macOS system notifications
6. **GlobalKeyboardMonitor.swift** - Global backtick (`) key monitoring

### Configuration (2 files):
7. **FilmManager.entitlements** - Downloads folder + sandbox permissions
8. **Info.plist** - Accessibility & notification permission descriptions

### Integration:
- **DataModels.swift** - Added veoImportManager and keyboard monitor to FilmManager class
- **PromptGenerationPanel.swift** - Added "Activate Veo/Sora Import" to Actions menu
- **project.pbxproj** - Configured entitlements and Info.plist references

---

## 🚀 How to Use

### 1. Build & Run
```bash
# Open in Xcode
open /Users/ingthor/Documents/stories/App/App/FilmManager.xcodeproj

# Build (Cmd+B) then Run (Cmd+R)
```

### 2. Grant Permissions (First Run Only)
**Accessibility Permission:**
- System Settings → Privacy & Security → Accessibility
- Add "FilmManager" and toggle ON
- (Required for global `` ` `` key monitoring)

**Notification Permission:**
- Click "Allow" when prompted

### 3. Activate Import Mode
Click **Actions** → **Activate Veo/Sora Import** (bottom of screen, next to Save All button)

### 4. Import Workflow
1. Download 2-4 videos from Veo/Sora (they'll have `.download` extension initially)
2. Copy the prompt to clipboard in Veo/Sora UI
3. Press **`` ` ``** (backtick key, left of `1`)
4. Wait for macOS notification: "✅ Imported 3 videos to Shot #8"
5. Videos appear in Media Management panel
6. Repeat for next batch

### 5. Deactivate
Click **Actions** → **Stop Veo/Sora Import**

---

## 🎯 Supported File Patterns

**Veo Files:**
- Pattern: `Subject_in_the_202510202228_mpoah.mp4`
- Regex: `[A-Za-z_]+\d{12}_[a-z0-9]+\.mp4`

**Sora Files:**
- Pattern: `20251019_1723_01k6f16xrsfnwts6dkfs9pcdsq.mp4`
- Regex: `\d{8}_\d{4}_[a-z0-9]+\.mp4`

---

## 🔍 How Shot Matching Works

**Search Priority:**
1. ACTION (50% weight) - Most unique identifier
2. SCENE (30% weight)
3. STYLE (20% weight)
4. DIALOGUE (10% bonus if both have it)

**Note:** SUBJECT is NOT used for matching (contains reference plates which vary)

**Match Threshold:** 30% similarity for ACTION, or 20% ACTION + 25% SCENE combined

**On No Match:** Shows notification with all search attempts and similarity scores for manual diagnosis

---

## ⚙️ Technical Details

**Download Handling:**
- Detects `.download` in-progress files
- Polls every 0.5s until `.download` extension removed
- Timeout: 3 minutes per file
- Only imports files downloaded BEFORE pressing `` ` ``

**Batch Separation:**
```
[Download 3 videos] → [Press `] → Import those 3
[Download 2 videos] → [Press `] → Import those 2
```

**Auto-Save:**
- Videos automatically added to shot.videos array
- shot.isDirty flag set
- FilmFileManager.saveShot() called
- Standard auto-save persists changes

---

## 🐛 Troubleshooting

**Problem:** Backtick key not working
- Check Accessibility permissions granted
- Verify "Activate Veo/Sora Import" is enabled (check Actions menu)
- Restart app after granting permissions

**Problem:** "No matching shot found"
- Check notification for search attempts and similarity scores
- Verify clipboard contains full prompt with ACTION: and SCENE: sections
- Prompt must be from Veo/Sora (includes all sections)

**Problem:** Videos not detected
- Verify filenames match Veo/Sora patterns (see above)
- Ensure Import Mode is activated
- Check Downloads folder is `/Users/[you]/Downloads/`

**Problem:** Downloads timeout
- Check internet connection
- Large files may take >30 seconds
- Default timeout is 3 minutes

---

## 📊 Console Logging

All operations log to Console.app. Search for "FilmManager" to see:
- ✅ Mode activated/deactivated
- 📥 File detection
- ⏳ Download completion waiting
- 🔍 Shot matching with similarity scores
- 📹 Video import
- 💾 Auto-save

---

## 🎬 That's It!

The feature is ready to use. Just:
1. Build & run
2. Grant permissions
3. Activate mode
4. Download → Copy → Press `` ` ``

**Enjoy streamlined Veo/Sora importing!** 🚀
