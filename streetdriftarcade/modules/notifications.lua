-- modules/notifications.lua - Queue-based Notification System with Animations
-- Save as: assettocorsa/apps/lua/streetdriftarcade/modules/notifications.lua

local M = {}
local vars = require('modules/variables')
local utils = require('modules/utilities')

-- =============================================================================
-- NOTIFICATION QUEUE SYSTEM
-- =============================================================================

-- Notification queue and current display state
local notification_queue = {}
local current_notification = nil
local animation_state = "idle" -- "idle", "pop_in", "showing", "pop_out"
local animation_timer = 0.0

-- Animation configuration
local ANIMATION_CONFIG = {
    pop_in_duration = 0.3,     -- Time for pop-in effect
    display_duration = 2.0,    -- Time to show notification
    pop_out_duration = 0.2,    -- Time for pop-out effect
    
    -- Easing and effects
    overshoot_amount = 1.2,    -- Scale overshoot (120% max)
    bounce_back = 0.95,        -- Settle to 95% 
    final_scale = 1.0,         -- Final display scale
    
    -- Pop-out effect
    pop_out_scale = 0.0,       -- Scale down to 0
    fade_out_alpha = 0.0,      -- Fade to transparent
}

-- =============================================================================
-- QUEUE MANAGEMENT
-- =============================================================================

-- Add notification to queue
function M.add_notification(text, duration, priority)
    local notification = {
        text = text,
        duration = duration or ANIMATION_CONFIG.display_duration,
        priority = priority or 1, -- Higher number = higher priority
        timestamp = os.clock()
    }
    
    -- Insert based on priority (higher priority goes first)
    local inserted = false
    for i = 1, #notification_queue do
        if notification.priority > notification_queue[i].priority then
            table.insert(notification_queue, i, notification)
            inserted = true
            break
        end
    end
    
    if not inserted then
        table.insert(notification_queue, notification)
    end
    
    utils.debug_log(string.format("Notification queued: '%s' (Priority: %d, Queue: %d)", 
                    text, priority, #notification_queue), "NOTIF")
end

-- Get next notification from queue
local function get_next_notification()
    if #notification_queue > 0 then
        return table.remove(notification_queue, 1)
    end
    return nil
end

-- Clear all notifications (emergency clear)
function M.clear_all_notifications()
    notification_queue = {}
    current_notification = nil
    animation_state = "idle"
    animation_timer = 0.0
    utils.debug_log("All notifications cleared", "NOTIF")
end

-- =============================================================================
-- ANIMATION SYSTEM
-- =============================================================================

-- Easing functions for smooth animations
local function ease_out_back(t)
    local c1 = 1.70158
    local c3 = c1 + 1
    return 1 + c3 * math.pow(t - 1, 3) + c1 * math.pow(t - 1, 2)
end

local function ease_in_back(t)
    local c1 = 1.70158
    local c3 = c1 + 1
    return c3 * t * t * t - c1 * t * t
end

-- Calculate current animation values
local function get_animation_values()
    local scale = 1.0
    local alpha = 1.0
    local y_offset = 0.0
    
    if animation_state == "pop_in" then
        local progress = animation_timer / ANIMATION_CONFIG.pop_in_duration
        progress = math.min(progress, 1.0)
        
        -- Smooth pop-in with overshoot
        local eased_progress = ease_out_back(progress)
        scale = eased_progress * ANIMATION_CONFIG.overshoot_amount
        
        -- Clamp to prevent too much overshoot
        if scale > ANIMATION_CONFIG.overshoot_amount then
            scale = ANIMATION_CONFIG.bounce_back
        end
        
        alpha = progress -- Fade in
        y_offset = (1.0 - progress) * -20 -- Slide down from above
        
    elseif animation_state == "showing" then
        scale = ANIMATION_CONFIG.final_scale
        alpha = 1.0
        y_offset = 0.0
        
    elseif animation_state == "pop_out" then
        local progress = animation_timer / ANIMATION_CONFIG.pop_out_duration
        progress = math.min(progress, 1.0)
        
        -- Fast pop-out with easing
        local eased_progress = ease_in_back(progress)
        scale = ANIMATION_CONFIG.final_scale * (1.0 - eased_progress)
        alpha = 1.0 - progress
        y_offset = eased_progress * 10 -- Slight upward movement
    end
    
    return {
        scale = scale,
        alpha = alpha,
        y_offset = y_offset
    }
end

-- =============================================================================
-- UPDATE SYSTEM
-- =============================================================================

-- Update notification system
function M.update(dt)
    if animation_state == "idle" then
        -- Try to start next notification
        if #notification_queue > 0 then
            current_notification = get_next_notification()
            if current_notification then
                animation_state = "pop_in"
                animation_timer = 0.0
                utils.debug_log(string.format("Starting notification: '%s'", 
                               current_notification.text), "NOTIF")
            end
        end
        
    elseif animation_state == "pop_in" then
        animation_timer = animation_timer + dt
        
        if animation_timer >= ANIMATION_CONFIG.pop_in_duration then
            animation_state = "showing"
            animation_timer = 0.0
        end
        
    elseif animation_state == "showing" then
        animation_timer = animation_timer + dt
        
        if animation_timer >= current_notification.duration then
            animation_state = "pop_out"
            animation_timer = 0.0
        end
        
    elseif animation_state == "pop_out" then
        animation_timer = animation_timer + dt
        
        if animation_timer >= ANIMATION_CONFIG.pop_out_duration then
            current_notification = nil
            animation_state = "idle"
            animation_timer = 0.0
        end
    end
end

-- =============================================================================
-- RENDERING INTERFACE
-- =============================================================================

-- Get current notification for rendering
function M.get_current_notification()
    if not current_notification or animation_state == "idle" then
        return nil
    end
    
    local animation_values = get_animation_values()
    
    return {
        text = current_notification.text,
        scale = animation_values.scale,
        alpha = animation_values.alpha,
        y_offset = animation_values.y_offset,
        animation_state = animation_state
    }
end

-- Check if notification system is active
function M.is_active()
    return current_notification ~= nil or #notification_queue > 0
end

-- Get queue status for debugging
function M.get_queue_status()
    return {
        queue_length = #notification_queue,
        current_state = animation_state,
        current_text = current_notification and current_notification.text or "none",
        animation_timer = animation_timer
    }
end

-- =============================================================================
-- CONVENIENCE FUNCTIONS
-- =============================================================================

-- Quick notification (normal priority)
function M.show(text, duration)
    M.add_notification(text, duration, 1)
end

-- High priority notification (shows first)
function M.show_priority(text, duration)
    M.add_notification(text, duration, 10)
end

-- Ultra high priority (emergency, clears queue)
function M.show_urgent(text, duration)
    M.clear_all_notifications()
    M.add_notification(text, duration, 100)
end

-- =============================================================================
-- LEGACY COMPATIBILITY
-- =============================================================================

-- Legacy function for backward compatibility
function M.set_notification(text, duration)
    M.show(text, duration)
end

-- =============================================================================
-- MODULE INITIALIZATION
-- =============================================================================

function M.initialize()
    notification_queue = {}
    current_notification = nil
    animation_state = "idle"
    animation_timer = 0.0
    
    utils.debug_log("Notification queue system initialized with smooth animations", "INIT")
end

return M