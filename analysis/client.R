require(dplyr)

data.client <- read.csv("logs/clients/requests.txt", sep = "-", header = FALSE)
colnames(data.client) <- c("timestamp", "request_time")

data.client$timestamp <- data.client$timestamp/10^9

ggplot(data.client, aes(timestamp, request_time/10^9)) + 
  geom_line() +
  xlab("Timestamp (in seconds)") +
  ylab("Request time (in seconds)")
ggsave("analysis/plots/client_request_time.png")
