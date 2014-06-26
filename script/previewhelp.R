require('ggplot2')
pr.dens <- function(distn, parama, paramb, n = 1000, alpha = 0.001) {
  alpha <- ifelse(alpha < 0.5, alpha, 1-alpha)
  n <- ifelse(alpha == 0.5, 1, n)
  range.x <- do.call(paste('q', distn, sep = ""), list(c(alpha, 1-alpha), parama, paramb))
  seq.x   <- seq(from = range.x[1], to = range.x[2], length.out = n)
  dens.df <- data.frame(x = seq.x,
                        y = do.call(paste('d', distn, sep=""),
                                    list(seq.x, parama, paramb)))
  return(dens.df)
}

args <- commandArgs()

imgfile <- args[4]
priorname <- args[5]
aparam <- as.numeric( args[6] )
bparam <- as.numeric( args[7] )
n <- as.numeric( args[8] )

prior.density <- pr.dens(priorname, aparam, bparam)
cdf <-data.frame(x=prior.density$x,y=do.call(paste("p",sep="", priorname), list(prior.density$x, aparam, bparam)))
median.x <- cdf$x[cdf$y>=0.5][1]
median.y <- prior.density$y[prior.density$x >= median.x][1]
ci.min.x <- cdf$x[cdf$y>=0.025][1]
ci.min.y <- prior.density$y[prior.density$x >= ci.min.x][1]
ci.max.x <- cdf$x[cdf$y>=0.975][1]
ci.max.y <- prior.density$y[prior.density$x >= ci.max.x][1]
png(imgfile, height = 120, width = 200)
p<- ggplot(data = prior.density, aes(x = x, y = y))
p <- p + geom_segment(x=median.x, xend=median.x, y=0, yend=median.y, color="Blue")
p <- p + geom_segment(x=ci.min.x, xend=ci.min.x, y=0, yend=ci.min.y, color="Gray")
p <- p + geom_segment(x=ci.max.x, xend=ci.max.x, y=0, yend=ci.max.y, color="Gray")
p <- p + geom_line()
p <- p + scale_y_continuous(breaks=NULL) 
Distn <- paste0(priorname, '(', aparam, ', ', bparam, ')')
Stat <- paste0(signif(median.x,2),',[',signif(ci.min.x,2),',',signif(ci.max.x,2),']')
Size <- paste0("N= ",n);
p <- p + xlab(Size) + ylab(NULL)
p <- p + ggtitle(paste0(Distn,'\n',Stat))
p + theme_minimal()

dev.off()
