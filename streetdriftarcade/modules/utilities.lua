-- modules/utilities.lua - Helper Functions and Utilities
-- Save as: assettocorsa/apps/lua/streetdriftarcade/modules/utilities.lua

local M = {}

-- =============================================================================
-- NUMBER FORMATTING
-- =============================================================================

-- Number formatting function with safety checks
function M.format_number(num)
    if not num or num == nil then
        return "0"
    end
    
    -- Convert to number if it's a string
    if type(num) == "string" then
        num = tonumber(num) or 0
    end
    
    -- Ensure it's a valid number
    if type(num) ~= "number" or num ~= num then  -- Check for NaN
        return "0"
    end
    
    local formatted = tostring(math.floor(num))
    local k = 0
    while k < string.len(formatted) do
        k = k + 4
        if k <= string.len(formatted) then
            formatted = string.sub(formatted, 1, string.len(formatted) - k + 1) .. "," .. string.sub(formatted, string.len(formatted) - k + 2)
        end
    end
    return formatted
end

-- =============================================================================
-- DISTANCE CALCULATIONS
-- =============================================================================

-- Helper function to calculate distance between two 3D points
function M.calculate_distance_3d(pos1, pos2)
    if not pos1 or not pos2 or not pos1.x or not pos1.z or not pos2.x or not pos2.z then
        return 0
    end
    
    local dx = pos1.x - pos2.x
    local dz = pos1.z - pos2.z
    local dy = (pos1.y or 0) - (pos2.y or 0)  -- Y is elevation
    
    return math.sqrt(dx*dx + dz*dz + dy*dy)
end

-- Helper function to calculate 2D distance (ignoring elevation)
function M.calculate_distance_2d(pos1, pos2)
    if not pos1 or not pos2 or not pos1.x or not pos1.z or not pos2.x or not pos2.z then
        return 0
    end
    
    local dx = pos1.x - pos2.x
    local dz = pos1.z - pos2.z
    
    return math.sqrt(dx*dx + dz*dz)
end

-- =============================================================================
-- CAR DATA SAFETY FUNCTIONS
-- =============================================================================

-- Safely get car speed with error handling
function M.get_safe_speed(car)
    if car.speedKmh and type(car.speedKmh) == "number" then
        return car.speedKmh
    end
    return 0
end

-- Safely get car RPM with error handling
function M.get_safe_rpm(car)
    if car.rpm and type(car.rpm) == "number" then
        return car.rpm
    end
    return 0
end

-- Safely get car gear with error handling
function M.get_safe_gear(car)
    if car.gear and type(car.gear) == "number" then
        return car.gear
    end
    return 0
end

-- =============================================================================
-- TIMER MANAGEMENT
-- =============================================================================

-- Update all display and notification timers
function M.update_timers(dt)
    -- Update pulse timer for flashing notifications
    vars.pulse_timer = vars.pulse_timer + dt
    if vars.pulse_timer > 0.3 then
        vars.pulse_state = not vars.pulse_state
        vars.pulse_timer = 0.0
    end
    
    -- Update notification display timer
    if vars.notification_text ~= "" then
        vars.notification_timer = vars.notification_timer + dt
        if vars.notification_timer > vars.notification_display_time then
            vars.notification_text = ""
            vars.notification_timer = 0
        end
    end
end

-- Set a notification with automatic timing
function M.set_notification(text, duration)
    vars.notification_text = text
    vars.notification_timer = 0.0
    if duration then
        vars.notification_display_time = duration
    else
        vars.notification_display_time = 2.0  -- Default 2 seconds
    end
end

-- =============================================================================
-- COLOR UTILITIES
-- =============================================================================

-- Get color based on total points for UI theming - simplified without ranking
function M.get_points_color(points)
    -- Simple color progression without ranking system
    if points >= 10000000 then
        return rgbm(0.0, 1.0, 1.0, 1.0)  -- Cyan for very high scores
    elseif points >= 1000000 then
        return rgbm(1.0, 1.0, 0.0, 1.0)  -- Yellow for high scores
    else
        return rgbm(1.0, 1.0, 1.0, 1.0)  -- White for normal scores
    end
end

-- Get notification color based on notification type
function M.get_notification_color(notification_text, pulse_state)
    local base_color, pulse_color
    
    -- Special colors for different notification types
    if string.find(notification_text, "SKILL BONUS") then
        base_color = vars.colors.cyan
        pulse_color = {r=0, g=0.7, b=0.7, a=1}
    elseif string.find(notification_text, "SPINOUT") then
        base_color = {r=1, g=0, b=1, a=1}  -- Magenta
        pulse_color = {r=0.7, g=0, b=0.7, a=1}
    elseif string.find(notification_text, "FARMING") then
        base_color = vars.colors.orange
        pulse_color = {r=0.8, g=0.3, b=0, a=1}
    else
        -- Default yellow flash
        base_color = vars.colors.yellow
        pulse_color = {r=0.7, g=0.7, b=0.5, a=1}
    end
    
    -- Choose color based on pulse state and convert to rgbm()
    local chosen_color = pulse_state and base_color or pulse_color
    return rgbm(chosen_color.r, chosen_color.g, chosen_color.b, chosen_color.a)
end

-- =============================================================================
-- ANGLE AND DIRECTION UTILITIES
-- =============================================================================

-- Calculate slip angle safely with error handling
function M.calculate_slip_angle(car)
    local angle = 0
    local angle_with_direction = 0
    local lateral_velocity = 0
    
    pcall(function()
        local local_vel = car.localVelocity
        if local_vel and local_vel.x and local_vel.z then
            if math.abs(local_vel.z) > 1.0 then
                angle_with_direction = math.deg(math.atan2(local_vel.x, local_vel.z))
                angle = math.abs(angle_with_direction)
                lateral_velocity = math.abs(local_vel.x)
            end
            if angle > 180 then
                angle = 0
                angle_with_direction = 0
            end
        end
    end)
    
    return angle, angle_with_direction, lateral_velocity
end

-- Determine drift direction from angle
function M.get_drift_direction(angle, angle_with_direction)
    if angle > vars.transition_threshold then
        if angle_with_direction > 0 then
            return 1  -- Right
        else
            return -1  -- Left
        end
    end
    return 0  -- Straight
end

-- Get direction text for display
function M.get_direction_text(angle, angle_with_direction, is_drifting)
    local direction_threshold = is_drifting and vars.transition_threshold or 1.0
    
    if angle > direction_threshold then
        if is_drifting then
            -- When drifting, show drift direction normally
            if angle_with_direction > 0 then
                return "RIGHT 👉"
            else
                return "LEFT  👈"  -- Extra space to match "RIGHT"
            end
        else
            -- When not drifting, flip the direction
            if angle_with_direction > 0 then
                return "LEFT  👈"  -- Flipped!
            else
                return "RIGHT 👉"  -- Flipped!
            end
        end
    else
        return "STRAIGHT ⬆️"
    end
end

-- =============================================================================
-- PHYSICS UTILITIES
-- =============================================================================

-- Get forward velocity safely
function M.get_forward_velocity(car)
    local forward_velocity = 0
    pcall(function()
        local local_vel = car.localVelocity
        if local_vel and local_vel.z then
            forward_velocity = local_vel.z
        end
    end)
    return forward_velocity
end

-- Get car angular velocity safely
function M.get_car_angular_velocity(car)
    local car_angular_velocity = nil
    
    -- Try to get from car first
    pcall(function()
        if car.localAngularVelocity then
            car_angular_velocity = car.localAngularVelocity
        end
    end)
    
    -- Fallback: try to get from physics data
    if not car_angular_velocity then
        pcall(function()
            local physics = ac.accessCarPhysics()
            if physics and physics.localAngularVelocity then
                car_angular_velocity = physics.localAngularVelocity
            end
        end)
    end
    
    -- Final fallback: estimate from lateral velocity
    if not car_angular_velocity then
        local lateral_velocity = 0
        pcall(function()
            local local_vel = car.localVelocity
            if local_vel and local_vel.x then
                lateral_velocity = local_vel.x
            end
        end)
        
        local speed = M.get_safe_speed(car)
        local estimated_yaw_rate = 0
        if speed > 10 then
            estimated_yaw_rate = lateral_velocity / speed
        end
        
        car_angular_velocity = {
            x = 0,
            y = estimated_yaw_rate,
            z = 0
        }
    end
    
    return car_angular_velocity
end

-- =============================================================================
-- VALIDATION UTILITIES
-- =============================================================================

-- Check if a number is valid (not nil, not NaN, is a number)
function M.is_valid_number(num)
    return num and type(num) == "number" and num == num
end

-- Clamp a value between min and max
function M.clamp(value, min_val, max_val)
    if not M.is_valid_number(value) then return min_val end
    if value < min_val then return min_val end
    if value > max_val then return max_val end
    return value
end

-- Linear interpolation between two values
function M.lerp(a, b, t)
    t = M.clamp(t, 0, 1)
    return a + (b - a) * t
end

-- =============================================================================
-- DEBUG UTILITIES
-- =============================================================================

-- Log with timestamp and formatting
function M.debug_log(message, category)
    local timestamp = string.format("%.3f", os.clock())
    local prefix = category and string.format("[%s]", category) or "[DEBUG]"
    ac.log(string.format("%s %s %s", timestamp, prefix, message))
end

-- Log car state for debugging
function M.debug_car_state(car, speed, angle)
    M.debug_log(string.format("Speed: %.1f km/h, Angle: %.1f°, Gear: %d, RPM: %.0f", 
                speed, angle, M.get_safe_gear(car), M.get_safe_rpm(car)), "CAR")
end

-- =============================================================================
-- MODULE INITIALIZATION
-- =============================================================================

function M.initialize()
    ac.log("✅ Utilities module initialized")
end

return M
