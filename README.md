
#Ren Search Engine

 Shaowen Ren(shaoren) 


URL: http://cgi.soic.indiana.edu/~shaoren/ren-search.html

### Setting up the pages data in single-processor way by running shell script:
You might need to install three gems: fast-stemmer, mechanize and nokogiri.

Ruby version required: at least 2.2.0

```shell
	$ ./run_setup.sh
```
	if it not working, type this first:
```shell
	$ chmod 755 run_setup.sh
```
	Then, the program will ask you if you want to delete pagedata to start fresh ("Y" is recommended),
	how many pages you want to crawling, and the actual URL of the seed URL.
	After the program stop, the Search engine will be good to search.


### MPIPageRank (multi-processor) version of setting and running 
### Setting up the pages data by running shell script:
```shell
	$ ./MPI_run_setup.sh
```
	if it not working, type this first:
```shell
	$ chmod 755 MPI_run_setup.sh
```
	This will first setup the enviornment variable for the "/mpj-v0_38". Then, 
	convert the linksnet.dat to the format that MPIPageRank.java can read("MPI_linksnet.dat").
	At the end, compile MPIPageRank.java. 
	Run it with default 8 processors,delta factor = 0.001, damping factor = 0.85, iteration = 30. 
	Everything else is the same with run_setup.sh
	
	
	
	If you want to mannully running the MPIPageRank, Here is the commands you need:
```shell
	$export MPJ_HOME=mpj-v0_38/
	$export PATH=$PATH:$MPJ_HOME/bin
	$ruby MPI_input_converter.rb
	$javac -cp .:$MPJ_HOME/lib/mpj.jar MPIPageRank.java
	$mpjrun.sh -np 8 MPIPageRank pagedata/MPI_linksnet.dat pagedata/pagerank.dat 0.001 0.85 30
```
	P.S. The only difference between these two shell script is the way it deal with pagerank. 
	P.S. Do not change the location of any file or directory, that will make program doesnt work.
```

### The initial push is the first working version. I'll keep edit the code in the future as I learned something new.

