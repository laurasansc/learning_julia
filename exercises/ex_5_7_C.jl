# commandline julia ex_5_8.jl <infile>
infile = ARGS[1]

open(infile) do file
	numbers = readlines(file)
	counter = 0 
	for number in numbers
		if parse(Float32, number) < 0
			counter += 1
		end 
	end
	println("There are $counter negative numbers")
end
