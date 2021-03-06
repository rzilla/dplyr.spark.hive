# Copyright 2015 Revolution Analytics
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

library(dplyr)
library(dplyr.spark.hive)
library(quickcheck)

my_db = src_SparkSQL()


sql_colnames =
  function(x)
    sapply(colnames(x), function(x) paste0("`", x, "`"))

rsupported.data.frame =
  function() {
    df =
      rdata.frame(
        elements =
          mixture(list(rinteger, rdouble, rcharacter)),
        nrow = c(min = 1000, max =2000), #schema autodetect fails on small dfs
        ncol = c(min = 1))
    names(df) = gsub("\\.", "_", names(df))
    df}

rnumeric.data.frame =
  function() {
    df =
      rdata.frame(
        elements =
          mixture(list(rinteger, rdouble)),
        nrow = c(min = 1000, max =2000),
        ncol = c(min = 1))
    names(df) = gsub("\\.", "_", names(df))
    df}

rdplyr_expression =
  function(height){
    sample(rselect, rarrange, rfilter, rmutate, rgroup_by, rsummarize) %>%
      if(height > 0)
        rdplyr_expression(height - 1)
    else identity}

somecols =
  function(df)
    unname(rsample(sql_colnames(df), size = ~sample(1:ncol(df), 1), replace = FALSE))

rselect =
  function(df){
    cols = somecols(df)
    function(x)
      select_(x, .dots = cols)}

arrange.expr =
  function(x)
    sample(
      c(x,
        paste("desc(", x, ")")), 1)[[1]]

rarrange =
  function(df) {
    cols = somecols(df)
    cols = lapply(cols, arrange.expr)
    function(x)
      arrange_(x, .dots = cols)}

mutate.expr =
  function(x, df) {
    if(is.numeric(df[[x]]))
      paste(sample( c("","-"), 1), x)
    else
      x}

rmutate =
  function(df) {
    cols = somecols(df)
    cols = lapply(cols, mutate.expr, df = df)
    cols = setNames(cols, letters[1:length(cols)])
    function(x)
      mutate_(x, .dots = cols)}

filter.expr =
  function(x, df) {
    if(class(df[[x]]) %in% c("integer", "double", "numeric"))
      paste(x , ">", sample(df[[x]], 1) + 0.00001)
    else{
      if(class(df[[x]]) == "Date")
        paste(x, "> ", as.character(sample(df[[x]], 1)))
      else
        TRUE}}

rfilter =
  function(df) {
    cols = somecols(df)[[1]]
    cols = unique(lapply(cols, filter.expr, df = df))
    function(x)
      filter_(x, .dots = cols)}

rsummarize =
  function(df) {
    cols = somecols(df)
    function(x)
      summarize_(x, .dots = lapply(cols, function(x) paste("mean(", x, ")")))}

rgroup_by =
  function(df) {
    cols = somecols(df)
    function(x)
      group_by_(x, .dots = cols)}


rgroup_by_summarize =
  function(x){
    rs = rsummarize(x)
    rg = rgroup_by(x)
    function(y)
      rs(rg(y))}

normalize =
  function(df) {
    df = arrange_(df, .dots = sql_colnames(df))
    rownames(df) = NULL
    as.data.frame(df)}

cmp =
  function(x, y) {
    x = normalize(x)
    y = normalize(y)
    isTRUE(all.equal(x, y))}

copy_to_from_local = dplyr.spark.hive:::copy_to_from_local

equiv.test =
  function(expr.gen, dfgen = rsupported.data.frame, src = src){
    test(
      forall(
        x = dfgen(),
        rx = expr.gen(x),
        name = dplyr:::random_table_name(), {
          on.exit(db_drop_table(table = name, con = src$con))
          retval =
            cmp(
              rx(x),
              collect(rx(copy_to_from_local(src, x, name))))
          retval}),
      about = deparse(substitute(expr.gen)))}


equiv.test(rselect, src = my_db)
equiv.test(rarrange, src = my_db)
equiv.test(rmutate, src = my_db)
equiv.test(rfilter, src = my_db)
equiv.test(rgroup_by_summarize, rnumeric.data.frame, src = my_db)
