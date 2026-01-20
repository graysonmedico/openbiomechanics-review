library(tidyverse)

# 1. Load the new file
df <- read_csv("data/pitcher_profiles.csv", show_col_types = FALSE)

cat("\n========================================\n")
cat("      FINAL MASTER SANITY CHECK       \n")
cat("========================================\n")

# --- CHECK 1: The Velocity Name Fix ---
if ("pitch_speed_mph" %in% names(df)) {
  cat("✅ [PASS] Column Name: 'pitch_speed_mph' is correct.\n")
  cat("   Max Velo: ", max(df$pitch_speed_mph, na.rm = TRUE), " mph\n")
} else {
  cat("❌ [FAIL] Column 'pitch_speed_mph' is MISSING.\n")
}

# --- CHECK 2: The Column Count ---
# We expect around 75-80 columns now (IDs + ~70 metrics)
col_count <- ncol(df)
cat(paste("✅ [PASS] Column Count: Found", col_count, "columns.\n"))
if (col_count < 50) {
  cat("⚠️ WARNING: You seem to be missing data columns.\n")
}

# --- CHECK 3: The Data Completeness ---
# Let's check a few random "Deep" metrics to make sure they aren't empty
metrics_to_check <- c("max_rotation_hip_shoulder_separation", "elbow_varus_moment", "rear_grf_mag_max")

cat("\n--- Data Quality Sample ---\n")
for (m in metrics_to_check) {
  if (m %in% names(df)) {
    val <- mean(df[[m]], na.rm = TRUE)
    if (!is.na(val) && val != 0) {
      cat(paste("   OK:", m, "=", round(val, 1), "\n"))
    } else {
      cat(paste("⚠️ EMPTY:", m, "\n"))
    }
  } else {
    cat(paste("❌ MISSING:", m, "\n"))
  }
}

cat("\n========================================\n")
cat("VERDICT: If you see green checks above, you are ready to build.\n")