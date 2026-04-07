#!/bin/bash
#SBATCH -J vortex_bank_cut
#SBATCH --cpus-per-task=8
#SBATCH --ntasks=1
#SBATCH --nodes=1
#SBATCH --mem=32G
#SBATCH --time=12:00:00
#SBATCH --mail-type=END,FAIL
#SBATCH --export=ALL
#SBATCH --output=%x.o%j
#SBATCH --error=%x.e%j
#SBATCH --array=1

cores=1 # 2
warps=32
threads=32
kernel=sgemm2 # sgemm2
cutcycle=10000
tile_size=32 # 32
problem_size=128 # 64
# how to turn off l3?

VORTEX_IMAGE="/scratch/gpfs/WENTZLAF/lm4677/differential_arch/vortex/miscs/apptainer/vortex.sif"
OG_VORTEX="/scratch/gpfs/WENTZLAF/lm4677/differential_arch/vortex"
TOOLS="/scratch/gpfs/WENTZLAF/lm4677/differential_arch/tools"

LOCAL_VORTEX="/tmp/vortex_run_${SLURM_JOB_ID}_${SLURM_ARRAY_TASK_ID}"
mkdir -p "$LOCAL_VORTEX"
cp -r "$OG_VORTEX/." "$LOCAL_VORTEX/"

cut_factor=$SLURM_ARRAY_TASK_ID

file_full="${cut_factor}_${problem_size}_${tile_size}_${cores}_${warps}_${threads}_${kernel}_${cutcycle}_full_output.txt"
file_perf="${cut_factor}_${problem_size}_${tile_size}_${cores}_${warps}_${threads}_${kernel}_${cutcycle}_perf_output.txt"

> "$file_full"
> "$file_perf"

echo "start file" >  multi_cycle_cut_output.csv

apptainer exec --cleanenv --writable-tmpfs \
  --bind "${LOCAL_VORTEX}:/home/vortex" \
  --bind "${TOOLS}:/home/tools" \
  $VORTEX_IMAGE bash -c "
    cd /home/vortex/build && \
    source ./ci/toolchain_env.sh && \
    ./ci/blackbox.sh \
  --cores=$cores --warps=$warps --threads=$threads --app=sgemm2 --driver=rtlsim \
  --cutfactor=$cut_factor --cutcycle=$cutcycle \
  --perf=2 --args='-n$problem_size -t$tile_size'" > "$file_full"

grep "^PERF: instrs" "$file_full" > "$file_perf"

# for ((i=32; i>=1; i/=2))
# do
#     full_output=$(./build/ci/blackbox.sh --cores=$cores --warps=$warps --threads=$threads --app=$kernel --driver=rtlsim --cutfactor=$i --cutcycle=$cutcycle --perf=2 --args="-n$problem_size -t$tile_size")
#     perf_output=$(echo "$full_output" | grep "^PERF: instrs")
#     echo "$full_output" >> "$file_full"
#     echo "$perf_output" >> "$file_perf"
# done

# add different kernels to compare against
# ./build/ci/blackbox.sh --cores=2 --warps=8 --threads=8 --app=sgemm2 --driver=rtlsim --cutfactor=8 --cutcycle=10000 --perf=2 --args="-n64 -t8"
# cores=2
# warps=32 <-- try to make it larger over time
# threads=32
# kernel=sgemm2
# cutcycle=10000
# tile_size=32
# problem_size=64
# 8, 16, 32