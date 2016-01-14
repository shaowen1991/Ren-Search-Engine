#!/l/ruby-2.2.2/bin/ruby

#code author: Shaowen Ren(shaoren) 

require 'cgi'
require '../ren-search/retrieve.rb'

def output(input)
	output_hash = {}
	Dir.chdir('../ren-search/') do 
		retrieval = Retrieval.new
		keyword_list = input.split.to_a
		stop_words = retrieval.load_stopwords_file("stop.txt")
		keyword_list = retrieval.remove_stop_tokens(keyword_list, stop_words)
		keyword_list = retrieval.stem_tokens(keyword_list)

		docindex = retrieval.read_data("pagedata/docs.dat")
		invindex = retrieval.read_data("pagedata/invindex.dat")
		pagerank = retrieval.read_data("pagedata/pagerank.dat")
 
		output_hash = retrieval.retrieve(keyword_list,docindex,invindex,pagerank)
	end
	
	output_string = ""
	output_hash.values.each do |value|
		output_string += ("<tr> ##{value[0]}  <a href = #{value[2]}>#{value[1]}</a></tr>")
		output_string += ("<p> #{value[2]}</p>")
	end
	return output_string
end


####################################
#####      main program        #####
####################################

cgi = CGI.new("html4")
cgi.out{
	cgi.html{
		cgi.head{ "\n" + cgi.title{"Ren Search"} + "<link href=\"bootstrap.css\" rel=\"stylesheet\" type=\"text/css\">"}+ 
		cgi.body{
			"<nav class=\"navbar navbar-default\">"+

					"<!-- Collect the nav links, forms, and other content for toggling -->"+
					"<div class=\"collapse navbar-collapse\" id=\"defaultNavbar1\">"+
						"<a href=\"http://cgi.soic.indiana.edu/~shaoren/ren-search.html\">" +
							"<img src = \"logo.jpg\" alt = \"logo\" style=\"width:264px;height:25px;\">" +
						"</a>" +
	
						"<form name=\"my_form\" action=\"http://cgi.soic.indiana.edu/~shaoren/ren-search-retrieve.cgi \"style=\"float: middle\" >" +
							"<input type=\"text\" name=\"query\" class=\"form-control\"style=\"width:500px\"   placeholder=\"Search\" >" + 
							"<button type=\"submit\" class=\"btn btn-default\" value=\"Search!\" >Search</button>" + 
						"</form>" + 
				
					"</div>"+
			"</nav>"+
			"<ul class=\"navbar-nav\" style= \"padding:80px;\">"+
				"\n" + cgi.h5{"Search Result of #{cgi['query']} :"} + 
				output(cgi['query'])+ 
			"</ul>"
											

		}
	}
}

