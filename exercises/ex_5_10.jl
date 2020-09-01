# julia ex_5_10.jl <infile> 

infile = ARGS[1]

open(infile) do file
    numbers = readlines(file)
    
    clean_array = []
    num_columns = 0
    for line in numbers
        line = split(line, "\t")
        push!(clean_array, line)
        
        num_columns = length(line)
    end 

    for i in 1:num_columns
    	total = 0
    	for item in clean_array
    		total += parse(Float64, item[i])
    	end
    	println("Column $i, the total sum is $total")
    end
end