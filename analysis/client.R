require(dplyr)
require(ggplot2)

data.client <- read.csv("logs/clients/requests.txt", sep = "-", header = FALSE)
scaling.client <- read.csv("analysis/scaling_times.txt", header = FALSE)

colnames(data.client) <- c("timestamp", "request_time")
colnames(scaling.client) <- c("timestamp")

# Convert all times to seconds
data.client$timestamp <- data.client$timestamp/10^9
scaling.client$timestamp <- scaling.client$timestamp/10^9

# Analyze only the first 3 scaling processes
useful.scaling <- head(scaling.client, 3)
# Exclude the data after the last scaling process
useful.data <- filter(data.client, timestamp < useful.scaling$timestamp[3] + 100)

ggplot(useful.data, aes(timestamp, request_time/10^9)) + 
  geom_line() +
  xlab("Timestamp (in seconds)") +
  ylab("Request time (in seconds)") + 
  geom_vline(xintercept = useful.scaling$timestamp, colour = "red")
ggsave("analysis/plots/client_request_time.png")
