require(dplyr)
require(ggplot2)

throughput_diff <- function(data) {
  t <- c()
  for (i in 1:(length(data)-1)){
    t <- c(t, 1/(data[i+1]-data[i]))
  }
  t <- c(t, t[length(t)])
  return(t)
}

throughput_mean <- function(data, elapsed_time) {
  base <- data[1]
  data1 <- (data - base)%/%elapsed_time
  return(as.data.frame(table(data1)))
}

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

# Plot request time
ggplot(useful.data, aes(timestamp, request_time/10^9)) + 
  geom_line() +
  xlab("Timestamp (in seconds)") +
  ylab("Request time (in seconds)") + 
  geom_vline(xintercept = useful.scaling$timestamp, colour = "red")
ggsave("analysis/plots/client_request_time.png")

# Plot throughput diff
useful.data$throughput_diff <- throughput_diff(useful.data$timestamp)
useful.data <- filter(useful.data, throughput_diff < 1000)
ggplot(useful.data, aes(timestamp, throughput_diff)) + 
  geom_line() +
  xlab("Timestamp (in seconds)") +
  ylab("Throughput") + 
  geom_vline(xintercept = useful.scaling$timestamp, colour = "red")
ggsave("analysis/plots/throughput_diff.png")

# Plot throughput mean
tp_mean <- throughput_mean(useful.data$timestamp, 5)
colnames(tp_mean) <- c("time", "count")
scaling_mean <- (useful.scaling$timestamp-useful.data$timestamp[1])%/%5
ggplot(tp_mean, aes(time, count, group = 1)) + 
  geom_line() +
  xlab("Time") +
  ylab("Throughput") + 
  geom_vline(xintercept = scaling_mean, colour = "red")
ggsave("analysis/plots/throughput_mean.png")

