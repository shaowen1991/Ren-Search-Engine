#!/bin/bash
#This script is used to crawling, indexing and MPI_pageranking within one click 
#The difference between this file and run_setup.sh: 
#	the MPI setup commands
#	converting the linksnet.dat to MPI_linksnet.dat that the Java can read as input.
#	compile and running MPIPagerank.java

export MPJ_HOME=mpj-v0_38/
export PATH=$PATH:$MPJ_HOME/bin

ruby newcrawler.rb
ruby indexer.rb pagedata/ index.dat
ruby linksnet.rb
ruby MPI_input_converter.rb

javac -cp .:$MPJ_HOME/lib/mpj.jar MPIPageRank.java
mpjrun.sh -np 8 MPIPageRank pagedata/MPI_linksnet.dat pagedata/pagerank.dat 0.001 0.85 30

