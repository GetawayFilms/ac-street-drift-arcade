-- modules/records.lua - Personal Best Tracking and File I/O
-- Save as: assettocorsa/apps/lua/streetdriftarcade/modules/records.lua

local M = {}
local vars = require('modules/variables')
local utils = require('modules/utilities')

-- =============================================================================
-- PERSONAL BEST TRACKING
-- =============================================================================

-- Check if current segment qualifies as a Pure Skill record
function M.check_pure_skill_record(segment_points)
    if segment_points > vars.all_time_best_pure_drift then
        local old_record = vars.all_time_best_pure_drift
        vars.all_time_best_pure_drift = segment_points
        vars.pb_drift_animation_timer = vars.pb_animation_duration
        
        M.save_personal_bests()
        
        utils.debug_log(string.format("🏆 NEW PURE SKILL RECORD! %s (was %s)", 
                        utils.format_number(segment_points), 
                        utils.format_number(old_record)), "RECORD")
        
        return true
    end
    return false
end

-- Check if current final score qualifies as a Best Run record
function M.check_final_score_record(final_score)
    if final_score > vars.all_time_best_final_score then
        local old_record = vars.all_time_best_final_score
        vars.all_time_best_final_score = final_score
        vars.pb_final_animation_timer = vars.pb_animation_duration
        
        M.save_personal_bests()
        
        utils.debug_log(string.format("🏆 NEW BEST RUN RECORD! %s (was %s)", 
                        utils.format_number(final_score), 
                        utils.format_number(old_record)), "RECORD")
        
        return true
    end
    return false
end

-- Check if current total qualifies as a Best Session record
function M.check_total_points_record(total_points)
    if total_points > vars.all_time_best_total_points then
        local old_record = vars.all_time_best_total_points
        vars.all_time_best_total_points = total_points
        vars.pb_total_animation_timer = vars.pb_animation_duration
        
        M.save_personal_bests()
        
        utils.debug_log(string.format("🏆 NEW BEST SESSION RECORD! %s (was %s)", 
                        utils.format_number(total_points), 
                        utils.format_number(old_record)), "RECORD")
        
        return true
    end
    return false
end

-- Check all records at once (used when drift ends)
function M.check_all_records(segment_points, final_score, total_points)
    local records_broken = {
        pure_skill = M.check_pure_skill_record(segment_points),
        final_score = M.check_final_score_record(final_score),
        total_points = M.check_total_points_record(total_points)
    }
    
    -- Log summary if any records were broken
    local broken_count = 0
    for _, broken in pairs(records_broken) do
        if broken then broken_count = broken_count + 1 end
    end
    
    if broken_count > 0 then
        utils.debug_log(string.format("🎉 %d RECORD(S) BROKEN THIS DRIFT!", broken_count), "RECORD")
    end
    
    return records_broken
end

-- =============================================================================
-- LIVE PURE SKILL TRACKING
-- =============================================================================

-- Get live pure skill display info (for real-time UI updates)
function M.get_live_pure_skill_info()
    local display_text = utils.format_number(vars.all_time_best_pure_drift)
    local display_color = {r=0.8, g=0.8, b=1, a=1}  -- Default blue
    local is_live_record = false
    
    -- Check if currently breaking the record
    if vars.is_drifting and vars.current_segment_points > vars.all_time_best_pure_drift then
        display_text = utils.format_number(vars.current_segment_points) .. " 🔥"
        display_color = {r=1, g=0.4, b=0, a=1}  -- Orange fire
        is_live_record = true
    end
    
    -- Apply animation if record was recently broken
    if vars.pb_drift_animation_timer > 0 then
        local pulse = math.sin(vars.pb_drift_animation_timer * 15) * 0.5 + 0.5
        display_color = {r=0.2 + pulse * 0.8, g=1, b=0.2 + pulse * 0.8, a=1}  -- Green pulse
    end
    
    return {
        text = display_text,
        color = rgbm(display_color.r, display_color.g, display_color.b, display_color.a),
        is_live_record = is_live_record,
        current_segment = vars.current_segment_points,
        record_value = vars.all_time_best_pure_drift
    }
end

-- =============================================================================
-- RECORD STATISTICS AND ANALYTICS
-- =============================================================================

-- Get comprehensive record statistics
function M.get_record_statistics()
    return {
        pure_skill = {
            value = vars.all_time_best_pure_drift,
            description = "Single segment, no multiplier",
            category = "Skill"
        },
        final_score = {
            value = vars.all_time_best_final_score,
            description = "Best single drift with multiplier",
            category = "Performance"
        },
        total_points = {
            value = vars.all_time_best_total_points,
            description = "Best session total",
            category = "Endurance"
        },
        session_stats = {
            current_total = vars.total_banked_points,
            current_drift = vars.current_drift_points,
            current_segment = vars.current_segment_points,
            current_multiplier = vars.drift_multiplier
        }
    }
end

-- Calculate record progression (how close current values are to records)
function M.get_record_progression()
    local progression = {}
    
    -- Pure Skill progression
    if vars.is_drifting and vars.current_segment_points > 0 then
        progression.pure_skill = {
            current = vars.current_segment_points,
            target = vars.all_time_best_pure_drift,
            percentage = vars.all_time_best_pure_drift > 0 and 
                        (vars.current_segment_points / vars.all_time_best_pure_drift) * 100 or 0,
            is_record = vars.current_segment_points > vars.all_time_best_pure_drift
        }
    end
    
    -- Final Score progression (projected)
    if vars.is_drifting and vars.current_drift_points > 0 then
        local projected_final = math.floor(vars.current_drift_points) * vars.drift_multiplier
        progression.final_score = {
            current = projected_final,
            target = vars.all_time_best_final_score,
            percentage = vars.all_time_best_final_score > 0 and 
                        (projected_final / vars.all_time_best_final_score) * 100 or 0,
            is_record = projected_final > vars.all_time_best_final_score
        }
    end
    
    -- Total Points progression
    progression.total_points = {
        current = vars.total_banked_points,
        target = vars.all_time_best_total_points,
        percentage = vars.all_time_best_total_points > 0 and 
                    (vars.total_banked_points / vars.all_time_best_total_points) * 100 or 0,
        is_record = vars.total_banked_points > vars.all_time_best_total_points
    }
    
    return progression
end

-- =============================================================================
-- FILE I/O SYSTEM
-- =============================================================================

-- Save personal bests to JSON file
function M.save_personal_bests()
    local json_content = string.format(
        '{\n  "all_time_best_pure_drift": %d,\n  "all_time_best_final_score": %d,\n  "all_time_best_total_points": %d,\n  "last_updated": "%.0f"\n}',
        math.floor(vars.all_time_best_pure_drift),
        math.floor(vars.all_time_best_final_score),
        math.floor(vars.all_time_best_total_points),
        os.clock()
    )
    
    local save_success = pcall(function()
        local file = io.open("drift_records.json", "w")
        if file then
            file:write(json_content)
            file:close()
            return true
        end
        return false
    end)
    
    if save_success then
        utils.debug_log("Personal bests saved successfully", "FILE")
    else
        utils.debug_log("Failed to save personal bests", "FILE")
    end
    
    return save_success
end

-- Load personal bests from JSON file
function M.load_personal_bests()
    vars.debug_info = "Testing file I/O..."
    
    -- Set defaults first
    vars.all_time_best_pure_drift = 0
    vars.all_time_best_final_score = 0
    vars.all_time_best_total_points = 0
    
    local load_success = pcall(function()
        vars.debug_info = "Attempting file open..."
        local file = io.open("drift_records.json", "r")
        
        if file then
            vars.debug_info = "File opened! Reading..."
            local content = file:read("*all")
            file:close()
            
            if content and content ~= "" then
                vars.debug_info = "Parsing JSON..."
                
                -- Parse new format
                local pure_drift = content:match('"all_time_best_pure_drift"%s*:%s*([%d%.]+)')
                local final_score = content:match('"all_time_best_final_score"%s*:%s*([%d%.]+)')
                local total_points = content:match('"all_time_best_total_points"%s*:%s*([%d%.]+)')
                
                -- Backwards compatibility: try old format if new format not found
                if not pure_drift then
                    local old_single_drift = content:match('"all_time_best_single_drift"%s*:%s*([%d%.]+)')
                    if old_single_drift then
                        pure_drift = old_single_drift
                        final_score = old_single_drift
                        vars.debug_info = vars.debug_info .. " [MIGRATED OLD FORMAT]"
                    end
                end
                
                -- Apply parsed values
                if pure_drift then vars.all_time_best_pure_drift = tonumber(pure_drift) or 0 end
                if final_score then vars.all_time_best_final_score = tonumber(final_score) or 0 end
                if total_points then vars.all_time_best_total_points = tonumber(total_points) or 0 end
                
                vars.debug_info = string.format("✅ Loaded PBs: Pure:%s Final:%s Total:%s", 
                                  utils.format_number(vars.all_time_best_pure_drift),
                                  utils.format_number(vars.all_time_best_final_score),
                                  utils.format_number(vars.all_time_best_total_points))
                
                -- Convert to new format if migrated
                if not content:match('"all_time_best_pure_drift"') then
                    M.save_personal_bests()
                    vars.debug_info = vars.debug_info .. " [CONVERTED TO NEW FORMAT]"
                end
                
                return true
            else
                -- Empty file - create with defaults
                vars.debug_info = "📄 File empty, creating new one..."
                return M.create_default_file()
            end
        else
            -- No file found - create new one
            vars.debug_info = "📁 No file found, creating..."
            return M.create_default_file()
        end
    end)
    
    if not load_success then
        vars.debug_info = "❌ File I/O completely blocked"
        utils.debug_log("File I/O error during load", "FILE")
    end
    
    utils.debug_log(vars.debug_info, "FILE")
    return load_success
end

-- Create default records file
function M.create_default_file()
    local create_success = pcall(function()
        local file = io.open("drift_records.json", "w")
        if file then
            file:write('{"all_time_best_pure_drift": 0, "all_time_best_final_score": 0, "all_time_best_total_points": 0, "last_updated": "0"}')
            file:close()
            vars.debug_info = "✅ Created new file with defaults"
            return true
        else
            vars.debug_info = "❌ Can't create file - no write permission"
            return false
        end
    end)
    
    return create_success
end

-- =============================================================================
-- BACKUP AND RECOVERY
-- =============================================================================

-- Create backup of current records
function M.create_backup()
    local timestamp = string.format("%.0f", os.clock())
    local backup_filename = "drift_records_backup_" .. timestamp .. ".json"
    
    local backup_success = pcall(function()
        -- Read current file
        local current_file = io.open("drift_records.json", "r")
        if not current_file then return false end
        
        local content = current_file:read("*all")
        current_file:close()
        
        -- Write backup
        local backup_file = io.open(backup_filename, "w")
        if not backup_file then return false end
        
        backup_file:write(content)
        backup_file:close()
        
        return true
    end)
    
    if backup_success then
        utils.debug_log("Backup created: " .. backup_filename, "FILE")
    else
        utils.debug_log("Failed to create backup", "FILE")
    end
    
    return backup_success
end

-- Reset all records (with backup)
function M.reset_all_records()
    -- Create backup first
    local backup_created = M.create_backup()
    
    -- Reset in-memory values
    vars.all_time_best_pure_drift = 0
    vars.all_time_best_final_score = 0
    vars.all_time_best_total_points = 0
    
    -- Save reset values to file
    local save_success = M.save_personal_bests()
    
    utils.debug_log(string.format("Records reset (backup: %s, save: %s)", 
                    tostring(backup_created), tostring(save_success)), "FILE")
    
    return save_success
end

-- =============================================================================
-- IMPORT/EXPORT FUNCTIONALITY
-- =============================================================================

-- Export records in human-readable format
function M.export_records_readable()
    local export_content = string.format([[
========================================
STREET DRIFT ARCADE - PERSONAL RECORDS
========================================
Export Date: %s

🎯 PURE SKILL RECORD: %s points
   (Single segment, no multiplier - pure driving skill)

🏁 BEST RUN RECORD: %s points  
   (Best single drift with multiplier applied)

📈 BEST SESSION RECORD: %s points
   (Highest total points in one session)

========================================
]], 
        os.date("%Y-%m-%d %H:%M:%S"),
        utils.format_number(vars.all_time_best_pure_drift),
        utils.format_number(vars.all_time_best_final_score),
        utils.format_number(vars.all_time_best_total_points)
    )
    
    local export_success = pcall(function()
        local file = io.open("drift_records_export.txt", "w")
        if file then
            file:write(export_content)
            file:close()
            return true
        end
        return false
    end)
    
    if export_success then
        utils.debug_log("Records exported to drift_records_export.txt", "FILE")
    else
        utils.debug_log("Failed to export records", "FILE")
    end
    
    return export_success
end

-- =============================================================================
-- RECORD VALIDATION
-- =============================================================================

-- Validate that records are reasonable (anti-cheat)
function M.validate_records()
    local issues = {}
    local max_reasonable = 50000000  -- 50 million points
    
    if vars.all_time_best_pure_drift > max_reasonable then
        table.insert(issues, "Pure skill record suspiciously high: " .. utils.format_number(vars.all_time_best_pure_drift))
    end
    
    if vars.all_time_best_final_score > max_reasonable then
        table.insert(issues, "Final score record suspiciously high: " .. utils.format_number(vars.all_time_best_final_score))
    end
    
    if vars.all_time_best_total_points > max_reasonable * 10 then  -- Allow higher total
        table.insert(issues, "Total points record suspiciously high: " .. utils.format_number(vars.all_time_best_total_points))
    end
    
    -- Check for impossible relationships
    if vars.all_time_best_final_score < vars.all_time_best_pure_drift then
        table.insert(issues, "Final score cannot be less than pure skill record")
    end
    
    -- Log validation results
    if #issues > 0 then
        for _, issue in ipairs(issues) do
            utils.debug_log("VALIDATION: " .. issue, "RECORD")
        end
    else
        utils.debug_log("Record validation passed", "RECORD")
    end
    
    return #issues == 0, issues
end

-- =============================================================================
-- MODULE INITIALIZATION
-- =============================================================================

function M.initialize()
    utils.debug_log("Records module initialized", "INIT")
end

return M