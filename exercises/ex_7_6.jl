# julia ex_7_6.jl <input file>

input = ARGS[1]

# Initialize

open(input) do file
	authors = []
	flag = false
	for ln in eachline(file)
		if occursin("TITLE", ln)
			flag = false
		end
		if flag == true
		    push!(authors, ln)
		end
		if occursin("AUTHORS", ln)
			flag = true
			authors_search = match(r"AUTHORS\s+(.+)", ln)
			push!(authors, authors_search.captures[1]) 
		end
	end

	authors_clean = []	
	for item in authors

		#item = replace(item, " and " => ", ")
		item = replace(item, " and" => ", ")
		item = strip(item)
		#println(item)
		sub_list = split(item, ", ")
		for sub_item in sub_list
			sub_item = strip(sub_item)
			push!(authors_clean, sub_item)
		end
		
	end
	println(unique(authors_clean))
end

