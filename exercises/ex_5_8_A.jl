##### WAY A for only 1 column ######
# julia ex_5_8_A.jl <infile> <int(column)>  e.g. exercise.py ex1.dat 1

infile = ARGS[1] # enter a infile path
column = parse(Int64, ARGS[2]) # enter column

open(infile) do file 
    numbers = readlines(file)
    
    output = open("output_5_8_A.txt", "w")
    for line in numbers
        line = split(line, "\t")
        
        write(output, line[column], "\n")
    end
    close(output)
end