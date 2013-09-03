require('PEcAn.priors')

args <- commandArgs()

imgfile <- args[4]
priorname <- args[5]
aparam <- as.numeric( args[6] )
bparam <- as.numeric( args[7] )
n <- as.numeric( args[8] )

prior.density <- pr.dens(priorname, aparam, bparam)

png(imgfile, height = 100, width = 200)
p<- ggplot(data = prior.density, aes(x = x, y = y))
p <- p + geom_line()
p <- p + scale_y_continuous(breaks = NULL)
p <- p + xlab(NULL) + ylab(NULL)
<<<<<<< HEAD
p <- p + ggtitle(paste(priorname, '(', aparam, ',', bparam, ')', ' N=', n))
=======
p <- p + ggtitle(paste0(priorname, '(', aparam, ', ', bparam, ')', 'n = ', n))
>>>>>>> 9a7baf90807c6dc2c019fbf6682e774f5d7b8c35
p + theme_minimal()

dev.off()
