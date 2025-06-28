-- modules/variables.lua - All Variables and Constants
-- Save as: assettocorsa/apps/lua/streetdriftarcade/modules/variables.lua

local M = {}

-- =============================================================================
-- DRIFT TRACKING VARIABLES
-- =============================================================================
M.current_drift_points = 0      -- This will show raw points in UI
M.total_drift_score = 0         -- This accumulates the multiplied total
M.current_segment_points = 0    -- Track current single segment for Pure Skill
M.total_banked_points = 0
M.drift_multiplier = 1
M.is_drifting = false
M.drift_direction = 0
M.drift_end_timer = 0.0
M.drift_end_delay = 1.5  -- Reduced from 2.5 to 1.5 seconds
M.drift_threshold = 8.0
M.min_speed = 10  -- Minimum speed (km/h) to count drift
M.transition_threshold = 5.0

-- =============================================================================
-- ANGLE BONUS SYSTEM
-- =============================================================================
M.angle_tracking_enabled = false        -- Flag to start/stop angle tracking
M.angle_samples = {}                    -- Array to store {angle, timestamp} pairs
M.angle_sample_count = 0               -- Counter for samples
M.drift_start_time = 0                 -- When current drift started (>20°)
M.drift_end_time = 0                   -- When current drift ended (<20°)
M.dominant_angle_range = ""            -- Which range dominated the drift
M.dominant_angle_duration = 0          -- How long the dominant angle was held
M.angle_bonus_points = 0               -- Calculated bonus points
M.angle_bonus_notification = ""        -- Notification text for the bonus

-- Angle range definitions (duration tracking) - REFINED RANGES (NO <30° REWARDS)
M.angle_range_durations = {
    ["30-45"] = 0,      -- Good Drift (30-45°)
    ["45-60"] = 0,      -- Great Drift (45-60°)
    ["60+"] = 0         -- Angle Master (60°+)
}

-- =============================================================================
-- PERSONAL BEST TRACKING
-- =============================================================================
M.session_best_single_drift = 0
M.session_best_total_points = 0
M.all_time_best_pure_drift = 0    -- Pure drift points, no multiplier - ULTIMATE SKILL MEASURE
M.all_time_best_final_score = 0   -- Best final score (with multiplier) for comparison
M.all_time_best_total_points = 0

-- =============================================================================
-- SWEET SPOT SYSTEM
-- =============================================================================
M.sweet_spot_time = 0.0
M.perfect_zone_time = 0.0
M.consistency_bonus = 0

-- =============================================================================
-- SCORING SYSTEM VARIABLES
-- =============================================================================
M.base_drift_rate = 0.8  -- Base multiplier for angle × speed calculation
M.duration_bonus_multiplier = 1.0  -- Exponential bonus for sustained drifting
M.high_speed_drift_time = 0.0  -- Time spent drifting above threshold speed
M.high_speed_threshold = 80    -- Speed threshold for duration bonuses

-- =============================================================================
-- ENHANCED ROTATION-BASED ANTI-FARMING WITH FALSE POSITIVE PREVENTION
-- =============================================================================
M.rotation_samples = {}  -- Circular buffer for rotation samples
M.max_rotation_samples = 30  -- 30 samples at 60fps = 0.5 seconds of data
M.sample_index = 1
M.rotation_variance_threshold = 0.12  -- Slightly lowered for more sensitivity
M.farming_detection_delay = 5.0  -- Increased to 5 seconds to avoid false positives
M.total_rotation_magnitude = 0.0
M.last_significant_rotation_time = 0.0
M.is_farming = false
M.total_drift_time = 0.0  -- Keep this for duration bonus calculations

-- =============================================================================
-- FALSE POSITIVE PREVENTION VARIABLES
-- =============================================================================
M.position_samples = {}  -- Track car position to detect forward progress
M.max_position_samples = 60  -- 1 second of position data at 60fps
M.position_sample_index = 1
M.distance_traveled_threshold = 50.0  -- Minimum distance (meters) in last second to NOT be farming
M.elevation_change_threshold = 2.0  -- Minimum elevation change (meters) to indicate ramp/hill

M.speed_variance_samples = {}  -- Track speed changes
M.max_speed_samples = 30  -- 0.5 seconds of speed data
M.speed_sample_index = 1
M.speed_variance_threshold = 5.0  -- Minimum speed variance to indicate track progression

-- =============================================================================
-- REVERSE ENTRY SYSTEM WITH FAILURE PENALTIES
-- =============================================================================
M.reverse_entry_active = false
M.reverse_entry_timer = 0.0
M.reverse_entry_grace_period = 3.0
M.reverse_entry_min_speed = 80
M.reverse_entry_awarded = false
M.reverse_entry_max_angle = 0
M.reverse_entry_failures = 0  -- Track failures in session
M.max_failures_before_penalty = 3

-- =============================================================================
-- ROLLBACK EXPLOIT PREVENTION
-- =============================================================================
M.backward_movement_timer = 0.0
M.backward_detection_threshold = 1.0  -- Seconds of backward movement = exploit

-- =============================================================================
-- CRASH DETECTION SYSTEM
-- =============================================================================
M.crash_speed_threshold = 40  -- km/h - minimum speed for crash detection
M.last_speed_for_crash = 0    -- Track speed changes for crash detection
M.crash_detection_timer = 0.0 -- Timer to delay speed comparisons
M.crash_detection_interval = 0.1  -- Check every 0.1 seconds (a few frames)
M.crash_cooldown_timer = 0.0  -- Timer for post-crash cooldown
M.crash_cooldown_period = 3.0 -- Seconds after crash before points can be scored again
M.drift_cancelled_by_crash = false  -- Flag to prevent banking points after crash

-- =============================================================================
-- ANIMATION AND DISPLAY
-- =============================================================================
M.notification_text = ""
M.notification_timer = 0.0
M.notification_display_time = 2.0
M.pulse_timer = 0.0
M.pulse_state = false

-- =============================================================================
-- PIT DETECTION
-- =============================================================================
M.in_pits = false
M.last_pit_status = false
M.pit_area_center = nil
M.pit_detection_radius = 5.0
M.pit_area_established = false

-- =============================================================================
-- SMOKE PROGRESSION
-- =============================================================================
M.drift_smoke_timer = 0.0
M.smoke_stage = 0

-- =============================================================================
-- DISPLAY LEVELS (SIMPLIFIED)
-- =============================================================================
M.last_total_display_level = 0
M.last_multiplier_level = 0

-- =============================================================================
-- ANIMATION SYSTEM FOR PBs
-- =============================================================================
M.pb_drift_animation_timer = 0.0
M.pb_total_animation_timer = 0.0
M.pb_final_animation_timer = 0.0  -- Animation for Best Run (final score)
M.pb_animation_duration = 3.0

-- =============================================================================
-- FONT SCALES FOR 4K READABILITY
-- =============================================================================
M.title_scale = 1.2      -- Title
M.huge_scale = 2.5       -- Total Points (MASSIVE!)
M.large_scale = 2.0      -- Drift & Multiplier (BIG!)
M.medium_scale = 1.0     -- Status & PB (readable)
M.small_scale = 0.8      -- Small details

-- =============================================================================
-- COLORS (SIMPLIFIED)
-- =============================================================================
M.colors = {
    white = {r=1.0, g=1.0, b=1.0, a=1.0},
    yellow = {r=1.0, g=0.9, b=0.0, a=1.0},
    cyan = {r=0.0, g=1.0, b=1.0, a=1.0},
    red = {r=1.0, g=0.0, b=0.0, a=1.0},
    orange = {r=1.0, g=0.4, b=0.0, a=1.0},
    blue = {r=0.8, g=0.8, b=1.0, a=1.0},
    gray = {r=0.7, g=0.7, b=0.7, a=1.0}
}

-- =============================================================================
-- DEBUG AND FILE I/O
-- =============================================================================
M.debug_info = "Starting..."
M.file_test_results = {}
M.loaded_once = false  -- Flag to only load once

-- =============================================================================
-- CONSTANTS
-- =============================================================================
M.MINIMUM_LATERAL_VELOCITY = 3.0  -- m/s - must be sliding sideways to count as drift

-- =============================================================================
-- MODULE FUNCTIONS
-- =============================================================================

-- Initialize all variables to their default state
function M.initialize()
    -- Reset drift tracking
    M.current_drift_points = 0
    M.total_drift_score = 0
    M.current_segment_points = 0
    M.drift_multiplier = 1
    M.is_drifting = false
    M.drift_direction = 0
    M.drift_end_timer = 0.0
    
    -- Reset angle bonus system
    M.angle_tracking_enabled = false
    M.angle_samples = {}
    M.angle_sample_count = 0
    M.drift_start_time = 0
    M.drift_end_time = 0
    M.dominant_angle_range = ""
    M.dominant_angle_duration = 0
    M.angle_bonus_points = 0
    M.angle_bonus_notification = ""
    for range, _ in pairs(M.angle_range_durations) do
        M.angle_range_durations[range] = 0
    end
    
    -- Reset timers
    M.sweet_spot_time = 0.0
    M.perfect_zone_time = 0.0
    M.consistency_bonus = 0
    M.total_drift_time = 0.0
    M.drift_smoke_timer = 0.0
    M.smoke_stage = 0
    
    -- Reset anti-farming
    M.rotation_samples = {}
    M.sample_index = 1
    M.position_samples = {}
    M.position_sample_index = 1
    M.speed_variance_samples = {}
    M.speed_sample_index = 1
    M.total_rotation_magnitude = 0.0
    M.last_significant_rotation_time = os.clock()
    M.is_farming = false
    
    -- Reset detection systems
    M.reverse_entry_active = false
    M.reverse_entry_timer = 0.0
    M.reverse_entry_awarded = false
    M.reverse_entry_max_angle = 0
    M.backward_movement_timer = 0.0
    M.crash_cooldown_timer = 0.0
    M.drift_cancelled_by_crash = false
    
    -- Reset display
    M.notification_text = ""
    M.notification_timer = 0.0
    M.pulse_timer = 0.0
    M.pulse_state = false
    
    ac.log("✅ Variables module initialized with Angle Bonus System")
end

-- Reset all tracking data when entering pits
function M.reset_session()
    M.total_banked_points = 0
    M.current_drift_points = 0
    M.total_drift_score = 0
    M.current_segment_points = 0
    M.drift_multiplier = 1
    M.is_drifting = false
    M.drift_direction = 0
    M.drift_end_timer = 0.0
    M.reverse_entry_active = false
    M.reverse_entry_timer = 0.0
    M.last_total_display_level = 0
    M.last_multiplier_level = 0
    M.session_best_single_drift = 0
    M.session_best_total_points = 0
    M.sweet_spot_time = 0.0
    M.perfect_zone_time = 0.0
    M.consistency_bonus = 0
    M.drift_smoke_timer = 0.0
    M.smoke_stage = 0
    M.total_drift_time = 0.0
    M.is_farming = false
    M.last_speed_for_crash = 0
    M.crash_detection_timer = 0.0
    M.crash_cooldown_timer = 0.0
    M.drift_cancelled_by_crash = false
    M.backward_movement_timer = 0.0
    M.reverse_entry_failures = 0
    
    -- Reset angle bonus system
    M.angle_tracking_enabled = false
    M.angle_samples = {}
    M.angle_sample_count = 0
    M.drift_start_time = 0
    M.drift_end_time = 0
    M.dominant_angle_range = ""
    M.dominant_angle_duration = 0
    M.angle_bonus_points = 0
    M.angle_bonus_notification = ""
    for range, _ in pairs(M.angle_range_durations) do
        M.angle_range_durations[range] = 0
    end
    
    -- Reset all tracking arrays
    M.rotation_samples = {}
    M.sample_index = 1
    M.position_samples = {}
    M.position_sample_index = 1
    M.speed_variance_samples = {}
    M.speed_sample_index = 1
    M.total_rotation_magnitude = 0.0
    M.last_significant_rotation_time = os.clock()
    
    ac.log("🏁 Session reset - all variables cleared including Angle Bonus System")
end

-- Reset drift-specific tracking when drift starts
function M.reset_drift_tracking()
    M.rotation_samples = {}
    M.sample_index = 1
    M.position_samples = {}
    M.position_sample_index = 1
    M.speed_variance_samples = {}
    M.speed_sample_index = 1
    M.total_rotation_magnitude = 0.0
    M.last_significant_rotation_time = os.clock()
    
    -- Reset angle bonus tracking
    M.angle_tracking_enabled = false
    M.angle_samples = {}
    M.angle_sample_count = 0
    for range, _ in pairs(M.angle_range_durations) do
        M.angle_range_durations[range] = 0
    end
end

return M
