-- modules/variables.lua - All Variables and Constants
-- Save as: assettocorsa/apps/lua/streetdriftarcade/modules/variables.lua


-- =============================================================================
-- DRIFT TRACKING VARIABLES
-- =============================================================================
current_drift_points = 0      -- This will show raw points in UI
total_drift_score = 0         -- This accumulates the multiplied total
current_segment_points = 0    -- Track current single segment for Pure Skill
total_banked_points = 0
drift_multiplier = 1
is_drifting = false
drift_direction = 0
drift_end_timer = 0.0
drift_end_delay = 1.5  -- Reduced from 2.5 to 1.5 seconds
drift_threshold = 8.0
min_speed = 10  -- Minimum speed (km/h) to count drift
transition_threshold = 5.0

-- =============================================================================
-- ANGLE BONUS SYSTEM
-- =============================================================================
angle_tracking_enabled = false        -- Flag to start/stop angle tracking
angle_samples = {}                    -- Array to store {angle, timestamp} pairs
angle_sample_count = 0               -- Counter for samples
drift_start_time = 0                 -- When current drift started (>20°)
drift_end_time = 0                   -- When current drift ended (<20°)
dominant_angle_range = ""            -- Which range dominated the drift
dominant_angle_duration = 0          -- How long the dominant angle was held
angle_bonus_points = 0               -- Calculated bonus points
angle_bonus_notification = ""        -- Notification text for the bonus

-- Angle range definitions (duration tracking) - REFINED RANGES (NO <30° REWARDS)
angle_range_durations = {
    ["30-45"] = 0,      -- Good Drift (30-45°)
    ["45-60"] = 0,      -- Great Drift (45-60°)
    ["60+"] = 0         -- Angle Master (60°+)
}

-- =============================================================================
-- PERSONAL BEST TRACKING
-- =============================================================================
session_best_single_drift = 0
session_best_total_points = 0
all_time_best_pure_drift = 0    -- Pure drift points, no multiplier - ULTIMATE SKILL MEASURE
all_time_best_final_score = 0   -- Best final score (with multiplier) for comparison
all_time_best_total_points = 0

-- =============================================================================
-- SWEET SPOT SYSTEM
-- =============================================================================
sweet_spot_time = 0.0
perfect_zone_time = 0.0
consistency_bonus = 0

-- =============================================================================
-- SCORING SYSTEM VARIABLES
-- =============================================================================
base_drift_rate = 0.8  -- Base multiplier for angle × speed calculation
duration_bonus_multiplier = 1.0  -- Exponential bonus for sustained drifting
high_speed_drift_time = 0.0  -- Time spent drifting above threshold speed
high_speed_threshold = 80    -- Speed threshold for duration bonuses

-- =============================================================================
-- ENHANCED ROTATION-BASED ANTI-FARMING WITH FALSE POSITIVE PREVENTION
-- =============================================================================
rotation_samples = {}  -- Circular buffer for rotation samples
max_rotation_samples = 30  -- 30 samples at 60fps = 0.5 seconds of data
sample_index = 1
rotation_variance_threshold = 0.12  -- Slightly lowered for more sensitivity
farming_detection_delay = 5.0  -- Increased to 5 seconds to avoid false positives
total_rotation_magnitude = 0.0
last_significant_rotation_time = 0.0
is_farming = false
total_drift_time = 0.0  -- Keep this for duration bonus calculations

-- =============================================================================
-- FALSE POSITIVE PREVENTION VARIABLES
-- =============================================================================
position_samples = {}  -- Track car position to detect forward progress
max_position_samples = 60  -- 1 second of position data at 60fps
position_sample_index = 1
distance_traveled_threshold = 50.0  -- Minimum distance (meters) in last second to NOT be farming
elevation_change_threshold = 2.0  -- Minimum elevation change (meters) to indicate ramp/hill

speed_variance_samples = {}  -- Track speed changes
max_speed_samples = 30  -- 0.5 seconds of speed data
speed_sample_index = 1
speed_variance_threshold = 5.0  -- Minimum speed variance to indicate track progression

-- =============================================================================
-- REVERSE ENTRY SYSTEM WITH FAILURE PENALTIES
-- =============================================================================
reverse_entry_active = false
reverse_entry_timer = 0.0
reverse_entry_grace_period = 3.0
reverse_entry_min_speed = 80
reverse_entry_awarded = false
reverse_entry_max_angle = 0
reverse_entry_failures = 0  -- Track failures in session
max_failures_before_penalty = 3

-- =============================================================================
-- ROLLBACK EXPLOIT PREVENTION
-- =============================================================================
backward_movement_timer = 0.0
backward_detection_threshold = 1.0  -- Seconds of backward movement = exploit

-- =============================================================================
-- CRASH DETECTION SYSTEM
-- =============================================================================
crash_speed_threshold = 40  -- km/h - minimum speed for crash detection
last_speed_for_crash = 0    -- Track speed changes for crash detection
crash_detection_timer = 0.0 -- Timer to delay speed comparisons
crash_detection_interval = 0.1  -- Check every 0.1 seconds (a few frames)
crash_cooldown_timer = 0.0  -- Timer for post-crash cooldown
crash_cooldown_period = 3.0 -- Seconds after crash before points can be scored again
drift_cancelled_by_crash = false  -- Flag to prevent banking points after crash

-- =============================================================================
-- ANIMATION AND DISPLAY
-- =============================================================================
notification_text = ""
notification_timer = 0.0
notification_display_time = 2.0
pulse_timer = 0.0
pulse_state = false

-- =============================================================================
-- PIT DETECTION
-- =============================================================================
in_pits = false
last_pit_status = false
pit_area_center = nil
pit_detection_radius = 5.0
pit_area_established = false

-- =============================================================================
-- SMOKE PROGRESSION
-- =============================================================================
drift_smoke_timer = 0.0
smoke_stage = 0

-- =============================================================================
-- DISPLAY LEVELS (SIMPLIFIED)
-- =============================================================================
last_total_display_level = 0
last_multiplier_level = 0

-- =============================================================================
-- ANIMATION SYSTEM FOR PBs
-- =============================================================================
pb_drift_animation_timer = 0.0
pb_total_animation_timer = 0.0
pb_final_animation_timer = 0.0  -- Animation for Best Run (final score)
pb_animation_duration = 3.0

-- =============================================================================
-- FONT SCALES FOR 4K READABILITY
-- =============================================================================
title_scale = 1.2      -- Title
huge_scale = 2.5       -- Total Points (MASSIVE!)
large_scale = 2.0      -- Drift & Multiplier (BIG!)
medium_scale = 1.0     -- Status & PB (readable)
small_scale = 0.8      -- Small details

-- =============================================================================
-- COLORS (SIMPLIFIED)
-- =============================================================================
colors = {
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
debug_info = "Starting..."
file_test_results = {}
loaded_once = false  -- Flag to only load once

-- =============================================================================
-- CONSTANTS
-- =============================================================================
MINIMUM_LATERAL_VELOCITY = 3.0  -- m/s - must be sliding sideways to count as drift

-- =============================================================================
-- MODULE FUNCTIONS
-- =============================================================================

-- Initialize all variables to their default state
function initialize()
    -- Reset drift tracking
    current_drift_points = 0
    total_drift_score = 0
    current_segment_points = 0
    drift_multiplier = 1
    is_drifting = false
    drift_direction = 0
    drift_end_timer = 0.0
    
    -- Reset angle bonus system
    angle_tracking_enabled = false
    angle_samples = {}
    angle_sample_count = 0
    drift_start_time = 0
    drift_end_time = 0
    dominant_angle_range = ""
    dominant_angle_duration = 0
    angle_bonus_points = 0
    angle_bonus_notification = ""
    for range, _ in pairs(angle_range_durations) do
        angle_range_durations[range] = 0
    end
    
    -- Reset timers
    sweet_spot_time = 0.0
    perfect_zone_time = 0.0
    consistency_bonus = 0
    total_drift_time = 0.0
    drift_smoke_timer = 0.0
    smoke_stage = 0
    
    -- Reset anti-farming
    rotation_samples = {}
    sample_index = 1
    position_samples = {}
    position_sample_index = 1
    speed_variance_samples = {}
    speed_sample_index = 1
    total_rotation_magnitude = 0.0
    last_significant_rotation_time = os.clock()
    is_farming = false
    
    -- Reset detection systems
    reverse_entry_active = false
    reverse_entry_timer = 0.0
    reverse_entry_awarded = false
    reverse_entry_max_angle = 0
    backward_movement_timer = 0.0
    crash_cooldown_timer = 0.0
    drift_cancelled_by_crash = false
    
    -- Reset display
    notification_text = ""
    notification_timer = 0.0
    pulse_timer = 0.0
    pulse_state = false
    
    ac.log("✅ Variables module initialized with Angle Bonus System")
end

-- Reset all tracking data when entering pits
function reset_session()
    total_banked_points = 0
    current_drift_points = 0
    total_drift_score = 0
    current_segment_points = 0
    drift_multiplier = 1
    is_drifting = false
    drift_direction = 0
    drift_end_timer = 0.0
    reverse_entry_active = false
    reverse_entry_timer = 0.0
    last_total_display_level = 0
    last_multiplier_level = 0
    session_best_single_drift = 0
    session_best_total_points = 0
    sweet_spot_time = 0.0
    perfect_zone_time = 0.0
    consistency_bonus = 0
    drift_smoke_timer = 0.0
    smoke_stage = 0
    total_drift_time = 0.0
    is_farming = false
    last_speed_for_crash = 0
    crash_detection_timer = 0.0
    crash_cooldown_timer = 0.0
    drift_cancelled_by_crash = false
    backward_movement_timer = 0.0
    reverse_entry_failures = 0
    
    -- Reset angle bonus system
    angle_tracking_enabled = false
    angle_samples = {}
    angle_sample_count = 0
    drift_start_time = 0
    drift_end_time = 0
    dominant_angle_range = ""
    dominant_angle_duration = 0
    angle_bonus_points = 0
    angle_bonus_notification = ""
    for range, _ in pairs(angle_range_durations) do
        angle_range_durations[range] = 0
    end
    
    -- Reset all tracking arrays
    rotation_samples = {}
    sample_index = 1
    position_samples = {}
    position_sample_index = 1
    speed_variance_samples = {}
    speed_sample_index = 1
    total_rotation_magnitude = 0.0
    last_significant_rotation_time = os.clock()
    
    ac.log("🏁 Session reset - all variables cleared including Angle Bonus System")
end

-- Reset drift-specific tracking when drift starts
function reset_drift_tracking()
    rotation_samples = {}
    sample_index = 1
    position_samples = {}
    position_sample_index = 1
    speed_variance_samples = {}
    speed_sample_index = 1
    total_rotation_magnitude = 0.0
    last_significant_rotation_time = os.clock()
    
    -- Reset angle bonus tracking
    angle_tracking_enabled = false
    angle_samples = {}
    angle_sample_count = 0
    for range, _ in pairs(angle_range_durations) do
        angle_range_durations[range] = 0
    end
end
