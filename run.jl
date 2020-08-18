using Pkg
Pkg.activate(".")
using MPIMap
using MPI

MPI.Init()
comm = MPI.COMM_WORLD

my_rank=MPI.Comm_rank(comm)
n_procs=MPI.Comm_size(comm)

a=zeros(500,500)
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
result=mpi_map(a, comm; mgr_cb=cb) do x
    x+1.0
end


if my_rank==0
    #println(result)
end
