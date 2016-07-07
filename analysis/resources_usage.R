require(dplyr)
require(ggplot2)

args <- commandArgs(trailingOnly = TRUE)
input_log_file <- args[1]
plot_output_file <- args[2]

data <- read.csv(input_log_file, sep = " ", header = FALSE)
scaling.times <- read.csv("analysis/scaling_times.txt", header = FALSE)

colnames(data) <-  c("timestamp", "idle")
colnames(scaling.times) <- c("timestamp")

# Convert all times to seconds
scaling.times$timestamp <- scaling.times$timestamp/10^9
data$timestamp <- data$timestamp/10^9

# Analyze only the first 3 scaling processes
useful.scaling <- head(scaling.times, 3)
data <- data %>% mutate(usage = 100 - idle)
# Exclude the data after the last scaling process
data <- filter(data, timestamp < useful.scaling$timestamp[3] + 100)

ggplot(data, aes(timestamp, usage)) + 
  geom_line() +
  xlab("Timestamp (in seconds)") +
  ylab("CPU usage (in %)") +
  geom_vline(xintercept = useful.scaling$timestamp, colour = "red")
ggsave(plot_output_file)
