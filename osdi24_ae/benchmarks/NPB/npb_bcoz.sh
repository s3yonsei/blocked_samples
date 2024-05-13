#!/bin/bash

export OMP_NUM_THREADS=32

# Line-level virtual speedup -> Figure 15a
for((i=0;i<5;i++))
do
	echo "Line-level virtual speedup ${i}th iter"
	sleep 2;
	taskset -c 0 bcoz run --- ./bin/is.C.x_bcoz
done

mv profile.coz profile_line-level.coz

# Subclass-level virutal speedup -> Figure 15b
# cores=1
$ for((i=0;i<5;i++)); do echo "Subclass-level virtual speedup, # cores=1, ${i}th iter"; sleep 2; taskset -c 0 bcoz run --blocked-scope s --- ./bin/is.C.x_bcoz; done
mv profile.coz profile_subclass-level-1.coz

# cores=2
$ for((i=0;i<5;i++)); do echo "Subclass-level virtual speedup, # cores=2, ${i}th iter"; sleep 2; taskset -c 0-1 bcoz run --blocked-scope s --- ./bin/is.C.x_bcoz; done
mv profile.coz profile_subclass-level-2.coz

# cores=4
$ for((i=0;i<5;i++)); do echo "Subclass-level virtual speedup, # cores=4, ${i}th iter"; sleep 2; taskset -c 0-3 bcoz run --blocked-scope s --- ./bin/is.C.x_bcoz; done
mv profile.coz profile_subclass-level-4.coz

# cores=8
$ for((i=0;i<5;i++)); do echo "Subclass-level virtual speedup, # cores=8, ${i}th iter"; sleep 2; taskset -c 0-7 bcoz run --blocked-scope s --- ./bin/is.C.x_bcoz; done
mv profile.coz profile_subclass-level-8.coz

# cores=16
$ for((i=0;i<5;i++)); do echo "Subclass-level virtual speedup, # cores=16, ${i}th iter"; sleep 2; taskset -c 0-15 bcoz run --blocked-scope s --- ./bin/is.C.x_bcoz; done
mv profile.coz profile_subclass-level-16.coz

# cores=32
$ for((i=0;i<5;i++)); do echo "Subclass-level virtual speedup, # cores=32, ${i}th iter"; sleep 2; taskset -c 0-31 bcoz run --blocked-scope s --- ./bin/is.C.x_bcoz; done
mv profile.coz profile_subclass-level-32.coz
