#------------------------------------------------------------------------------------------
# IMPORT LIBRARIES
#------------------------------------------------------------------------------------------
#using Plots
using LinearAlgebra
#------------------------------------------------------------------------------------------
# BASICS
#------------------------------------------------------------------------------------------
function remove!(array, element)
	# Function to remove elements from array
	return filter!(e -> e ≠ element, array)
end

function symmetric_diff!(s1,s2)
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

function get_threshold(qt::String, distance_matrix::Array{Float64,2})
	sample_diameter = maximum(distance_matrix)
	# Define the threshold
	if occursin("%", qt) == true
		threshold = sample_diameter * parse(Float64,qt[1:end-1]) / 100
	else
		threshold = parse(Float64,qt)
	end
	return threshold
end

function calculate_distance_matrix(coordinates::Array{Any,1})
	# from coordinates construct a distance matrix
	n = length(coordinates)
	MA = zeros(Float64, n, n)

	for j = 1:n, i = 1:n
        MA[i,j] = sqrt(sum(abs2.(coordinates[j])) + sum(abs2.(coordinates[i])) - 2*(⋅)(coordinates[i],coordinates[j]))
    end
    return MA
end

#------------------------------------------------------------------------------------------
# START CLUSTERING
#------------------------------------------------------------------------------------------
function get_candidates(distance_matrix::Array{Float64,2}, threshold::Float64, points::Array{Int64,1})
	# points that are candidates for a cluster  
	# are distance < threshold to the centroid point
	candidate_points = Vector{}()
	
	for i = 1:length(points)
		row = []
		#push!(row, i)
		for j = 1:length(points)
			if i != j && distance_matrix[i,j] < threshold
				push!(row, j)
			end	
		end
		push!(candidate_points, row)
	end
	return candidate_points
end


function calculate_candidate_cluster(origin::Int64, candidate_points::Array{Any,1}, threshold::Float64, distance_matrix::Array{Float64,2})

	candidate_points_2 = deepcopy(candidate_points)
	candidate_cluster = []

	push!(candidate_cluster, origin)
	
	# Now get the distance from the centroid point to other points from the candidate_cluster
	neighbor_distance = distance_matrix[candidate_cluster[1], candidate_points_2]
	cluster_diameter = 0.0
	
	while isempty(candidate_points_2) == false

		nearest_neighbor = argmin(neighbor_distance)
		cluster_diameter = neighbor_distance[nearest_neighbor]

		push!(candidate_cluster, candidate_points_2[nearest_neighbor])
		popat!(candidate_points_2, nearest_neighbor)
		popat!(neighbor_distance, nearest_neighbor)

		for i in length(neighbor_distance):-1:1

			selected_distance = neighbor_distance[i]

			if selected_distance < distance_matrix[candidate_cluster[end],candidate_points_2[i]]
				neighbor_distance[i]=distance_matrix[candidate_cluster[end],candidate_points_2[i]]
			end

			if neighbor_distance[i] > threshold
				popat!(candidate_points_2,i)
				popat!(neighbor_distance,i)
			end
		end
	end

	return candidate_cluster, cluster_diameter
end


function update_points(points::Array{Int64,1}, top_cluster::Array{Int64,1})
	for point in top_cluster
		remove!(points,point)
	end
	return points
end

function get_top_cluster(points::Array{Int64,1}, output_cluster::Array{Array{Int64,1},1}, output_cluster_diameter::Array{Float64,1})
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

function qt_clustering(distance_matrix::Array{Float64,2}, threshold::Float64, candidate_points::Array{Any,1}, points::Array{Int64,1}, output_cluster::Array, output_cluster_diameter::Array{Float64,1})
	
	new_cluster_points = Vector{Int64}()
	
	#For each start position 
	for x in points
		if isempty(output_cluster[x]) == true
			output_cluster[x], output_cluster_diameter[x] = calculate_candidate_cluster(x, candidate_points[x], threshold, distance_matrix)
		end 
	end
end

function recalculate_candidate_points(points::Array{Int64,1}, candidate_points::Array{Any,1}, index_top_cluster::Int64, output_cluster::Array{Array{Int64,1},1})
	# Get points that are QT distance from top_cluster points
	aggregate = Set()
	
	for point in output_cluster[index_top_cluster]
		union!(aggregate, Set(candidate_points[point]))
	end
	
	aggregate = setdiff(aggregate, Set(output_cluster[index_top_cluster]))

	for point in aggregate
		output_cluster[point] = Vector{Array{Int64}}()
	end
	
	for point in aggregate
		candidate_points[point] = setdiff(candidate_points[point], output_cluster[index_top_cluster])
		if isdisjoint(output_cluster[point], output_cluster[index_top_cluster]) == false
			output_cluster[point] = Vector{Array{Int64}}()
		end
	end
	
end

function print_to_file(output_file::IOStream, top_cluster::Array{Int64,1}, data_lines::Array{String,1}, top_diameter::Float64, counter::Int64)
	println(output_file, "-> Cluster $counter  Diameter:  $top_diameter")
	for points in sort(top_cluster)
		line =  data_lines[points]
		println(output_file, "$line")
	end
end

function QT(filename::String, qt::String)
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
		#println(output_cluster[index_top_cluster])
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
