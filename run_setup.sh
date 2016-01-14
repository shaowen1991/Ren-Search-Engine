#!/bin/bash
#This script is used to crawling, indexing and pageranking within one click 

ruby newcrawler.rb
ruby indexer.rb pagedata/ index.dat
ruby linksnet.rb
ruby pageranker.rb 0.001 0.85
