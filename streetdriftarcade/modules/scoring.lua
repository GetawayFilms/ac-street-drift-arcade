-- modules/scoring.lua - Scoring System and Point Calculations
-- Save as: assettocorsa/apps/lua/streetdriftarcade/modules/scoring.lua

local M = {}

-- =============================================================================
-- MAIN SCORING CALCULATION
-- =============================================================================

-- Calculate and apply points for the current frame
function M.calculate_and_apply_points(dt, angle, speed)
    -- ✨ ELEGANT SCORING SYSTEM! ✨
    -- Simple and beautiful: base_rate * angle * speed * time
    
    -- LOW ANGLE COMPENSATION - Boost shallow angles since extreme speeds aren't realistic
    local angle_multiplier = M.calculate_angle_multiplier(angle)
    
    -- Base points calculation
    local points_this_frame = vars.base_drift_rate * angle * speed * dt * angle_multiplier
    
    -- Apply duration bonus
    local duration_multiplier = M.calculate_duration_bonus()
    points_this_frame = points_this_frame * duration_multiplier
    
    -- Apply sweet spot bonuses
    local sweet_spot_multiplier, consistency_bonus = M.calculate_sweet_spot_bonus(dt, angle)
    points_this_frame = points_this_frame * sweet_spot_multiplier
    points_this_frame = points_this_frame + (consistency_bonus * dt)
    
    -- Apply farming penalty if detected
    if vars.is_farming then
        points_this_frame = points_this_frame * 0.1  -- Reduce to 10% when farming
    end
    
    -- Add to segment points (no multiplier for pure skill tracking)
    vars.current_segment_points = vars.current_segment_points + points_this_frame
    
    -- Add to current drift points (raw points for display)
    vars.current_drift_points = vars.current_drift_points + points_this_frame
    
    -- Debug logging removed - no more high score frame spam
end

-- =============================================================================
-- ANGLE COMPENSATION SYSTEM
-- =============================================================================

-- Calculate angle multiplier for low angle compensation
function M.calculate_angle_multiplier(angle)
    -- Gradual compensation from 40° down to 10°
    if angle < 40 and angle >= 10 then
        -- Linear scaling: 1.0x at 40°, up to 2.0x at 10°
        return 1.0 + (40 - angle) / 30  -- (40-angle)/30 gives 0 to 1, so 1.0x to 2.0x
    elseif angle < 10 then
        -- Cap at 2.0x for angles below 10°
        return 2.0
    else
        return 1.0  -- Normal multiplier for angles 40° and above
    end
end

-- =============================================================================
-- DURATION BONUS SYSTEM
-- =============================================================================

-- Calculate aggressive duration bonus that starts immediately
function M.calculate_duration_bonus()
    -- REBALANCED DURATION BONUS - More reasonable progression
    -- New formula: 1.0 + (time^2 / 6.25) to achieve 4x at 5 seconds
    -- Examples: 1s = 1.16x, 2s = 1.64x, 3s = 2.44x, 5s = 4.0x, 8s = 11.24x
    vars.duration_bonus_multiplier = 1.0 + (math.pow(vars.total_drift_time, 2) / 6.25)
    return vars.duration_bonus_multiplier
end

-- Get duration bonus info for display
function M.get_duration_bonus_info()
    return {
        multiplier = vars.duration_bonus_multiplier,
        time = vars.total_drift_time,
        description = string.format("%.1fx", vars.duration_bonus_multiplier)
    }
end

-- =============================================================================
-- SWEET SPOT SYSTEM
-- =============================================================================

-- Calculate sweet spot bonus and update timing
function M.calculate_sweet_spot_bonus(dt, angle)
    local multiplier = 1.0
    local consistency_bonus = 0
    
    if angle >= 37 and angle <= 43 then
        -- PERFECT ZONE - Triple points!
        vars.perfect_zone_time = vars.perfect_zone_time + dt
        vars.sweet_spot_time = vars.sweet_spot_time + dt
        consistency_bonus = math.floor(vars.perfect_zone_time * 100) + math.floor(vars.sweet_spot_time * 50)
        multiplier = 3.0  -- Triple points for perfect zone
        
        -- Log perfect zone achievements
        if vars.perfect_zone_time == dt then  -- First frame in perfect zone
            utils.debug_log("Entered PERFECT ZONE!", "SWEET")
        end
        
    elseif angle >= 30 and angle <= 50 then
        -- SWEET SPOT - Bonus based on distance from perfect
        vars.sweet_spot_time = vars.sweet_spot_time + dt
        consistency_bonus = math.floor(vars.sweet_spot_time * 50)
        
        local distance_from_perfect = math.abs(angle - 40)
        if distance_from_perfect <= 6 then
            multiplier = 1.6  -- 60% bonus for good zone
        else
            multiplier = 1.3  -- 30% bonus for sweet spot edges
        end
        
        -- Log sweet spot entry
        if vars.sweet_spot_time == dt then  -- First frame in sweet spot
            utils.debug_log("Entered SWEET SPOT!", "SWEET")
        end
        
    else
        -- Outside sweet spot - reset timers
        if vars.sweet_spot_time > 0 then
            utils.debug_log(string.format("Left sweet spot after %.1fs", vars.sweet_spot_time), "SWEET")
        end
        vars.sweet_spot_time = 0.0
        vars.perfect_zone_time = 0.0
        consistency_bonus = 0
    end
    
    vars.consistency_bonus = consistency_bonus
    return multiplier, consistency_bonus
end

-- Get sweet spot info for display
function M.get_sweet_spot_info(angle)
    if angle >= 37 and angle <= 43 then
        if vars.perfect_zone_time > 1.0 then
            return {
                zone = "PERFECT",
                text = string.format("🎯 PERFECT ZONE! (%.0fs)", vars.perfect_zone_time),
                color = vars.colors.cyan,
                multiplier = 3.0
            }
        else
            return {
                zone = "PERFECT",
                text = "🎯 PERFECT ZONE!",
                color = vars.colors.cyan,
                multiplier = 3.0
            }
        end
    elseif angle >= 30 and angle <= 50 then
        if vars.sweet_spot_time > 1.0 then
            return {
                zone = "SWEET",
                text = string.format("✨ SWEET SPOT! (%.0fs)", vars.sweet_spot_time),
                color = vars.colors.yellow,
                multiplier = vars.sweet_spot_time > 0 and 1.6 or 1.3
            }
        else
            return {
                zone = "SWEET",
                text = "✨ SWEET SPOT!",
                color = vars.colors.yellow,
                multiplier = 1.3
            }
        end
    else
        return {
            zone = "NONE",
            text = "",
            color = vars.colors.white,
            multiplier = 1.0
        }
    end
end

-- =============================================================================
-- ANGLE BONUS SYSTEM
-- =============================================================================

-- Get angle bonus info for display
function M.get_angle_bonus_info()
    return {
        enabled = vars.angle_tracking_enabled,
        current_ranges = vars.angle_range_durations,
        last_bonus_points = vars.angle_bonus_points,
        last_bonus_message = vars.angle_bonus_notification,
        last_dominant_range = vars.dominant_angle_range,
        last_dominant_duration = vars.dominant_angle_duration
    }
end

-- =============================================================================
-- COMBO SYSTEM (LEGACY - KEPT FOR COMPATIBILITY)
-- =============================================================================

-- Get combo display information
function M.get_combo_info()
    local combo_info = {
        multiplier = vars.drift_multiplier,
        text = "",
        emojis = "",
        color = rgbm(vars.colors.white.r, vars.colors.white.g, vars.colors.white.b, vars.colors.white.a)
    }
    
    if vars.drift_multiplier == 5 then
        combo_info.text = "MAX COMBO"
        combo_info.emojis = "⚡⚡⚡⚡⚡"
        combo_info.color = rgbm(vars.colors.cyan.r, vars.colors.cyan.g, vars.colors.cyan.b, vars.colors.cyan.a)
    elseif vars.drift_multiplier == 4 then
        combo_info.text = "QUAD COMBO"
        combo_info.emojis = "💥💥💥💥"
        combo_info.color = rgbm(vars.colors.red.r, vars.colors.red.g, vars.colors.red.b, vars.colors.red.a)
    elseif vars.drift_multiplier == 3 then
        combo_info.text = "TRIPLE COMBO"
        combo_info.emojis = "🔥🔥🔥"
        combo_info.color = rgbm(vars.colors.orange.r, vars.colors.orange.g, vars.colors.orange.b, vars.colors.orange.a)
    elseif vars.drift_multiplier == 2 then
        combo_info.text = "DOUBLE COMBO"
        combo_info.emojis = "✨✨"
        combo_info.color = rgbm(vars.colors.yellow.r, vars.colors.yellow.g, vars.colors.yellow.b, vars.colors.yellow.a)
    end
    -- No display for x1 multiplier
    
    return combo_info
end

-- =============================================================================
-- SMOKE SYSTEM
-- =============================================================================

-- Get smoke display information
function M.get_smoke_info()
    local smoke_info = {
        stage = vars.smoke_stage,
        display = "",
        color = rgbm(0.8, 0.8, 0.8, 1)  -- Light gray
    }
    
    if vars.smoke_stage >= 3 then
        smoke_info.display = "💨💨💨"
    elseif vars.smoke_stage >= 2 then
        smoke_info.display = "💨💨"
    elseif vars.smoke_stage >= 1 then
        smoke_info.display = "💨"
    end
    
    return smoke_info
end

-- =============================================================================
-- SCORING STATISTICS
-- =============================================================================

-- Get comprehensive scoring statistics for display or debug
function M.get_scoring_stats()
    local duration_info = M.get_duration_bonus_info()
    local combo_info = M.get_combo_info()
    local angle_bonus_info = M.get_angle_bonus_info()
    
    return {
        current_points = vars.current_drift_points,
        segment_points = vars.current_segment_points,
        total_banked = vars.total_banked_points,
        multiplier = vars.drift_multiplier,
        duration_bonus = duration_info,
        combo = combo_info,
        angle_bonus = angle_bonus_info,
        sweet_spot_time = vars.sweet_spot_time,
        perfect_zone_time = vars.perfect_zone_time,
        consistency_bonus = vars.consistency_bonus,
        drift_time = vars.total_drift_time,
        is_farming = vars.is_farming
    }
end

-- Calculate theoretical maximum points per second at current state
function M.calculate_max_points_per_second(angle, speed)
    local angle_multiplier = M.calculate_angle_multiplier(angle)
    local duration_multiplier = M.calculate_duration_bonus()
    local sweet_spot_multiplier = vars.perfect_zone_time > 0 and 3.0 or (vars.sweet_spot_time > 0 and 1.6 or 1.0)
    
    local base_points_per_second = vars.base_drift_rate * angle * speed
    local total_multiplier = angle_multiplier * duration_multiplier * sweet_spot_multiplier
    
    return base_points_per_second * total_multiplier
end

-- =============================================================================
-- SCORE VALIDATION AND SAFETY
-- =============================================================================

-- Validate that scoring variables are in reasonable ranges
function M.validate_scoring_state()
    local issues = {}
    
    -- Check for unreasonable values
    if vars.current_drift_points > 1000000 then
        table.insert(issues, "Current drift points suspiciously high: " .. utils.format_number(vars.current_drift_points))
    end
    
    if vars.duration_bonus_multiplier > 100 then
        table.insert(issues, "Duration bonus suspiciously high: " .. string.format("%.1fx", vars.duration_bonus_multiplier))
    end
    
    if vars.total_drift_time > 300 then  -- 5 minutes
        table.insert(issues, "Drift time suspiciously long: " .. string.format("%.1fs", vars.total_drift_time))
    end
    
    if vars.drift_multiplier > 5 then
        table.insert(issues, "Drift multiplier above maximum: x" .. vars.drift_multiplier)
        vars.drift_multiplier = 5  -- Cap it
    end
    
    -- Log any issues found
    for _, issue in ipairs(issues) do
        utils.debug_log("VALIDATION: " .. issue, "SCORE")
    end
    
    return #issues == 0
end

-- Reset scoring variables to safe defaults
function M.reset_scoring_variables()
    vars.current_drift_points = 0
    vars.current_segment_points = 0
    vars.drift_multiplier = 1
    vars.sweet_spot_time = 0.0
    vars.perfect_zone_time = 0.0
    vars.consistency_bonus = 0
    vars.total_drift_time = 0.0
    vars.duration_bonus_multiplier = 1.0
    vars.is_farming = false
    
    -- Reset angle bonus variables
    vars.angle_tracking_enabled = false
    vars.angle_bonus_points = 0
    vars.angle_bonus_notification = ""
    vars.dominant_angle_range = ""
    vars.dominant_angle_duration = 0
end

-- =============================================================================
-- SCORING PRESETS AND TUNING
-- =============================================================================

-- Apply scoring preset (for different difficulty levels or car types)
function M.apply_scoring_preset(preset_name)
    if preset_name == "beginner" then
        vars.base_drift_rate = 1.2  -- Higher base rate
        vars.drift_threshold = 6.0  -- Lower threshold
        utils.debug_log("Applied BEGINNER scoring preset", "SCORE")
        
    elseif preset_name == "expert" then
        vars.base_drift_rate = 0.6  -- Lower base rate
        vars.drift_threshold = 10.0  -- Higher threshold
        utils.debug_log("Applied EXPERT scoring preset", "SCORE")
        
    elseif preset_name == "default" then
        vars.base_drift_rate = 0.8
        vars.drift_threshold = 8.0
        utils.debug_log("Applied DEFAULT scoring preset", "SCORE")
        
    else
        utils.debug_log("Unknown scoring preset: " .. tostring(preset_name), "SCORE")
    end
end

-- Get current scoring configuration
function M.get_scoring_config()
    return {
        base_drift_rate = vars.base_drift_rate,
        drift_threshold = vars.drift_threshold,
        min_speed = vars.min_speed,
        transition_threshold = vars.transition_threshold,
        farming_penalty = 0.1  -- 10% points when farming
    }
end

-- =============================================================================
-- ADVANCED SCORING FEATURES
-- =============================================================================

-- Calculate score projection (what the final score would be if drift ended now)
function M.calculate_score_projection()
    if not vars.is_drifting then
        return 0
    end
    
    local rounded_drift_points = math.floor(vars.current_drift_points)
    local projected_final_score = rounded_drift_points * vars.drift_multiplier
    
    return {
        raw_points = rounded_drift_points,
        multiplier = vars.drift_multiplier,
        final_score = projected_final_score,
        would_be_record = projected_final_score > vars.all_time_best_final_score
    }
end

-- Calculate efficiency rating (points per second of drift time)
function M.calculate_efficiency_rating()
    if vars.total_drift_time <= 0 then
        return 0
    end
    
    return vars.current_drift_points / vars.total_drift_time
end

-- =============================================================================
-- MODULE INITIALIZATION
-- =============================================================================

function M.initialize()
    -- Validate initial scoring state
    M.validate_scoring_state()
    utils.debug_log("Scoring module initialized with Angle Bonus System", "INIT")
end

return M
