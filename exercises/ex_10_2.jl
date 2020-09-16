function read_file(filename)
    dict_array = Dict()
    col_classes = []
    # Open file
    infile = open(filename, "r")
    for line in eachline(infile)
        # create a list for the 1 and 1
        if occursin("COL_CLASSES", line)
            col_classes = split(line, "\t")
            col_classes = col_classes[4:end]
        else
            # get the rest of the lines
            if occursin("DB_ID", line) == false 
                gene_data = split(line, "\t")
                id = gene_data[2]
                gene_data = gene_data[4:end]
                
                dict_array[id] = []
                
                l0 = []
                l1 = [] 
                
                # create a dictionary with a list of lists as value
                for i in 1:length(col_classes)
                    if col_classes[i] == "0"
                        push!(l0, gene_data[i])
                    end
                    if col_classes[i] == "1"
                        push!(l1, gene_data[i])
                    end
                end
                # append lists into dict value
                if length(dict_array[id]) == 0
                    push!(dict_array[id],l0)
                else
                    push!(dict_array[id][1],l0)
                end
                if length(dict_array[id]) == 1
                    push!(dict_array[id],l1)
                else
                    push!(dict_array[id][2],l1)
                end
            end
        end
    end
    return dict_array
end
        
function get_value(lst, idx)
    try
        return lst[idx]
    catch
        return " "
    end
end
   
function get_query(dict_array, acc_num) 
    # search if the query is in the dict
    if haskey(dict_array, acc_num)
        # print out the values
        v = dict_array[acc_num]
        println(v)
        println("For this accession number $acc_num there are this values:")
        println("Controls (0)\tColon Cancer Patients(1)")
        index = 1

        a_list = v[1]
        b_list = v[2]
        result = []

        for i in 1:(min(length(a_list), length(b_list)))
            push!(result,get_value(a_list, i))
            push!(result,get_value(b_list, i))
        end

        for i in min(length(a_list), length(b_list)):max(length(a_list), length(b_list))
            push!(result,get_value(a_list, i))
            push!(result,get_value(b_list, i))
        end

        for i in 1:2:length(result)
            println(join((result[i], result[i+1]), "\t\t"))

        end

    else
        print("The accession number entered ($acc_num) does not exist in the file.")
        exit(1)
    end
end


############ MAIN ################

filename = ARGS[1]
query = ARGS[2]

#Initialize
dict_array = Dict()
col_classes = []

dict_array = read_file(filename)

get_query(dict_array, query)
