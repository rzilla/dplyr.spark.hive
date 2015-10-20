


# dplyr.spark.hive

This package implements [`spark`](http://spark.apache.org/) and [`hive`](http://hive.apache.org) backends for the [`dplyr`](http://github.com/hadley/dplyr) package, providing a powerful and intuitive DSL to manipulate large datasets on two powerful big data platforms. It is a simple package: simple to learn if you have any familiarity with `dplyr` or even just R and SQL, simple to deploy: just a few packages to install on a single machine, as long as your Spark or Hive installations comes with JDBC support.

The current state of the project is:

 - most `dplyr` features supported
 - adds some `spark`-specific goodies, like *caching* tables.
 - can go succesfully through tutorials for `dplyr` like any other database backend. 
 - not yet endowed with a thorugh test suite. Nonetheless we expect it to inherit much of its correctness, scalability and robustness from its main dependencies, `dplyr` and `spark`.
 - we don't recommend production use yet

## Installation

For Spark, [download](https://spark.apache.org/downloads.html) and [build it](https://spark.apache.org/docs/latest/building-spark.html) as follows

```
cd <spark root>
build/mvn -Pyarn -Phadoop-2.6 -Dhadoop.version=2.6.0 -DskipTests -Phive -Phive-thriftserver clean package
```

It may work with other hadoop versions, but we need the hive and hive-thriftserver support. Spark 1.5 and later is highly recommended because of bugs that affect this package. The package is able to start the thrift server but can also connect to a running one.

For Hive, any recent Hadoop distribution should do. We did some testing with the latest HDP as provided in the Hortonworks sandbox.

`dplyr.spark.hive` has a few dependencies: get them with

```
install.packages(c("RJDBC", "dplyr", "DBI", "devtools", "purrr", "lazyeval"))
```

Indirectly `RJDBC` needs `rJava`. Make sure that you have `rJava` working with:


```r
library(rJava)
.jinit()
```

This is only a test, in general you don't need it before loading `dplyr.spark.hive`.

----------------

#### Mac Digression

On the mac `rJava` required two different versions of java installed, [for real](http://andrewgoldstone.com/blog/2015/02/03/rjava/), and in particular this shell variable set

```
DYLD_FALLBACK_LIBRARY_PATH=/Library/Java/JavaVirtualMachines/jdk1.8.0_51.jdk/Contents/Home/jre/lib/server/
```
The specific path may be different, particularly the version numbers. To start Rstudio (optional, you can use a different GUI or none at all), which doesn't read environment variables, you can enter the following command:
```
DYLD_FALLBACK_LIBRARY_PATH=/Library/Java/JavaVirtualMachines/jdk1.8.0_51.jdk/Contents/Home/jre/lib/server/ open -a rstudio
```

----------------



The `HADOOP_JAR` environment variable needs to be set to the main hadoop JAR file, something like `"<spark home>/assembly/target/scala-2.10/spark-assembly-*-hadoop*.jar"`. The packaging of Spark is under review (SPARK-11157) so expect changes here. We then may be able to bundle the necessary jars with this package, at least for the most recent versions, thus removing the need to install spark on client machines. For hive users, the path will be a little different but the principle is the same. This is needed for the instantiation of  a JDBC driver, which needs to be able to find class `org.apache.hive.jdbc.HiveDriver` fot both Spark and Hive, which share some of these components.

To start the thrift server from R, you need one more variable set, `SPARK_HOME`, as the name suggests pointing to the root of the Spark installation. If you are connecting with a running server, you just need host and port information. Those can be stored in environment variable as well, see help documentation. The option to start a server from R is not available for Hive.



Then, to install from source:


```
devtools::install_github("piccolbo/dplyr.spark.hive", subdir = "pkg")
```

We are still figuring out the details of how to conduct formal releases, whatever that means. Stay tuned.
<!--
Linux package:


```
devtools::install_url(
  "https://github.com/piccolbo/dplyr.spark.hive/releases/download/NOT AVAILABLE/dplyr.spark.hive_NOT AVAILABLE.tar.gz")
```

The current version is NOT AVAILABLE .
-->

You can find a number of examples derived from @hadley's own tutorials for dplyr looking under the [tests](https://github.com/piccolbo/dplyr.spark.hive/tree/master/pkg/tests) directory, files `databases.R`, `window-functions.R` and `two-table.R`.


<!-- For new releases, subscribe to `dplyr.spark.hive`'s Release notes [feed](https://github.com/piccolbo/dplyr.spark.hive/releases.atom). The latter is also the best place to get support, together with the  -->

If you notice any problems, please create an item in the [issue tracker](http://github.com/piccolbo/dplyr.spark.hive/issues).


