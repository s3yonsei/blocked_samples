#!/bin/bash

export OMP_NUM_THREADS=32

# cores=1
for((i=0;i<5;i++)); do echo "# cores=1 ${i}th iteration"; sleep 2; taskset -c 0 ./bin/is.C.x_perf >> temp.txt; done
echo "# cores=1" > npb.txt
cat temp.txt | grep total >> npb.txt
rm temp.txt

# cores=2
for((i=0;i<5;i++)); do echo "# cores=2 ${i}th iteration"; sleep 2; taskset -c 0-1 ./bin/is.C.x_perf >> temp.txt; done
echo "# cores=2" >> npb.txt
cat temp.txt | grep total >> npb.txt
rm temp.txt

# cores=4
for((i=0;i<5;i++)); do echo "# cores=4 ${i}th iteration"; sleep 2; taskset -c 0-3 ./bin/is.C.x_perf >> temp.txt; done
echo "# cores=4" >> npb.txt
cat temp.txt | grep total >> npb.txt
rm temp.txt

# cores=8
for((i=0;i<5;i++)); do echo "# cores=8 ${i}th iteration"; sleep 2; taskset -c 0-7 ./bin/is.C.x_perf >> temp.txt; done
echo "# cores=8" >> npb.txt
cat temp.txt | grep total >> npb.txt
rm temp.txt

# cores=16
for((i=0;i<5;i++)); do echo "# cores=16 ${i}th iteration"; sleep 2; taskset -c 0-15 ./bin/is.C.x_perf >> temp.txt; done
echo "# cores=16" >> npb.txt
cat temp.txt | grep total >> npb.txt
rm temp.txt

# cores=32
for((i=0;i<5;i++)); do echo "# cores=32 ${i}th iteration"; sleep 2; taskset -c 0-31 ./bin/is.C.x_perf >> temp.txt; done
echo "# cores=32" >> npb.txt
cat temp.txt | grep total >> npb.txt
rm temp.txt

cat npb.txt
