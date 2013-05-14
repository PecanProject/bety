

require('PEcAn.utils')

args <- commandArgs()
print(args)
id <- args[4]
priorname <- args[5]
aparam <- as.numeric(args[6])
bparam <- as.numeric(args[7])
n <- as.numeric(args[8])
print("success")


prior1 <- data.frame(distn=priorname,parama=aparam,paramb=bparam)

prior.density <- create.density.df(distribution=prior1)

png(paste('public/images/prev/',id,'.png',sep=""),height=220,width=220)
p<- ggplot(data=prior.density,aes(x=x,y=y))
p <- p+ geom_line()
p <- p + xlab(NULL)+ ylab(NULL)
p <- p + ggtitle(paste(priorname,'(',aparam,',',bparam,')','N=',n))
p

dev.off()
