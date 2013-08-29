require('PEcAn.priors')

args <- commandArgs()

imgfile <- args[4]
priorname <- args[5]
aparam <- as.numeric( args[6] )
bparam <- as.numeric( args[7] )
n <- as.numeric( args[8] )

prior.density <- pr.dens(priorname, aparam, bparam)

png(imgfile, height = 220, width = 220)
p<- ggplot(data = prior.density, aes(x = x, y = y))
p <- p + geom_line()
p <- p + scale_y_continuous(breaks = NULL)
p <- p + xlab(NULL) + ylab(NULL)
p <- p + ggtitle(paste0(priorname, '(', aparam, ', ', bparam, ')', 'n = ', n))
p + theme_minimal()

dev.off()
