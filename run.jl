using Pkg
Pkg.activate(".")
using MPIMap
using MPI

MPI.Init()
comm = MPI.COMM_WORLD

my_rank=MPI.Comm_rank(comm)
n_procs=MPI.Comm_size(comm)

a=zeros(5,5)
result=mpi_map(a, comm) do x
    x+1.0
end


if my_rank==0
    println(result)
end
