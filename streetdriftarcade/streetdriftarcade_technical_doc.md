# Street Drift Arcade - Technical Documentation
## Complete Project Reference Guide

### **Project Overview**
Street Drift Arcade is a sophisticated drift scoring system for Assetto Corsa, built with a clean modular Lua architecture. The app provides real-time drift detection, scoring, personal records tracking, and anti-farming systems with a **beautiful full-screen overlay UI** that distributes elements across the entire screen with scalable text sizing.

---

## **File Structure & Architecture**

```
assettocorsa/apps/lua/streetdriftarcade/
├── manifest.ini                    # AC app configuration (full-screen overlay)
├── streetdriftarcade.lua           # CLEAN main coordinator (lightweight ~150 lines)
└── modules/
    ├── variables.lua               # Central variable storage
    ├── utilities.lua               # Helper functions & utilities
    ├── detection.lua               # Physics detection systems + LIVE ANGLE BONUSES
    ├── scoring.lua                 # Scoring calculations (NO MULTIPLIERS)
    ├── anti_farming.lua            # Anti-farming intelligence (CLEAN DEBUG)
    ├── records.lua                 # Personal best tracking & I/O (NO RANKING)
    └── display.lua                 # FULL-SCREEN rendering system with scaling
```

---

## **CURRENT STATUS: Clean Modular Architecture (v2.0)**

### **Major Systems Removed:**
❌ **Ranking System** - Completely eliminated (Bronze/Silver/Gold progression)  
❌ **Multiplier/Combo System** - No more drift multipliers or combo building  
❌ **Debug Spam** - Clean console output, essential messages only  

### **Major Systems Added:**
✅ **Live Angle Bonus System** - Instant rewards when hitting 2.5s thresholds  
✅ **Rebalanced Duration Bonus** - More reasonable progression (4x at 5s)  
✅ **Refined Angle Ranges** - Higher skill requirements (30°+ minimum)  

### **Philosophy: Pure Skill Focus**
> **"Instant feedback for demonstrated skill, no artificial progression mechanics"**

---

## **Full-Screen Overlay System**

### **Main File Responsibility (streetdriftarcade.lua)**
```lua
function script.windowMain(dt)
    -- Minimal coordination only:
    -- 1. Load personal bests on first run
    -- 2. Detect screen size
    -- 3. Create invisible full-screen capture
    -- 4. Call display module to render everything
    display.render_fullscreen_overlay(screen_width, screen_height)
end
```

### **Display Module Responsibility (display.lua)**
- **All visual rendering** for full-screen overlay
- **Text scaling system** for easy size adjustments
- **Element positioning** across screen sections
- **Visual effects** (animations, colors, shadows)
- **Fixed white colors** (no ranking-based color changes)

### **Current Manifest Settings (manifest.ini)**
```ini
[WINDOW_0]
SIZE = 4000, 3000           # Oversized for full coverage
POS = 0, 0                  # Top-left positioning
FLAGS = NO_TITLE_BAR, NO_RESIZE, NO_MOVE, NO_COLLAPSE, 
        NO_BACKGROUND, NO_SCROLLBAR, NO_BORDER, 
        NO_INPUTS, NO_MOUSE_INPUTS, NO_SCROLL_WITH_MOUSE
```

---

## **Text Scaling System**

### **Current Scaling Configuration**
Located in `display.lua` `ui_config` table:

```lua
notification_size = 80          -- Critical messages (reduced from 120)
total_points_*_size = 70        -- Main score display (ALWAYS WHITE)
drift_*_size = 34              -- Current drift points
status_*_size = 40             -- Car telemetry
records_*_size = 22-28         -- Historical data
angle_bonus_size = 36          -- Live angle bonuses
```

### **Visual Hierarchy (by font size)**
1. **Notifications:** 80px (critical messages)
2. **Total Points:** 70px (main score display - always white)
3. **Status Info:** 40px (speed, angle, drift state)
4. **Angle Bonuses:** 36px (live rewards)
5. **Drift Counter:** 34px (current drift points)
6. **Records:** 22-28px (historical data)

---

## **Live Angle Bonus System - GAME CHANGER!**

### **Revolutionary Real-Time Rewards:**
- **Old System**: Wait for drift end → get bonus
- **New System**: Hit 2.5s threshold → **INSTANT BONUS!**

### **Refined Angle Ranges (No Reward for <30°):**
- **🚫 Under 30°**: No tracking, no rewards - mundane driving
- **👍 30-45°**: Good Drift - 1,000 points after 2.5s
- **✨ 45-60°**: Great Drift - 5,000 points after 2.5s  
- **🔥 60°+**: Angle Master - 25,000 points after 2.5s

### **Smart Implementation:**
✅ **Instant feedback** - Rewards awarded immediately when threshold reached  
✅ **No double-dipping** - Bonus flags prevent multiple awards per segment  
✅ **Segment reset** - Fresh opportunities on direction changes  
✅ **Enhanced notifications** - Shows bonus amount: "🔥 ANGLE MASTER! +25,000"  

### **Key Functions (detection.lua):**
- `check_live_angle_bonuses()` - Monitors thresholds every frame
- `award_live_angle_bonus()` - Instantly applies bonus and notification
- `reset_live_bonus_flags()` - Resets flags for new segments

---

## **Scoring System (Simplified)**

### **NO MORE MULTIPLIERS - Pure Points System:**
- **Direction changes**: Seamless drift continuation (no multiplier boost)
- **Drift end**: Raw points banked directly to total
- **Records**: "Best Run" now same as raw drift points

### **Rebalanced Duration Bonus:**
- **New formula**: `1.0 + (time^2 / 6.25)`
- **Progression**: 1s=1.16x, 2s=1.64x, 3s=2.44x, 5s=4.0x, 8s=11.24x
- **Resets**: Every direction change for fresh progression

### **Core Scoring Elements:**
- **Base calculation**: `base_rate × angle × speed × time × angle_multiplier`
- **Duration bonus**: Exponential growth per segment
- **Sweet spot bonuses**: 37-43° perfect zone = 3x multiplier
- **Angle compensation**: 2x boost for angles below 40°
- **Live angle bonuses**: Instant rewards for sustained angles

### **Faster Gameplay:**
- **Drift end delay**: Reduced from 2.5s to 1.5s for quicker flow
- **Responsive transitions**: Less waiting, more action

---

## **Anti-Farming System (Clean Debug)**

### **Intelligent Detection (No Spam):**
- **Rotation analysis**: Detects repetitive patterns
- **Position tracking**: Monitors forward progress
- **False positive prevention**: Distinguishes legitimate track drifting
- **Clean logging**: Only logs "🚨 FARMING DETECTED!" and "✅ Farming ended"

### **Debug Output Eliminated:**
❌ No more spam about rotation variance, progress analysis, confidence levels  
✅ Essential notifications only: farming start/stop  

---

## **Personal Records System (No Ranking)**

### **Three Pure Record Types:**
1. **🎯 Pure Skill**: Single segment, no multiplier - ultimate skill measure
2. **🏁 Best Run**: Best single drift (now same as raw points)
3. **📈 Best Session**: Highest total points in one session

### **Live Tracking:**
- **Pure Skill**: Real-time color coding when breaking records
- **Visual feedback**: Pulsing animations for record breaking
- **File I/O**: Automatic save/load from `drift_records.json`

### **What's Gone:**
❌ No ranking progression (Bronze/Silver/Gold)  
❌ No milestone notifications  
❌ No ranking-based color changes  

---

## **Module Dependencies & Architecture**

### **Clean Dependency Chain:**
- **Level 0**: `variables.lua` (no dependencies)
- **Level 1**: `utilities.lua` (depends on variables)
- **Level 2**: Core modules (depend on variables + utilities)
- **Level 3**: `display.lua` (depends on utilities, scoring, records, etc.)
- **Level 4**: `streetdriftarcade.lua` (coordinates ALL modules)

### **Updated Module Responsibilities:**

#### **streetdriftarcade.lua (Main Coordinator)**
- **Purpose**: Lightweight coordination and screen management
- **Size**: ~150 lines (kept minimal)
- **Key Changes**: Removed milestone checking
- **Dependencies**: ALL modules
- **Rule**: Only coordinates, never renders directly

#### **detection.lua (Physics + Live Bonuses)**
- **Purpose**: ALL detection systems + LIVE angle bonus awards
- **Key Features**: Real-time angle bonus system, crash detection, anti-exploit
- **New**: `check_live_angle_bonuses()`, `award_live_angle_bonus()`
- **Removed**: Old end-of-drift angle bonus system

#### **scoring.lua (Simplified Scoring)**
- **Purpose**: Point calculations without multipliers
- **Key Changes**: Removed high score frame spam, rebalanced duration bonus
- **Removed**: All multiplier logic, debug spam
- **Formula**: `1.0 + (time^2 / 6.25)` for duration bonus

#### **display.lua (Clean Visual System)**
- **Purpose**: ALL visual rendering with fixed colors
- **Key Changes**: Total points always white, no ranking colors
- **Preserved**: All text scaling, animations, record breaking effects

#### **anti_farming.lua (Clean Detection)**
- **Purpose**: Smart farming detection without spam
- **Key Changes**: Removed detailed debug logging
- **Output**: Only "🚨 FARMING DETECTED!" and "✅ Farming ended"

#### **variables.lua (Updated Ranges)**
- **Purpose**: Central variable storage
- **Key Changes**: New angle ranges, faster drift end (1.5s)
- **Removed**: Ranking-related variables, multiplier variables

#### **utilities.lua (No Ranking)**
- **Purpose**: Helper functions and utilities
- **Key Changes**: Simplified color system, removed milestone checking
- **Removed**: All ranking/milestone logic

---

## **Screen Detection & Positioning**

### **Screen Size Detection (Unchanged)**
```lua
-- Priority order:
1. AC sim.windowWidth/Height (most reliable)
2. ui.windowWidth/Height with scaling
3. Fallback to 2560x1440 (1440p default)
```

### **Element Positioning System**
```lua
-- Absolute positioning based on detected screen size:
- top_left: vec2(50, 50)           # Total Points + Live Drift Info
- top_center: vec2(screen_width / 2 - 300, 70)  # Notifications + Live Bonuses
- bottom_left: vec2(50, screen_height - 250)    # Personal Records
- bottom_right: vec2(screen_width - 350, screen_height - 200)  # Status
```

---

## **Development Workflow**

### **Current System Status:**
🎯 **Pure skill focus** - No artificial progression  
⚡ **Live feedback** - Instant angle bonus rewards  
🧹 **Clean output** - No debug spam  
🎨 **Consistent visuals** - White text, no ranking colors  
⚡ **Responsive gameplay** - 1.5s drift end, live bonuses  

### **Making Changes:**

#### **Visual Changes (Most Common)**
1. **Text Size**: Modify `ui_config` in `display.lua`
2. **New Elements**: Add render functions in `display.lua`
3. **Layout Changes**: Adjust positioning in `display.lua`
4. **Keep main file untouched**

#### **Scoring Changes**
1. **Duration bonus**: Modify formula in `scoring.lua`
2. **Angle bonuses**: Modify thresholds in `detection.lua`
3. **Base scoring**: Modify calculations in `scoring.lua`

#### **Live Bonus Changes**
1. **Thresholds**: Modify `check_live_angle_bonuses()` in `detection.lua`
2. **Bonus amounts**: Modify `award_live_angle_bonus()` in `detection.lua`
3. **Angle ranges**: Update `variables.lua` angle range definitions

### **Testing & Debugging**
```lua
-- Debug commands (unchanged):
force_4k()          -- Test 4K resolution
force_1440p()       -- Test 1440p resolution
force_1080p()       -- Test 1080p resolution

-- New display debugging:
display.get_ui_config()  -- Show current scaling
```

---

## **Current Configuration Values**

### **Angle Bonus System**
```lua
-- Duration requirement: 2.5 seconds minimum
-- Ranges and rewards:
["30-45"] = 1000 points    -- Good Drift
["45-60"] = 5000 points    -- Great Drift
["60+"] = 25000 points     -- Angle Master
```

### **Timing Configuration**
```lua
drift_end_delay = 1.5         -- Faster drift end detection
farming_detection_delay = 5.0 -- Anti-farming sensitivity
pb_animation_duration = 3.0   -- Record breaking animation
```

### **Scoring Configuration**
```lua
base_drift_rate = 0.8                    -- Base scoring multiplier
drift_threshold = 8.0                    -- Minimum angle to start drift
min_speed = 10                           -- Minimum speed (km/h)
-- Duration bonus: 1.0 + (time^2 / 6.25) -- 4x at 5 seconds
```

### **Current Font Sizes (Optimized)**
```lua
notification_size = 80       # Critical messages
total_points_*_size = 70     # Main score (always white)
drift_*_size = 34           # Current drift
status_*_size = 40          # Car telemetry
records_*_size = 22-28      # Historical data
angle_bonus_size = 36       # Live bonuses
```

---

## **Troubleshooting & Common Issues**

### **Live Angle Bonus Issues**
- **Problem**: Bonuses not triggering
- **Solution**: Check 2.5s duration requirement and angle thresholds
- **Debug**: Monitor angle tracking debug output

### **Window Focus Issues**
- **Problem**: Window stealing focus or scrolling
- **Solution**: Use `NO_SCROLL_WITH_MOUSE` flag in manifest
- **Reset**: Restart app to reset window position if accidentally moved

### **Text Scaling Issues**
- **Problem**: Font sizes not changing
- **Solution**: Check `ui_config` values in `display.lua`
- **Debug**: Use `display.get_ui_config()` to verify

### **Clean Console Output**
- **Expected**: Only essential messages (farming start/stop, live bonuses)
- **Problem**: Too much debug spam
- **Solution**: Verify anti-farming and scoring modules have spam removed

---

## **Future Development Areas**

### **Immediate Opportunities**
1. **Progressive Visual Feedback** - Live progress bars for angle ranges
2. **Chain Bonus System** - Multiple angle bonuses creating multipliers
3. **Advanced HUD Elements** - G-force meters, tire temperature simulation
4. **Session Analytics** - Drift maps, performance graphs

### **Potential Features**
1. **Dynamic Challenges** - Target zones, time trials
2. **Car-Specific Logic** - Different physics per car type
3. **Track Integration** - Automatic track detection
4. **Advanced Visual Effects** - Screen effects, particle systems

### **System Improvements**
1. **Performance Optimization** - Better frame rate management
2. **Enhanced Notifications** - More sophisticated visual feedback
3. **Customization Options** - User-configurable layouts
4. **Analytics Dashboard** - Session summaries and statistics

---

## **Architecture Success Metrics**

### **✅ Achieved Goals:**
- **Clean Architecture**: Lightweight main file (~150 lines)
- **Live Feedback**: Instant angle bonus system implemented
- **Skill Focus**: Eliminated artificial progression mechanics
- **Clean Output**: Removed debug spam completely
- **Responsive UI**: 1.5s drift end, instant rewards
- **Pure Scoring**: No multipliers, direct point banking

### **✅ Maintainability:**
- **Modular Design**: Logic and visuals completely separated
- **Easy Scaling**: One config table controls all text sizes
- **Future-Proof**: Clean structure for new feature expansion
- **Development Efficiency**: Parallel development possible

---

## **Key Achievements**

### **Game-Changing Features:**
🎉 **Live Angle Bonus System** - Revolutionary instant feedback  
🧹 **Clean Debug Output** - Essential messages only  
🎯 **Pure Skill Focus** - No artificial progression  
⚡ **Responsive Gameplay** - Faster transitions, live rewards  

### **Technical Excellence:**
✅ **Modular Architecture** - Clean separation of concerns  
✅ **Scalable UI System** - Easy text size management  
✅ **Multi-Resolution Support** - Works on all screen sizes  
✅ **Smart Anti-Farming** - Intelligent detection without spam  

---

*This document serves as the complete technical reference for Street Drift Arcade's **Live Angle Bonus System** and **Clean Modular Architecture**. The system now provides instant feedback for demonstrated skill while maintaining clean, maintainable code. Share this in new development sessions to maintain context and continue efficient development.*