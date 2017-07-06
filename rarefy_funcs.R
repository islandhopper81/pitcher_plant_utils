# functions for rarefication

require("AMOR", quietly=T)

my_rare = function(tbl, rare=1000, out_file=NULL, out_obj=NULL) {
	if ( ! is.matrix(tbl) ) {
		tbl = as.matrix(tbl)
	}
    # remove samples that have fewer than opt$rare
    tot = apply(tbl, 2, sum)
    to_keep = tot > rare
    tbl = tbl[,to_keep]

    rare = rarefaction(x=tbl, sample=rare)

    if ( ! is.null(out_file) ) { 
        write.table(rare, file=out_file, quote=F, row.names=T, col.names=T, sep="\t")
    }   

    if ( ! is.null(out_obj) ) { 
        save(rare, file=out_obj)
    }   

    return(rare)
}
