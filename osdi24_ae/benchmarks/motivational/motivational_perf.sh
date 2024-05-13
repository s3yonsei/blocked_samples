#!/bin/bash

# This script is for reproduce Figure 7 in the paper.

cd src

./test_motivational_case1 &
pid=$!

sleep 1

bperf record -o ../perf_t1.data -g -e task-clock -c 1000000 --weight --tid=$((pid+2)) &
bperf record -o ../perf_t2.data -g -e task-clock -c 1000000 --weight --tid=$((pid+3)) &

cd ..
