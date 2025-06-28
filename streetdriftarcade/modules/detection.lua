-- modules/detection.lua - Physics Detection Systems
-- Save as: assettocorsa/apps/lua/streetdriftarcade/modules/detection.lua

local M = {}
local vars = require('modules/variables')
local utils = require('modules/utilities')

-- =============================================================================
-- ANGLE BONUS SYSTEM FUNCTIONS
-- =============================================================================

-- Start angle tracking when drift begins
function M.start_angle_tracking()
    vars.angle_tracking_enabled = true
    vars.angle_samples = {}
    vars.angle_sample_count = 0
    vars.drift_start_time = os.clock()
    
    -- Reset range durations
    for range, _ in pairs(vars.angle_range_durations) do
        vars.angle_range_durations[range] = 0
    end
    
    utils.debug_log("ANGLE TRACKING STARTED", "ANGLE")
end

-- Update angle tracking during drift - WITH LIVE BONUS SYSTEM
function M.update_angle_tracking(dt, current_angle)
    if not vars.angle_tracking_enabled then return end
    
    -- Add sample to tracking array
    vars.angle_sample_count = vars.angle_sample_count + 1
    vars.angle_samples[vars.angle_sample_count] = {
        angle = current_angle,
        timestamp = os.clock(),
        duration = dt
    }
    
    -- Track time spent in each range - REFINED RANGES (NO <30° REWARDS)
    if current_angle >= 60 then        -- Angle Master (60+)
        vars.angle_range_durations["60+"] = vars.angle_range_durations["60+"] + dt
    elseif current_angle >= 45 then    -- Great Drift (45-60)
        vars.angle_range_durations["45-60"] = vars.angle_range_durations["45-60"] + dt
    elseif current_angle >= 30 then    -- Good Drift (30-45)
        vars.angle_range_durations["30-45"] = vars.angle_range_durations["30-45"] + dt
    end
    -- NO TRACKING FOR <30° - these are mundane and deserve no reward
    
    -- LIVE BONUS SYSTEM - Award bonuses immediately when 2.5s threshold reached!
    M.check_live_angle_bonuses()
    
    -- Debug logging for angle tracking (reduced frequency)
    if vars.angle_sample_count % 120 == 0 then  -- Log every 120 samples (~2 seconds)
        utils.debug_log(string.format("Angle tracking: %.1f° | Ranges: 30-45=%.1fs, 45-60=%.1fs, 60+=%.1fs", 
                        current_angle, 
                        vars.angle_range_durations["30-45"],
                        vars.angle_range_durations["45-60"], 
                        vars.angle_range_durations["60+"]), "ANGLE")
    end
end

-- NEW: Check for live angle bonuses during drift
function M.check_live_angle_bonuses()
    -- Check each range for 2.5s threshold and award bonus immediately
    for range, duration in pairs(vars.angle_range_durations) do
        if duration >= 2.5 then
            local bonus_key = "bonus_awarded_" .. string.gsub(range, "[^%w]", "_")
            
            -- Only award once per segment per range
            if not vars[bonus_key] then
                M.award_live_angle_bonus(range, duration)
                vars[bonus_key] = true  -- Mark as awarded for this segment
            end
        end
    end
end

-- Award live angle bonus immediately
function M.award_live_angle_bonus(range, duration)
    local bonus_points = 0
    local bonus_message = ""
    
    if range == "60+" then        -- Angle Master (60+)
        bonus_points = 25000
        bonus_message = "💎 DRIFT KING! 💎"
    elseif range == "45-60" then  -- Great Drift (45-60)
        bonus_points = 5000
        bonus_message = "🔥 GREAT DRIFT! 🔥"
    elseif range == "30-45" then  -- Good Drift (30-45)
        bonus_points = 1000
        bonus_message = "✨ GOOD DRIFT! ✨"
    end
    
    if bonus_points > 0 then
        -- Apply bonus immediately to live points
        vars.current_drift_points = vars.current_drift_points + bonus_points
        vars.current_segment_points = vars.current_segment_points + bonus_points
        
        -- Show instant notification
        utils.set_notification(bonus_message .. " +" .. utils.format_number(bonus_points))
        
        utils.debug_log(string.format("🎉 LIVE ANGLE BONUS! Range: %s, Duration: %.1fs, Bonus: +%s", 
                        range, duration, utils.format_number(bonus_points)), "LIVE")
    end
end

-- Reset live bonus flags for new segment
function M.reset_live_bonus_flags()
    vars.bonus_awarded_30_45 = false
    vars.bonus_awarded_45_60 = false
    vars.bonus_awarded_60_plus = false
end

-- =============================================================================
-- CRASH DETECTION SYSTEM
-- =============================================================================

-- Update crash detection with speed loss monitoring
function M.update_crash_detection(dt, speed)
    -- Update crash cooldown timer
    if vars.crash_cooldown_timer > 0 then
        vars.crash_cooldown_timer = vars.crash_cooldown_timer - dt
    end
    
    -- SIMPLE CRASH DETECTION - Speed loss with delayed comparison for accuracy
    vars.crash_detection_timer = vars.crash_detection_timer + dt
    
    if vars.crash_detection_timer >= vars.crash_detection_interval then
        -- Only check for crashes every 0.1 seconds for clearer speed differences
        if utils.is_valid_number(vars.last_speed_for_crash) and 
           vars.last_speed_for_crash >= vars.crash_speed_threshold and 
           utils.is_valid_number(speed) then
            
            local speed_loss = vars.last_speed_for_crash - speed
            
            -- Debug logging for crash detection
            if speed_loss > 10 then
                utils.debug_log(string.format("Speed loss: %.1f km/h in %.3fs", 
                               speed_loss, vars.crash_detection_timer), "CRASH")
            end
            
            -- Significant speed loss indicates crash - INCREASED SENSITIVITY
            if speed_loss >= 15 and speed_loss > 0 then  -- Lost 15+ km/h in 0.1 seconds
                if vars.is_drifting then
                    M.cancel_drift_due_to_crash(speed_loss)
                end
            end
        end
        
        -- Reset timer and store current speed for next comparison
        vars.crash_detection_timer = 0.0
        if utils.is_valid_number(speed) then
            vars.last_speed_for_crash = speed
        end
    end
end

-- Cancel drift due to crash detection
function M.cancel_drift_due_to_crash(speed_loss)
    -- CRASH! Cancel drift immediately - NO NOTIFICATION
    vars.is_drifting = false
    vars.current_drift_points = 0
    vars.current_segment_points = 0
    vars.drift_direction = 0
    vars.drift_end_timer = 0.0
    vars.sweet_spot_time = 0.0
    vars.perfect_zone_time = 0.0
    vars.consistency_bonus = 0
    vars.drift_smoke_timer = 0.0
    vars.smoke_stage = 0
    vars.total_drift_time = 0.0
    vars.is_farming = false
    
    -- Cancel angle tracking
    vars.angle_tracking_enabled = false
    
    -- Start crash cooldown period - no points for 3 seconds
    vars.crash_cooldown_timer = vars.crash_cooldown_period
    vars.drift_cancelled_by_crash = true  -- Flag to prevent banking points
    
    utils.debug_log(string.format("CRASH DETECTED! Speed loss: %.0f km/h - Drift cancelled, 3s cooldown", 
                    speed_loss), "CRASH")
end

-- =============================================================================
-- ROLLBACK EXPLOIT DETECTION
-- =============================================================================

-- Update rollback exploit detection using wheel rotation analysis
function M.update_rollback_detection(dt, car, speed)
    local wheel_rotation_speed = M.get_wheel_rotation_intent(car)
    
    -- SMART ROLLBACK EXPLOIT DETECTION - Using wheel rotation intent
    -- Detect if player is trying to roll backward while in forward gear (exploit)
    if wheel_rotation_speed == 0 and speed > 15 then  -- No throttle input but moving at speed
        local forward_velocity = utils.get_forward_velocity(car)
        
        -- If moving backward without throttle input = likely rollback exploit
        if forward_velocity < -5 then
            vars.backward_movement_timer = vars.backward_movement_timer + dt
            
            if vars.backward_movement_timer >= vars.backward_detection_threshold then
                M.cancel_drift_due_to_rollback()
            end
        else
            vars.backward_movement_timer = 0.0  -- Reset if not moving backward
        end
    else
        vars.backward_movement_timer = 0.0  -- Reset if throttle input detected or low speed
    end
end

-- Determine wheel rotation intent from RPM and gear
function M.get_wheel_rotation_intent(car)
    local wheel_rotation_speed = 0
    
    pcall(function()
        local rpm = utils.get_safe_rpm(car)
        local gear = utils.get_safe_gear(car)
        
        if rpm > 0 and gear ~= 0 then
            -- Positive gear + positive RPM = trying to go forward
            -- Negative gear (reverse) + positive RPM = trying to go backward
            if gear > 0 and rpm > 500 then
                wheel_rotation_speed = 1  -- Trying to accelerate forward
            elseif gear < 0 and rpm > 500 then
                wheel_rotation_speed = -1  -- Trying to accelerate backward (legitimate reverse)
            elseif gear == 0 or rpm < 500 then
                wheel_rotation_speed = 0  -- Neutral/idle or very low RPM
            end
        end
    end)
    
    return wheel_rotation_speed
end

-- Cancel drift due to rollback exploit
function M.cancel_drift_due_to_rollback()
    -- ROLLBACK EXPLOIT DETECTED! Cancel drift
    if vars.is_drifting then
        vars.is_drifting = false
        vars.current_drift_points = 0
        vars.current_segment_points = 0
        vars.drift_direction = 0
        vars.drift_end_timer = 0.0
        vars.sweet_spot_time = 0.0
        vars.perfect_zone_time = 0.0
        vars.consistency_bonus = 0
        vars.drift_smoke_timer = 0.0
        vars.smoke_stage = 0
        vars.total_drift_time = 0.0
        vars.is_farming = false
        
        -- Cancel angle tracking
        vars.angle_tracking_enabled = false
        
        utils.set_notification("💫 SPINOUT! 💫")
        utils.debug_log("ROLLBACK EXPLOIT DETECTED! No throttle input while rolling backward", "EXPLOIT")
    end
end

-- =============================================================================
-- PIT DETECTION SYSTEM
-- =============================================================================

-- Update pit detection and handle pit entry/exit
function M.update_pit_detection(car, speed)
    local car_pos = car.position
    
    -- Establish pit area when car is stationary at low speed
    if car_pos and not vars.pit_area_established and speed < 10 then
        vars.pit_area_center = {x = car_pos.x, z = car_pos.z}
        vars.pit_area_established = true
        utils.debug_log("PIT AREA ESTABLISHED", "PIT")
    end
    
    -- Check if currently in pits
    if vars.pit_area_established and vars.pit_area_center and car_pos then
        local distance = utils.calculate_distance_2d(car_pos, vars.pit_area_center)
        vars.in_pits = distance < vars.pit_detection_radius
    end
    
    -- Handle pit entry (session reset)
    if vars.in_pits and not vars.last_pit_status then
        vars.reset_session()
        utils.set_notification("🏁 SESSION RESET! 🏁")
        utils.debug_log("PIT AREA ENTERED - Session reset!", "PIT")
    end
    
    vars.last_pit_status = vars.in_pits
end

-- =============================================================================
-- REVERSE ENTRY AND SPINOUT DETECTION
-- =============================================================================

-- Update reverse entry and spinout detection
function M.update_reverse_entry_detection(dt, angle, speed)
    -- GENERAL SPINOUT DETECTION - covers all spinout scenarios
    if vars.is_drifting and speed > 30 and angle > 75 then
        if not vars.reverse_entry_active then
            M.start_reverse_entry_tracking(angle, speed, "POTENTIAL SPINOUT")
        end
    end
    
    -- REVERSE ENTRY DETECTION - high-speed skill move
    if not vars.reverse_entry_active and speed > vars.reverse_entry_min_speed and angle > 75 then
        M.start_reverse_entry_tracking(angle, speed, "REVERSE ENTRY")
    end
    
    -- Handle active reverse entry situation
    if vars.reverse_entry_active then
        M.handle_active_reverse_entry(dt, angle, speed)
    end
end

-- Start tracking a reverse entry or spinout situation
function M.start_reverse_entry_tracking(angle, speed, situation_type)
    vars.reverse_entry_active = true
    vars.reverse_entry_timer = 0.0
    vars.reverse_entry_awarded = false
    vars.reverse_entry_max_angle = angle
    utils.debug_log(string.format("%s! Angle: %.0f° at %.0f km/h", 
                    situation_type, angle, speed), "REVERSE")
end

-- Handle an active reverse entry situation
function M.handle_active_reverse_entry(dt, angle, speed)
    vars.reverse_entry_timer = vars.reverse_entry_timer + dt
    
    -- Track maximum angle reached
    if angle > vars.reverse_entry_max_angle then
        vars.reverse_entry_max_angle = angle
    end
    
    -- Check for successful recovery
    if angle < 75 and angle > vars.drift_threshold and speed > vars.min_speed and not vars.reverse_entry_awarded then
        M.handle_reverse_entry_recovery(speed)
    end
    
    -- Check for timeout or failure
    if vars.reverse_entry_timer >= vars.reverse_entry_grace_period or 
       (angle < vars.drift_threshold and speed < vars.min_speed) then
        if not vars.reverse_entry_awarded then
            M.handle_reverse_entry_failure(speed)
        end
        M.end_reverse_entry_tracking()
    end
end

-- Handle successful recovery from reverse entry
function M.handle_reverse_entry_recovery(speed)
    if speed >= vars.reverse_entry_min_speed then
        -- High-speed recovery = reverse entry skill bonus
        local excess_angle = vars.reverse_entry_max_angle - 75
        local bonus_points = math.floor(50 * excess_angle)
        vars.current_drift_points = vars.current_drift_points + bonus_points
        vars.current_segment_points = vars.current_segment_points + bonus_points
        vars.reverse_entry_awarded = true
        
        utils.set_notification("SKILL BONUS! " .. utils.format_number(bonus_points))
        utils.debug_log(string.format("SKILL BONUS! Bonus: +%s", utils.format_number(bonus_points)), "SKILL")
    else
        -- Lower-speed recovery = just avoided spinout, no bonus but no penalty
        utils.debug_log(string.format("Spinout avoided - good recovery at %.0f km/h", speed), "RECOVERY")
        vars.reverse_entry_awarded = true
    end
end

-- Handle failure to recover from reverse entry
function M.handle_reverse_entry_failure(speed)
    if speed >= vars.reverse_entry_min_speed then
        -- High-speed spinout = reverse entry failure (with penalty tracking)
        vars.reverse_entry_failures = vars.reverse_entry_failures + 1
        
        M.cancel_drift_completely()
        
        -- Check for 3-failure penalty
        if vars.reverse_entry_failures >= vars.max_failures_before_penalty then
            M.apply_three_failure_penalty()
        else
            M.apply_single_failure_notification()
        end
    else
        -- Lower-speed spinout = just cancel drift, no penalty tracking
        M.cancel_drift_completely()
        utils.set_notification("💫 SPINOUT! 💫")
        utils.debug_log(string.format("Low-speed spinout - drift cancelled at %.0f km/h", speed), "SPINOUT")
    end
end

-- Cancel drift completely (used by spinout detection)
function M.cancel_drift_completely()
    vars.is_drifting = false
    vars.current_drift_points = 0
    vars.current_segment_points = 0
    vars.drift_direction = 0
    vars.drift_end_timer = 0.0
    vars.sweet_spot_time = 0.0
    vars.perfect_zone_time = 0.0
    vars.consistency_bonus = 0
    vars.drift_smoke_timer = 0.0
    vars.smoke_stage = 0
    vars.high_speed_drift_time = 0.0
    vars.duration_bonus_multiplier = 1.0
    vars.total_drift_time = 0.0
    vars.is_farming = false
    
    -- Cancel angle tracking
    vars.angle_tracking_enabled = false
end

-- Apply three-failure penalty
function M.apply_three_failure_penalty()
    local penalty_amount = math.floor(vars.total_banked_points * 0.5)
    vars.total_banked_points = vars.total_banked_points - penalty_amount
    vars.reverse_entry_failures = 0  -- Reset failure counter
    
    utils.set_notification("💀 FAIL THREE! -50% PENALTY! 💀")
    utils.debug_log(string.format("3 REVERSE ENTRY FAILURES! 50%% penalty applied: -%s", 
                    utils.format_number(penalty_amount)), "PENALTY")
end

-- Apply single failure notification
function M.apply_single_failure_notification()
    local fail_text = ""
    if vars.reverse_entry_failures == 1 then
        fail_text = "💀 FAIL ONE! 💀"
    elseif vars.reverse_entry_failures == 2 then
        fail_text = "💀 FAIL TWO! 💀"
    end
    utils.set_notification(fail_text)
    utils.debug_log(string.format("Reverse entry failed - drift cancelled (%d/3)", 
                    vars.reverse_entry_failures), "FAIL")
end

-- End reverse entry tracking
function M.end_reverse_entry_tracking()
    vars.reverse_entry_active = false
    vars.reverse_entry_timer = 0.0
    vars.reverse_entry_max_angle = 0
end

-- =============================================================================
-- DRIFT DETECTION SYSTEM
-- =============================================================================

-- Get comprehensive car data for drift detection
function M.get_car_data(car, speed)
    local angle, angle_with_direction, lateral_velocity = utils.calculate_slip_angle(car)
    local angular_velocity = utils.get_car_angular_velocity(car)
    local gear = utils.get_safe_gear(car)
    
    return {
        angle = angle,
        angle_with_direction = angle_with_direction,
        lateral_velocity = lateral_velocity,
        angular_velocity = angular_velocity,
        gear = gear,
        speed = speed
    }
end

-- Check if car is actively drifting
function M.check_active_drifting(car_data, speed)
    return speed > vars.min_speed and 
           car_data.angle > vars.drift_threshold and 
           vars.crash_cooldown_timer <= 0 and
           car_data.gear >= 0 and  -- No reverse gear drifting
           car_data.lateral_velocity >= vars.MINIMUM_LATERAL_VELOCITY  -- Must be sliding sideways
end

-- Handle drift start or direction change
function M.handle_drift_start_or_change(car_data, speed)
    local current_direction = utils.get_drift_direction(car_data.angle, car_data.angle_with_direction)
    
    if not vars.is_drifting then
        M.start_new_drift(current_direction, speed)
    elseif current_direction ~= 0 and current_direction ~= vars.drift_direction then
        M.handle_direction_change(current_direction)
    end
end

-- Start a new drift
function M.start_new_drift(current_direction, speed)
    vars.is_drifting = true
    vars.current_drift_points = 0
    vars.current_segment_points = 0
    vars.drift_direction = current_direction
    vars.sweet_spot_time = 0.0
    vars.perfect_zone_time = 0.0
    vars.consistency_bonus = 0
    vars.drift_smoke_timer = 0.0
    vars.smoke_stage = 0
    vars.total_drift_time = 0.0
    vars.is_farming = false
    
    -- Reset all tracking
    vars.reset_drift_tracking()
    
    -- Reset live bonus flags
    M.reset_live_bonus_flags()
    
    -- Start angle tracking
    M.start_angle_tracking()
    
    utils.debug_log(string.format("DRIFT STARTED! Speed: %.0f km/h", speed), "DRIFT")
end

-- Handle direction change during drift - NO MORE MULTIPLIER SYSTEM
function M.handle_direction_change(current_direction)
    -- NO MORE END-OF-SEGMENT ANGLE BONUS - Live system handles this now
    
    -- Bank current segment for Pure Skill tracking
    local records = require('modules/records')  -- Late require to avoid circular dependency
    records.check_pure_skill_record(vars.current_segment_points)
    
    -- NO MORE MULTIPLIER - just continue the drift seamlessly
    utils.debug_log("DIRECTION CHANGE! Continuing seamless drift", "DRIFT")
    
    -- Reset for new drift segment but keep total points accumulating
    vars.drift_direction = current_direction
    vars.current_segment_points = 0
    vars.sweet_spot_time = 0.0
    vars.perfect_zone_time = 0.0
    vars.consistency_bonus = 0
    vars.drift_smoke_timer = 0.0
    vars.smoke_stage = 0
    vars.total_drift_time = 0.0
    vars.is_farming = false
    
    -- Reset all tracking for new segment
    vars.reset_drift_tracking()
    
    -- Reset live bonus flags for new segment
    M.reset_live_bonus_flags()
    
    -- START ANGLE TRACKING FOR NEW SEGMENT
    M.start_angle_tracking()
end

-- Update drift progression (smoke, timers, etc.)
function M.update_drift_progression(dt)
    vars.drift_end_timer = 0.0
    
    -- Update smoke progression
    vars.drift_smoke_timer = vars.drift_smoke_timer + dt
    if vars.drift_smoke_timer >= 6.0 then
        vars.smoke_stage = 3
    elseif vars.drift_smoke_timer >= 4.0 then
        vars.smoke_stage = 2
    elseif vars.drift_smoke_timer >= 2.0 then
        vars.smoke_stage = 1
    else
        vars.smoke_stage = 0
    end
    
    -- Update total drift time for duration bonus calculations
    vars.total_drift_time = vars.total_drift_time + dt
    
    -- Update angle tracking
    local car = ac.getCar(0)
    if car then
        local angle, _, _ = utils.calculate_slip_angle(car)
        M.update_angle_tracking(dt, angle)
    end
end

-- Handle drift end
function M.handle_drift_end(dt)
    if vars.is_drifting then
        vars.drift_end_timer = vars.drift_end_timer + dt
        
        if vars.drift_end_timer >= vars.drift_end_delay then
            M.end_drift()
        end
    end
end

-- End the current drift and bank points - NO MORE MULTIPLIER
function M.end_drift()
    local records = require('modules/records')  -- Late require to avoid circular dependency
    
    -- NO MORE END-OF-DRIFT ANGLE BONUS - Live system already awarded them
    
    vars.is_drifting = false
    vars.drift_end_timer = 0.0
    
    -- Only bank points if drift wasn't cancelled by crash
    if vars.current_drift_points > 25 and not vars.drift_cancelled_by_crash then
        local rounded_drift_points = math.floor(vars.current_drift_points)
        -- NO MORE MULTIPLIER - direct banking of raw points
        vars.total_banked_points = vars.total_banked_points + rounded_drift_points
        
        -- Check records (final score is now the same as raw points)
        records.check_all_records(vars.current_segment_points, rounded_drift_points, vars.total_banked_points)
        
        utils.debug_log(string.format("DRIFT ENDED! Points banked: %s", 
                        utils.format_number(rounded_drift_points)), "DRIFT")
    elseif vars.drift_cancelled_by_crash then
        utils.debug_log("DRIFT ENDED! NO POINTS BANKED - Cancelled by crash", "DRIFT")
    else
        utils.debug_log("DRIFT ENDED! Too short - no points banked", "DRIFT")
    end
    
    -- Reset all drift variables
    M.reset_drift_variables()
end

-- Reset all drift-related variables
function M.reset_drift_variables()
    vars.current_drift_points = 0
    vars.current_segment_points = 0
    vars.drift_direction = 0
    vars.sweet_spot_time = 0.0
    vars.perfect_zone_time = 0.0
    vars.consistency_bonus = 0
    vars.drift_smoke_timer = 0.0
    vars.smoke_stage = 0
    vars.total_drift_time = 0.0
    vars.is_farming = false
    vars.drift_cancelled_by_crash = false
    
    -- Reset angle tracking
    vars.angle_tracking_enabled = false
    
    -- Reset all tracking
    vars.reset_drift_tracking()
end

-- =============================================================================
-- MODULE INITIALIZATION
-- =============================================================================

function M.initialize()
    utils.debug_log("Detection module initialized with Live Angle Bonus System", "INIT")
end

return M