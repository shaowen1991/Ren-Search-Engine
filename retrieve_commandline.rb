# Code authors:  Shaowen Ren(shaoren)


#Using this file to test retrieve function in command line.

require "rubygems"
require "fast_stemmer"

def write_data(filename, data)
  file = File.open(filename, "w")
  file.puts(data)
  file.close
end

# This function reads in a hash or an array (list) from a file produced by write_file().
def read_data(file_name)
  file = File.open(file_name,"r")
  #object = eval(file.gets.untaint)
  object = eval(file.gets.untaint.encode('UTF-8', :invalid => :replace))
  file.close()
  return object
end

def load_stopwords_file(file) 
  file = File.open(file, "r")
  data = file.read().split()
  file.close()
  return data
end

def remove_stop_tokens(tokens, stop_words)
  
  stop_words.each do |stop|
    tokens.delete(stop)
  end

  return tokens
end


def stem_tokens(tokens)
  stem_list = []  
  for word in tokens
    stem_list << word.strip().stem
  end
  return stem_list
end


def retrieve(searchList)
  allHits_hash = {} # the hash table that store how many keywords that each page contain
                    # {html => count}
		    # i.e. {"1.html" => 4, "2.html" => 2} means 1.html contains 4 keywords from user typed,
		    #      2.html contains 2 keywords.
					  
  allHits = [] #the list store the result pages that contain most of the keywords.
  search_through = 0 #initialize the total number of documents that were searched through
 
  searchList.each do |x| x.downcase! end
  searchList.each do |word| #the idea here is to loop through every word in the searchList,
    if not INVINDEX[word].nil?
      INVINDEX[word].keys.each do |html| #and for every keyword, extract the html pages that contain this word

        if allHits_hash.include?(html) 
          #if this page is already in the allHits_hash,
          #which means it contains previous keyword.
          #then add 1 to that html's counting number
          #i.e. {"1.html"=> 2}  --->  {"1.html" => 3}			
          allHits_hash[html] = allHits_hash[html] + 1	
	else
          # if this page doesnt contain any previous keyword(or in the first iteration)
          # then put it in the hash and set the value(count) as 1.
          # i.e. {} ---> {"1.html" => 1}		
          allHits_hash[html] = 1  							   
        end
	search_through += 1
      end
    end
  end
	
  #then, put every hash key(html name) in the allHits_hash whose value(keywords count)
  #is greater than half of the searchList size
  allHits_hash.each {|html, count| allHits.push(html) if count >= searchList.size / 2.0 }
  #now, we have a list of all the hits. next step is to ranked them by tf-idf score
  tfidf = Hash.new()
  hits_score = Hash.new() # creat a new hash to store the score for each hit
  #This loop is a implementation of tf-idf algorithm
  allHits.each do |document| #calculate score for each document(hit)
    tfidf_score = 0.0 
    pagerank_score = PAGERANK[document]
	
    searchList.each do |word| #for each word in query
	
      if not INVINDEX[word].nil?
        if not INVINDEX[word][document].nil? #if this word exist in this document
          #add the tfidf score together
          tfidf_score += (INVINDEX[word][document]*1.0/DOCINDEX[document][0]* 1.0) \
			 * ( 1.0 / (1 + Math.log(INVINDEX[word].length)))
		end
      end
    end
    tfidf[document] = tfidf_score
    hits_score[document] = tfidf_score * pagerank_score
  end	
  #this long function: 1,desending sort the hits key by value
  #					   2,convert it to another hash

  ranked_hits = hits_score.sort_by{|_key, value| value}.reverse.to_h.keys
  
  return hits_display_commandline(ranked_hits, hits_score, search_through, tfidf)
  
end




def hits_display_commandline(ranked_hits, hits_score, search_through,tfidf) #result displaying method
  count = 1
  ranked_hits.each do |hit|		
    puts "##{count}  #{DOCINDEX[hit][2]}"
    puts "      #{DOCINDEX[hit][1].to_s} "
    puts "      TF-IDF score: #{tfidf[hit]} * PageRank: #{PAGERANK[hit]} = #{hits_score[hit]}"
    count += 1
  end
  puts "========================================================================="
  puts ""
  puts "The total number of documents that were searched through is #{search_through}."
  puts "The total number of hits that were found is #{ranked_hits.size}."
  puts ""
  puts "========================================================================="
end

################################################# 
# Main program. We expect the user to run the program like this:
#
#   ./retrieve_commandline.rb kw1 kw2 kw3 .. kwn
#################################################

# check that the user gave us correct command line parameters
abort "Command line should have at least 1 parameters." if ARGV.size<1

keyword_list = ARGV[0..ARGV.size]


#processs the keyword list
stop_words = load_stopwords_file("stop.txt")
keyword_list = remove_stop_tokens(keyword_list, stop_words)
keyword_list = stem_tokens(keyword_list)

# read in the index file produced by the crawler from Assignment 2 (mapping URLs to filenames).
DOCINDEX = read_data("pagedata/docs.dat")

# read in the inverted index produced by the indexer. 
INVINDEX = read_data("pagedata/invindex.dat")
# invindex is still a dictionary
PAGERANK = read_data("pagedata/pagerank.dat")

retrieve(keyword_list)
