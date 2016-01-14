# Code authors:  Shaowen Ren(shaoren)

# The result may show "duplicated" pages. They have the same title, but the url is a little different.
# I think it is just a problem of the crawled data.
# More details are in the comment beside the code

#"fast_stemmer" gem might need to install before running
#if this gem is not in the library, then type "gem fetch fast-stemmer" to download it.

class Retrieval

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


def retrieve(searchList,docindex,invindex,pagerank)
  allHits_hash = {} # the hash table that store how many keywords that each page contain
                    # {html => count}
		    # i.e. {"1.html" => 4, "2.html" => 2} means 1.html contains 4 keywords from user typed,
		    #      2.html contains 2 keywords.
					  
  allHits = [] #the list store the result pages that contain most of the keywords.
  search_through = 0 #initialize the total number of documents that were searched through
  
  searchList.each do |x| x.downcase! end
  searchList.each do |word| #the idea here is to loop through every word in the searchList,
    if not invindex[word].nil?
      invindex[word].keys.each do |html| #and for every keyword, extract the html pages that contain this word

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
	
  hits_score = Hash.new() # creat a new hash to store the score for each hit
  #This loop is a implementation of tf-idf algorithm
  allHits.each do |document| #calculate score for each document(hit)
    tfidf_score = 0.0 
    pagerank_score = pagerank[document]
    searchList.each do |word| #for each word in query
	
      if not invindex[word].nil?
        if not invindex[word][document].nil? #if this word exist in this document
          #add the tfidf score together
          tfidf_score += (invindex[word][document]*1.0/docindex[document][0]* 1.0) \
			 * ( 1.0 / (1 + Math.log(invindex[word].length)))
		end
      end
    end
    hits_score[document] = tfidf_score + (Math.atan(pagerank_score * 1000))/700 #score calculate method
  end	
  #this long function: 1,desending sort the hits key by value
  #					   2,convert it to another hash
  #					   
  ranked_hits = hits_score.sort_by{|_key, value| value}.reverse.to_h.keys
  
  return hits_display_cgi(ranked_hits, hits_score, search_through, docindex)
  
end


def hits_display_cgi(ranked_hits, hits_score, search_through, docindex) #result displaying method
  output = {}
  count = 1
  ranked_hits.each do |hit|	
	single_output = []
    single_output.push(count)#rank
	single_output.push(docindex[hit][1].to_s)#title
	single_output.push(docindex[hit][2])#url
    single_output.push(hits_score[hit])
    single_output.push(hits_score[hit])
    count += 1
	output[hit] = single_output
  end
  return output
end

end

