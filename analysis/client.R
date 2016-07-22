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

plot.request.time.cpucap <- ggplot(data.client.cpucap, aes(timestamp, request_time/10^9)) + 
  geom_line() +
  xlab("") +
  ylab("") +
  ggtitle("Limitante de consumo") +
  # TODO better option?
  geom_vline(xintercept = scaling.client.cpucap$start, colour = "red") +
  geom_vline(xintercept = scaling.client.cpucap$end, colour ="blue")

plot.request.time.n_cpus <- ggplot(data.client.n_cpus, aes(timestamp, request_time/10^9)) + 
  geom_line() +
  xlab("") +
  ylab("Tempo da requisição (em segundos)") +
  ggtitle("Adição de CPUs") +
  # TODO better option?
  geom_vline(xintercept = scaling.client.n_cpus$start, colour = "red") +
  geom_vline(xintercept = scaling.client.n_cpus$end, colour ="blue")

plot.request.time.vms <- ggplot(data.client.vms, aes(timestamp, request_time/10^9)) + 
  geom_line() +
  xlab("Tempo (em segundos)") +
  ylab("") +
  ggtitle("Adição de máquinas virtuais") +
  # TODO better option?
  geom_vline(xintercept = scaling.client.vms$start, colour = "red") +
  geom_vline(xintercept = scaling.client.vms$end, colour ="blue")

png("analysis/plots/request_time.png", width=1200, height=900)
multiplot(plot.request.time.cpucap, plot.request.time.n_cpus, plot.request.time.vms)
dev.off()

ggsave("analysis/plots/client_request_time.png")

elapsed_time <- 5

tp_mean.cpucap <- throughput_mean(data.client.cpucap$timestamp, elapsed_time)
colnames(tp_mean.cpucap) <- c("time", "count")
plot.throughput.cpucap <- ggplot(tp_mean.cpucap, aes(time, count/elapsed_time, group = 1)) + 
  geom_line() +
  xlab("") +
  #ylab("Vazão (em requisições por segundo)") + 
  ylab("") +
  ggtitle("Limitante de consumo") +
  geom_vline(xintercept = scaling.client.cpucap$start%/%elapsed_time, colour = "red") +
  geom_vline(xintercept = scaling.client.cpucap$end%/%elapsed_time, colour ="blue")

tp_mean.n_cpus <- throughput_mean(data.client.n_cpus$timestamp, elapsed_time)
colnames(tp_mean.n_cpus) <- c("time", "count")
plot.throughput.n_cpus <- ggplot(tp_mean.n_cpus, aes(time, count/elapsed_time, group = 1)) + 
  geom_line() +
  xlab("") +
  ylab("Vazão (em requisições por segundo)") + 
  ggtitle("Adição de CPUs") +
  geom_vline(xintercept = scaling.client.n_cpus$start%/%elapsed_time, colour = "red") +
  geom_vline(xintercept = scaling.client.n_cpus$end%/%elapsed_time, colour ="blue")

tp_mean.vms <- throughput_mean(data.client.vms$timestamp, elapsed_time)
colnames(tp_mean.vms) <- c("time", "count")
plot.throughput.vms <- ggplot(tp_mean.vms, aes(time, count/elapsed_time, group = 1)) + 
  geom_line() +
  xlab("Tempo") +
  #ylab("Vazão (em requisições por segundo)") + 
  ylab("") +
  ggtitle("Adição de máquinas virtuais") +
  geom_vline(xintercept = scaling.client.vms$start%/%elapsed_time, colour = "red") +
  geom_vline(xintercept = scaling.client.vms$end%/%elapsed_time, colour ="blue")

png("analysis/plots/throughput.png", width=1200, height=900)
multiplot(plot.throughput.cpucap, plot.throughput.n_cpus, plot.throughput.vms)
dev.off()

ggsave("analysis/plots/throughput_mean5.png")
