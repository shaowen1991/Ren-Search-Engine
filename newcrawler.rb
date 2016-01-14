require "mechanize"
require "fileutils"

def crawlPage(url) 

  #receives a url and returns that URL's source code with a list of its links
  
  mechanize = Mechanize.new
  begin
    page = mechanize.get(url)
  rescue
    print "Mech Error: " + url + "\nStill working...\n"
  end
  links = []
  #print url + "\n"
  #need to handle exceptions regarding pages that have "about.html" (non full addresses)
  begin
    page.links_with(:href => /.html/).each do |link|
      links << link.href
    end
  rescue Exception
    return "", []
  end
  pageSource = page.body()
  return pageSource, links   
end


output_dir = "pagedata"

print "Directory Name: #{output_dir}\n"
print "Delete #{output_dir} directory to start fresh? Y/N\n"
yn = gets().strip().downcase()

if yn == "y"
  begin
    FileUtils.remove_dir(output_dir)
    print "\ndirectory deleted\n"
  rescue Exception
    print "Dir does not exist\n"
  end
end


print "Enter Max_Pages\n"
max_pages = gets()
max_pages = max_pages.strip().to_i()
print "Max Pages: #{max_pages}\n"
print "Enter starting URL. I.E https://en.wikipedia.org/wiki/Facebook\n"
seedURL = gets().strip()
source = crawlPage(seedURL)



####################################
dictionary = {}
visited = []
url = seedURL
dictionary[seedURL] = []
count = 0
valueCount = 0 #for the PR algorithm
repeats = 0
keys = dictionary.keys
pageRankDict = {} #to be used in the future of PankRank

#this loop has a double purpose: 
#populate dictionary used to keep track of what needs to be crawled
#make the files and populate them ie 1.html, 2.html, etc

#create the directory
FileUtils.mkdir_p output_dir
FileUtils.mkdir_p output_dir+"/pages"

pathdat = Dir.pwd.to_s()+"/"+output_dir+"/"+"index.dat"
print "\nTotal Pages to crawl: #{max_pages}\n"


for key in keys

  if count < max_pages

    pageSource, linksList = crawlPage(key)
    sleep(1.0/10.0)
    
        
    tempList = []
    for templink in linksList
      if templink =~ / /
        templink = templink.split(" ")[0]
      else
        if not templink =~ /#/
          if templink[0..3] == "http"
            tempList << templink
          elsif templink[0] == "\/"  
            templink = key.split("\/", 4)[0] + "\/\/" + key.split("\/", 4)[2] + templink
            tempList << templink
          else
            templink = key.rpartition("\/")[0] + "\/" + templink
            tempList << templink
          end
        end
      end
    end
    
    linksList = []
    linksList = tempList    
    dictionary[key] = linksList  
    
    #initiate the addresses to the directory and files
    path = Dir.pwd.to_s()+"/"+output_dir+"/"+"pages/" +count.to_s()+".html"
    
    File.open(path, "w"){|f| f.write(pageSource.force_encoding("iso-8859-1").encode("utf-8"))}
    File.open(pathdat, "a") {|f| f.write(count.to_s()+".html "+ key + "\n")}
    
    print key
    print "\n"
    begin
      for link in dictionary[key] #for every link in the value list      
        if not keys.include?(link) 
          keys << link
        else
          repeats += 1
        end
      end
      #i'll deal with this exception later. right now, things work. 
    rescue Exception
      print "\n\n\n\nerror: " + dictionary[key] + "\n\n\n"
    end #rescue
    #crawl how many pages? number also used to name the files
    count += 1
  end
end
print "done"
dictpath = Dir.pwd.to_s()+"/"+output_dir+"/"+ "dict.dat"
dictfile = File.open(dictpath, "w")
dictfile.write(dictionary)
dictfile.close()
print "\n--Totals--\n"
print "Total Webpages indexed and sourced: #{count}\n"
print "Total unique links seen in #{count} webpages: #{keys.length}\n"
print "Total repeat links among the indexed pages: #{repeats}? <--test feature\n"
