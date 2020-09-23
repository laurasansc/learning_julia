# Read inputs
# create help for args and try and catch for errors

filename = ARGS[1]
qt = ARGS[2]

#------------------------------------------------------------------------------------------
# BASICS
#------------------------------------------------------------------------------------------

function read_file(filename::String)
	# In this function read the file
	# get points IDs
	# contstruct and return a distance matrix
	infile = open(filename, "r")

	points = Vector{String}()
	coordinates = [] 
	for ln in eachline(infile)
		ln = split(ln)
		rows =Vector{String}()
		for item in ln
			if match(r"^\D+", item) == nothing && match(r"\D+$", item) == nothing
				push!(rows, item)
			else
				push!(points, item)
			end
		end
		rows = parse.(Float64,rows)
		push!(coordinates, rows)

	end
	distance_matrix = get_matrix(coordinates)
	return points, distance_matrix
end

function get_threshold(qt, distance_matrix)
	sample_diameter = maximum(distance_matrix)
	#Define the threshold
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

function get_euclidean_dist(vector_1::Array, vector_2::Array)
	# Calculate simple euclidean distance between two vectors
	return sqrt(sum((vector_1 - vector_2).^2))
end

#------------------------------------------------------------------------------------------
# START CLUSTERING
#------------------------------------------------------------------------------------------


function get_candidates(distance_matrix::Array, threshold::Float64, free_points::Array)#, calculated_points::Array)
	# points that are candidates for a cluster  
	# are distance < threshold to the centroid point
	clusters = Vector{}()
	for i in free_points
		row = []
		push!(row, i) # there is a problem here
		for j in free_points
			if i != j && distance_matrix[i,j] < threshold
				push!(row, j)
			end	
		end
		push!(clusters, row)
	end
	return clusters
end

function make_cluster(candidate_cluster::Array, threshold::Float64, distance_matrix::Array)
	
	new_cluster = Vector{Int64}()
	push!(new_cluster, candidate_cluster[1])
	popat!(candidate_cluster, 1)

	next_distance = 0.0

	# Now get the distance from the centroid point to other points from the candidate_cluster
	neighbor_distance = distance_matrix[new_cluster[1],candidate_cluster]
	
	while length(candidate_cluster) > 0 
		nearest_neighbor = argmin(neighbor_distance)
		next_distance = neighbor_distance[nearest_neighbor]
		push!(new_cluster, candidate_cluster[nearest_neighbor])
		popat!(candidate_cluster, nearest_neighbor)
		popat!(neighbor_distance, nearest_neighbor)

		for i in length(neighbor_distance):-1:1
			item = neighbor_distance[i]
			if item < distance_matrix[new_cluster[end],candidate_cluster[i]]
				neighbor_distance[i]=distance_matrix[new_cluster[end],candidate_cluster[i]]
			end

			if neighbor_distance[i] > threshold
				popat!(candidate_cluster,i)
				popat!(neighbor_distance,i)
			end
		end
	end	
	return new_cluster, next_distance
end

function get_top_cluster(output_cluster)
	#println(argmax(length.(output_cluster)))
	return output_cluster[argmax(length.(output_cluster))]
end 

function qt_clustering(distance_matrix::Array,threshold::Float64,candidate_clusters::Array)
	# dimensions of the matrix 
	m = size(distance_matrix, 1)
	n = size(distance_matrix, 2)
	

	output_cluster = Vector{Array{Int64,1}}()
	output_cluster_distance = Vector{Float64}()
	new_cluster_points = Vector{Int64}()
	#For each start position 
	for x in candidate_clusters
		if length(x) > 1
			new_cluster_points, distance = make_cluster(x, threshold, distance_matrix)
			push!(output_cluster, new_cluster_points)
			push!(output_cluster_distance, distance)
		else
			push!(output_cluster, x)
			push!(output_cluster_distance, 0.0)
		end 
	end

	return output_cluster

end

function update_points(top_cluster, selected_points, free_points)#, calculated_points,)

	selected_points = union(selected_points, top_cluster)
	free_points = setdiff(free_points,selected_points)
	#free_points = setdiff(recalculatelist,blacklist)

	return selected_points, free_points

end


function QT(filename, qt)
	# Read file
	points, distance_matrix = read_file(filename)

	# Get threshold, qt * max dis / 100
	threshold = get_threshold(qt, distance_matrix)
	
	# get lists of clusters
	#calculated_points = Array{Int64}(1:1:size(distance_matrix,1))
	selected_points = zeros(size(distance_matrix,1))
	free_points = Array{Int64}(1:1:size(distance_matrix,1))

	# Now create primary clusters
	clusters = get_candidates(distance_matrix, threshold, free_points)#, calculated_points)
	
	# get all clusters
	resulting_clusters = Array{Array{Int64,1}, 1}()

	while length(free_points) > 0
		# problem doesnt get other clusters just one then all
		candidate_clusters = qt_clustering(distance_matrix, threshold, clusters)

		#Find the biggest cluster and return it 
		top_cluster = sort(get_top_cluster(candidate_clusters))

		selected_points, free_points = update_points(top_cluster, selected_points, free_points)#,  calculated_points)
		
		if length(top_cluster) != 0
			push!(resulting_clusters, top_cluster)
		end

	end
	
	# print to output file 
	return(resulting_clusters)
	
end

@time QT(filename, qt)
