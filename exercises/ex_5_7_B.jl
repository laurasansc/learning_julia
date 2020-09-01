# This works with a file with numbers
# command line will be julia ex_5_7_B.jl <infile>
infile = ARGS[1]
open(infile) do file
	numbers = readlines(file)
	counter = 0
	total = 0

	for number in numbers
		total += parse(Int64, number)
		counter += 1
	end

	average = round(total/counter, digits = 3)
	print("The average between the numbers in the file is $average")
end