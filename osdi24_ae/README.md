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
$ cd motivational
$ make clean && make
```

Four binary files (test\_motivational\_case1, test\_motivational\_case2, test\_motivational\_case1_coz, test\_motivational\_case2_coz) are generated after make. The two binaries without '\_coz' can be run directly (i.e., ./test\_motivational\_case1), and you should verify that each behaves the same as in Figure 1 in the paper. We've added print some text before the two threads enter *barrier()*. When running test\_motivational\_case1, thread 1's print should come first in every iteration, and vice versa when running test\_motivational\_case2. 

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

### 5-2. RocksDB-*prefix\_dist*

### 5-3. RocksDB-*allrandom*

### 5-4. RocksDB-*fillrandom*

### 5-5. NPB-*integer sort*

### 5-6. Overhead

## 6. Conclusion

To conclude, 
