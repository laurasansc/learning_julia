#------------------------------------------------------------------------------------------
# IMPORT LIBRARIES
#------------------------------------------------------------------------------------------
#using Plots

#------------------------------------------------------------------------------------------
# BASICS
#------------------------------------------------------------------------------------------
function remove!(array, element)
	# Function to remove elements from array
	return filter!(e -> e ≠ element, array)
end

function get_euclidean_dist(vector_1::Array, vector_2::Array)
	# Calculate simple euclidean distance between two vectors
	return sqrt(sum((vector_1 - vector_2).^2))
end

function symmetric_diff!(s1::Array,s2::Array)
	# return the differences of between both arrays
	# disjoint!(s1,s2) is s1 △ s2 
	set_1 = setdiff(s1,s2)
	set_2 = setdiff(s2,s1)
	return union!(set_1, set_2)
end

#------------------------------------------------------------------------------------------
# READ FILE / THRESHOLD HANDLING / DISTANCE MATRIX 
#------------------------------------------------------------------------------------------
function read_file(filename::String)
	# In this function read the file
	# get points IDs
	# contstruct and return a distance matrix
	infile = open(filename, "r")

	data_lines = Vector{String}()
	coordinates = [] 
	for ln in eachline(infile)
		push!(data_lines, ln)

		ln = split(ln)
		rows =Vector{String}()

		for item in ln
			if match(r"^\D+", item) == nothing && match(r"\D+$", item) == nothing
				push!(rows, item)
			end
		end
		rows = parse.(Float64,rows)
		push!(coordinates, rows)

	end

	distance_matrix = calculate_distance_matrix(coordinates)
	close(infile)
	
	return data_lines, distance_matrix
end

function get_threshold(qt, distance_matrix)
	sample_diameter = maximum(distance_matrix)
	# Define the threshold
	if occursin("%", qt) == true
		threshold = sample_diameter * parse(Float64,qt[1:end-1]) / 100
	else
		threshold = parse(Float64,qt)
	end
	return threshold
end

function calculate_distance_matrix(coordinates::Array)
	# from coordinates construct a distance matrix
	# get matrix dimensions
	rows = length(coordinates)

	# distance matrix of zeros
	distance_matrix = zeros(Float64, rows, rows)

	# fill distance matrix
	for i in 1:rows
		for j in 1:rows
			if i != j || i > j 
				# calculate each point to point distance
				distance = get_euclidean_dist(coordinates[i], coordinates[j])
				distance_matrix[i,j] = distance
				distance_matrix[j,i] = distance
			end
		end
	end	
	return distance_matrix
end

#------------------------------------------------------------------------------------------
# START CLUSTERING
#------------------------------------------------------------------------------------------
function get_candidates(distance_matrix::Array, threshold::Float64, points::Array)
	# points that are candidates for a cluster  
	# are distance < threshold to the centroid point
	candidate_points = Vector{}()
	for i in points
		row = []
		#push!(row, i)
		for j in points
			if i != j && distance_matrix[i,j] < threshold
				push!(row, j)
			end	
		end
		push!(candidate_points, row)
	end
	return candidate_points
end


function calculate_candidate_cluster(origin::Int64, candidate_points::Array, threshold::Float64, distance_matrix::Array)

	# Fibonnacci list
	fib = [2, 3, 5, 8, 13, 21, 34, 55, 89, 144, 233, 377, 610, 987, 1597, 2584, 4181, 6765]
		
	
	candidate_points_2 = deepcopy(candidate_points)
	candidate_cluster = []

	push!(candidate_cluster, origin)
	
	# Now get the distance from the centroid point to other points from the candidate_cluster
	neighbor_distance = distance_matrix[candidate_cluster[1], candidate_points_2[origin]]
	cluster_diameter = 0.0
	

	while isempty(candidate_points_2[origin]) == false
		
		# Check if cluster already exists
		if length(candidate_cluster) ∈ fib
			if check_existing_candidate(candidate_cluster, output_cluster)
				println(candidate_cluster)
				candidate_cluster = []
			end
		end
		
		nearest_neighbor = argmin(neighbor_distance)
		cluster_diameter = neighbor_distance[nearest_neighbor]

		push!(candidate_cluster, candidate_points_2[origin][nearest_neighbor])
		popat!(candidate_points_2[origin], nearest_neighbor)
		popat!(neighbor_distance, nearest_neighbor)

		for i in length(neighbor_distance):-1:1
			selected_distance = neighbor_distance[i]
			if selected_distance < distance_matrix[candidate_cluster[end],candidate_points_2[origin][i]]
				neighbor_distance[i]=distance_matrix[candidate_cluster[end],candidate_points_2[origin][i]]
			end
			if neighbor_distance[i] > threshold
				popat!(candidate_points_2[origin],i)
				popat!(neighbor_distance,i)
			end
		end
	
	end

	return candidate_cluster, cluster_diameter
end

function check_existing_candidate(candidate, candidate_clusters)
	# check if the current cluster is the same as any of the candidate clusters
	if (candidate ∉ candidate_clusters) == false
		return true
	else
		return false
	end
end

function update_points(points, top_cluster)
	for point in top_cluster
		remove!(points,point)
	end
	return points
end

function get_top_cluster(points, output_cluster, output_cluster_diameter)
	# check which cluster has the highest num of clusters
	# use max algorithm
	# if n > 1 we check the diameters of the clusters and we get the output with the smallest diameter
	# if same diameters get smallest index

	index_longest_cluster = points[1]
	cluster_diameter = output_cluster_diameter[points[1]]

	for point in points
		if length(output_cluster[point]) > length(output_cluster[index_longest_cluster])
			index_longest_cluster = point
			cluster_diameter = output_cluster_diameter[point]

		elseif length(output_cluster[point]) == length(output_cluster[index_longest_cluster])
			if output_cluster_diameter[point] < cluster_diameter
				
				index_longest_cluster = point
				cluster_diameter = output_cluster_diameter[point]

			elseif output_cluster_diameter[point] == cluster_diameter
				
				if point < index_longest_cluster
					
					index_longest_cluster = point
					cluster_diameter = output_cluster_diameter[point]
				end
			end
		end
	end
	return index_longest_cluster
end

function qt_clustering(distance_matrix::Array, threshold::Float64, candidate_points::Array, points::Array, output_cluster::Array, output_cluster_diameter::Array)
	
	new_cluster_points = Vector{Int64}()

	#For each start position 
	for x in points
		if isempty(output_cluster[x]) == true
			output_cluster[x], output_cluster_diameter[x] = calculate_candidate_cluster(x, candidate_points, threshold, distance_matrix)
		end 
	end
end

function recalculate_candidate_points(points, candidate_points, index_top_cluster, output_cluster)
	# Get points that are QT distance from top_cluster points
	aggregate = Set()

	for point in output_cluster[index_top_cluster]
		push!(aggregate, candidate_points[point])
	end

	aggregate = setdiff(aggregate, output_cluster[index_top_cluster])

	for point in aggregate
		setdiff(candidate_points[point], output_cluster[index_top_cluster])
		if isdisjoint(output_cluster[point], output_cluster[index_top_cluster]) == false
			output_cluster[point] = Vector{Array{Int64}}()
		end
	end
end

function print_to_file(output_file, top_cluster, data_lines, top_diameter, counter::Int64)
	println(output_file, "-> Cluster $counter  Diameter:  $top_diameter")
	for points in sort(top_cluster)
		line =  data_lines[points]
		println(output_file, "$line")
	end
end

function QT(filename, qt)
	# Read file
	data_lines, distance_matrix = read_file(filename)

	# Get threshold, qt * max dis / 100
	threshold = get_threshold(qt, distance_matrix)

	# get list of points
	points =  Array{Int64}(1:1:size(distance_matrix,1))
	# available = Array{Int64}(1:1:size(distance_matrix,1))

	# now create primary clusters
	candidate_points = get_candidates(distance_matrix, threshold, points)

	# count clusters
	counter = 0

	# create output_file
	output_file = open("results_$filename.txt", "w")

	# output clusters & diameter
	#status_output_cluster = length(points)[false]
	output_cluster = [Int64[] for i=1:length(points)]
	output_cluster_diameter = Array{Float64}(1:1:length(points))

	while isempty(points) == false
		
		qt_clustering(distance_matrix, threshold, candidate_points, points, output_cluster, output_cluster_diameter)
		
		index_top_cluster = get_top_cluster(points, output_cluster, output_cluster_diameter)

		update_points(points, output_cluster[index_top_cluster])

		recalculate_candidate_points(points, candidate_points, index_top_cluster, output_cluster)

		counter += 1
		# avoid 2 for loops in print_to_file while printing by creating top clusters
		print_to_file(output_file, output_cluster[index_top_cluster], data_lines, round(output_cluster_diameter[index_top_cluster], digits=5), counter)
	end
	close(output_file)
end

#------------------------------------------------------------------------------------------
# MAIN
#------------------------------------------------------------------------------------------

function __main__()

	command_line_length = length(ARGS)

	if command_line_length == 2
		filename = ARGS[1]
		qt = ARGS[2]

		@time QT(filename, qt)
	elseif command_line_length == 1
		if ARGS[1] == "-h" || ARGS[1] == "--help"
			println("HELP (-h --help)\nqt.jl <input file> <threshold>\n\tThreshold: INT or INT%")
			exit(1)
		else
			println("ARGS error. See qt.jl -h or --help. ")
			exit(1)
		end
	elseif command_line_length == 0
		println("ARGS error. Too few arguments!. See qt.jl -h or --help. ")
		exit(1)
	else 
		println("ARGS error. Too many arguments!. See qt.jl -h or --help. ")
		exit(1)
	end
end

__main__()
