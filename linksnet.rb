
require "fileutils"

def read_data(file_name)
  file = File.open(file_name,"r")
  object = eval(file.gets)
  file.close()
  return object
end

dictData = read_data("pagedata\/dict.dat") #http://cnn.com=>[page, page, page]
indexData = File.open("pagedata\/index.dat", "r").read() #1.html http://cnn.com
indexData = indexData.split("\n") #1.html http://cnn.com
indexDict = {}

#make a simple dictionary from the index.dat to refer back to later
#http://cnn.com=>1.html

iterlist = []
for line in indexData
  line = line.split(" ")
  indexDict[line[1]] = line[0]
  iterlist << line[1]
end

prDict = Hash.new{|h, k| h[k] = []}

for key in iterlist


  thisPage = indexDict[key] #match http://cnn.com to 1.html

  prDict[thisPage] = []


  
  for link in dictData[key]
    if indexDict.keys.include?(link)
      thisPage = indexDict[key]
      
      linkedPage = indexDict[link]
      if not prDict[thisPage].include?(linkedPage)
        prDict[thisPage] << linkedPage
      end
    end
    if dictData[key].length == 0
      thisPage = indexDict[key]
      prDict[thisPage] = []
    end
  end

end


prFile = File.open("pagedata\/linksnet.dat", "w")
prFile.write(prDict)
prFile.close()

puts ""
puts "complete links net!"
puts ""