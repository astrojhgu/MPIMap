using Pkg
Pkg.activate(".")
using MPIMap
using MPI

MPI.Init()
comm = MPI.COMM_WORLD

my_rank=MPI.Comm_rank(comm)
n_procs=MPI.Comm_size(comm)

input=zeros(15,15)
function cb(result)
    s=sum(map(result) do x
        if ismissing(x)
            1
        else
            0
        end
    end)
    println(s)
end

temp_result=Matrix{Union{Missing, Float64}}(missing, 15, 15)
# We force the [1,1] element to be 50, which is obviously a wrong result.
# The purpose is to check if the mpi_map will touch this element
# given that it has a value.
temp_result[1,1]=50.0 

result=mpi_map(input, comm, temp_result; mgr_cb=cb) do x
    x+1.0
end

answer=ones(size(input))
answer[1,1]=50.0

if my_rank==0
    @assert answer==result
    println(result)
end
