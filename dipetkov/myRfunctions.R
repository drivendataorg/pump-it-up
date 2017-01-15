
## Three functions to reduce the number of levels of a categorical variable
## by grouping the smaller levels into "other"

reduce.num.levels = function(x, nlevels = 12) {
  levels = table(x)
  if ( n_distinct(x) > (nlevels+1) )  {
    small.levels = names(sort(levels, decreasing = TRUE)[ - seq(nlevels)])
    x[x %in% small.levels] = "other"
  }
  return (x)
}
reduce.size.levels = function(x, min.size = 500) {
  levels = table(x)
  if ( min(levels) < min.size) {
    small.levels = names(levels[levels < min.size])
    x[x %in% small.levels] = "other"
  }
  return (x)
}
myreduce.levels = function(x) {
  return (reduce.num.levels(reduce.size.levels(x)))
}
