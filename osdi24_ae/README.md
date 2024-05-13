# OSDI'24 Artifacts Evaluation


## Title: Identifying On-/Off-CPU Bottlenecks Together with Blocked Samples

Author: Minwoo Ahn, Jeongmin Han, Youngjin Kwon, Jinkyu Jeong

**Contacts**: Please contact us if you have any questions. [Minwoo Ahn](mailto:mwahn402@gmail.com), [Jinkyu Jeong](mailto:jinkyu@yonsei.ac.kr), [Scalable Systems Software Lab](https://cslab.yonsei.ac.kr), Yonsei University, South Korea

## Contents
1. [Introduction](#1-introduction)
2. [Artifacts Components](#2-artifacts-components)
3. [Configurations](#3-configurations)
4. [Getting Started Instructions](#4-getting-started-instructions)
5. [Detailed Instructions](#5-detailed-instructions)
6. [Conclusion](#6-conclusion)

## 1. Introduction

This repository is for reproducing the experimental results presented in the paper published at OSDI'24. Our evaluation consist of 'motivational', 'RocksDB (*prefix\_dist*, *allrandom*, *fillrandom*)', 'NPB (*integer sort*)', and 'overhead'.

* #### Motivational - Figure 7, 9
* #### RocksDB-*prefix\_dist* (Section 4.2 - Optimization 1) - Figure 10
* #### RocksDB-*allrandom* (Section 4.2 - Optimization 2) - Figure 12a, 12b
* #### RocksDB-*fillrandom* (Section 4.3 - Optimization 3) - Figure 13b, 13c, 14
* #### NPB - Figure 15
* #### Overhead - Figure 16, 17


## 2. Artifacts components

Blocked samples consist of two main components: the Linux kernel for blocked samples (which includes bperf), and BCOZ source code. Both are maintained in *blocked_samples* and *bcoz* directories in this repository, respectively (https://github.com/s3yonsei/blocked_samples).

## 3. Configurations

| **Component** | **Specification**                  |
|---------------|------------------------------------|
| Processor     | Intel Xeon Gold 5218 2.30 GHz * 2, 32 physical cores |
| **SSD**       | Samsung NVMe PM983 (540K IOPS) and PM1735 (1,500K IOPS)|
| Memory        | DDR4 2933 MHz, 384 GB (32 GB x 12)  |
| **OS**        | Ubuntu 20.04 Server |

**Note**: To evaluate our artifacts, special hardwares are required (high-end SSD that shows high IOPS and low-end SSD).The performance of the SSDs used in the RocksDB experiment can affect the profiling results. For instance, the *prefix\_dist* experiment demonstrates profiling results that underscore the importance of optimizing block cache lock contention over optimizing I/O events in read-only workloads, but this may be reversed if a slow SSD is utilized.

We have specified the SSDs we used for each experiment and recommend using NVMe SSDs that closely match their performance. If this is not feasible, we suggest employing two NVMe SSDs with differing IOPS.


## 4. Getting Started Instructions
Please refer to the instructions in [Getting Started with Blocked Samples](https://github.com/s3yonsei/blocked_samples/tree/main?tab=readme-ov-file#getting-started-with-blocked-samples). This section will help you quickly verify whether blocked samples functions correctly. If you encounter any difficulties during this process, please contact us.

## 5. Detailed Instructions

### 5-1. Mount I/O devices

Make sure that your device files (e.g., /dev/nvme0n1p1) are formatted with the ext4 file system and mounted. Please mount your devices at `/media/nvme_slow` and `/media/nvme_fast`.

```bash
[Assuming that the device file name for slower SSD is /dev/nvme0n1p1 and for the faster device is /dev/nvme1n1p1]
$ mkfs -t ext4 /dev/nvme0n1p1
$ mkfs -t ext4 /dev/nvme1n1p1

$ mkdir -p /media/nvme_slow /media/nvme_fast

$ mount -t ext4 /dev/nvme0n1p1 /media/nvme_slow
$ mount -t ext4 /dev/nvme1n1p1 /media/nvme_fast
```

### 5-2. Motivational

#### 5-2-1. Build

```bash
$ cd benchmarks/motivational/src
$ make clean && make
$ cd ..
```

Four binary files (test\_motivational\_case1, test\_motivational\_case2, test\_motivational\_case1\_bcoz, test\_motivational\_case2\_bcoz) are generated after make. The two binaries without '\_coz' can be executed directly (`$ ./test\_motivational\_case1`). You should verify that each behaves the same as illustrated in Figure 1 of the paper. We've included code to print some text before the two threads enter the *barrier()*. When running test\_motivational\_case1, thread 1's print should appear first in every iteration, and vice versa when running test\_motivational\_case2.


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

If your execution does not print as described above, you should adjust the amount of computation which *compute_heavy()* conducts (line 56). Increasing the computation load shifts thread 2 onto the critical path (case 1), while decreasing it shifts thread 1 onto the critical path (case 2).

#### 5-2-2. bperf

Figure 7 is obtained by sampling case 1 using bperf. To obtain the sampling results for individual threads, you need to record using bperf by specifying the tid. To generate the results shown in Figure 7, execute the `motivational_perf.sh` script.

```bash
$ sudo ./motivational_perf.sh
```

When the application finishes, the recording also ends. You can report the sampling results as follows.

```bash
[Thread 1 in case 1]
$ bperf report -i perf_t1.data --no-children

[Thread 2 in case 1]
$ bperf report -i perf_t2.data --no-children
```

Although the reported results and Figure 7 may differ in details, the off-CPU events corresponding to blocking I/O (**I** in the square brackets) for `__libc_pread64', and `__libc_pwrite`, and lock-waiting (**L** in the square brackets) for `pthread_cond_wait` should be reported.


**Note**: If you want to campare perf's sampling results with bperf's, recording should be done after booting into a original Linux kernel rather than the Linux kernel for blocked samples.

#### 5-2-3. BCOZ

Figure 9 is obtained by run BCOZ. We recommend that you run the application repeatedly to accumulate many virtual speedup results for accuracy. To get the results in Figure 9, run the `motivational_bcoz.sh` script.

```bash
$ ./motivational_bcoz.sh
```
Load the generated `.coz` files (profile\_case1.coz and profile\_case2.coz) into [plot](https://plasma-umass.org/coz/).

**Note**: Although the reported results and the Figure 9 may differ in details, you should be able to figure out the followings.

* `Case 1` - There is no predicted performance gain from optimizing I/O events (*pread*, *pwrite*, and I/O subclass) and only *compute\_heavy* function have predicted performance gain from optimization.
* `Case 2` - There is no predicted performance gain from optimizing *compute\_heavy* function and there are predicted performance gain from optimizing *pread*, *pwrite*, and I/O subclass.

### 5-3. RocksDB

#### 5-3-1. Build

Many libraries are dynamically loaded when running db\_bench. As explained in [glibc build](https://github.com/s3yonsei/blocked_samples/tree/main?tab=readme-ov-file#getting-started-with-blocked-samples), to obtain correct profiling results, the libraries should be rebuilt to do not omit frame pointers. In our experiments, rather than rebuilt them, we statically link libraries with execution binary.

```bash
$ cd benchmarks/RocksDB
$ make clean

[Required libraries]
$ sudo apt install libtbb2 libtbb-dev libgflags-dev libsnappy-dev
$ make libsnappy.a DEBUG_LEVEL=2 -j $(nproc)
$ make libzstd.a DEBUG_LEVEL=2 -j $(nproc)

[Build db_bench for baseline execution]
$ cp db/db_impl/db_impl_perf.cc db/db_impl/db_impl.cc
$ cp db/db_impl/db_impl_write_perf.cc db/db_impl/db_impl_write.cc
$ make db_bench -j $(nproc)
$ mv db_bench db_bench_perf

[Build db_bench for BCOZ]
$ cp db/db_impl/db_impl_coz.cc db/db_impl/db_impl.cc
$ cp db/db_impl/db_impl_write_coz.cc db/db_impl/db_impl_write.cc
$ make db_bench DEBUG_LEVEL=2 -j $(nproc)
$ mv db_bench db_bench_bcoz

[Move some shared libraries that will be loaded]
$ cp /lib/x86_64-linux-gnu/libtbb.so.2 /usr/local/lib/glibc-testing/lib
$ cp /lib/x86_64-linux-gnu/libnuma.so.1 /usr/local/lib/glibc-testing/lib
$ cp /lib/x86_64-linux-gnu/libgflags.so.2.2 /usr/local/lib/glibc-testing/lib
```

**Note**: Built static libraries are removed with `$ make clean`. Please backup these libraries and copy at making db\_bench. We modified Makefile to add compile flags needed for generating debug information and preserving frame pointers, as well as linking static libraries.

#### 5-3-2. Data loading

In experiments RocksDB-*prefix\_dist* and RocksDB-*allrandom*, we perform a read-only workload on the same dataset. Load 100GB of data on each SSD. Data load takes about 2~3 hours each with our SSDs.

```bash
[Load data on fast ssd]
$ ./db_bench_perf --threads=1 --bloom_bits=10 --num=$((1024*1024*1024)) --key_size=48 --value_size=43 \
--cache_size=$((10*1024*1024*1024)) --use_direct_reads=true --use_direct_io_for_flush_and_compaction=true \
--ttl_seconds=$((60*60*24*30*12)) --partition_index=true --partition_index_and_filters=true \
--db=/media/nvme_fast/rocksdb_partitioned --use_existing_db=false --max_write_buffer_number=16 --compression_type=none \
--max_background_compactions=2 --benchmarks=filluniquerandom

[Load data on slow ssd]
$ ./db_bench_perf --threads=1 --bloom_bits=10 --num=$((1024*1024*1024)) --key_size=48 --value_size=43 \
--cache_size=$((10*1024*1024*1024)) --use_direct_reads=true --use_direct_io_for_flush_and_compaction=true \
--ttl_seconds=$((60*60*24*30*12)) --partition_index=true --partition_index_and_filters=true \
--db=/media/nvme_slow/rocksdb_partitioned --use_existing_db=false --max_write_buffer_number=16 --compression_type=none \
--max_background_compactions=2 --benchmarks=filluniquerandom
```

**Note**: Due to the data left in the memtable, compaction will occur once when you first run the workload. Execute a dummy run (not for performance measurement) once per dataset to ensure that compaction does not occur in subsequent read-only workload.

```bash
[Dummy run on dataset in fast ssd]
$ ./db_bench_perf --threads=1 --cache_index_and_filter_blocks=true --bloom_bits=10 --partition_index=true \
--partition_index_and_filters=true --num=$((1024*1024*1024)) --reads=1024 --use_direct_reads=true --key_size=48 \
--value_size=43  --cache_numshardbits=-1 --db=/media/nvme_fast/rocksdb_partitioned --use_existing_db=1 --cache_size=$((10*1024*1024*1024)) \
--benchmarks=mixgraph --key_dist_a=0.002312 --key_dist_b=0.3467 --keyrange_dist_a=14.18 --keyrange_dist_b=-2.917 \
--keyrange_dist_c=0.0164 --keyrange_dist_d=-0.08082 --keyrange_num=30 --mix_get_ratio=1 --mix_put_ratio=0 \
--mix_seek_ratio=0 --value_k=0.2615 --value_sigma=25.45 --iter_k=2.517 --iter_sigma=14.236 \
--sine_mix_rate_interval_milliseconds=5000 --sine_a=1000 --sine_b=0.000073 --sine_d=4500 --ttl_seconds=$((3600*24*365))

[Dummy run on dataset in slow ssd]
$ ./db_bench_perf --threads=1 --cache_index_and_filter_blocks=true --bloom_bits=10 --partition_index=true \
--partition_index_and_filters=true --num=$((1024*1024*1024)) --reads=1024 --use_direct_reads=true --key_size=48 \
--value_size=43  --cache_numshardbits=-1 --db=/media/nvme_fast/rocksdb_partitioned --use_existing_db=1 --cache_size=$((10*1024*1024*1024)) \
--benchmarks=mixgraph --key_dist_a=0.002312 --key_dist_b=0.3467 --keyrange_dist_a=14.18 --keyrange_dist_b=-2.917 \
--keyrange_dist_c=0.0164 --keyrange_dist_d=-0.08082 --keyrange_num=30 --mix_get_ratio=1 --mix_put_ratio=0 \
--mix_seek_ratio=0 --value_k=0.2615 --value_sigma=25.45 --iter_k=2.517 --iter_sigma=14.236 \
--sine_mix_rate_interval_milliseconds=5000 --sine_a=1000 --sine_b=0.000073 --sine_d=4500 --ttl_seconds=$((3600*24*365))
```

#### 5-3-3. RocksDB-*prefix_dist*

In this experiment, BCOZ identifies and address the bottleneck of block cache operations in a read-only workload. We profiled read-only execution of *prefix_dist*, an open-sourced real-world workload by Facebook. The number of shard is one to reproduce the well-known lock contention problem of RocksDB's LRU-based block cache.

Figure 12a is obtained by profiling with BCOZ.

```bash
$ sudo ./rocksdb_1_bcoz.sh
```

Load the generated profile.coz into [plot](https://plasma-umass.org/coz/).

**Note**: Although the reported results and the Figure 10a may differ in details, you should be able to figure out the predicted performance gain through optimizing lock contention (*GetDataBlockFromCache*) is larger than optimizing I/O event (*ReadBlockContents*). 

Figure 10b is obtained by running `db_bench_perf` while adjusting options.

```bash
$ sudo ./rocksdb_1_performance.sh

[Print performance of each execution]
$ cat rocksdb_1.txt
```

The command for the baseline experiment is as follows. 

```bash
$ ./db_bench_perf --threads=8 --cache_index_and_filter_blocks=true --bloom_bits=10 --partition_index=true \
--partition_index_and_filters=true --num=$((1024*1024*1024)) --reads=$((2*1024*1024)) --use_direct_reads=true \
--key_size=48 --value_size=43  --cache_numshardbits=0 --db=/media/nvme_slow/rocksdb_partitioned --use_existing_db=1 \
--cache_size=$((10*1024*1024*1024)) --benchmarks=mixgraph --key_dist_a=0.002312 --key_dist_b=0.3467 \
--keyrange_dist_a=14.18 --keyrange_dist_b=-2.917 --keyrange_dist_c=0.0164 --keyrange_dist_d=-0.08082 \
--keyrange_num=30 --mix_get_ratio=1 --mix_put_ratio=0 --mix_seek_ratio=0 --value_k=0.2615 --value_sigma=25.45 \
--iter_k=2.517 --iter_sigma=14.236  --sine_mix_rate_interval_milliseconds=5000 --sine_a=1000 --sine_b=0.000073 \
--sine_d=4500 --ttl_seconds=$((3600*24*365))
```

* `SSD+`: change *db* to /media/nvme\_fast/rocksdb\_partitioned.
* `Shard-X`: change *cache_numshardbits* from 0 to 1-6 (e.g., *cache_numshardbits* value of Shard-16 is 4).

#### 5-3-4. RocksDB-*allrandom*

In this experiment, BCOZ identifies and address the bottleneck where I/O events become a bottleneck as block cache lock contention is resovled. We profiled read-only execution of *allrandom*, an open-sourced real-world workload by Facebook. The size of the block cache is 128MB to incur a large amount of I/O events.

Figure 12a is obtained by profiling with BCOZ.

```bash
$ sudo ./rocksdb_2_bcoz.sh
```

Load the generated profile.coz into [plot](https://plasma-umass.org/coz/).

**Note**: Although the reported results and the Figure 12a may differ in details, you should be able to figure out the predicted performance gain through optimizing blocking I/O events (I/O subclass in the figure) is high. Furthermore, predicted performance gain through optimizing filter block read (*GetFilterPartitionBlock*) is highest among the index and data block reads (*IndexBlockIter* and *DataBlockIter*, respectively).

Figure 12b is obtained by comparing the result of baseline and optimized execution. We opened our asynchronous I/O-enabled RocksDB code as an optimization, in rocksdb\_aio directory.

```bash
$ cd ~
$ apt-get install libudev-dev libaio-dev
$ git clone https://github.com/axboe/liburing.git
$ cd liburing
$ make && sudo make install
$ cp liburing.h ~/blocked_samples/osdi24_ae/benchmarks/rocksdb_aio/aio/
$ cd ~/blocked_samples/osdi24_ae/benchmarks/rocksdb_aio

$ make libsnappy.a DEBUG_LEVEL=2 -j $(nproc)
$ make libzstd.a DEBUG_LEVEL=2 -j $(nproc)
$ make db_bench -j $(nproc)
$ mv db_bench db_bench_perf
$ cd ../rocksdb
```

```bash
$ sudo ./rocksdb_2_performance.sh

[Print performance of each execution]
$ cat rocksdb_2.txt

```

The command for the both execution is as follows.

```bash
$ ./db_bench_perf --threads=8 --cache_index_and_filter_blocks=true --bloom_bits=10 --partition_index=true \
--partition_index_and_filters=true --num=$((1024*1024*1024)) --reads=$((1024*1024)) --use_direct_reads=true \
--key_size=48 --value_size=43  --cache_numshardbits=-1 --db=/media/nvme_fast/rocksdb_partitioned --use_existing_db=1 \
--cache_size=$((128*1024*1024)) --benchmarks=mixgraph --keyrange_num=1 --value_k=0.2615 --value_sigma=25.45 \
--iter_k=2.517 --iter_sigma=14.236 --mix_get_ratio=1 --mix_put_ratio=0 --mix_seek_ratio=0 \
--sine_mix_rate_interval_milliseconds=5000 --sine_a=1000 --sine_b=0.000073 --sine_d=4500 --ttl_seconds=$((3600*24*365))
```

**Note**: We used fast SSD in this experiment.

#### 5-3-5. RocksDB-*fillrandom*

In this experiment, BCOZ identifies and address the bottleneck of write-only workload. We profiled *fillrandom* in db\_bench. The size of the key-value pair is 1KB and the number of worker thread is 16.


Figure 13b, 13c are obtained by profiling with BCOZ

```bash
$ sudo ./rocksdb_3_bcoz.sh
```

Load the generated profile.coz into [plot](https://plasma-umass.org/coz/).

**Note**: Although the reported results and the Figure 13b, 13c may differ in details, you should be able to figure out the predicted performance gain through optimizing compression events is higher than optimizing I/O events. Furthermore, optimizing synchronization between worker threads and write stall of worker threads are more important than optimizing WAL (write-ahead-log) events.

Figure 14 is obtained by running `db_bench_perf` while adjusting options.

```bash
$ sudo ./rocksdb_3_performance.sh

[Print performance of each execution]
$ cat rocksdb_3.txt

```

The command for the baseline execution is as follows.

```bash
./db_bench_perf --threads=16 --bloom_bits=10 --num=$((10*1024*1024)) --key_size=48 --value_size=43 \
--cache_size=$((10*1024*1024*1024)) --use_direct_reads=true --use_direct_io_for_flush_and_compaction=true \
--ttl_seconds=$((60*60*24*30*12)) --partition_index=true --partition_index_and_filters=true --db=/media/nvme_fast/rocksdb_temp \
--use_existing_db=false --max_write_buffer_number=2 --max_background_compactions=1 --benchmarks=fillrandom
```

* `RamDisk`: change *db* to the ramdisk.
* `no-WAL`: add --disable\_wal=true to the command.
* `Compress+`: add --compress\_type=none to the command.
* `Comp+`: increase the number of *max_background_compactions* to 2
* `Stall`: increase the number of *max_write_buffer_number* to 16

### 5-4. NPB

#### 5-4-1. Build

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

#### 5-4-2. BCOZ

```
[Run IS with 32 openmp threads]
$ export OMP_NUM_THREADS=32

[Run IS with BCOZ (default run) -> Figure 15a]
$ for((i=0;i<5;i++)); do sleep 2; taskset -c 0 bcoz run --- ./bin/is.C.x_bcoz; done
$ mv profile.coz profile_line-level.coz

[Run IS with BCOZ (specifying offcpu subclass) -> Figure 15b]
[# cores=1]
$ for((i=0;i<5;i++)); do sleep 2; taskset -c 0 bcoz run --blocked-scope s --- ./bin/is.C.x_bcoz; done
[# cores=2]
$ for((i=0;i<5;i++)); do sleep 2; taskset -c 0-1 bcoz run --blocked-scope s --- ./bin/is.C.x_bcoz; done
[# cores=4]
$ for((i=0;i<5;i++)); do sleep 2; taskset -c 0-3 bcoz run --blocked-scope s --- ./bin/is.C.x_bcoz; done
[# cores=8]
$ for((i=0;i<5;i++)); do sleep 2; taskset -c 0-7 bcoz run --blocked-scope s --- ./bin/is.C.x_bcoz; done
[# cores=16]
$ for((i=0;i<5;i++)); do sleep 2; taskset -c 0-15 bcoz run --blocked-scope s --- ./bin/is.C.x_bcoz; done
[# cores=32]
$ for((i=0;i<5;i++)); do sleep 2; taskset -c 0-31 bcoz run --blocked-scope s --- ./bin/is.C.x_bcoz; done

$ mv profile.coz profile_subclass-level.coz
```

Load the generated '.coz' file into [plot](https://plasma-umass.org/coz/). Figure 15a and 15b are obtained from `profile_line-level.coz` and `profile_subclass-level.coz`, respectively.

To compare the virtual speedup results with actual speedup (Figure 15c), try to run `is.C.x_perf` without BCOZ.

### 5-5. Overhead

