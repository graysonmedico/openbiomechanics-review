library(tidyverse)

# --- 1. Setup ---
if (!dir.exists("data")) dir.create("data")

poi_url  <- "https://raw.githubusercontent.com/drivelineresearch/openbiomechanics/main/baseball_pitching/data/poi/poi_metrics.csv"
meta_url <- "https://raw.githubusercontent.com/drivelineresearch/openbiomechanics/main/baseball_pitching/data/metadata.csv"

# --- 2. Download ---
message("Downloading data...")
tryCatch({
  download.file(poi_url, "data/raw_poi.csv", mode = "wb")
  download.file(meta_url, "data/raw_metadata.csv", mode = "wb")
}, error = function(e) message("Download warning (files might already exist)."))

# --- 3. Join and Rename Fix ---
message("Processing...")
df_poi  <- read_csv("data/raw_poi.csv", show_col_types = FALSE)
df_meta <- read_csv("data/raw_metadata.csv", show_col_types = FALSE)

# Join the tables
df_full <- df_poi %>%
  left_join(df_meta, by = c("session_pitch", "session"))

# --- CRITICAL FIX: Handle the renaming issue ---
# If joining created 'pitch_speed_mph.x', we rename it back to 'pitch_speed_mph'
# and force it to be numeric so it isn't dropped.
if ("pitch_speed_mph.x" %in% names(df_full)) {
  df_full <- df_full %>% rename(pitch_speed_mph = pitch_speed_mph.x)
}
df_full$pitch_speed_mph <- as.numeric(df_full$pitch_speed_mph)

# --- 4. The Complete Column List ---
cols_of_interest <- c(
  # Identifiers
  "session_pitch", "session", "user", "p_throws", "pitch_type", "pitch_speed_mph",
  
  # Max Velocities
  "max_shoulder_internal_rotational_velo", "max_elbow_extension_velo", 
  "max_torso_rotational_velo", "max_pelvis_rotational_velo", "max_cog_velo_x",
  
  # Max Angles
  "max_rotation_hip_shoulder_separation", "max_elbow_flexion", 
  "max_shoulder_external_rotation", "max_shoulder_horizontal_abduction",
  "torso_rotation_min", "arm_slot", "stride_length", "stride_angle",
  
  # Foot Plant (FP) Metrics
  "elbow_flexion_fp", "elbow_pronation_fp", "rotation_hip_shoulder_separation_fp", 
  "shoulder_horizontal_abduction_fp", "shoulder_abduction_fp", 
  "shoulder_external_rotation_fp", "lead_knee_extension_angular_velo_fp", 
  "torso_anterior_tilt_fp", "torso_lateral_tilt_fp", "torso_rotation_fp", 
  "pelvis_anterior_tilt_fp", "pelvis_lateral_tilt_fp", "pelvis_rotation_fp", 
  "glove_shoulder_horizontal_abduction_fp", "glove_shoulder_abduction_fp", 
  "glove_shoulder_external_rotation_fp",
  
  # Ball Release (BR) & MER Metrics
  "lead_knee_extension_angular_velo_br", "lead_knee_extension_angular_velo_max", 
  "lead_knee_extension_from_fp_to_br",
  "torso_anterior_tilt_br", "torso_lateral_tilt_br", "torso_rotation_br", 
  "glove_shoulder_abduction_mer", "elbow_flexion_mer", 
  "torso_anterior_tilt_mer", "torso_lateral_tilt_mer", "torso_rotation_mer",
  "cog_velo_pkh", "timing_peak_torso_to_peak_pelvis_rot_velo",
  
  # Kinetics (Torque/Force)
  "elbow_varus_moment", "shoulder_internal_rotation_moment",
  
  # Energy Flow
  "shoulder_transfer_fp_br", "shoulder_generation_fp_br", "shoulder_absorption_fp_br",
  "elbow_transfer_fp_br", "elbow_generation_fp_br", "elbow_absorption_fp_br",
  "lead_hip_transfer_fp_br", "lead_hip_generation_fp_br", "lead_hip_absorption_fp_br",
  "lead_knee_transfer_fp_br", "lead_knee_generation_fp_br", "lead_knee_absorption_fp_br",
  "rear_hip_transfer_pkh_fp", "rear_hip_generation_pkh_fp", "rear_hip_absorption_pkh_fp",
  "rear_knee_transfer_pkh_fp", "rear_knee_generation_pkh_fp", "rear_knee_absorption_pkh_fp",
  "pelvis_lumbar_transfer_fp_br", "thorax_distal_transfer_fp_br",
  
  # Ground Reaction Forces (GRF)
  "rear_grf_x_max", "rear_grf_y_max", "rear_grf_z_max", "rear_grf_mag_max", "rear_grf_angle_at_max",
  "lead_grf_x_max", "lead_grf_y_max", "lead_grf_z_max", "lead_grf_mag_max", "lead_grf_angle_at_max"
)

# --- 5. Select and Create Profiles ---
message("Aggregating data...")

df_clean <- df_full %>%
  select(any_of(cols_of_interest))

df_pitcher_profiles <- df_clean %>%
  group_by(user) %>%
  summarise(
    throws = first(p_throws), 
    pitch_count = n(),
    # Average all numeric columns found in the list above
    across(where(is.numeric), \(x) round(mean(x, na.rm = TRUE), 2))
  ) %>%
  arrange(desc(pitch_speed_mph))

# --- 6. Save ---
write_csv(df_clean, "data/cleaned_pitch_data.csv")
write_csv(df_pitcher_profiles, "data/pitcher_profiles.csv")

message("✅ Success! Full dataset processed.")
message("Columns processed: ", ncol(df_pitcher_profiles))
message("Top Pitcher Velocity: ", df_pitcher_profiles$pitch_speed_mph[1], " mph")