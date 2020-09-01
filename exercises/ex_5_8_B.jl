##### WAY B to cut MORE than 1 column #####
# julia ex_5_8_B.jl <infile> <columns> e.g. exercise.py ex1.dat 1,2,3

infile = ARGS[1] # enter a infile path
columns = ARGS[2] # enter columns

columns = split(columns, ",")

open(infile) do file 
    numbers = readlines(file)
   
    output = open("output_5_8_A.txt", "w")
    for column in columns
    	column  = parse(Int64, column)
    	for line in numbers
        	line = split(line, "\t")
        	write(output, line[column], "\n")
        end
    end
    close(output)
end