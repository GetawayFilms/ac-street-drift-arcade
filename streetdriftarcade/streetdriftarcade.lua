-- Version 2 test
-- streetdriftarcade.lua - UPDATED with proportional scaling integration
-- Save as: assettocorsa/apps/lua/streetdriftarcade/streetdriftarcade.lua

local vars = require('variables')
local utilities = require('modules/utilities')
local detection = require('modules/detection')
local scoring = require('modules/scoring')
local anti_farming = require('modules/anti_farming')
local records = require('modules/records')
local display = require('modules/display')  -- Now handles ALL visual rendering with scaling

-- Full-screen overlay variables
local screen_width = 1920  -- Default, will be detected
local screen_height = 1080 -- Default, will be detected
local overlay_initialized = false

-- =============================================================================
-- SCREEN DETECTION WITH SCALING
-- =============================================================================

local function detect_screen_size()
    -- Try to get screen dimensions from AC
    local sim = ac.getSim()
    if sim and sim.windowWidth and sim.windowHeight then
        screen_width = sim.windowWidth
        screen_height = sim.windowHeight
        ac.log(string.format("🖥️ AC Sim detected: %dx%d", screen_width, screen_height))
        return true
    end
    
    -- Try window size but scale up more aggressively
    local window_width = ui.windowWidth()
    local window_height = ui.windowHeight()
    
    if window_width and window_height then
        -- If window is large, assume it's close to screen size
        if window_width > 2500 then
            screen_width = window_width
            screen_height = window_height
        else
            -- Scale up based on common ratios
            screen_width = math.max(window_width * 2, 1920)
            screen_height = math.max(window_height * 2, 1080)
        end
        ac.log(string.format("🖥️ Window scaled: %dx%d -> %dx%d", window_width, window_height, screen_width, screen_height))
        return true
    end
    
    -- Fallback to larger common resolutions
    screen_width = 2560  -- Default to 1440p instead of 1080p
    screen_height = 1440
    ac.log("🖥️ Using fallback 1440p resolution")
    return false
end

-- =============================================================================
-- MAIN WINDOW - CLEAN AND LIGHTWEIGHT WITH SCALING!
-- =============================================================================

function script.windowMain(dt)
    -- Load personal bests on first run
    if not vars.loaded_once then
        records.load_personal_bests()
        vars.loaded_once = true
    end
    
    -- Initialize overlay with scaling
    if not overlay_initialized then
        detect_screen_size()
        
        -- CRUCIAL: Initialize the scaling system in display module
        display.set_screen_dimensions(screen_width, screen_height)
        
        overlay_initialized = true
        local scale_info = display.get_scaling_info()
        ac.log(string.format("🖥️ Screen: %dx%d, Scale: %.2fx", screen_width, screen_height, scale_info.scale_factor))
        ac.log(string.format("📏 Scaled sizes - Notifications: %dpx, Total: %dpx, Records: %dpx", 
               scale_info.notification_size, scale_info.total_points_size, scale_info.records_size))
    end
    
    -- Create invisible full-screen button to capture the entire window area
    ui.invisibleButton("fullscreen_lock", vec2(3840, 2160))
    
    -- ALL VISUAL RENDERING IS NOW HANDLED BY DISPLAY MODULE WITH PROPORTIONAL SCALING!
    display.render_fullscreen_overlay(screen_width, screen_height)
end

-- =============================================================================
-- MAIN UPDATE (unchanged)
-- =============================================================================

function script.update(dt)
    -- Update animation timers
    display.update_animations(dt)
    
    -- Update pulse and notification timers
    utilities.update_timers(dt)
    
    local car = ac.getCar(0)
    if not car then return end
    
    -- Get basic car data
    local speed = utilities.get_safe_speed(car)
    
    -- Update all detection systems
    detection.update_crash_detection(dt, speed)
    detection.update_rollback_detection(dt, car, speed)
    
    -- Get car physics data
    local car_data = detection.get_car_data(car, speed)
    
    -- Update pit detection
    detection.update_pit_detection(car, speed)
    
    -- Update reverse entry and spinout detection
    detection.update_reverse_entry_detection(dt, car_data.angle, speed)
    
    -- Main drift logic
    local actively_drifting = detection.check_active_drifting(car_data, speed)
    
    if actively_drifting then
        -- Handle drift start or direction changes
        detection.handle_drift_start_or_change(car_data, speed)
        
        -- Update drift progression
        detection.update_drift_progression(dt)
        
        -- Enhanced anti-farming with false positive prevention
        anti_farming.update_anti_farming(car_data.angular_velocity, car.position, speed, dt)
        
        -- Calculate and apply points
        scoring.calculate_and_apply_points(dt, car_data.angle, speed)
        
    else
        -- Handle drift end
        detection.handle_drift_end(dt)
    end
end

-- =============================================================================
-- SETTINGS - WITH ENHANCED SCALING INFO
-- =============================================================================

function script.windowSettings(dt)
    ui.text("🎮 Street Drift Arcade - Proportional Scaling System")
    ui.separator()
    ui.text("Total Points: " .. utilities.format_number(vars.total_banked_points))
    ui.text("Actively Drifting: " .. tostring(vars.actively_drifting or false))
    
    -- Enhanced scaling information
    local scale_info = display.get_scaling_info()
    ui.text(string.format("Screen: %dx%d", screen_width, screen_height))
    ui.text(string.format("Scale Factor: %.2fx", scale_info.scale_factor))
    ui.text(string.format("Reference: %s", scale_info.reference_resolution))
    ui.separator()
    
    -- Display current scaled UI configuration
    ui.text("🎨 Scaled Display Configuration:")
    ui.text(string.format("Notification Size: %dpx", scale_info.notification_size))
    ui.text(string.format("Total Points Size: %dpx", scale_info.total_points_size))
    ui.text(string.format("Records Size: %dpx", scale_info.records_size))
    
    if ui.button("Re-detect Screen Size & Rescale") then
        overlay_initialized = false
        ac.log("🔄 Forcing screen re-detection and rescaling...")
    end
    
    if ui.button("Test Notification") then
        utilities.set_notification("🔥 EPIC DRIFT! 🔥")
    end
    
    if ui.button("Show Scaling Debug") then
        local scale_factor = display.get_scale_factor()
        ac.log(string.format("🎨 Current scale factor: %.2fx", scale_factor))
        ac.log(string.format("📏 Screen: %dx%d", screen_width, screen_height))
        ac.log(string.format("🎯 Notification size: %dpx", scale_info.notification_size))
    end
    
    ui.separator()
    ui.text("🎯 Position Controls:")
    
    if ui.button("Test Notification Centering") then
        utilities.set_notification("🔥 CENTERING TEST! 🔥")
    end
    
    if ui.button("Move Notifications Up") then
        display.set_notification_y_position(50)
    end
    
    if ui.button("Move Notifications Down") then
        display.set_notification_y_position(100)
    end
    
    if ui.button("Reset Position") then
        display.set_notification_y_position(70)
        display.set_notification_center_offset(0)
    end
    
    if ui.button("Show Position Info") then
        local pos_info = display.get_position_info()
        ac.log("=== POSITION INFO ===")
        ac.log(string.format("Y: %d, Offset: %d", pos_info.notification_y_position, pos_info.notification_center_offset))
    end
end

-- =============================================================================
-- DEBUG COMMANDS - ENHANCED WITH SCALING AND POSITIONING
-- =============================================================================

function force_4k()
    screen_width = 3840
    screen_height = 2160
    overlay_initialized = false
    ac.log("🔧 FORCED 4K RESOLUTION - will rescale UI")
end

function force_1440p()
    screen_width = 2560
    screen_height = 1440
    overlay_initialized = false
    ac.log("🔧 FORCED 1440P RESOLUTION - will rescale UI")
end

function force_1080p()
    screen_width = 1920
    screen_height = 1080
    overlay_initialized = false
    ac.log("🔧 FORCED 1080P RESOLUTION - will rescale UI")
end

function test_scaling()
    local scale_info = display.get_scaling_info()
    ac.log("=== SCALING TEST ===")
    ac.log(string.format("Screen: %dx%d", screen_width, screen_height))
    ac.log(string.format("Scale Factor: %.2fx", scale_info.scale_factor))
    ac.log(string.format("Notification: %dpx", scale_info.notification_size))
    ac.log(string.format("Total Points: %dpx", scale_info.total_points_size))
    ac.log(string.format("Records: %dpx", scale_info.records_size))
end

-- =============================================================================
-- POSITION ADJUSTMENT DEBUG COMMANDS
-- =============================================================================

function move_notifications_up()
    display.set_notification_y_position(50)  -- Move up from default 70
    ac.log("🔧 Notifications moved UP (Y=50)")
end

function move_notifications_down()
    display.set_notification_y_position(100)  -- Move down from default 70
    ac.log("🔧 Notifications moved DOWN (Y=100)")
end

function move_notifications_left()
    display.set_notification_center_offset(-50)  -- Move left from center
    ac.log("🔧 Notifications moved LEFT (offset=-50)")
end

function move_notifications_right()
    display.set_notification_center_offset(50)  -- Move right from center
    ac.log("🔧 Notifications moved RIGHT (offset=+50)")
end

function reset_notification_position()
    display.set_notification_y_position(70)   -- Default Y
    display.set_notification_center_offset(0) -- Default center
    ac.log("🔧 Notifications reset to DEFAULT position")
end

function test_notification_centering()
    utilities.set_notification("🔥 CENTERING TEST! 🔥")
    ac.log("🎯 Testing notification centering - should be perfectly centered")
end

function show_position_info()
    local pos_info = display.get_position_info()
    ac.log("=== NOTIFICATION POSITION INFO ===")
    ac.log(string.format("Y Position: %d", pos_info.notification_y_position))
    ac.log(string.format("Center Offset: %d", pos_info.notification_center_offset))
    ac.log(string.format("Y Spacing: %d", pos_info.notification_y_spacing))
end

-- =============================================================================
-- INITIALIZATION - ENHANCED WITH SCALING
-- =============================================================================

function script.init()
    ac.log("🔥🎮 STREET DRIFT ARCADE - PERFECT CENTERING VERSION! 🎮🔥")
    ac.log("✨ All visual rendering with automatic scaling & perfect centering")
    ac.log("🏗️ Main file with lightweight architecture")
    ac.log("🎨 UI scales from 4K down to 1080p automatically")
    ac.log("📏 Perfect text sizes & centering on any screen resolution")
    ac.log("🎯 Notifications perfectly centered without point values")
    ac.log("🚫 Ranking system completely removed")
    ac.log("")
    
    vars.initialize()
    utilities.initialize()
    detection.initialize()
    scoring.initialize()
    anti_farming.initialize()
    records.initialize()
    display.initialize()  -- Now initializes the proportional scaling system
    
    ac.log("🚀 ALL SYSTEMS INITIALIZED - PERFECT CENTERING & SCALING READY!")
end
