# Code authors:  Shaowen Ren(shaoren)

#This file is to convert the linksnet.dat to a Java version that MPIPageRank can use

# This function reads in a hash or an array (list) from a file produced by write_file().

def read_data(file_name)
  file = File.open(file_name,"r")
  object = eval(file.gets.untaint.encode('UTF-8', :invalid => :replace))
  file.close()
  return object
end

def converter()
  file = File.open("pagedata/MPI_linksnet.dat", "w")
  
  Ruby_hash.keys.each do |key|
	values = ""
	Ruby_hash[key].each do |value|
	  values += "#{value.delete('.html')} "
	end
	file.puts("#{key.delete('.html')}" + " "+ values)
  end
  file.close
end

Ruby_hash = read_data("pagedata/linksnet.dat")
converter()
