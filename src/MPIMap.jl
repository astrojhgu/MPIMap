module MPIMap
    using MPI:send,recv, Comm, Status, Barrier, Bcast!, Comm_rank, Comm_size, MPI_ANY_SOURCE
    export mpi_map

    function mpi_map(func::Function, data::AbstractArray{T}, comm::Comm, temp_result::Union{Nothing, AbstractArray{Union{Missing, U}}}=nothing; mgr_cb::Union{Nothing, Function}=nothing) where {T,U}
        my_rank=Comm_rank(comm)
        #println(my_rank)
        n_procs=Comm_size(comm)
        n_workers=n_procs-1
        RT=Base.return_types(func, (eltype(data),))[1]
        
        if my_rank==0
            #result=similar(data)
            reply_cnt=0
            
            #result=Array{Union{Missing, RT}}(missing, size(data)...)
            result = if isnothing(temp_result)
                Array{Union{Missing, RT}}(missing, size(data)...)
            else
                @assert RT<:U
                @assert size(temp_result)==size(data)
                temp_result
            end
            
            missing_idx=findall(reshape(map(ismissing,result), length(result)))
            n_tasks=length(missing_idx)
            #println("waiting...")
            for i in missing_idx
                (p, s)=recv(MPI_ANY_SOURCE, 1, comm)::Tuple{Union{Nothing, Tuple{Int, RT}}, Status}
                reply_cnt+=1
                target=s.source
                send(i, target, 2, comm)

                if !isnothing(p)
                    #println("received from ",target)
                    r_idx, r=p
                    result[r_idx]=r
                    if !isnothing(mgr_cb)
                        mgr_cb(result)
                    end
                end
            end
            #println("shutting down...")
            while true
                (p, s)=recv(MPI_ANY_SOURCE, 1, comm)::Tuple{Union{Nothing, Tuple{Int, RT}}, Status}
                reply_cnt+=1
                #println("reply_cnt=", reply_cnt)
                target=s.source
                send(nothing, target, 2, comm)
                                
                if !isnothing(p)
                    r_idx, r=p
                    result[r_idx]=r
                    if !isnothing(mgr_cb)
                        mgr_cb(result)
                    end
                end
                if reply_cnt==n_tasks+n_workers
                    break
                end
            end
            Barrier(comm)
            #Bcast!(result, 0, comm)
            for i in 1:n_workers
                send(result, i,3,  comm)
            end
            #println("ntasks=", n_tasks)
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
            #Bcast!(result, 0, comm)
            result=recv(0, 3, comm)
            result
        end
    end


end # module
