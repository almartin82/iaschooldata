#!/usr/bin/env Rscript
# Generate README figures for iaschooldata

library(ggplot2)
library(dplyr)
library(scales)
devtools::load_all(".")

# Create figures directory
dir.create("man/figures", recursive = TRUE, showWarnings = FALSE)

# Theme
theme_readme <- function() {
  theme_minimal(base_size = 14) +
    theme(
      plot.title = element_text(face = "bold", size = 16),
      plot.subtitle = element_text(color = "gray40"),
      panel.grid.minor = element_blank(),
      legend.position = "bottom"
    )
}

colors <- c("total" = "#2C3E50", "white" = "#3498DB", "black" = "#E74C3C",
            "hispanic" = "#F39C12", "asian" = "#9B59B6")

# Get available years (handles both vector and list return types)
years <- get_available_years()
if (is.list(years)) {
  max_year <- years$max_year
  min_year <- years$min_year
} else {
  max_year <- max(years)
  min_year <- min(years)
}

# Fetch data
message("Fetching data...")
key_years <- seq(max(min_year, 1995), max_year, by = 5)
if (!max_year %in% key_years) key_years <- c(key_years, max_year)
enr <- fetch_enr_multi(key_years)
enr_recent <- fetch_enr_multi((max_year - 10):max_year)

# 1. 30-year enrollment (state total)
message("Creating 30-year enrollment chart...")
state_trend <- enr %>%
  filter(is_state, grade_level == "TOTAL", subgroup == "total_enrollment")

p <- ggplot(state_trend, aes(x = end_year, y = n_students)) +
  geom_line(linewidth = 1.5, color = colors["total"]) +
  geom_point(size = 3, color = colors["total"]) +
  scale_y_continuous(labels = comma, limits = c(0, NA)) +
  labs(title = "Iowa Public School Enrollment",
       subtitle = "Remarkably stable at ~500,000 students for three decades",
       x = "School Year", y = "Students") +
  theme_readme()
ggsave("man/figures/enrollment-30yr.png", p, width = 10, height = 6, dpi = 150)

# 2. Hispanic growth
message("Creating Hispanic growth chart...")
hispanic <- enr %>%
  filter(is_state, grade_level == "TOTAL", subgroup == "hispanic")

p <- ggplot(hispanic, aes(x = end_year, y = pct * 100)) +
  geom_line(linewidth = 1.5, color = colors["hispanic"]) +
  geom_point(size = 3, color = colors["hispanic"]) +
  labs(title = "Hispanic Student Population in Iowa",
       subtitle = "From 2% to 13% since 1992",
       x = "School Year", y = "Percent of Students") +
  theme_readme()
ggsave("man/figures/hispanic-growth.png", p, width = 10, height = 6, dpi = 150)

# 3. Kindergarten trend
message("Creating kindergarten chart...")
k_trend <- enr_recent %>%
  filter(is_state, subgroup == "total_enrollment", grade_level == "K")

p <- ggplot(k_trend, aes(x = end_year, y = n_students)) +
  geom_line(linewidth = 1.5, color = colors["total"]) +
  geom_point(size = 3, color = colors["total"]) +
  scale_y_continuous(labels = comma) +
  labs(title = "Iowa Kindergarten Enrollment",
       subtitle = "Holding steady while other states see declines",
       x = "School Year", y = "Students") +
  theme_readme()
ggsave("man/figures/kindergarten.png", p, width = 10, height = 6, dpi = 150)

# 4. Urban-rural divide (Waukee, Ankeny, West Des Moines suburbs)
message("Creating urban-rural chart...")
suburbs <- c("Waukee", "Ankeny", "West Des Moines")

suburb_trend <- enr_recent %>%
  filter(is_district,
         grepl(paste(suburbs, collapse = "|"), district_name, ignore.case = TRUE),
         subgroup == "total_enrollment", grade_level == "TOTAL")

p <- ggplot(suburb_trend, aes(x = end_year, y = n_students, color = district_name)) +
  geom_line(linewidth = 1.2) +
  geom_point(size = 2.5) +
  scale_y_continuous(labels = comma) +
  labs(title = "Des Moines Suburb Growth",
       subtitle = "Waukee, Ankeny, and West Des Moines are booming",
       x = "School Year", y = "Students", color = "") +
  theme_readme()
ggsave("man/figures/urban-rural.png", p, width = 10, height = 6, dpi = 150)

message("Done! Generated 4 figures in man/figures/")
