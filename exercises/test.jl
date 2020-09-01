println("Please enter a string:")
stdin = readline()
#result = re.search(r'\B[-]?\d+[\.]?\d+', my_str) # Search the digits that start with - or nothing, but not with .
												# search also digits that continue with a dot + more digits after
num = match(r"^[-]*\d+([\.]*\d)*+$", stdin)

if num != nothing
	println("Your number is ", num.match)
else
	println("You did not enter a number")

end