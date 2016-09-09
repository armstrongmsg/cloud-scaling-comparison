require(dplyr)
require(ggplot2)
require(reshape2)

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

# Multiple plot function
#
# ggplot objects can be passed in ..., or to plotlist (as a list of ggplot objects)
# - cols:   Number of columns in layout
# - layout: A matrix specifying the layout. If present, 'cols' is ignored.
#
# If the layout is something like matrix(c(1,2,3,3), nrow=2, byrow=TRUE),
# then plot 1 will go in the upper left, 2 will go in the upper right, and
# 3 will go all the way across the bottom.
#
multiplot <- function(..., plotlist=NULL, file, cols=1, layout=NULL) {
  library(grid)
  
  # Make a list from the ... arguments and plotlist
  plots <- c(list(...), plotlist)
  
  numPlots = length(plots)
  
  # If layout is NULL, then use 'cols' to determine layout
  if (is.null(layout)) {
    # Make the panel
    # ncol: Number of columns of plots
    # nrow: Number of rows needed, calculated from # of cols
    layout <- matrix(seq(1, cols * ceiling(numPlots/cols)),
                     ncol = cols, nrow = ceiling(numPlots/cols))
  }
  
  if (numPlots==1) {
    print(plots[[1]])
    
  } else {
    # Set up the page
    grid.newpage()
    pushViewport(viewport(layout = grid.layout(nrow(layout), ncol(layout))))
    
    # Make each plot, in the correct location
    for (i in 1:numPlots) {
      # Get the i,j matrix positions of the regions that contain this subplot
      matchidx <- as.data.frame(which(layout == i, arr.ind = TRUE))
      
      print(plots[[i]], vp = viewport(layout.pos.row = matchidx$row,
                                      layout.pos.col = matchidx$col))
    }
  }
}

# TODO fix the directory dependence
data.client <- read.csv("analysis/requests.txt", sep = "-", header = FALSE)
scaling.client <- read.csv("analysis/scaling_times.txt", sep = "-", header = FALSE)

# TODO add scaling type
colnames(data.client) <- c("timestamp", "request_time", "scaling_type")
colnames(scaling.client) <- c("start", "end", "scaling_type")

# Convert all times to seconds
data.client$timestamp <- data.client$timestamp/10^9
scaling.client$start <- scaling.client$start/10^9
scaling.client$end <- scaling.client$end/10^9

# FIXME there must be a better solution
# Gets elapsed time
data.client.cpucap <- filter(data.client, scaling_type == "CPU_CAP")
data.client.cpucap.start <- data.client.cpucap$timestamp[1]
data.client.cpucap$timestamp <- data.client.cpucap$timestamp - data.client.cpucap.start

# Analyze only the first 3 scaling processes
scaling.client.cpucap <- head(filter(scaling.client, scaling_type == "CPU_CAP"), 3)
scaling.client.cpucap$start <- scaling.client.cpucap$start - data.client.cpucap.start
scaling.client.cpucap$end <- scaling.client.cpucap$end - data.client.cpucap.start

data.client.n_cpus <- filter(data.client, scaling_type == "N_CPUs")
data.client.n_cpus.start <- data.client.n_cpus$timestamp[1]
data.client.n_cpus$timestamp <- data.client.n_cpus$timestamp - data.client.n_cpus.start

# Analyze only the first 3 scaling processes
scaling.client.n_cpus <- head(filter(scaling.client, scaling_type == "N_CPUs"), 3)
scaling.client.n_cpus$start <- scaling.client.n_cpus$start - data.client.n_cpus.start
scaling.client.n_cpus$end <- scaling.client.n_cpus$end - data.client.n_cpus.start

data.client.vms <- filter(data.client, scaling_type == "VMs")
data.client.vms.start <- data.client.vms$timestamp[1]
data.client.vms$timestamp <- data.client.vms$timestamp - data.client.vms.start

# Analyze only the first 3 scaling processes
scaling.client.vms <- head(filter(scaling.client, scaling_type == "VMs"), 3)
scaling.client.vms$start <- scaling.client.vms$start - data.client.vms.start
scaling.client.vms$end <- scaling.client.vms$end - data.client.vms.start

data.client <- rbind(data.client.cpucap, data.client.n_cpus, data.client.vms)
scaling.client <- rbind(scaling.client.cpucap, scaling.client.n_cpus, scaling.client.vms)

useful.scaling <- scaling.client
useful.data <- data.client

scaling.client.cpucap <- mutate(scaling.client.cpucap, type="CPU_CAP")
scaling.client.n_cpus <- mutate(scaling.client.n_cpus, type="N_CPUs")
scaling.client.vms <- mutate(scaling.client.vms, type="VMs")

# Mark the scaling period the data belong to
data.client.cpucap <- mutate(data.client.cpucap, scaling = ifelse (timestamp < scaling.client.cpucap$end[1],1, ifelse (timestamp < scaling.client.cpucap$end[2],2, ifelse (timestamp < scaling.client.cpucap$end[3],3,4))))
data.client.n_cpus <- mutate(data.client.n_cpus, scaling = ifelse (timestamp < scaling.client.n_cpus$end[1],1, ifelse (timestamp < scaling.client.n_cpus$end[2],2, ifelse (timestamp < scaling.client.n_cpus$end[3],3,4))))
data.client.vms <- mutate(data.client.vms, scaling = ifelse (timestamp < scaling.client.vms$end[1],1, ifelse (timestamp < scaling.client.vms$end[2],2, ifelse (timestamp < scaling.client.vms$end[3],3,4))))

latency <- rbind(data.client.cpucap, data.client.n_cpus, data.client.vms)
latency$type <- factor(latency$scaling_type, labels = c("CPU Cap", "N CPUs", "VMs"))
scaling <- rbind(scaling.client.cpucap, scaling.client.n_cpus, scaling.client.vms)
scaling$type <- factor(scaling$scaling_type, labels = c("CPU Cap", "N CPUs", "VMs"))

ggplot(latency, aes(x=latency$timestamp,y=latency$request_time/10^9)) + 
  geom_line() +
  geom_step(mapping=aes(x=timestamp,y=scaling/2), color = "blue") + 
  facet_grid(type ~ .) +
  xlab("Time (seconds)") +
  ylab("Request time (seconds)") +
  coord_cartesian(ylim = c(0,3))

ggsave("analysis/plots/client_request_time.png")

elapsed_time <- 5

tp_mean.cpucap <- throughput_mean(data.client.cpucap$timestamp, elapsed_time)
colnames(tp_mean.cpucap) <- c("time", "count")
tp_mean.cpucap$time <- elapsed_time*as.numeric(tp_mean.cpucap$time)
tp_mean.cpucap$count <- tp_mean.cpucap$count/elapsed_time

tp_mean.n_cpus <- throughput_mean(data.client.n_cpus$timestamp, elapsed_time)
colnames(tp_mean.n_cpus) <- c("time", "count")
tp_mean.n_cpus$time <- elapsed_time*as.numeric(tp_mean.n_cpus$time)
tp_mean.n_cpus$count <- tp_mean.n_cpus$count/elapsed_time

tp_mean.vms <- throughput_mean(data.client.vms$timestamp, elapsed_time)
colnames(tp_mean.vms) <- c("time", "count")
tp_mean.vms$time <- elapsed_time*as.numeric(tp_mean.vms$time)
tp_mean.vms$count <- tp_mean.vms$count/elapsed_time

tp_mean.cpucap <- mutate(tp_mean.cpucap, type="CPU_CAP")
tp_mean.n_cpus <- mutate(tp_mean.n_cpus, type="N_CPUs")
tp_mean.vms <- mutate(tp_mean.vms, type="VMs")

scaling.client.cpucap <- mutate(scaling.client.cpucap, type="CPU_CAP")
scaling.client.n_cpus <- mutate(scaling.client.n_cpus, type="N_CPUs")
scaling.client.vms <- mutate(scaling.client.vms, type="VMs")

# Mark the scaling period the data belong to
tp_mean.cpucap <- mutate(tp_mean.cpucap, scaling = ifelse (time < scaling.client.cpucap$end[1],1, ifelse (time < scaling.client.cpucap$end[2],2, ifelse (time < scaling.client.cpucap$end[3],3,4))))
tp_mean.n_cpus <- mutate(tp_mean.n_cpus, scaling = ifelse (time < scaling.client.n_cpus$end[1],1, ifelse (time < scaling.client.n_cpus$end[2],2, ifelse (time < scaling.client.n_cpus$end[3],3,4))))
tp_mean.vms <- mutate(tp_mean.vms, scaling = ifelse (time < scaling.client.vms$end[1],1, ifelse (time < scaling.client.vms$end[2],2, ifelse (time < scaling.client.vms$end[3],3,4))))

tp_mean <- rbind(tp_mean.cpucap, tp_mean.n_cpus, tp_mean.vms)
tp_mean$type <- factor(tp_mean$type, labels = c("CPU Cap", "N CPUs", "VMs"))
scaling <- rbind(scaling.client.cpucap, scaling.client.n_cpus, scaling.client.vms)
scaling$type <- factor(scaling$type, labels = c("CPU Cap", "N CPUs", "VMs"))

ggplot(tp_mean, aes(x=tp_mean$time,y=tp_mean$count)) + 
  geom_line() +
  geom_step(mapping=aes(x=time,y=scaling*10), color = "blue") + 
  facet_grid(type ~ .) +
  xlab("Time (seconds)") +
  ylab("Throughput (requests per second)")

ggsave("analysis/plots/throughput_mean5.png")
