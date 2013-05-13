

require('PEcAn.utils')

args <- commandArgs()
print(args)
id <- args[4]
priorname <- args[5]
aparam <- as.numeric(args[6])
bparam <- as.numeric(args[7])


prior1 <- data.frame(distn=priorname,parama=aparam,paramb=bparam)

prior.density <- create.density.df(distribution=prior1)

png(paste('public/images/prev/',id,'.png',sep=""))
add.prior.density(prior.density)


dev.off()
