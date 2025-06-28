-- modules/resolution.lua - CSP-Compatible Resolution Detection with "Cheat" Method
-- Save as: assettocorsa/apps/lua/streetdriftarcade/modules/resolution.lua


-- =============================================================================
-- ENHANCED DETECTION VARIABLES
-- =============================================================================

detected_width = 1920
detected_height = 1080
detection_locked = false          -- Lock detection once stable
detection_confidence = 0          -- Confidence score (0-100)
detection_method = "unknown"      -- Which method succeeded
detection_attempts = 0            -- How many attempts made
last_detection_time = 0
detection_history = {}            -- Track detection results over time

-- Base resolution for scaling calculations
base_width = 1920
base_height = 1080

-- Target resolutions with scaling presets
target_resolutions = {
    {width = 3840, height = 2160, name = "4K", scale = 2.0},
    {width = 2560, height = 1440, name = "1440p", scale = 1.5},
    {width = 1920, height = 1080, name = "1080p", scale = 1.0}
}

-- Current scaling factors
ui_scale = 1.0
font_scale = 1.0
position_scale = 1.0

-- Cheat method variables
cheat_window = nil
cheat_attempt_count = 0
cheat_max_attempts = 3

-- =============================================================================
-- "CHEAT" METHOD - TEMPORARY FULLSCREEN WINDOW MEASUREMENT
-- =============================================================================

function detect_cheat_fullscreen_window()
    local results = {}
    
    cheat_attempt_count = cheat_attempt_count + 1
    ac.log(string.format("🎯 CHEAT METHOD ATTEMPT #%d: Creating temporary fullscreen window...", cheat_attempt_count))
    
    -- Save debug info to file so we can read it
    local debug_info = {}
    table.insert(debug_info, string.format("CHEAT METHOD ATTEMPT #%d", cheat_attempt_count))
    table.insert(debug_info, "Time: " .. os.date("%H:%M:%S"))
    
    -- Method 1: Try creating a window with massive size and see what we actually get
    local success, error_msg = pcall(function()
        ac.log("  🔧 Attempting massive window creation...")
        table.insert(debug_info, "Attempting massive window creation...")
        
        table.insert(debug_info, "About to call ui.beginWindow...")
        
        local test_window = ui.beginWindow("__resolution_test_" .. cheat_attempt_count, {
            size = vec2(9999, 9999),  -- Request impossibly large size
            padding = vec2(0, 0),
            position = vec2(0, 0),
            flags = bit.bor(
                ui.WindowFlags.NoTitleBar,
                ui.WindowFlags.NoResize,
                ui.WindowFlags.NoMove,
                ui.WindowFlags.NoScrollbar,
                ui.WindowFlags.NoCollapse,
                ui.WindowFlags.NoBackground,
                ui.WindowFlags.NoBringToFrontOnFocus,
                ui.WindowFlags.NoFocusOnAppearing
            )
        })
        
        table.insert(debug_info, "ui.beginWindow call completed")
        
        local success_msg = string.format("Window created: %s", test_window and "SUCCESS" or "FAILED")
        ac.log("  🪟 " .. success_msg)
        table.insert(debug_info, success_msg)
        
        if test_window then
            table.insert(debug_info, "Inside window block - about to get size...")
            
            -- Get the actual size that was allocated
            local actual_size = ui.windowSize()
            local actual_pos = ui.windowPos()
            
            table.insert(debug_info, "Got size data - processing...")
            
            local size_msg = string.format("Requested: 9999x9999, Got: %.0fx%.0f at (%.0f,%.0f)", 
                   actual_size.x, actual_size.y, actual_pos.x, actual_pos.y)
            ac.log("  📐 " .. size_msg)
            table.insert(debug_info, size_msg)
            
            -- Always save the raw data regardless of validation
            table.insert(debug_info, string.format("Raw data types: size=%s, pos=%s", type(actual_size), type(actual_pos)))
            if actual_size then
                table.insert(debug_info, string.format("Size details: x=%s (type:%s), y=%s (type:%s)", 
                    tostring(actual_size.x), type(actual_size.x), 
                    tostring(actual_size.y), type(actual_size.y)))
            end
            
            -- Check validation conditions step by step
            local width_ok = actual_size.x > 1000 and actual_size.x < 8000
            local height_ok = actual_size.y > 600 and actual_size.y < 6000
            table.insert(debug_info, string.format("Validation: width_ok=%s, height_ok=%s", 
                tostring(width_ok), tostring(height_ok)))
            
            -- This might be our screen resolution!
            if width_ok and height_ok then
                local conf = calculate_confidence(actual_size.x, actual_size.y, "cheat_massive_window")
                table.insert(results, {
                    width = actual_size.x, 
                    height = actual_size.y, 
                    confidence = conf + 25, -- Bonus for this method
                    method = "cheat_massive_window"
                })
                local success_result = string.format("✅ Cheat method found: %.0fx%.0f (confidence: %d)", 
                       actual_size.x, actual_size.y, conf + 25)
                ac.log("  " .. success_result)
                table.insert(debug_info, success_result)
            else
                local fail_msg = string.format("❌ Size failed validation: %.0fx%.0f (width_ok:%s, height_ok:%s)", 
                    actual_size.x, actual_size.y, tostring(width_ok), tostring(height_ok))
                ac.log("  " .. fail_msg)
                table.insert(debug_info, fail_msg)
            end
        else
            table.insert(debug_info, "❌ Failed to create test window")
            ac.log("  ❌ Failed to create test window")
        end
        
        table.insert(debug_info, "About to call ui.endWindow...")
        ui.endWindow()
        table.insert(debug_info, "ui.endWindow completed")
    end)
    
    if not success then
        table.insert(debug_info, "❌ PCALL FAILED: " .. tostring(error_msg))
        ac.log("❌ PCALL FAILED: " .. tostring(error_msg))
    end
    
    -- Method 2: Try creating a window positioned at extreme coordinates
    pcall(function()
        local test_window2 = ui.beginWindow("__resolution_test_corners_" .. cheat_attempt_count, {
            size = vec2(100, 100),
            position = vec2(9999, 9999),  -- Try to position way off screen
            padding = vec2(0, 0),
            flags = bit.bor(
                ui.WindowFlags.NoTitleBar,
                ui.WindowFlags.NoResize,
                ui.WindowFlags.NoScrollbar,
                ui.WindowFlags.NoCollapse,
                ui.WindowFlags.NoBackground,
                ui.WindowFlags.NoBringToFrontOnFocus,
                ui.WindowFlags.NoFocusOnAppearing
            )
        })
        
        if test_window2 then
            local clamped_pos = ui.windowPos()
            
            ac.log(string.format("  📍 Requested position: (9999,9999), Clamped to: (%.0f,%.0f)", 
                   clamped_pos.x, clamped_pos.y))
            
            -- The clamped position might reveal screen boundaries
            if clamped_pos.x > 1000 and clamped_pos.y > 600 then
                -- Estimate screen size based on where it got clamped
                local estimated_width = clamped_pos.x + 100  -- Add window size
                local estimated_height = clamped_pos.y + 100
                
                if estimated_width > 1000 and estimated_height > 600 then
                    local conf = calculate_confidence(estimated_width, estimated_height, "cheat_corner_clamp")
                    table.insert(results, {
                        width = estimated_width, 
                        height = estimated_height, 
                        confidence = conf + 15, -- Bonus for this method
                        method = "cheat_corner_clamp"
                    })
                    ac.log(string.format("  ✅ Corner clamp method found: %.0fx%.0f (confidence: %d)", 
                           estimated_width, estimated_height, conf + 15))
                end
            end
        end
        
        ui.endWindow()
    end)
    
    -- Method 3: Try the "anchor trick" - create windows at opposite corners and measure distance
    pcall(function()
        -- Create top-left anchor
        local anchor_tl = ui.beginWindow("__anchor_tl_" .. cheat_attempt_count, {
            size = vec2(1, 1),
            position = vec2(0, 0),
            padding = vec2(0, 0),
            flags = bit.bor(
                ui.WindowFlags.NoTitleBar,
                ui.WindowFlags.NoResize,
                ui.WindowFlags.NoMove,
                ui.WindowFlags.NoScrollbar,
                ui.WindowFlags.NoCollapse,
                ui.WindowFlags.NoBackground,
                ui.WindowFlags.NoBringToFrontOnFocus,
                ui.WindowFlags.NoFocusOnAppearing
            )
        })
        
        local tl_pos = vec2(0, 0)
        if anchor_tl then
            tl_pos = ui.windowPos()
        end
        ui.endWindow()
        
        -- Create bottom-right anchor
        local anchor_br = ui.beginWindow("__anchor_br_" .. cheat_attempt_count, {
            size = vec2(1, 1),
            position = vec2(8000, 6000),  -- Try to position at bottom-right
            padding = vec2(0, 0),
            flags = bit.bor(
                ui.WindowFlags.NoTitleBar,
                ui.WindowFlags.NoResize,
                ui.WindowFlags.NoMove,
                ui.WindowFlags.NoScrollbar,
                ui.WindowFlags.NoCollapse,
                ui.WindowFlags.NoBackground,
                ui.WindowFlags.NoBringToFrontOnFocus,
                ui.WindowFlags.NoFocusOnAppearing
            )
        })
        
        local br_pos = vec2(8000, 6000)
        if anchor_br then
            br_pos = ui.windowPos()
        end
        ui.endWindow()
        
        -- Calculate distance between anchors
        local width_estimate = br_pos.x - tl_pos.x + 1
        local height_estimate = br_pos.y - tl_pos.y + 1
        
        ac.log(string.format("  📏 Anchor method: TL(%.0f,%.0f) to BR(%.0f,%.0f) = %.0fx%.0f", 
               tl_pos.x, tl_pos.y, br_pos.x, br_pos.y, width_estimate, height_estimate))
        
        if width_estimate > 1000 and height_estimate > 600 and 
           width_estimate < 8000 and height_estimate < 6000 then
            local conf = calculate_confidence(width_estimate, height_estimate, "cheat_anchor_distance")
            table.insert(results, {
                width = width_estimate, 
                height = height_estimate, 
                confidence = conf + 20, -- Good bonus for this clever method
                method = "cheat_anchor_distance"
            })
            ac.log(string.format("  ✅ Anchor distance method found: %.0fx%.0f (confidence: %d)", 
                   width_estimate, height_estimate, conf + 20))
        end
    end)
    
    -- Method 4: Try using current app window size if it appears to be maximized
    pcall(function()
        -- Get current window information
        local current_size = ui.windowSize()
        local current_pos = ui.windowPos()
        
        ac.log(string.format("  📱 Current app window: %.0fx%.0f at (%.0f,%.0f)", 
               current_size.x, current_size.y, current_pos.x, current_pos.y))
        
        -- If the app window is large and positioned at/near origin, it might be maximized
        if current_size.x > 1500 and current_size.y > 900 and 
           current_pos.x < 100 and current_pos.y < 100 then
            local conf = calculate_confidence(current_size.x, current_size.y, "cheat_current_maximized")
            table.insert(results, {
                width = current_size.x, 
                height = current_size.y, 
                confidence = conf + 10, -- Small bonus
                method = "cheat_current_maximized"
            })
            ac.log(string.format("  ✅ Current window method found: %.0fx%.0f (confidence: %d)", 
                   current_size.x, current_size.y, conf + 10))
        end
    end)
    
    -- Save debug info to file
    local debug_text = table.concat(debug_info, "\n")
    ac.log("🔍 SAVING DEBUG INFO TO FILE")
    
    -- Write to AC root directory
    pcall(function()
        local file = io.open(ac.getFolder(ac.FolderID.Root) .. "/resolution_debug.txt", "w")
        if file then
            file:write("RESOLUTION DETECTION DEBUG LOG\n")
            file:write("==============================\n\n")
            file:write(debug_text)
            file:write("\n\nResults found: " .. #results)
            if #results > 0 then
                file:write("\nResults:\n")
                for i, result in ipairs(results) do
                    file:write(string.format("  %d. %dx%d (%s) - Confidence: %d\n", 
                               i, result.width, result.height, result.method, result.confidence))
                end
            end
            file:close()
            ac.log("✅ Debug info saved to resolution_debug.txt")
        else
            ac.log("❌ Failed to save debug file")
        end
    end)
    
    return results
end

-- =============================================================================
-- SIMPLIFIED MANIFEST ANALYSIS
-- =============================================================================

function detect_manifest_intelligent()
    ac.log("🧠 SIMPLIFIED MANIFEST ANALYSIS:")
    
    -- Just provide reasonable fallbacks without overthinking
    ac.log("  📄 Providing fallback resolutions")
    
    local possible_resolutions = {
        {
            width = 3840, height = 2160, 
            confidence = 40, 
            method = "manifest_fallback_4k",
            reasoning = "Common 4K resolution"
        },
        
        {
            width = 2560, height = 1440, 
            confidence = 30, 
            method = "manifest_fallback_1440p",
            reasoning = "Common 1440p resolution"
        },
        
        {
            width = 1920, height = 1080, 
            confidence = 20, 
            method = "manifest_fallback_1080p",
            reasoning = "Common 1080p resolution"
        }
    }
    
    for _, res in ipairs(possible_resolutions) do
        ac.log(string.format("  💡 Fallback: %dx%d (confidence: %d) - %s", 
               res.width, res.height, res.confidence, res.reasoning))
    end
    
    return possible_resolutions
end

-- =============================================================================
-- CONFIDENCE CALCULATION SYSTEM
-- =============================================================================

function calculate_confidence(width, height, method)
    local confidence = 0
    
    -- Check if it matches our target resolutions exactly
    for _, target in ipairs(target_resolutions) do
        if width == target.width and height == target.height then
            confidence = confidence + 50  -- Big bonus for exact match
            break
        end
    end
    
    -- Check if it's a reasonable resolution
    if width >= 1920 and width <= 4096 and height >= 1080 and height <= 2400 then
        confidence = confidence + 30  -- Reasonable size
    end
    
    -- Check aspect ratio (should be close to 16:9)
    local aspect_ratio = width / height
    if aspect_ratio >= 1.7 and aspect_ratio <= 1.8 then
        confidence = confidence + 20  -- Good aspect ratio
    else
        -- Also check for 16:10 aspect ratio (common for older monitors)
        if aspect_ratio >= 1.55 and aspect_ratio <= 1.65 then
            confidence = confidence + 15  -- 16:10 is also valid
        end
    end
    
    -- Method-specific bonuses
    if string.find(method, "cheat_") then
        confidence = confidence + 25  -- Cheat methods get big bonus!
    elseif string.find(method, "csp_") then
        confidence = confidence + 15  -- CSP methods are usually reliable
    elseif string.find(method, "ac_") then
        confidence = confidence + 10  -- AC methods are good
    elseif method == "window_context" then
        confidence = confidence + 5   -- Window context is okay but estimated
    end
    
    -- Penalize weird resolutions
    if width < 1920 or height < 1080 then
        confidence = confidence - 20  -- Too small
    end
    
    if width % 2 ~= 0 or height % 2 ~= 0 then
        confidence = confidence - 10  -- Odd numbers are suspicious
    end
    
    return math.max(0, math.min(100, confidence))
end

-- =============================================================================
-- ENHANCED DETECTION WITH CHEAT METHOD PRIORITIZED
-- =============================================================================

function detect_resolution()
    -- Don't re-detect if we have a locked, confident result
    if detection_locked and detection_confidence >= 80 then
        return detected_width, detected_height
    end
    
    -- Rate limiting - don't check too frequently
    local current_time = os.clock()
    if current_time - last_detection_time < 3.0 then
        return detected_width, detected_height
    end
    
    last_detection_time = current_time
    detection_attempts = detection_attempts + 1
    
    ac.log(string.format("🔍 ENHANCED RESOLUTION DETECTION ATTEMPT #%d", detection_attempts))
    ac.log("=========================================================")
    
    -- Try all detection methods with cheat method prioritized
    local all_results = {}
    
    -- Method 1: THE CHEAT METHOD - Try temporary fullscreen windows
    if cheat_attempt_count < cheat_max_attempts then
        local cheat_results = detect_cheat_fullscreen_window()
        for _, result in ipairs(cheat_results) do
            table.insert(all_results, result)
        end
    end
    
    -- Method 2: Manifest fallbacks (only if cheat method fails)
    if #all_results == 0 or (detection_confidence < 50 and detection_attempts > 2) then
        local manifest_results = detect_manifest_intelligent()
        for _, result in ipairs(manifest_results) do
            table.insert(all_results, result)
        end
    end
    
    -- Choose the best result
    local best_result = choose_best_result(all_results)
    
    if best_result then
        update_detection_result(best_result)
    else
        ac.log("❌ All detection methods failed!")
    end
    
    ac.log("=========================================================")
    
    return detected_width, detected_height
end

-- =============================================================================
-- RESULT SELECTION AND STABILIZATION
-- =============================================================================

function choose_best_result(results)
    if #results == 0 then
        return nil
    end
    
    -- Sort by confidence score
    table.sort(results, function(a, b) return a.confidence > b.confidence end)
    
    ac.log("🏆 DETECTION RESULTS (sorted by confidence):")
    for i, result in ipairs(results) do
        ac.log(string.format("  %d. %dx%d (%s) - Confidence: %d", 
               i, result.width, result.height, result.method, result.confidence))
    end
    
    local best = results[1]
    
    -- Add to detection history for stability analysis
    add_to_history(best)
    
    -- Check for stability (same result multiple times)
    local stability_bonus = calculate_stability_bonus(best)
    best.confidence = best.confidence + stability_bonus
    
    ac.log(string.format("✅ CHOSEN: %dx%d (%s) - Final Confidence: %d (stability bonus: %d)", 
           best.width, best.height, best.method, best.confidence, stability_bonus))
    
    return best
end

function add_to_history(result)
    table.insert(detection_history, {
        width = result.width,
        height = result.height,
        method = result.method,
        confidence = result.confidence,
        timestamp = os.clock()
    })
    
    -- Keep only last 10 results
    if #detection_history > 10 then
        table.remove(detection_history, 1)
    end
end

function calculate_stability_bonus(result)
    local matches = 0
    
    for _, hist in ipairs(detection_history) do
        if hist.width == result.width and hist.height == result.height then
            matches = matches + 1
        end
    end
    
    -- Bonus for consistent results
    return math.min(20, matches * 5)
end

function update_detection_result(result)
    local previous_width = detected_width
    local previous_height = detected_height
    local previous_confidence = detection_confidence
    
    -- Only update if confidence is better, or if we're not locked
    if not detection_locked or result.confidence > detection_confidence then
        detected_width = result.width
        detected_height = result.height
        detection_confidence = result.confidence
        detection_method = result.method
        
        -- Lock detection if confidence is high enough (especially for cheat methods)
        if result.confidence >= 80 or (string.find(result.method, "cheat_") and result.confidence >= 60) then
            detection_locked = true
            ac.log(string.format("🔒 DETECTION LOCKED: %dx%d (confidence: %d)", 
                   detected_width, detected_height, detection_confidence))
        end
        
        -- Calculate new scaling
        calculate_scaling()
        
        -- Log the change
        if previous_width ~= detected_width or previous_height ~= detected_height then
            ac.log(string.format("📏 RESOLUTION CHANGED: %dx%d → %dx%d (confidence: %d → %d)", 
                   previous_width, previous_height, detected_width, detected_height, 
                   previous_confidence, detection_confidence))
        end
    else
        ac.log(string.format("🚫 IGNORED: %dx%d (confidence: %d < current: %d)", 
               result.width, result.height, result.confidence, detection_confidence))
    end
end

-- =============================================================================
-- SCALING CALCULATION
-- =============================================================================

function calculate_scaling()
    -- Find the closest target resolution
    local closest_target = nil
    local smallest_diff = math.huge
    
    for _, target in ipairs(target_resolutions) do
        local diff = math.abs(detected_height - target.height)
        if diff < smallest_diff then
            smallest_diff = diff
            closest_target = target
        end
    end
    
    if closest_target then
        -- Use preset scaling for close matches
        if smallest_diff <= 100 then  -- Within 100 pixels
            ui_scale = closest_target.scale
            font_scale = closest_target.scale
            position_scale = closest_target.scale
            
            ac.log(string.format("📊 Using %s preset scaling: %.1fx", closest_target.name, ui_scale))
        else
            -- Calculate custom scaling based on height
            ui_scale = detected_height / base_height
            font_scale = ui_scale
            position_scale = ui_scale
            
            ac.log(string.format("📊 Custom scaling: %.2fx (height-based)", ui_scale))
        end
    else
        -- Fallback scaling
        ui_scale = 1.0
        font_scale = 1.0
        position_scale = 1.0
        
        ac.log("📊 Fallback scaling: 1.0x")
    end
    
    -- Clamp scaling to reasonable limits
    ui_scale = math.max(0.5, math.min(3.0, ui_scale))
    font_scale = math.max(0.5, math.min(3.0, font_scale))
    position_scale = math.max(0.5, math.min(3.0, position_scale))
    
    ac.log(string.format("📏 Final scaling - UI: %.2f, Font: %.2f, Position: %.2f", 
           ui_scale, font_scale, position_scale))
end

-- =============================================================================
-- SCALING UTILITY FUNCTIONS
-- =============================================================================

function scale_font_size(base_size)
    return math.floor(base_size * font_scale + 0.5)
end

function scale_position_x(x)
    return math.floor(x * position_scale + 0.5)
end

function scale_position_y(y)
    return math.floor(y * position_scale + 0.5)
end

function scale_position(vec)
    return vec2(scale_position_x(vec.x), scale_position_y(vec.y))
end

-- =============================================================================
-- MANUAL OVERRIDE AND DEBUG FUNCTIONS
-- =============================================================================

function force_resolution(width, height, reason)
    reason = reason or "manual override"
    
    ac.log(string.format("🔧 FORCED RESOLUTION: %dx%d (%s)", width, height, reason))
    
    detected_width = width
    detected_height = height
    detection_confidence = 100
    detection_method = "manual"
    detection_locked = true
    
    calculate_scaling()
end

function unlock_detection()
    detection_locked = false
    detection_confidence = 0
    detection_attempts = 0
    detection_history = {}
    cheat_attempt_count = 0  -- Reset cheat attempts too
    
    ac.log("🔓 Detection unlocked - will re-detect on next update")
end

function get_detection_status()
    return {
        width = detected_width,
        height = detected_height,
        confidence = detection_confidence,
        method = detection_method,
        locked = detection_locked,
        attempts = detection_attempts,
        cheat_attempts = cheat_attempt_count,
        ui_scale = ui_scale,
        font_scale = font_scale,
        position_scale = position_scale
    }
end

function debug_print_status()
    local status = get_detection_status()
    
    ac.log("🔍 CURRENT RESOLUTION STATUS:")
    ac.log(string.format("  Resolution: %dx%d", status.width, status.height))
    ac.log(string.format("  Confidence: %d/100", status.confidence))
    ac.log(string.format("  Method: %s", status.method))
    ac.log(string.format("  Locked: %s", status.locked and "YES" or "NO"))
    ac.log(string.format("  Attempts: %d (cheat: %d)", status.attempts, status.cheat_attempts))
    ac.log(string.format("  Scaling: UI=%.2f, Font=%.2f, Pos=%.2f", 
           status.ui_scale, status.font_scale, status.position_scale))
end

-- =============================================================================
-- QUICK PRESETS FOR TESTING
-- =============================================================================

function force_4k()
    force_resolution(3840, 2160, "4K preset")
end

function force_1440p()
    force_resolution(2560, 1440, "1440p preset")
end

function force_1080p()
    force_resolution(1920, 1080, "1080p preset")
end

-- =============================================================================
-- CHEAT METHOD TESTING FUNCTIONS
-- =============================================================================

function test_cheat_method_once()
    ac.log("🎯 MANUAL CHEAT METHOD TEST:")
    local results = detect_cheat_fullscreen_window()
    
    if #results > 0 then
        ac.log("✅ Cheat method results:")
        for i, result in ipairs(results) do
            ac.log(string.format("  %d. %dx%d (%s) - Confidence: %d", 
                   i, result.width, result.height, result.method, result.confidence))
        end
        return results[1]  -- Return best result
    else
        ac.log("❌ Cheat method found no results")
        return nil
    end
end

function reset_cheat_attempts()
    cheat_attempt_count = 0
    ac.log("🔄 Cheat method attempt counter reset")
end

-- =============================================================================
-- MODULE INITIALIZATION AND UPDATE
-- =============================================================================

function initialize()
    ac.log("🖥️ Enhanced Resolution Detection with Cheat Method Initialized")
    ac.log("==============================================================")
    
    -- Perform initial detection
    detect_resolution()
    
    -- Print initial status
    debug_print_status()
    
    ac.log("==============================================================")
end

function update()
    -- Periodic re-detection (only if not locked with high confidence)
    detect_resolution()
end

-- =============================================================================
-- ADDITIONAL UTILITY FUNCTIONS FOR DISTRIBUTED UI
-- =============================================================================

function get_screen_positions()
    -- Calculate standard positions for distributed UI layout
    local positions = {}
    
    -- Get current detected resolution
    local width = detected_width
    local height = detected_height
    
    -- Define percentage-based positions
    positions.top_left = scale_position(vec2(width * 0.02, height * 0.02))
    positions.top_center = scale_position(vec2(width * 0.5, height * 0.02))
    positions.top_right = scale_position(vec2(width * 0.85, height * 0.02))
    
    positions.middle_left = scale_position(vec2(width * 0.02, height * 0.4))
    positions.middle_center = scale_position(vec2(width * 0.5, height * 0.4))
    positions.middle_right = scale_position(vec2(width * 0.85, height * 0.4))
    
    positions.bottom_left = scale_position(vec2(width * 0.02, height * 0.85))
    positions.bottom_center = scale_position(vec2(width * 0.5, height * 0.85))
    positions.bottom_right = scale_position(vec2(width * 0.85, height * 0.85))
    
    -- Full screen size for transparent overlay
    positions.full_screen = {
        size = vec2(width, height),
        position = vec2(0, 0)
    }
    
    return positions
end

function create_full_screen_window_config()
    -- Returns configuration for a full-screen transparent window
    return {
        title = "streetdriftarcade_overlay",
        size = vec2(detected_width, detected_height),
        position = vec2(0, 0),
        padding = vec2(0, 0),
        flags = bit.bor(
            ui.WindowFlags.NoTitleBar,
            ui.WindowFlags.NoResize,
            ui.WindowFlags.NoMove,
            ui.WindowFlags.NoScrollbar,
            ui.WindowFlags.NoCollapse,
            ui.WindowFlags.NoBackground,
            ui.WindowFlags.NoBringToFrontOnFocus,
            ui.WindowFlags.NoFocusOnAppearing,
            ui.WindowFlags.NoInputs  -- Make it non-interactive
        )
    }
end
