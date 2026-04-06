#!/bin/bash
#SBATCH -J vortex_bank_cut
#SBATCH --cpus-per-task=8
#SBATCH --ntasks=1
#SBATCH --nodes=1
#SBATCH --mem-per-cpu=64G
#SBATCH --time=12:00:00
#SBATCH --mail-type=END,FAIL
#SBATCH --export=ALL
#SBATCH --output=%x.o%j
#SBATCH --error=%x.e%j

cores=4
warps=4
threads=32
kernel=sgemm2
cutcycle=10000

file_full="128_32_${cores}_${warps}_${threads}_${kernel}_${cutcycle}_full_output.txt"
file_perf="128_32_${cores}_${warps}_${threads}_${kernel}_${cutcycle}_perf_output.txt"

> "$file_full"
> "$file_perf"

echo "start file" >  multi_cycle_cut_output.csv

for ((i=32; i>=1; i/=2))
do
    full_output=$(./build/ci/blackbox.sh --cores=$cores --warps=$warps --threads=$threads --app=$kernel --driver=rtlsim --cutfactor=$i --cutcycle=$cutcycle --perf=2 --args="-n128 -t32")
    perf_output=$(echo "$full_output" | grep "^PERF: instrs")
    echo "$full_output" >> "$file_full"
    echo "$perf_output" >> "$file_perf"
done

# add different kernels to compare against