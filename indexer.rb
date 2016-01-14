# Code authors:  Shaowen Ren(shaoren) 
#   
# based on skeleton code by D Crandall
# encoding: utf-8

require "rubygems"
require "fast_stemmer"
require "nokogiri"

#PLEASE DOWNLOAD THE STEMMER 
#TYPE "gem install fast-stemmer" (yes, that's a dash, not underscore), into the command line

# This function writes out a hash or an array (list) to a file.
#
def write_data(filename, data)
  file = File.open(filename, "w")
  file.puts(data)
  file.close
end


# function that takes the name of a file and loads in the stop words from the file.
# You could return a list from this function, but a hash might be easier and more efficient.
#
def load_stopwords_file(file) 
  file = File.open(file, "r")
  data = file.read().split()
  file.close()
  return data
end


# function that takes the name of a directory, and returns a list of all the filenames in that
# directory.
def list_files(dir)
  filenames = Dir.entries(dir)
  
  #delete some hidden useless file
  filenames.delete('.')
  filenames.delete('..')
  filenames.delete('.DS_Store')
  return filenames
end


# function that takes the *name of an html file stored on disk*, and returns a list
#  of tokens (words) in that file. 
#
def find_tokens(filename)
  data = ""
  page = Nokogiri::HTML(open(filename))
  
  
# each loop below, is to extracting the specific text content
# of ('...') in the HTML file. 
  
  page.css('title').each do |line| #extracting <title>
    data += line.to_s
    data += " "
  end
  
  page.css('h1').each do |line| #extracting <h1>
    data += line.to_s
    data += " "
  end
  
  page.css('h2').each do |line| #extracting <h2>
    data += line.to_s
    data += " "
  end
  
  page.css('h3').each do |line| #extracting <h3>
    data += line.to_s
    data += " "
  end
  
  page.css('h4').each do |line| #extracting <h4>
    data += line.to_s
    data += " "
  end
 
  page.css('li').each do |line| #extracting <li>
    data += line.to_s
    data += " "
  end
  
  page.css('p').each do |line| #extracting <p>
    data += line.to_s
    data += " "
  end
  
  wordList = []
  for thing in data.split(/\W/)
    if thing != ""
      wordList << thing.downcase
    end
  end

  return wordList

end


# function that takes a list of tokens, and a list (or hash) of stop words,
#  and returns a new list with all of the stop words removed
#
def remove_stop_tokens(tokens, stop_words)
  
  stop_words.each do |stop|
    tokens.delete(stop)
  end

  return tokens
end


# function that takes a list of tokens, runs a stemmer on each token,
#  and then returns a new list with the stems
#
def stem_tokens(tokens)
  stem_list = []  
  for word in tokens
      stem_list << word.strip().stem
    end
  return stem_list
end


#makes the embedded hash under the intial hash per html
def make_counter_hash(doc_name, stem_tokens)
  #main hash already created. this function spits out a sub hash
    subHash = Hash.new 0
    for token in stem_tokens #per html file
      #print token
      print "\n"
      subHash[doc_name] += 1
    end

  return subHash
end        





#################################################
# Main program. We expect the user to run the program like this:
#
#   ruby index.rb pages_dir/ index.dat
#################################################

# check that the user gave us 2 command line parameters
if ARGV.size != 2
  abort "Command line should have 2 parameters."
end

# fetch command line parameters
(pages_dir, index_file) = ARGV


# read in list of stopwords from file
stop_words = load_stopwords_file("stop.txt")

# get the list of files in the specified directory
file_list = list_files(pages_dir + "pages")



superHash = {}
htmlDict = {}
pageHash = {}
docDict = {}

#docsDict = {}
file = open(pages_dir + index_file, "r")
pageNames = file.read()
pageNames = pageNames.split("\n")
pageNames.each do |page|
	page_and_URL_list = page.split()
	pageHash[page_and_URL_list[0]] = page_and_URL_list[1]
end



# scan through the documents one-by-one
#main loop of the program
print "Initializing pages"
file_list.each do |doc_name|
	print "."
	#print doc_name + "\n"
    path = pages_dir + "pages\/" + doc_name
    tokens = find_tokens(path)
    tokens = remove_stop_tokens(tokens, stop_words)
    tokens = stem_tokens(tokens)
	
	#outside dictionary for the words
	#initiates the outside dictionary 
	#because we want to exclude duplicate words 
    for token in tokens
        superHash[token] = ""
    end
	
	#separate dictionary, unrelated to words dictionary
	#stores every word from every HTML file
	#{"1.html"=>["word", "word", "word"....], "2.html" => [""""]}
	htmlDict[doc_name] = tokens
	
	############################
    #here, we are going to deal with docs.dat
	#we want: file length in tokens, title, URL
	#{"0.html" => ["FileLength", "title",URL]}
	webPage = Nokogiri::HTML(open(path))
	
	docDict[doc_name] = [tokens.count(), webPage.css("title").text.strip().delete('Â'), pageHash[doc_name]] 
	############################
	
end
#the second main loop of the program
puts ""
print "Counting...please wait\n"
term_count = superHash.keys.count
print "Constructing dictionary...please wait\n"
for word in superHash.keys
#		if term_count % 100 == 0
			print "\r#{term_count} unique words left"
#		end
		subHash = {} #restart this hash after every word 
		
		htmlDict.each do |htmldoc, wordlist| #key, value
			if wordlist.include?(word)
				subHash[htmldoc] = wordlist.grep(word).size #number of times the word appears in the list
				#example {"1.html" => 2, "2.html" => 3}
			end
		end
		superHash[word] = subHash
		#example: {"informatic => {"1.html" => 2, "2.html" => 3"}}
		term_count -= 1
end


# save the hashes to the correct files
write_data(pages_dir + "invindex.dat", superHash)
write_data(pages_dir + "docs.dat", docDict)
puts ""
print "Data written to invindex.dat and docs.dat\n"

# done!
print "complete Indexing !\n";
puts ""

