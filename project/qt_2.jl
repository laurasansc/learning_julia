#------------------------------------------------------------------------------------------
# IMPORT LIBRARIES
#------------------------------------------------------------------------------------------
#using Plots

#------------------------------------------------------------------------------------------
# READ ARGS ------ create help for args and try and catch for errors
#------------------------------------------------------------------------------------------
filename = ARGS[1]
qt = ARGS[2]

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

	distance_matrix = get_matrix(coordinates)
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

function get_matrix(coordinates::Array)
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
		push!(row, i)
		for j in points
			if i != j && distance_matrix[i,j] < threshold
				push!(row, j)
			end	
		end
		push!(candidate_points, row)
	end
	return candidate_points
end


function get_clusters(candidate_points::Array, threshold::Float64, distance_matrix::Array)
	
	candidate_points_2 = deepcopy(candidate_points)
	candidate_cluster = Vector{Int64}()

	push!(candidate_cluster, candidate_points_2[1])
	popat!(candidate_points_2, 1)
	
	# Now get the distance from the centroid point to other points from the candidate_cluster
	neighbor_distance = distance_matrix[candidate_cluster[1],candidate_points_2]
	cluster_diameter = 0.0
	println(candidate_points_2)
	while isempty(candidate_points_2) == false

		nearest_neighbor = argmin(neighbor_distance)
		cluster_diameter = neighbor_distance[nearest_neighbor]

		push!(candidate_cluster, candidate_points_2[nearest_neighbor])
		popat!(candidate_points_2, nearest_neighbor)
		popat!(neighbor_distance, nearest_neighbor)

		for i in length(neighbor_distance):-1:1
			item = neighbor_distance[i]

			
			if item < distance_matrix[candidate_cluster[end],candidate_points_2[i]]
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

function update_points(points, top_cluster)
	for point in top_cluster
		remove!(points,point)
	end
	return points
end

function get_top_cluster(output_cluster, output_cluster_diameter)
	# check which cluster has the highest num of clusters
	# use max algorithm
	# if n > 1 we check the diameters of the clusters and we get the output with the smallest diameter
	# if same diameters get smallest index

	longest_cluster = (output_cluster[1],1)
	cluster_diameter = output_cluster_diameter[1]

	for i in 1:length(output_cluster)
		if length(output_cluster[i]) > length(longest_cluster[1])
			longest_cluster = [output_cluster[i],i]
			cluster_diameter = output_cluster_diameter[i]
		elseif length(output_cluster[i]) == length(longest_cluster[1])
			if output_cluster_diameter[i] < cluster_diameter
				longest_cluster = [output_cluster[i],i]
				cluster_diameter = output_cluster_diameter[i]

			elseif output_cluster_diameter[i] == output_cluster_diameter[longest_cluster[2]]
				if output_cluster[i][1] < longest_cluster[1][1]
					longest_cluster = [output_cluster[i],i]
					cluster_diameter = output_cluster_diameter[i]
				end
			end
		end
	end
	return longest_cluster[1], cluster_diameter
end

function qt_clustering(distance_matrix::Array, threshold::Float64, candidate_points::Array)
	
	output_cluster = Vector{Array{Int64}}()
	output_cluster_diameter = Vector{Float64}()
	new_cluster_points = Vector{Int64}()

	#For each start position 
	for x in candidate_points
		if length(x) > 1
			new_cluster_points, diameter = get_clusters(x, threshold, distance_matrix)
			push!(output_cluster, new_cluster_points)
			push!(output_cluster_diameter, diameter)
		else
			push!(output_cluster, x)
			push!(output_cluster_diameter, 0.0)
		end 
	end
	return output_cluster, output_cluster_diameter

end

function print_to_file(selected_clusters, data_lines, selected_clusters_diameter)
	output_file = open("output_clusters.txt", "w")

	sort(collect(zip(selected_clusters, selected_clusters_diameter)); by=first)
	for i in 1:length(selected_clusters)
		diameter = selected_clusters_diameter[i]
		println(output_file, "-> Cluster $i  Diameter:  $diameter")
		for points in selected_clusters[i]
			line =  data_lines[points]
			println(output_file, "$line")
		end
	end
	close(output_file)
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

	# final results
	selected_clusters = Array{Array{Int64,1}, 1}()
	selected_clusters_diameter = Array{Float64,1}()

	while isempty(points) == false
		
		candidate_cluster, candidate_cluster_diameter = qt_clustering(distance_matrix, threshold, candidate_points)
		
		top_cluster, top_diameter = get_top_cluster(candidate_cluster, candidate_cluster_diameter)

		points = update_points(points, top_cluster)

		push!(selected_clusters, sort(top_cluster))
		push!(selected_clusters_diameter, top_diameter)
		
		candidate_points = get_candidates(distance_matrix, threshold, points)
		
	end
	print_to_file(selected_clusters,data_lines, selected_clusters_diameter)
end

#------------------------------------------------------------------------------------------
# MAIN
#------------------------------------------------------------------------------------------

@time QT(filename, qt)
