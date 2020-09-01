# julia ex_5_9.jl <infile> 

infile = ARGS[1]

open(infile) do file
	numbers = readlines(file)
	total_1 = 0  # sums of each column
	total_2 = 0
	total_3 = 0
	for line in numbers
		line = split(line, "\t")
		total_1 += parse(Float64, line[1]) # sums of each column
		total_2 += parse(Float64, line[2])
		total_3 += parse(Float64, line[3])
	end
	println("Sum of the first column: $total_1")
	println("Sum of the second column: $total_2")
	println("Sum of the third column: $total_3")
end

