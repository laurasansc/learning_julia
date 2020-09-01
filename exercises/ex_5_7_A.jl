# command line will be julia ex_7_5.jl number1 number2

number1 = parse(Int64, ARGS[1])
number2 = parse(Int64, ARGS[2])

average = (number1 + number2) / 2

println("The average between $number1 and $number2 is $average")