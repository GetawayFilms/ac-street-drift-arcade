-- modules/anti_farming.lua - Enhanced Anti-Farming with False Positive Prevention
-- Save as: assettocorsa/apps/lua/streetdriftarcade/modules/anti_farming.lua

local M = {}

-- =============================================================================
-- ROTATION ANALYSIS SYSTEM
-- =============================================================================

-- Add rotation sample to circular buffer for analysis
function M.add_rotation_sample(car_angular_velocity)
    if not car_angular_velocity then return end
    
    -- Store sample in circular buffer
    vars.rotation_samples[vars.sample_index] = {
        x = car_angular_velocity.x or 0,
        y = car_angular_velocity.y or 0,  -- Yaw (most important for drift farming detection)
        z = car_angular_velocity.z or 0,
        timestamp = os.clock()
    }
    
    vars.sample_index = vars.sample_index + 1
    if vars.sample_index > vars.max_rotation_samples then
        vars.sample_index = 1
    end
    
    -- Calculate magnitude of current rotation
    local magnitude = math.sqrt(
        (car_angular_velocity.x or 0)^2 + 
        (car_angular_velocity.y or 0)^2 + 
        (car_angular_velocity.z or 0)^2
    )
    
    vars.total_rotation_magnitude = vars.total_rotation_magnitude + magnitude
    
    -- Detect significant rotation changes (sensitive for better detection)
    if magnitude > 1.5 then  -- Threshold for "significant" rotation (rad/s)
        vars.last_significant_rotation_time = os.clock()
    end
end

-- Calculate rotation variance to detect repetitive patterns
function M.calculate_rotation_variance()
    if #vars.rotation_samples < vars.max_rotation_samples then
        return 1.0  -- Not enough data, assume varied rotation
    end
    
    local sum = 0.0
    local sum_squared = 0.0
    local count = #vars.rotation_samples
    
    -- Calculate mean and variance of Y-axis rotation (yaw)
    for i = 1, count do
        local yaw = vars.rotation_samples[i].y
        sum = sum + yaw
        sum_squared = sum_squared + (yaw * yaw)
    end
    
    local mean = sum / count
    local variance = (sum_squared / count) - (mean * mean)
    
    return math.sqrt(variance)  -- Return standard deviation
end

-- =============================================================================
-- POSITION TRACKING SYSTEM
-- =============================================================================

-- Add position sample and analyze movement patterns
function M.add_position_sample(car_position, current_speed)
    if not car_position then return end
    
    -- Store position sample in circular buffer
    vars.position_samples[vars.position_sample_index] = {
        x = car_position.x,
        y = car_position.y or 0,  -- Elevation
        z = car_position.z,
        timestamp = os.clock()
    }
    
    vars.position_sample_index = vars.position_sample_index + 1
    if vars.position_sample_index > vars.max_position_samples then
        vars.position_sample_index = 1
    end
    
    -- Store speed sample for variance analysis
    vars.speed_variance_samples[vars.speed_sample_index] = current_speed or 0
    vars.speed_sample_index = vars.speed_sample_index + 1
    if vars.speed_sample_index > vars.max_speed_samples then
        vars.speed_sample_index = 1
    end
end

-- Analyze track progress to distinguish legitimate drifting from farming
function M.analyze_track_progress()
    if #vars.position_samples < vars.max_position_samples then
        return {
            distance_traveled = 1000,  -- Assume progress if not enough data
            elevation_change = 0,
            is_progressing = true,
            speed_variance = 100,
            analysis_confidence = "LOW"
        }
    end
    
    -- Get oldest and newest positions from circular buffer
    local oldest_pos = vars.position_samples[vars.position_sample_index] -- Oldest after circular wrap
    local newest_pos = vars.position_samples[vars.position_sample_index == 1 and vars.max_position_samples or vars.position_sample_index - 1]
    
    -- Calculate straight-line distance (for reference)
    local straight_distance = utils.calculate_distance_2d(oldest_pos, newest_pos)
    local elevation_change = math.abs((newest_pos.y or 0) - (oldest_pos.y or 0))
    
    -- Calculate total path distance (more accurate for winding tracks)
    local total_path_distance = M.calculate_path_distance()
    
    -- Calculate speed variance (indicates track progression vs. constant farming)
    local speed_variance = M.calculate_speed_variance()
    
    -- Determine if car is making legitimate track progress
    local is_progressing = (total_path_distance > vars.distance_traveled_threshold) or 
                          (elevation_change > vars.elevation_change_threshold) or
                          (speed_variance > vars.speed_variance_threshold)
    
    -- Determine analysis confidence based on data quality
    local analysis_confidence = M.determine_analysis_confidence(total_path_distance, elevation_change, speed_variance)
    
    return {
        distance_traveled = total_path_distance,
        straight_distance = straight_distance,
        elevation_change = elevation_change,
        is_progressing = is_progressing,
        speed_variance = speed_variance,
        analysis_confidence = analysis_confidence,
        path_efficiency = total_path_distance > 0 and (straight_distance / total_path_distance) or 0
    }
end

-- Calculate total path distance by summing incremental movements
function M.calculate_path_distance()
    local total_path_distance = 0
    
    for i = 1, #vars.position_samples - 1 do
        local current_pos = vars.position_samples[i]
        local next_pos = vars.position_samples[i + 1]
        if current_pos and next_pos then
            total_path_distance = total_path_distance + utils.calculate_distance_2d(current_pos, next_pos)
        end
    end
    
    return total_path_distance
end

-- Calculate speed variance to detect track progression patterns
function M.calculate_speed_variance()
    if #vars.speed_variance_samples < vars.max_speed_samples then
        return 100  -- Assume high variance if not enough data
    end
    
    local speed_sum = 0
    local speed_sum_squared = 0
    local speed_count = #vars.speed_variance_samples
    
    for i = 1, speed_count do
        local speed = vars.speed_variance_samples[i]
        speed_sum = speed_sum + speed
        speed_sum_squared = speed_sum_squared + (speed * speed)
    end
    
    local speed_mean = speed_sum / speed_count
    local speed_variance = math.sqrt((speed_sum_squared / speed_count) - (speed_mean * speed_mean))
    
    return speed_variance
end

-- Determine confidence level in the analysis
function M.determine_analysis_confidence(distance, elevation, speed_var)
    local confidence_score = 0
    
    -- High confidence indicators
    if distance > vars.distance_traveled_threshold * 2 then confidence_score = confidence_score + 2 end
    if elevation > vars.elevation_change_threshold * 2 then confidence_score = confidence_score + 2 end
    if speed_var > vars.speed_variance_threshold * 2 then confidence_score = confidence_score + 2 end
    
    -- Medium confidence indicators
    if distance > vars.distance_traveled_threshold then confidence_score = confidence_score + 1 end
    if elevation > vars.elevation_change_threshold then confidence_score = confidence_score + 1 end
    if speed_var > vars.speed_variance_threshold then confidence_score = confidence_score + 1 end
    
    if confidence_score >= 4 then
        return "HIGH"
    elseif confidence_score >= 2 then
        return "MEDIUM"
    else
        return "LOW"
    end
end

-- =============================================================================
-- INTELLIGENT FARMING DETECTION
-- =============================================================================

-- Main farming detection with false positive prevention
function M.detect_intelligent_farming()
    if vars.total_drift_time < vars.farming_detection_delay then
        return false  -- Too early to detect farming
    end
    
    -- Analyze rotation patterns
    local rotation_variance = M.calculate_rotation_variance()
    local time_since_significant_rotation = os.clock() - vars.last_significant_rotation_time
    
    -- Analyze track progression
    local progress_data = M.analyze_track_progress()
    
    -- Original farming indicators
    local is_repetitive = rotation_variance < vars.rotation_variance_threshold
    local is_stagnant = time_since_significant_rotation > 3.0  -- 3 seconds without significant rotation
    local sufficient_duration = vars.total_drift_time > vars.farming_detection_delay
    
    -- FALSE POSITIVE PREVENTION CHECKS
    local is_making_progress = progress_data.is_progressing
    local is_on_ramp_or_hill = progress_data.elevation_change > vars.elevation_change_threshold
    local has_speed_variation = progress_data.speed_variance > vars.speed_variance_threshold
    local is_following_track = progress_data.distance_traveled > vars.distance_traveled_threshold
    
    -- Enhanced logic: Only flag as farming if rotation is repetitive AND no track progress
    local base_farming_detected = is_repetitive and is_stagnant and sufficient_duration
    local false_positive_override = is_making_progress or is_on_ramp_or_hill or has_speed_variation or is_following_track
    
    -- Additional confidence check - don't flag if analysis confidence is low
    local high_confidence_detection = progress_data.analysis_confidence ~= "LOW"
    
    -- Final decision - NO MORE SPAM LOGGING
    local farming_detected = base_farming_detected and not false_positive_override and high_confidence_detection
    
    return farming_detected
end

-- =============================================================================
-- FARMING STATE MANAGEMENT
-- =============================================================================

-- Update anti-farming system (main entry point)
function M.update_anti_farming(car_angular_velocity, car_position, speed, dt)
    if not vars.is_drifting then return end
    
    -- Add samples for analysis
    M.add_rotation_sample(car_angular_velocity)
    M.add_position_sample(car_position, speed)
    
    -- Check for farming using intelligent analysis
    local is_farming_detected = M.detect_intelligent_farming()
    
    -- Handle farming state changes
    if is_farming_detected and not vars.is_farming then
        M.start_farming_penalty()
    elseif not is_farming_detected and vars.is_farming then
        M.check_farming_end()
    end
end

-- Start farming penalty - ONLY LOG WHEN FARMING IS DETECTED
function M.start_farming_penalty()
    vars.is_farming = true
    utils.set_notification("STOP FARMING!")
    
    -- ONLY log when farming is actually detected
    utils.debug_log("🚨 FARMING DETECTED!", "FARM")
end

-- Check if farming should end - ONLY LOG WHEN FARMING ENDS
function M.check_farming_end()
    local variance = M.calculate_rotation_variance()
    local progress_data = M.analyze_track_progress()
    
    -- End farming if rotation becomes varied OR legitimate progress is detected
    if variance > vars.rotation_variance_threshold * 1.5 or progress_data.is_progressing then
        vars.is_farming = false
        utils.debug_log("✅ Farming ended", "FARM")
    end
end

-- =============================================================================
-- FARMING ANALYTICS AND STATISTICS
-- =============================================================================

-- Get comprehensive farming analysis for debugging/display
function M.get_farming_analysis()
    if not vars.is_drifting then
        return {
            status = "NOT_DRIFTING",
            analysis_available = false
        }
    end
    
    local rotation_variance = M.calculate_rotation_variance()
    local progress_data = M.analyze_track_progress()
    local time_since_significant = os.clock() - vars.last_significant_rotation_time
    
    return {
        status = vars.is_farming and "FARMING" or "LEGITIMATE",
        analysis_available = true,
        rotation = {
            variance = rotation_variance,
            samples = #vars.rotation_samples,
            time_since_significant = time_since_significant,
            total_magnitude = vars.total_rotation_magnitude
        },
        progress = progress_data,
        thresholds = {
            rotation_variance = vars.rotation_variance_threshold,
            distance_traveled = vars.distance_traveled_threshold,
            elevation_change = vars.elevation_change_threshold,
            speed_variance = vars.speed_variance_threshold
        },
        timing = {
            drift_time = vars.total_drift_time,
            detection_delay = vars.farming_detection_delay
        }
    }
end

-- Get farming statistics summary for display
function M.get_farming_stats_summary()
    local analysis = M.get_farming_analysis()
    if not analysis.analysis_available then
        return "No analysis data available"
    end
    
    return string.format("Status: %s | Variance: %.3f | Distance: %.1fm | Confidence: %s", 
                        analysis.status, 
                        analysis.rotation.variance, 
                        analysis.progress.distance_traveled,
                        analysis.progress.analysis_confidence)
end

-- =============================================================================
-- FARMING DETECTION TUNING
-- =============================================================================

-- Adjust farming detection sensitivity
function M.adjust_sensitivity(sensitivity_level)
    if sensitivity_level == "strict" then
        vars.rotation_variance_threshold = 0.08  -- More sensitive
        vars.farming_detection_delay = 3.0
        utils.debug_log("Applied STRICT farming detection", "FARM")
        
    elseif sensitivity_level == "relaxed" then
        vars.rotation_variance_threshold = 0.20  -- Less sensitive
        vars.farming_detection_delay = 7.0
        utils.debug_log("Applied RELAXED farming detection", "FARM")
        
    elseif sensitivity_level == "default" then
        vars.rotation_variance_threshold = 0.12
        vars.farming_detection_delay = 5.0
        utils.debug_log("Applied DEFAULT farming detection", "FARM")
        
    else
        utils.debug_log("Unknown sensitivity level: " .. tostring(sensitivity_level), "FARM")
    end
end

-- Get current detection configuration
function M.get_detection_config()
    return {
        rotation_variance_threshold = vars.rotation_variance_threshold,
        farming_detection_delay = vars.farming_detection_delay,
        distance_traveled_threshold = vars.distance_traveled_threshold,
        elevation_change_threshold = vars.elevation_change_threshold,
        speed_variance_threshold = vars.speed_variance_threshold,
        max_rotation_samples = vars.max_rotation_samples,
        max_position_samples = vars.max_position_samples
    }
end

-- =============================================================================
-- FALSE POSITIVE PREVENTION SCENARIOS
-- =============================================================================

-- Test specific scenarios that should NOT be flagged as farming
function M.test_scenario_detection(scenario_name)
    local analysis = M.get_farming_analysis()
    if not analysis.analysis_available then
        return "No data to test"
    end
    
    local results = {}
    
    if scenario_name == "long_sweeping_corner" then
        -- Should have: forward progress, moderate elevation change, speed variance
        results.should_pass = analysis.progress.distance_traveled > 30 and analysis.progress.speed_variance > 3
        results.reason = "Long sweeping corner should show forward progress and speed variance"
        
    elseif scenario_name == "360_ramp" then
        -- Should have: significant elevation change
        results.should_pass = analysis.progress.elevation_change > 1.5
        results.reason = "360° ramp should show significant elevation change"
        
    elseif scenario_name == "banked_turn" then
        -- Should have: elevation change AND forward progress
        results.should_pass = analysis.progress.elevation_change > 1.0 and analysis.progress.distance_traveled > 20
        results.reason = "Banked turn should show both elevation change and forward progress"
        
    elseif scenario_name == "parking_lot_donuts" then
        -- Should fail: minimal progress, low speed variance, repetitive rotation
        results.should_pass = false
        results.expected_farming = analysis.rotation.variance < 0.15 and analysis.progress.distance_traveled < 20
        results.reason = "Parking lot donuts should be detected as farming"
        
    else
        return "Unknown scenario: " .. tostring(scenario_name)
    end
    
    results.current_status = analysis.status
    results.analysis = analysis
    
    return results
end

-- =============================================================================
-- MODULE INITIALIZATION
-- =============================================================================

function M.initialize()
    -- Initialize timing
    vars.last_significant_rotation_time = os.clock()
    
    utils.debug_log("Anti-farming module initialized with intelligent false positive prevention", "INIT")
end

return M
