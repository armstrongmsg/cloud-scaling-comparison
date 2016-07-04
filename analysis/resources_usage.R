require(dplyr)
require(ggplot2)

args <- commandArgs(trailingOnly = TRUE)
input_log_file <- args[1]
plot_output_file <- args[2]

data <- read.csv(input_log_file, sep = " ", header = FALSE)
colnames(data) <-  c("timestamp", "idle")

data <- data %>% mutate(usage = 100 - idle)
data$timestamp <- data$timestamp/10^9

ggplot(data, aes(timestamp, usage)) + 
  geom_line() +
  xlab("Timestamp (in seconds)") +
  ylab("CPU usage (in %)")
ggsave(plot_output_file)
