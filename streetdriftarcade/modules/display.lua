-- modules/display.lua - FIXED with perfect centering and vertical control
-- Save as: assettocorsa/apps/lua/streetdriftarcade/modules/display.lua


-- =============================================================================
-- PROPORTIONAL SCALING SYSTEM
-- =============================================================================

-- Base configuration designed for 4K (3840x2160)
local base_ui_config = {
    -- NOTIFICATION SYSTEM
    notification_size = 80,
    
    -- TOTAL POINTS SYSTEM
    total_points_label_size = 70,
    total_points_number_size = 70,
    
    -- DRIFT DISPLAY SYSTEM
    drift_label_size = 34,
    drift_number_size = 34,
    
    -- STATUS AND INFO SYSTEM
    status_info_size = 40,
    status_main_size = 40,
    
    -- RECORDS SYSTEM
    records_header_size = 28,
    records_label_size = 22,
    records_text_size = 22,
    
    -- ANGLE BONUS SYSTEM
    angle_bonus_size = 36,
    
    -- SPACING ADJUSTMENTS
    notification_y_spacing = 100,
    angle_bonus_y_spacing = 160,
    
    -- NOTIFICATION POSITIONING - EDIT THESE TO MOVE TOP-CENTER NOTIFICATIONS!
    notification_y_position = 70,        -- Change this to move up/down (50=higher, 100=lower)
    notification_center_offset = 0,      -- Change this to move left/right (-50=left, +50=right)
    
    -- TOP-LEFT POSITIONING - EDIT THESE TO MOVE TOTAL POINTS & DRIFT INFO!
    top_left_x_position = 90,            -- Horizontal position from left edge
    top_left_y_position = 70,            -- Vertical position from top edge
    
    -- TOTAL POINTS CONTROL
    total_points_label_x_offset = 0,     -- Extra horizontal offset for "TOTAL POINTS:" label
    total_points_number_x_offset = 460,  -- Horizontal offset for the numbers (460 = default spacing)
    total_points_number_y_offset = -4,   -- Vertical fine-tuning for numbers alignment
    
    -- DRIFT CONTROL
    drift_label_y_offset = 80,           -- Vertical spacing from total points to drift label
    drift_label_x_offset = 0,            -- Horizontal offset for "DRIFT:" label
    drift_number_x_offset = 108,         -- Horizontal offset for drift numbers
    drift_number_y_offset = -1,          -- Vertical fine-tuning for drift numbers
    
    -- CAR STATUS CONTROL (Speed, Angle, Direction)
    car_status_start_y_offset = 130,     -- Vertical spacing from total points to first car status line
    car_status_line_spacing = 50,        -- Vertical spacing between car status lines
    car_status_x_offset = 0,             -- Horizontal offset for all car status lines
    
    -- BOTTOM-LEFT POSITIONING - EDIT THESE TO MOVE PERSONAL RECORDS!
    bottom_left_x_position = 90,         -- Horizontal position from left edge
    bottom_left_y_from_bottom = 250,     -- Vertical position from bottom edge
    
    -- PERSONAL RECORDS CONTROL
    records_header_y_offset = 0,         -- Vertical offset for "PERSONAL RECORDS:" header
    records_header_x_offset = 0,         -- Horizontal offset for header
    records_first_line_y_offset = 60,    -- Spacing from header to first record line
    records_line_spacing = 40,           -- Vertical spacing between record lines
    records_label_x_offset = 0,          -- Horizontal offset for record labels (🎯 PURE SKILL:)
    records_value_x_offset = 180,        -- Horizontal offset for record values (numbers)
    records_value_y_fine_tune = 4,       -- Fine-tune vertical alignment of values
    
    -- BOTTOM-RIGHT POSITIONING - EDIT THESE TO MOVE STATUS SECTION!
    bottom_right_x_from_right = 450,     -- Horizontal position from right edge
    bottom_right_y_from_bottom = 250,    -- Vertical position from bottom edge
    
    -- STATUS SECTION CONTROL
    status_header_y_offset = 0,          -- Vertical offset for "STATUS" header
    status_header_x_offset = 0,          -- Horizontal offset for header
    status_first_line_y_offset = 60,     -- Spacing from header to first status line
    status_line_spacing = 75,            -- Vertical spacing between status lines
    status_text_x_offset = 0,            -- Horizontal offset for all status text
}

-- Reference resolution (4K)
local REFERENCE_WIDTH = 3840
local REFERENCE_HEIGHT = 2160

-- Current scaled configuration (will be calculated)
local ui_config = {}
local current_scale_factor = 1.0

-- Calculate scaling factor based on screen resolution
function calculate_scale_factor(screen_width, screen_height)
    -- Use the smaller dimension to ensure UI fits on screen
    local width_ratio = screen_width / REFERENCE_WIDTH
    local height_ratio = screen_height / REFERENCE_HEIGHT
    
    -- Use the smaller ratio to ensure everything fits
    local scale_factor = math.min(width_ratio, height_ratio)
    
    -- Apply some bounds to prevent too small or too large scaling
    scale_factor = math.max(0.3, math.min(scale_factor, 2.0))
    
    return scale_factor
end

-- Apply scaling to all UI configuration values
function apply_scaling(scale_factor)
    current_scale_factor = scale_factor
    
    -- Scale all size values
    for key, value in pairs(base_ui_config) do
        if type(value) == "number" then
            ui_config[key] = math.floor(value * scale_factor)
        else
            ui_config[key] = value
        end
    end
    
    -- Ensure minimum readable sizes
    ui_config.notification_size = math.max(ui_config.notification_size, 20)
    ui_config.total_points_label_size = math.max(ui_config.total_points_label_size, 16)
    ui_config.records_text_size = math.max(ui_config.records_text_size, 12)
end

-- Initialize scaling for given screen dimensions
function set_screen_dimensions(screen_width, screen_height)
    local scale_factor = calculate_scale_factor(screen_width, screen_height)
    apply_scaling(scale_factor)
    
    ac.log(string.format("🎨 UI Scaling: %dx%d -> %.2fx scale", screen_width, screen_height, scale_factor))
    ac.log(string.format("📏 Notification: %dpx, Total Points: %dpx, Records: %dpx", 
           ui_config.notification_size, ui_config.total_points_label_size, ui_config.records_text_size))
end

-- =============================================================================
-- SCALED POSITIONING SYSTEM
-- =============================================================================

-- Calculate scaled positions based on screen size
function get_scaled_positions(screen_width, screen_height)
    local scale = current_scale_factor
    
    return {
        top_left = vec2(50 * scale, 50 * scale),
        top_center = vec2(screen_width / 2 + (ui_config.notification_center_offset or 0), ui_config.notification_y_position * scale),
        bottom_left = vec2(50 * scale, screen_height - (200 * scale)),
        bottom_right = vec2(screen_width - (350 * scale), screen_height - (200 * scale)),
        
        -- Scaled offsets
        drift_y_offset = 80 * scale,
        status_y_offset = 50 * scale,
        records_y_spacing = 40 * scale,
        shadow_offset = math.max(1, 3 * scale),
    }
end

-- =============================================================================
-- CORE RENDERING FUNCTIONS (Updated with scaling)
-- =============================================================================

-- Helper function to draw text with scaled shadow
function draw_text_with_shadow(font, text, size, position, color, shadow_offset)
    shadow_offset = shadow_offset or math.max(1, 2 * current_scale_factor)
    local shadow_color = rgbm(0, 0, 0, 0.6)
    
    -- Draw shadow first
    ui.pushDWriteFont(font)
    ui.dwriteDrawText(text, size, vec2(position.x + shadow_offset, position.y + shadow_offset), shadow_color)
    ui.popDWriteFont()
    
    -- Draw main text
    ui.pushDWriteFont(font)
    ui.dwriteDrawText(text, size, position, color)
    ui.popDWriteFont()
end

-- Helper function to get perfectly centered X position for text
function get_centered_x_position(text, font, size, screen_width, center_offset)
    center_offset = center_offset or 0
    
    ui.pushDWriteFont(font)
    local text_size = ui.measureDWriteText(text, size)
    ui.popDWriteFont()
    
    return (screen_width / 2) - (text_size.x / 2) + center_offset
end

-- Clean notification text by removing point values
function clean_notification_text(notification_text)
    if not notification_text or notification_text == "" then
        return ""
    end
    
    -- Remove point values like "+25,000", "+5,000", etc.
    local cleaned = string.gsub(notification_text, "%s*%+[%d,]+", "")
    
    return cleaned
end

-- Update animation timers
function update_animations(dt)
    if vars.pb_drift_animation_timer > 0 then
        vars.pb_drift_animation_timer = vars.pb_drift_animation_timer - dt
    end
    if vars.pb_total_animation_timer > 0 then
        vars.pb_total_animation_timer = vars.pb_total_animation_timer - dt
    end
    if vars.pb_final_animation_timer > 0 then
        vars.pb_final_animation_timer = vars.pb_final_animation_timer - dt
    end
end

end

ac.log("🔍 update_animations function created: " .. tostring(update_animations))

-- TOP-LEFT: Total Points (with individual positioning controls)
function render_top_left_total_points(screen_width, screen_height)
    local positions = get_scaled_positions(screen_width, screen_height)
    local pos = positions.top_left
    
    local total_label = "TOTAL POINTS: "
    local total_number = utils.format_number(vars.total_banked_points)
    
    -- Fixed white color - no more ranking-based color changes
    local total_color = rgbm(1, 0.8, 0, 1)
    
    -- Add pulsing effect for PB animation only
    if vars.pb_total_animation_timer > 0 then
        local pulse_intensity = math.sin(vars.pb_total_animation_timer * 10) * 0.3 + 0.7
        total_color = rgbm(total_color.r * pulse_intensity, total_color.g, total_color.b * pulse_intensity, 1)
    end
    
    -- Draw "TOTAL POINTS:" label with individual positioning
    local label_pos = vec2(pos.x + ui_config.total_points_label_x_offset, pos.y)
    draw_text_with_shadow('fonts/Mogra-Regular.ttf', total_label, ui_config.total_points_label_size, 
                         label_pos, total_color, positions.shadow_offset)
    
    -- Draw numbers with individual positioning
    local number_pos = vec2(pos.x + ui_config.total_points_number_x_offset, pos.y + ui_config.total_points_number_y_offset)
    draw_text_with_shadow('fonts/Robotica.ttf', total_number, ui_config.total_points_number_size, 
                         number_pos, total_color, positions.shadow_offset)
    
    -- DRIFT SECTION - with individual control
    local is_drifting = vars.is_drifting or vars.actively_drifting or false
    
    local drift_label_pos = vec2(pos.x + ui_config.drift_label_x_offset, pos.y + ui_config.drift_label_y_offset)
    local drift_label = "DRIFT:"
    local drift_number = utils.format_number(vars.current_drift_points or 0)
    local drift_color = rgbm(1, 1, 1, 1)
    
    -- Add pulsing effect for drift PB animation
    if vars.pb_drift_animation_timer > 0 then
        local pulse_intensity = math.sin(vars.pb_drift_animation_timer * 10) * 0.3 + 0.7
        drift_color = rgbm(drift_color.r * pulse_intensity, 1, drift_color.b * pulse_intensity, 1)
    end
    
    -- Draw drift label with individual positioning
    draw_text_with_shadow('fonts/Mogra-Regular.ttf', drift_label, ui_config.drift_label_size, 
                         drift_label_pos, drift_color, positions.shadow_offset)
    
    -- Draw drift numbers with individual positioning
    local drift_number_pos = vec2(pos.x + ui_config.drift_number_x_offset, pos.y + ui_config.drift_label_y_offset + ui_config.drift_number_y_offset)
    draw_text_with_shadow('fonts/Robotica.ttf', drift_number, ui_config.drift_number_size, 
                         drift_number_pos, drift_color, positions.shadow_offset)
    
    -- CAR STATUS SECTION - with individual control
    local car = ac.getCar(0)
    if car then
        local speed = utils.get_safe_speed(car)
        local angle, angle_with_direction, lateral_velocity = utils.calculate_slip_angle(car)
        
        -- Calculate car status positions
        local status_start_y = pos.y + ui_config.car_status_start_y_offset
        local status_x = pos.x + ui_config.car_status_x_offset
        
        local speed_text = string.format("🏎️ %.0f KM/H", speed)
        local angle_text = string.format("📐 %.0f°", angle)
        
        -- Get direction text and extract emoji + text parts
        local direction_text = utils.get_direction_text(angle, angle_with_direction, is_drifting)
        local direction_emoji = ""
        local direction_label = ""
        
        -- Parse the direction text to separate emoji and text
        if direction_text:find("⬆️") then
            direction_emoji = "⬆️"
            direction_label = " STRAIGHT"
        elseif direction_text:find("👉") then
            direction_emoji = "👉"
            direction_label = " RIGHT"
        elseif direction_text:find("👈") then
            direction_emoji = "👈"
            direction_label = " LEFT"
        elseif direction_text:find("RIGHT") then
            direction_emoji = "👉"
            direction_label = " RIGHT"
        elseif direction_text:find("LEFT") then
            direction_emoji = "👈"
            direction_label = " LEFT"
        else
            direction_label = direction_text
        end
        
        -- Use different colors based on drift state
        local info_color = is_drifting and rgbm(0, 1, 0.8, 1) or rgbm(1, 1, 1, 1)
        
        -- Draw each car status line with individual positioning
        local speed_pos = vec2(status_x, status_start_y)
        local angle_pos = vec2(status_x, status_start_y + ui_config.car_status_line_spacing)
        local direction_pos = vec2(status_x, status_start_y + ui_config.car_status_line_spacing * 2)
        
        draw_text_with_shadow('fonts/Mogra-Regular.ttf', speed_text, ui_config.status_info_size, 
                             speed_pos, info_color, positions.shadow_offset)
        draw_text_with_shadow('fonts/Mogra-Regular.ttf', angle_text, ui_config.status_info_size, 
                             angle_pos, info_color, positions.shadow_offset)
        
        -- Draw direction with emoji
        local direction_text_formatted = direction_emoji .. direction_label
        draw_text_with_shadow('fonts/Mogra-Regular.ttf', direction_text_formatted, ui_config.status_info_size, 
                             direction_pos, info_color, positions.shadow_offset)
    end
end

-- TOP-CENTER: Notifications and Angle Bonus System (FIXED CENTERING & VERTICAL)
function render_top_center_notifications(screen_width, screen_height)
    -- Calculate position with proper scaling
    local center_x = screen_width / 2 + (ui_config.notification_center_offset or 0)
    local pos_y = ui_config.notification_y_position or (50 * current_scale_factor)
    local pos = vec2(center_x, pos_y)
    
    -- Main notification system - PERFECTLY CENTERED WITH CLEAN TEXT
    if vars.notification_text and vars.notification_text ~= "" then
        local flash_color = utils.get_notification_color(vars.notification_text, vars.pulse_state)
        
        -- CLEAN the notification text by removing point values
        local clean_notification = clean_notification_text(vars.notification_text)
        local notification_display = "" .. clean_notification .. ""
        
        -- Get perfectly centered X position
        local centered_x = get_centered_x_position(notification_display, 'fonts/Mogra-Regular.ttf', 
                                                  ui_config.notification_size, screen_width, 
                                                  ui_config.notification_center_offset or 0)
        
        local shadow_offset = math.max(1, 3 * current_scale_factor)
        draw_text_with_shadow('fonts/Mogra-Regular.ttf', notification_display, ui_config.notification_size, 
                             vec2(centered_x, pos_y), flash_color, shadow_offset)
    end
    
    -- Record breaking animation - PROPERLY CENTERED AND POSITIONED
    if vars.pb_drift_animation_timer > 0 or vars.pb_total_animation_timer > 0 or vars.pb_final_animation_timer > 0 then
        local record_y = pos_y + (ui_config.notification_y_spacing or (100 * current_scale_factor))
        local pulse = math.sin((vars.pb_drift_animation_timer + vars.pb_total_animation_timer + vars.pb_final_animation_timer) * 15) * 0.5 + 0.5
        local record_color = rgbm(1, 0.8 + pulse * 0.2, 0.2 + pulse * 0.3, 1)
        
        local record_text = "🏆 NEW RECORD! 🏆"
        local record_size = math.floor(36 * current_scale_factor)
        
        -- Get perfectly centered X position for record notification
        local record_centered_x = get_centered_x_position(record_text, 'fonts/Mogra-Regular.ttf', 
                                                         record_size, screen_width, 
                                                         ui_config.notification_center_offset or 0)
        
        local shadow_offset = math.max(1, 3 * current_scale_factor)
        draw_text_with_shadow('fonts/Mogra-Regular.ttf', record_text, record_size, 
                             vec2(record_centered_x, record_y), record_color, shadow_offset)
    end
    
    -- Live angle bonus display area - PERFECTLY CENTERED (Future animations will go here)
    -- This space is now reserved for your future animation ideas!
end

-- BOTTOM-LEFT: Personal Records (with individual positioning controls)
function render_bottom_left_records(screen_width, screen_height)
    -- Calculate position directly from base config (like we do for top-center)
    local pos = vec2(ui_config.bottom_left_x_position, screen_height - ui_config.bottom_left_y_from_bottom)
    local shadow_offset = math.max(1, 3 * current_scale_factor)
    
    -- Header with individual positioning
    local header_pos = vec2(pos.x + ui_config.records_header_x_offset, pos.y + ui_config.records_header_y_offset)
    draw_text_with_shadow('fonts/Mogra-Regular.ttf', "🏆 PERSONAL RECORDS:", ui_config.records_header_size, 
                         header_pos, rgbm(0.8, 0.8, 1, 1), shadow_offset)
    
    local pb_label_color = rgbm(0.8, 0.8, 1, 1)
    
    -- Get animation colors
    local drift_color = rgbm(0.8, 0.8, 1, 1)
    local total_color = rgbm(0.8, 0.8, 1, 1)
    local final_color = rgbm(0.8, 0.8, 1, 1)
    
    -- Apply pulsing animations
    if vars.pb_drift_animation_timer > 0 then
        local pulse = math.sin(vars.pb_drift_animation_timer * 15) * 0.5 + 0.5
        drift_color = rgbm(0.2 + pulse * 0.8, 1, 0.2 + pulse * 0.8, 1)
    end
    
    if vars.pb_total_animation_timer > 0 then
        local pulse = math.sin(vars.pb_total_animation_timer * 15) * 0.5 + 0.5
        total_color = rgbm(1, 0.8 + pulse * 0.2, 0.2 + pulse * 0.3, 1)
    end
    
    if vars.pb_final_animation_timer > 0 then
        local pulse = math.sin(vars.pb_final_animation_timer * 15) * 0.5 + 0.5
        final_color = rgbm(0.2 + pulse * 0.3, 0.2 + pulse * 0.8, 1, 1)
    end
    
    -- Get live pure skill info
    local pure_skill_info = records.get_live_pure_skill_info()
    local pure_skill_color = pure_skill_info.color
    if vars.pb_drift_animation_timer > 0 then
        local pulse = math.sin(vars.pb_drift_animation_timer * 15) * 0.5 + 0.5
        pure_skill_color = rgbm(0.2 + pulse * 0.8, 1, 0.2 + pulse * 0.8, 1)
    elseif not pure_skill_color or pure_skill_color.r == 0 and pure_skill_color.g == 0 and pure_skill_color.b == 0 then
        pure_skill_color = rgbm(0.8, 0.8, 1, 1)
    end
    
    -- Calculate positions for each record line
    local first_line_y = pos.y + ui_config.records_first_line_y_offset
    local label_x = pos.x + ui_config.records_label_x_offset
    local value_x = pos.x + ui_config.records_value_x_offset
    
    -- Pure Skill Record
    local pure_skill_label_pos = vec2(label_x, first_line_y)
    local pure_skill_value_pos = vec2(value_x, first_line_y + ui_config.records_value_y_fine_tune)
    
    draw_text_with_shadow('fonts/Mogra-Regular.ttf', "🎯 PURE SKILL:", ui_config.records_label_size, 
                         pure_skill_label_pos, pb_label_color, shadow_offset)
    draw_text_with_shadow('fonts/Robotica.ttf', pure_skill_info.text, ui_config.records_text_size, 
                         pure_skill_value_pos, pure_skill_color, shadow_offset)
    
    -- Best Run Record
    local best_run_y = first_line_y + ui_config.records_line_spacing
    local best_run_label_pos = vec2(label_x, best_run_y)
    local best_run_value_pos = vec2(value_x, best_run_y + ui_config.records_value_y_fine_tune)
    
    draw_text_with_shadow('fonts/Mogra-Regular.ttf', "🏁 BEST RUN:", ui_config.records_label_size, 
                         best_run_label_pos, pb_label_color, shadow_offset)
    draw_text_with_shadow('fonts/Robotica.ttf', utils.format_number(vars.all_time_best_final_score), ui_config.records_text_size, 
                         best_run_value_pos, final_color, shadow_offset)
    
    -- Best Session Record
    local best_session_y = first_line_y + ui_config.records_line_spacing * 2
    local best_session_label_pos = vec2(label_x, best_session_y)
    local best_session_value_pos = vec2(value_x, best_session_y + ui_config.records_value_y_fine_tune)
    
    draw_text_with_shadow('fonts/Mogra-Regular.ttf', "📈 BEST SESSION:", ui_config.records_label_size, 
                         best_session_label_pos, pb_label_color, shadow_offset)
    draw_text_with_shadow('fonts/Robotica.ttf', utils.format_number(vars.all_time_best_total_points), ui_config.records_text_size, 
                         best_session_value_pos, total_color, shadow_offset)
end

-- BOTTOM-RIGHT: Status Information (with individual positioning controls)
function render_bottom_right_status(screen_width, screen_height)
    -- Calculate position directly from base config (like we do for top-center)
    local pos = vec2(screen_width - ui_config.bottom_right_x_from_right, screen_height - ui_config.bottom_right_y_from_bottom)
    local shadow_offset = math.max(1, 3 * current_scale_factor)
    
    -- Status header with individual positioning
    local header_pos = vec2(pos.x + ui_config.status_header_x_offset, pos.y + ui_config.status_header_y_offset)
    draw_text_with_shadow('fonts/Mogra-Regular.ttf', "STATUS", ui_config.records_header_size, 
                         header_pos, rgbm(0.9, 0.9, 0.9, 1), shadow_offset)
    
    -- Calculate first status line position
    local current_line_y = pos.y + ui_config.status_first_line_y_offset
    local status_x = pos.x + ui_config.status_text_x_offset
    
    -- Drift status
    local status_text = vars.is_drifting and "🔥 DRIFTING!" or "🏎️ READY"
    local status_color = vars.is_drifting and rgbm(0, 1, 0, 1) or rgbm(0.8, 0.8, 0.8, 1)
    draw_text_with_shadow('fonts/Mogra-Regular.ttf', status_text, ui_config.status_main_size, 
                         vec2(status_x, current_line_y), status_color, shadow_offset)
    
    current_line_y = current_line_y + ui_config.status_line_spacing
    
    -- Anti-farming status
    if vars.farming_detected then
        local farming_size = math.floor(24 * current_scale_factor)
        draw_text_with_shadow('fonts/Mogra-Regular.ttf', "🚨 FARMING PENALTY", farming_size, 
                             vec2(status_x, current_line_y), rgbm(1, 0.3, 0.3, 1), shadow_offset)
        current_line_y = current_line_y + ui_config.status_line_spacing
    end
    
    -- Reverse entry status
    if vars.reverse_entry_active then
        local reverse_size = math.floor(24 * current_scale_factor)
        draw_text_with_shadow('fonts/Mogra-Regular.ttf', "🚨 REVERSE ENTRY!", reverse_size, 
                             vec2(status_x, current_line_y), rgbm(1, 1, 0, 1), shadow_offset)
        current_line_y = current_line_y + ui_config.status_line_spacing
    end
    
    -- Sweet spot zone (if drifting)
    if vars.is_drifting then
        local car = ac.getCar(0)
        if car then
            local angle, _, _ = utils.calculate_slip_angle(car)
            local sweet_spot_info = scoring.get_sweet_spot_info(angle)
            if sweet_spot_info.text ~= "" then
                local sweet_size = math.floor(24 * current_scale_factor)
                draw_text_with_shadow('fonts/Mogra-Regular.ttf', sweet_spot_info.text, sweet_size, 
                                     vec2(status_x, current_line_y), rgbm(1, 1, 0, 1), shadow_offset)
            end
        end
    end
end

-- =============================================================================
-- MAIN FULL-SCREEN OVERLAY FUNCTION (Updated)
-- =============================================================================

function render_fullscreen_overlay(screen_width, screen_height)
    if ui.dwriteDrawText then
        render_top_left_total_points(screen_width, screen_height)
        render_top_center_notifications(screen_width, screen_height)
        render_bottom_left_records(screen_width, screen_height)
        render_bottom_right_status(screen_width, screen_height)
        
        -- Special effects
        if vars.farming_detected then
            local warning_alpha = vars.pulse_state and 0.3 or 0.1
            ui.drawRectFilled(vec2(0, 0), vec2(screen_width, screen_height), rgbm(1, 0.5, 0, warning_alpha))
        end
        
    else
        ui.text("DWrite not available - using fallback UI")
        ui.text("TOTAL POINTS: " .. utils.format_number(vars.total_banked_points))
        ui.text("DRIFT: " .. utils.format_number(vars.current_drift_points))
        if vars.is_drifting then
            ui.textColored("🔥 DRIFTING!", rgbm(0, 1, 0, 1))
        end
    end
end

-- =============================================================================
-- UTILITY FUNCTIONS (Simplified)
-- =============================================================================

function get_ui_config()
    return ui_config
end

function get_scale_factor()
    return current_scale_factor
end

function get_scaling_info()
    return {
        reference_resolution = string.format("%dx%d", REFERENCE_WIDTH, REFERENCE_HEIGHT),
        scale_factor = current_scale_factor,
        notification_size = ui_config.notification_size,
        total_points_size = ui_config.total_points_label_size,
        records_size = ui_config.records_text_size,
        notification_y = ui_config.notification_y_position,
        notification_offset = ui_config.notification_center_offset
    }
end

function initialize()
    -- Initialize with default scaling (will be updated when screen size is set)
    apply_scaling(1.0)
    utils.debug_log("Display module initialized - edit notification_y_position and notification_center_offset in base_ui_config to adjust positioning", "INIT")
end
