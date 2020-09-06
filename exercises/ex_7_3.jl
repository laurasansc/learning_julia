# ex_7_3.jl <input> <output>


input = ARGS[1]
output = ARGS[2]

infile = open(input, "r")
outfile = open(output, "r")


# input is 1 column, put into list
start_ids = Set()
start_ids = readlines(infile)


# output is 5 columns, we want #2
lines = readlines(outfile)
res_ids = Set()

for line in lines
	line = split(line, "\t")
	push!(res_ids, line[2])
end

# now compare sets

difference = setdiff(start_ids, res_ids)
# Check which are in the 1st file that are not in the 2nd
first_check = intersect(difference, start_ids)

println(first_check)
println(difference)



close(infile)
close(outfile)