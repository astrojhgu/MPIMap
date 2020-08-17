module MPIMap
    using MPI:send,recv, Comm, Status, Barrier, Bcast!, Comm_rank, Comm_size, MPI_ANY_SOURCE
    export mpi_map

    function mpi_map(func::Function, data::AbstractArray, comm::Comm)
        my_rank=Comm_rank(comm)
        println(my_rank)
        n_procs=Comm_size(comm)
        RT=Base.return_types(func, (eltype(data),))[1]
        

        result_cnt=0
        if my_rank==0
            result=Array{Union{Missing, RT}}(missing, size(data)...)
            for (i, x) in enumerate(data)
                (p, s)=recv(MPI_ANY_SOURCE, 1, comm)::Tuple{Union{Nothing, Tuple{Int, RT}}, Status}
                target=s.source
                send(i, target, 2, comm)

                if !isnothing(p)
                    result_cnt+=1
                    r_idx, r=p
                    result[r_idx]=r
                end
            end
            while true
                (p, s)=recv(MPI_ANY_SOURCE, 1, comm)::Tuple{Union{Nothing, Tuple{Int, RT}}, Status}
                target=s.source
                send(nothing, target, 2, comm)
                @assert(!isnothing(p))
                result_cnt+=1
                r_idx, r=p
                result[r_idx]=r
                if result_cnt==length(data)
                    break
                end
            end
            Barrier(comm)
            #Bcast!(result, 0, comm)
            for i in 1:(n_procs-1)
                send(result, i, 3, comm)
            end
            result
        else
            send(nothing, 0, 1, comm)
            while true
                (idx, s)=recv(0, 2, comm)::Tuple{Union{Nothing, Int}, Status}
                if isnothing(idx)
                    break
                end
                output=func(data[idx])
                send((idx, output), 0, 1, comm)
            end
            Barrier(comm)
            
            result=recv(0, 3, comm)
            result
        end
    end


end # module
