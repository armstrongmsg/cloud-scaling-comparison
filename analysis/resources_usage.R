require(dplyr)
require(ggplot2)

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

args <- commandArgs(trailingOnly = TRUE)
#input_log_file <- args[1]
#plot_output_file <- args[2]

input_log_file <- "analysis/merged_usage.log"
plot_output_file <- "analysis/plots/usage.png"

data <- read.csv(input_log_file, sep = " ", header = FALSE)
scaling.times <- read.csv("analysis/scaling_times.txt", sep = "-", header = FALSE)

colnames(data) <-  c("timestamp", "idle", "scaling_type")
colnames(scaling.times) <- c("start", "end", "scaling_type")

# Convert all times to seconds
data$timestamp <- data$timestamp/10^9
scaling.times$start <- scaling.times$start/10^9
scaling.times$end <- scaling.times$end/10^9

# Gets elapsed time
data.cpucap <- filter(data, scaling_type == "CPU_CAP")
data.cpucap.start <- data.cpucap$timestamp[1]
data.cpucap$timestamp <- data.cpucap$timestamp - data.cpucap.start

scaling.cpucap <- head(filter(scaling.times, scaling_type == "CPU_CAP"), 3)
scaling.cpucap$start <- scaling.cpucap$start - data.cpucap.start
scaling.cpucap$end <- scaling.cpucap$end - data.cpucap.start

data.n_cpus <- filter(data, scaling_type == "N_CPUs")
data.n_cpus.start <- data.n_cpus$timestamp[1]
data.n_cpus$timestamp <- data.n_cpus$timestamp - data.n_cpus.start

scaling.n_cpus <- head(filter(scaling.times, scaling_type == "N_CPUs"), 3)
scaling.n_cpus$start <- scaling.n_cpus$start - data.n_cpus.start
scaling.n_cpus$end <- scaling.n_cpus$end - data.n_cpus.start

data.vms <- filter(data, scaling_type == "VMs")
data.vms.start <- data.vms$timestamp[1]
data.vms$timestamp <- data.vms$timestamp - data.vms.start

scaling.vms <- head(filter(scaling.times, scaling_type == "VMs"), 3)
scaling.vms$start <- scaling.vms$start - data.vms.start
scaling.vms$end <- scaling.vms$end - data.vms.start

data.cpucap <- data.cpucap %>% mutate(usage = 100 - idle)
data.n_cpus <- data.n_cpus %>% mutate(usage = 100 - idle)
data.vms <- data.vms %>% mutate(usage = 100 - idle)

# Mark the scaling period the data belong to
data.cpucap <- mutate(data.cpucap, scaling = ifelse (timestamp < scaling.cpucap$end[1],1, ifelse (timestamp < scaling.cpucap$end[2],2, ifelse (timestamp < scaling.cpucap$end[3],3,4))))
data.n_cpus <- mutate(data.n_cpus, scaling = ifelse (timestamp < scaling.n_cpus$end[1],1, ifelse (timestamp < scaling.n_cpus$end[2],2, ifelse (timestamp < scaling.n_cpus$end[3],3,4))))
data.vms <- mutate(data.vms, scaling = ifelse (timestamp < scaling.vms$end[1],1, ifelse (timestamp < scaling.vms$end[2],2, ifelse (timestamp < scaling.vms$end[3],3,4))))

usage.data <- rbind(data.cpucap, data.n_cpus, data.vms)
usage.data$scaling_type <- factor(usage.data$scaling_type, labels = c("CPU Cap", "N CPUs", "VMs"))
scaling <- rbind(scaling.cpucap, scaling.n_cpus, scaling.vms)
scaling$scaling_type <- factor(scaling$scaling_type, labels = c("CPU Cap", "N CPUs", "VMs"))

ggplot(usage.data, aes(x=usage.data$timestamp,y=usage.data$usage)) + 
  geom_line() +
  geom_step(mapping=aes(x=timestamp,y=scaling*25), color = "blue") + 
  facet_grid(scaling_type ~ .) +
  xlab("Time (seconds)") +
  ylab("CPU Usage (%)") 

ggsave(plot_output_file)
