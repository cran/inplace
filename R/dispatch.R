################################################################################

# Transform negative or boolean indices to positive indices
transform_ind <- function(k, lim) {
  
  if (is.null(k)) return(seq_len(lim))
  
  if (is.character(k))
    stop2("Character subsetting is not allowed.")
  
  res <- seq_len(lim)[k]
  
  if (any(is.na(res)))
    stop2("Error when subsetting (missing values? out of bounds?)")
  
  res
}

transform_i_only <- function(i, x) {
  
  if (is.logical(i))
    stop2("Logical vector subsetting is not allowed")
  
  if (!isTRUE(all(i > 0)))
    stop2("Only positive vector subsetting is allowed")
  
  if (is.matrix(i)) {
    if (is.matrix(x)) {
      n <- nrow(x)
      m <- ncol(x)
      i <- (transform_ind(i[, 2], m) - 1) * n + transform_ind(i[, 1], n)
    } else {
      stop2("This type of accessor is only available for matrices.")
    }
  }
  
  i
}

################################################################################

process_name <- function(name) {
  `if`(identical(as.character(name), ""), NULL, name)
}

interpret_call <- function(call, val, op) {
  
  call_list <- as.list(call)
  call_len <- length(call_list)
  parent_env <- parent.frame(n = 2)
  
  i <- j <- NULL
  
  if (call_len == 1) {                        ## x
    
    acc_append <- "all"
    x <- eval(call_list[[1]], parent_env)
    
  } else if (call_len == 3) {    
    
    x <- eval(call_list[[2]], parent_env)
    
    if (is.null(process_name(call_list[[3]]))) {    ## x[]
      acc_append <- "all"
    } else {                                  ## x[i]
      acc_append <- "subvec"
      i <- transform_i_only(eval(call_list[[3]], parent_env), x)
    }
    
  } else if (call_len == 4) {                 ## x[i, j] / x[, j] / x[i, ]
    
    acc_append <- "submat"
    x <- eval(call_list[[2]], parent_env)
    stopifnot(is.matrix(x))
    
    i <- transform_ind(eval(process_name(call_list[[3]]), parent_env), nrow(x))
    j <- transform_ind(eval(process_name(call_list[[4]]), parent_env), ncol(x))
    
  } else if (call_len > 4) {
    
    stop2("This is not yet available for arrays of more than 2 dimensions.")
    
  } else {
    
    stop2(GET_ERROR_FATAL())
    
  }
  
  val_append <- `if`(length(val) == 1, "one", "mult")
  
  list(
    fun = paste(op, acc_append, val_append, sep = "_"),
    x = x,
    i = i,
    j = j, 
    val = val
  )
}

################################################################################
