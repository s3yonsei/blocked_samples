# OSDI'24 Artifacts Evaluation


## Title: Identifying On-/Off-CPU Bottlenecks Together with Blocked Samples

Author: Minwoo Ahn, Jeongmin Han, Youngjin Kwon, Jinkyu Jeong

Contact: Minwoo Ahn (mwahn402@gmail.com), Jinkyu Jeong (jinkyu@yonsei.ac.kr)

## Contents
1. [Introduction](#1-introduction)
2. [Artifacts Components](#2-artifacts-components)
3. [Configurations](#3-configurations)
4. [Getting Started Instructions](#4-getting-started-instructions)
5. [Detailed Instructions](#5-detailed-instructions)
6. [Conclusion](#6-conclusion)

## 1. Introduction

This repository is for reproduce the experimental results presented in the paper published at OSDI'24. Our evaluations are consists of 'motivational', 'RocksDB (*prefix\_dist*, *allrandom*, *fillrandom*)', 'NPB (*integer sort*)', and 'overhead'.

We recommend that follow the instructions below after you complete the [Getting Started with Blocked Samples](https://github.com/s3yonsei/blocked_samples/tree/main?tab=readme-ov-file#getting-started-with-blocked-samples).

* #### Motivational - Figure 7, 9
* #### RocksDB-*prefix\_dist* (Section 4.2 - Optimization 1) - Figure 10
* #### RocksDB-*allrandom* (Section 4.2 - Optimization 2) - Figure 12a, 12b
* #### RocksDB-*fillrandom* (Section 4.3 - Optimization 3) - Figure 13b, 13c, 14
* #### NPB - Figure 15
* #### Overhead - Figure 16, 17


## 2. Artifacts components

Blocked samples is consists of two main components: Linux perf subsystem (Linux kernel), and BCOZ source codes (bperf is included in Linux kernel). Both are maintained in *bcoz* and *blocked\_samples* directories in this repository, respectively (https://github.com/s3yonsei/blocked_samples).

## 3. Configurations

| **Component** | **Specification**                  |
|---------------|------------------------------------|
| Processor     | Intel Xeon Gold 5218 2.30 GHz * 2, 32 physical cores |
| **SSD**       | Samsung NVMe PM983 (540K IOPS) and PM1735 (1,500K IOPS)|
| Memory        | DDR4 2933 MHz, 384 GB (32 GB x 12)  |
| **OS**        | Ubuntu 20.04 Server |

**Note**: To evaluate our artifacts, not all system configurations are mendatory. However, the performance of the SSD used in the RocksDB experiment can affect the profiling results. For example, the *prefix\_dist* experiment shows profiling results that emphasize the importance of optimizing block cache lock contention over optimizing I/O events in read-only workloads, but this can be reversed if the used SSD is slow.

This is the our biggest concern for artifacts evaluation. We have specified the SSDs we used for each experiment and recommend utilizing NVMe SSDs that are as close to the performance as possible. If this is not possible, we recommend utilizing two NVMe SSDs with different performance.


## 4. Getting Started Instructions
Please follow the instructions in [Getting Started with Blocked Samples](https://github.com/s3yonsei/blocked_samples/tree/main?tab=readme-ov-file#getting-started-with-blocked-samples). 

## 5. Detailed Instructions

### 5-0. Mount I/O devices

Make sure that your device files (e.g., /dev/nvme0n1p1) are formatted with ext4 file system and mounted. Please mount your devices on `/media/nvme_slow` and `/media/nvme_fast`.

```bash
[Assume that the name of the device file of slower device is /dev/nvme0n1p1 and faster device is /dev/nvme1n1p1]
$ mkfs -t ext4 /dev/nvme0n1p1
$ mkfs -t ext4 /dev/nvme1n1p1

$ mkdir -p /media/nvme_slow /media/nvme_fast

$ mount -t ext4 /dev/nvme0n1p1 /media/nvme_slow
$ mount -t ext4 /dev/nvme1n1p1 /media/nvme_fast
```

### 5-1. Motivational

#### 5-1-1. Build

```bash
$ cd benchmarks/motivational
$ make clean && make
```

Four binary files (test\_motivational\_case1, test\_motivational\_case2, test\_motivational\_case1_bcoz, test\_motivational\_case2_bcoz) are generated after make. The two binaries without '\_coz' can be run directly (i.e., ./test\_motivational\_case1), and you should verify that each behaves the same as in Figure 1 in the paper. We've added print some text before the two threads enter *barrier()*. When running test\_motivational\_case1, thread 1's print should come first in every iteration, and vice versa when running test\_motivational\_case2. 

```bash
[test_motivational_test1]
thread 1 iteration 1
thread 2 iteration 1
thread 1 iteration 2
thread 2 iteration 2
thread 1 iteration 3
thread 2 iteration 3
...

[test_motivational_test2]
thread 2 iteration 1
thread 1 iteration 1
thread 2 iteration 2
thread 1 iteration 2
thread 2 iteration 3
thread 1 iteration 3
...
```

If your execution does not prints as above, you should adjust the amount of *compute\_heavy()* (line 56). Increasing the computation load moves thread 2 on the critical path (case 1) and decreasing moves thread 1 on the critical path (case 2).

#### 5-1-2. bperf

Figure 7 is obtained by sampling case 1 using bperf. To obtain the sampling results of individual threads, you need to record using bperf by specifying the tid.

```bash
[Run application]
$ ./test_motivational_case1

[Assume that tid of thread 1 is t1 and thread 2 is t2. You can figure out tids simply using tools such as htop.]
$ bperf record -o perf_t1.data -g -e task-clock -c 1000000 --weight --tid=t1 &
$ bperf record -o perf_t2.data -g -e task-clock -c 1000000 --weight --tid=t2 &
```

When the application finished, the recording also finished. You can report the sampling results as follows.

```bash
[Thread 1]
$ bperf report -i perf_t1.data --no-children

[Thread 2]
$ bperf report -i perf_t2.data --no-children
```

Although the reported results and the Figure 7 may differ in details, the off-CPU events corresponding to blocking I/O (**I** in the square brackets) for `__libc_pread64`, `__libc_pwrite`, and lock-waiting (**L** in the square brackets) for `pthread_cond_wait` should be reported.

**Note**: The sampling results of original Linux perf (Figure 2) can be obtained with same recording commands above, except for the name of the tool (bperf->perf). However, for a proper comparison with bperf's sampling results with bperf's, recording should be done after booting into a original Linux kernel rather than the Linux kernel for blocked samples.

#### 5-1-3. BCOZ

Figure 9 is obtained by run BCOZ. We recommend that you run the application repeatedly to accumulate many virtual speedup results for accuracy.

```bash
[Case 1]
$ for((i=0;i<5;i++)); do sync; echo 3 > /proc/sys/vm/drop_caches; sleep 2; bcoz run --- ./test_motivational_case1_bcoz; done
$ for((i=0;i<5;i++)); do sync; echo 3 > /proc/sys/vm/drop-caches; sleep 2; bcoz run --blocked-scope i --- ./test_motivational_case1_bcoz; done
$ mv profile.coz profile_case1.coz

[Case 2]
$ for((i=0;i<5;i++)); do sync; echo 3 > /proc/sys/vm/drop_caches; sleep 2; bcoz run --- ./test_motivational_case2_bcoz; done
$ for((i=0;i<5;i++)); do sync; echo 3 > /proc/sys/vm/drop-caches; sleep 2; bcoz run --blocked-scope i --- ./test_motivational_case2_bcoz; done
$ mv profile.coz profile_case2.coz
```

Load the generated `.coz` files into [plot](https://plasma-umass.org/coz/).

### 5-2. RocksDB

#### 5-2-1. Build

Many libraries are dynamically loaded when running db\_bench. As explained in [glibc build](https://github.com/s3yonsei/blocked_samples/tree/main?tab=readme-ov-file#getting-started-with-blocked-samples), to obtain correct profiling results, the libraries should be rebuilt to do not omit frame pointers. In our experiments, rather than rebuilt them, we statically link libraries with execution binary.

```bash
$ cd benchmarks/RocksDB
$ make clean

$ make librocksdb_debug.a DEBUG_LEVEL=2 -j
$ make libsnappy.a DEBUG_LEVEL=2 -j
$ make libzstd.a DEBUG_LEVEL=2 -j
$ make libz.a DEBUG_LEVEL=2 -j
$ make liblz4.a DEBUG_LEVEL=2 -j

[Make db_bench for baseline execution]
$ make db_bench DEBUG_LEVEL=2 -j
$ mv db_bench db_bench_perf

[Make db_bench for BCOZ]
$ make db_bench DEBUG_LEVEL=2 -j
$ mv db_bench db_bench_bcoz
```

**Note**: Built static libraries are removed with `$ make clean`. Please backup these libraries and copy at making db\_bench. We modified Makefile to add compile flags needed for generating debug information and preserving frame pointers, as well as linking static libraries.

#### 5-2-2. RocksDB-*prefix\_dist*



#### 5-2-3. RocksDB-*allrandom*

#### 5-2-4. RocksDB-*fillrandom*

### 5-3. NPB

#### 5-3-1. Build

```
$ cd benchmarks/NPB

[Binary for measuring performance without BCOZ]
$ cp IS/is_bak.c IS/is.c
$ make clean && make is CLASS=C
$ cd bin; mv is.C.x is.C.x_perf; cd ..

[Binary for BCOZ]
$ cp IS/is_bcoz.c IS/is.c
$ make clean && make is CLASS=C
$ cd bin; mv is.C.x is.C.x_bcoz; cd ..
```

#### 5-3-2. BCOZ

```
[Run IS with 32 openmp threads]
$ export OMP_NUM_THREADS=32

[Run IS with BCOZ (default run)]
$ for((i=0;i<5;i++)); do sleep 2; taskset -c 0 bcoz run --- ./bin/is.C.x_bcoz; done
$ mv profile.coz profile_line-level.coz

[Run IS with BCOZ (specifying offcpu subclass)]
$ for((i=0;i<5;i++)); do sleep 2; taskset -c 0 bcoz run --blocked-scope s --- ./bin/is.C.x_bcoz; done
$ for((i=0;i<5;i++)); do sleep 2; taskset -c 0-1 bcoz run --blocked-scope s --- ./bin/is.C.x_bcoz; done
$ for((i=0;i<5;i++)); do sleep 2; taskset -c 0-3 bcoz run --blocked-scope s --- ./bin/is.C.x_bcoz; done
$ for((i=0;i<5;i++)); do sleep 2; taskset -c 0-7 bcoz run --blocked-scope s --- ./bin/is.C.x_bcoz; done
$ for((i=0;i<5;i++)); do sleep 2; taskset -c 0-15 bcoz run --blocked-scope s --- ./bin/is.C.x_bcoz; done
$ for((i=0;i<5;i++)); do sleep 2; taskset -c 0-31 bcoz run --blocked-scope s --- ./bin/is.C.x_bcoz; done
$ mv profile.coz profile_subclass-level.coz
```

Load the generated '.coz' file into [plot](https://plasma-umass.org/coz/). Figure 15a and 15b are obtained from `profile_line-level.coz` and `profile\_subclass-level.coz`, respectively.

To compare the virtual speedup results with actual speedup (Figure 15c), try to run `is.C.x_perf` without BCOZ.

### 5-4. Overhead

## 6. Conclusion

To conclude, our paper introduces a sampling technique called blocked samples, which enables the identification of application bottlenecks by integrating on- and off-CPU events within the same dimension. We present bperf, a Linux perf tool that utilizes the proposed blocked samples technique to identify application bottlenecks based on event execution time, and BCOZ, a causal profiler that offers a virtual speedup for both on-/off-CPU events.

We validated our proposal with the above experiments. We hope that our blocked samples technique, as well as bperf and BCOZ, will help you identify bottlenecks in your application!
