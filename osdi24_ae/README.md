# OSDI'24 Artifacts Evaluation

Please contact us if you have any questions. [Minwoo Ahn](mailto:mwahn402@gmail.com), [Jinkyu Jeong](mailto:jinkyu@yonsei.ac.kr), [Scalable Systems Software Lab](https://cslab.yonsei.ac.kr), Yonsei University, South Korea

## Contents
1. [Introduction](#1-introduction)
2. [Artifacts Components](#2-artifacts-components)
3. [Configurations](#3-configurations)
4. [Getting Started Instructions](#4-getting-started-instructions)
5. [Detailed Instructions](#5-detailed-instructions)

## 1. Introduction

This repository is for reproducing the experimental results presented in the paper published at OSDI'24. Our evaluation consist of 'motivational', 'RocksDB (*prefix\_dist*, *allrandom*, *fillrandom*)', 'NPB (*integer sort*)', and 'overhead'.

* #### Motivational - Figure 7, 9
* #### RocksDB-*prefix\_dist* (Section 4.2 - Optimization 1) - Figure 10
* #### RocksDB-*allrandom* (Section 4.2 - Optimization 2) - Figure 12a, 12b
* #### RocksDB-*fillrandom* (Section 4.3 - Optimization 3) - Figure 13b, 13c, 14
* #### NPB - Figure 15
* #### Overhead - Figure 16, 17


## 2. Artifacts components

Blocked samples consists of two main components: the Linux kernel for blocked samples (which includes bperf), and BCOZ source code. Both are maintained in *blocked_samples* and *bcoz* directories in this repository, respectively (https://github.com/s3yonsei/blocked_samples).

## 3. Configurations

| **Component** | **Specification**                  |
|---------------|------------------------------------|
| Processor     | Intel Xeon Gold 5218 2.30 GHz * 2, 32 physical cores |
| **SSD**       | Samsung NVMe PM983 (540K IOPS) and PM1735 (1,500K IOPS)|
| Memory        | DDR4 2933 MHz, 384 GB (32 GB x 12)  |
| **OS**        | Ubuntu 20.04 Server |

**Note**: To evaluate our artifacts, special hardwares are required (high-end SSD that shows high IOPS and low-end SSD).The performance of the SSDs used in the RocksDB experiment can affect the profiling results. For instance, the *prefix\_dist* experiment demonstrates profiling results that emphasize the importance of optimizing block cache lock contention over optimizing I/O events in read-only workloads, but this may be reversed if a slow SSD is utilized.

We have specified the SSDs we used for each experiment and recommend using NVMe SSDs that closely match their performance. If this is not feasible, we suggest employing two NVMe SSDs with differing IOPS.


## 4. Getting Started Instructions
Please refer to the instructions in [Getting Started with Blocked Samples](https://github.com/s3yonsei/blocked_samples/tree/main?tab=readme-ov-file#getting-started-with-blocked-samples). This section will help you quickly verify whether blocked samples functions correctly. If you encounter any difficulties during this process, please contact us.

## 5. Detailed Instructions

### 5-1. Mount I/O devices

Make sure that your device files (e.g., /dev/nvme0n1p1) are formatted with the ext4 file system and mounted. Please mount your devices at `/media/nvme_slow` and `/media/nvme_fast`.

```bash
[Assuming that the device file name for slower SSD is /dev/nvme0n1p1 and for the faster device is /dev/nvme1n1p1]
$ sudo mkfs -t ext4 /dev/nvme0n1p1
$ sudo mkfs -t ext4 /dev/nvme1n1p1

$ sudo mkdir -p /media/nvme_slow /media/nvme_fast

$ sudo mount -t ext4 /dev/nvme0n1p1 /media/nvme_slow
$ sudo mount -t ext4 /dev/nvme1n1p1 /media/nvme_fast
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


**Note**: If you want to campare perf's sampling results with bperf's, recording should be done after booting into an original Linux kernel rather than the Linux kernel for blocked samples.

#### 5-2-3. BCOZ

Figure 9 presents BCOZ's profiling results for the motivational example. We recommend running the application multiple times to accumulate numerous virtual speedup results for accuracy. To obtain the results shown in Figure 9, execute the `motivational_bcoz.sh` script.

```bash
$ ./motivational_bcoz.sh
```
Load the generated `.coz` files (profile\_case1.coz and profile\_case2.coz) into [plot](https://plasma-umass.org/coz/).

**Note**: While there may be differences in detail between the reported results and Figure 9, you should still be able to discern the following.

* `Case 1` - There is no predicted performance gain from optimizing I/O events (*pread*, *pwrite*, and I/O subclass), with only the *compute\_heavy* function showing a predicted performance gain from optimization.
* `Case 2` - There is no predicted performance gain from optimizing *compute\_heavy* function, while and there are predicted performance gains from optimizing *pread*, *pwrite*, and I/O subclass.

### 5-3. RocksDB

#### 5-3-1. Build

Many libraries are dynamically loaded when running db\_bench. As explained in [glibc build](https://github.com/s3yonsei/blocked_samples/tree/main?tab=readme-ov-file#getting-started-with-blocked-samples), to obtain correct profiling results, the libraries should be rebuilt to do not omit frame pointers. In our experiments, instead of rebuilding them all, we statically link some libraries with the execution binary.

```bash
$ cd benchmarks/rocksdb
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
$ sudo cp /lib/x86_64-linux-gnu/libtbb.so.2 /usr/local/lib/glibc-testing/lib
$ sudo cp /lib/x86_64-linux-gnu/libnuma.so.1 /usr/local/lib/glibc-testing/lib
$ sudo cp /lib/x86_64-linux-gnu/libgflags.so.2.2 /usr/local/lib/glibc-testing/lib
$ sudo cp /lib/x86_64-linux-gnu/libz.so.1 /usr/local/lib/glibc-testing/lib
```

**Note**: Built static libraries are removed with `$ make clean`. Please backup these libraries and copy at making db\_bench. We modified Makefile to add compile flags needed for generating debug information and preserving frame pointers, as well as linking static libraries.

#### 5-3-2. Data loading

In experiments RocksDB-*prefix\_dist* and RocksDB-*allrandom*, we execute a read-only workload using the same dataset. We load 100GB of data onto each SSD (high-end and low-end). Loading the data takes around 2~3 hours with our SSDs.

```bash
$ ulimit -n 1048576

[Load data on high-end ssd]
$ ./db_bench_perf --threads=1 --bloom_bits=10 --num=$((1024*1024*1024)) --key_size=48 --value_size=43 \
--cache_size=$((10*1024*1024*1024)) --use_direct_reads=true --use_direct_io_for_flush_and_compaction=true \
--ttl_seconds=$((60*60*24*30*12)) --partition_index=true --partition_index_and_filters=true \
--db=/media/nvme_fast/rocksdb_partitioned --use_existing_db=false --max_write_buffer_number=16 --compression_type=none \
--max_background_compactions=2 --benchmarks=filluniquerandom

[Load data on low-end ssd]
$ ./db_bench_perf --threads=1 --bloom_bits=10 --num=$((1024*1024*1024)) --key_size=48 --value_size=43 \
--cache_size=$((10*1024*1024*1024)) --use_direct_reads=true --use_direct_io_for_flush_and_compaction=true \
--ttl_seconds=$((60*60*24*30*12)) --partition_index=true --partition_index_and_filters=true \
--db=/media/nvme_slow/rocksdb_partitioned --use_existing_db=false --max_write_buffer_number=16 --compression_type=none \
--max_background_compactions=2 --benchmarks=filluniquerandom
```

**Note**: Because of the data retained in the memtable, compaction will occur initially when you start the workload. To prevent compaction from affecting subsequent read-only workloads, perform a dummy run (not intended for performance measurement) once for each dataset as follows.

```bash
$ ulimit -n 1048576

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

In this experiment, BCOZ identifies and addresses the bottleneck of block cache operations in a read-only workload. We profiled the read-only execution of *prefix_dist*, a real-world workload open-sourced by Facebook (i.e., Mixgraph). We set the number of shards to one to replicate the well-known lock contention problem of RocksDB's LRU-based block cache.

Figure 10a shows the profiling results for BCOZ. It can be reproduced with the following script.

```bash
$ sudo ./rocksdb_1_bcoz.sh
```

Load the generated profile\_rocksdb\_1.coz file into [plot](https://plasma-umass.org/coz/).

**Note**: While there may be differences in detail between the reported results and Figure 10a, you should still be able to discern that the predicted performance gain from optimizing lock contention (*GetDataBlockFromCache*) is larger than that from optimizing I/O events (*ReadBlockContents*).

Figure 10b shows the performance change after optimization. It can be reproduced with the following script.

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

* `SSD+`: *db* is changed to /media/nvme\_fast/rocksdb\_partitioned.
* `Shard-X`: *cache_numshardbits* is changed from 0 to 1-6. The number of the shards is 2^X.

#### 5-3-4. RocksDB-*allrandom*

In this experiment, BCOZ identifies and addresses the bottleneck where I/O events become a bottleneck once block cache lock contention is resovled. We profiled read-only execution of *allrandom*, a real-world workload open-sourced by Facebook. The size of the block cache is set to 128MB to increase the occurrence of I/O events.

Figure 12a shows the profiling results for BCOZ. It can be reproduced with the following script.

```bash
$ sudo ./rocksdb_2_bcoz.sh
```

Load the generated profile\_rocksdb\_2.coz file into [plot](https://plasma-umass.org/coz/).

**Note**: While there may be differences in detail between the reported results and Figure 12a, you should still be able to discern that the predicted performance gain through optimizing blocking I/O events (*I/O subclass* in the figure) is significant. Furthermore, the predicted performance gain through optimizing filter block reads (*GetFilterPartitionBlock*) is the highest among the index and data block reads (*IndexBlockIter* and *DataBlockIter*, respectively).

Figure 12b shows the performance change after utilizing the asynchronous I/O interface (i.e., io\_uring). We have made our asynchronous I/O-enabled RocksDB code available as an optimization in the rocksdb\_aio directory. You can reproduce this by running the following instructions.

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

**Note**: We used fast SSD in both (baseline and asynchronous I/O) experiment.

#### 5-3-5. RocksDB-*fillrandom*

In this experiment, BCOZ identifies and addresses the bottleneck of write-only workload. We profiled *fillrandom* in db\_bench. The size of the key-value pair is 1KB and the number of worker thread is 16.


Figure 13b and 13c show the profiling results for BCOZ. It can be reproduced with the following script.

```bash
$ sudo ./rocksdb_3_bcoz.sh
```

Load the generated profile\_rocksdb\_3.coz into file [plot](https://plasma-umass.org/coz/).

**Note**: While there may be differences in detail between the reported results and Figure 13b and 13c, you should still be able to discern that the predicted performance gain from optimizing compression events is higher than from optimizing I/O events. Furthermore, optimizing the synchronization between worker threads (*JoinBatchGroup*) and write stall of worker threads (*DelayWrite*) are more important than optimizing WAL (write-ahead-log) events.

Figure 14 shows the performance change after optimization. This can be reproduced with the following script.

```bash
$ sudo ./rocksdb_3_performance.sh

[Print performance of each execution]
$ cat rocksdb_3.txt
```

The command for the baseline execution is as follows.

```bash
./db_bench_perf --threads=16 --bloom_bits=10 --num=$((10*1024*1024)) --key_size=1000 --value_size=24 \
--cache_size=$((10*1024*1024*1024)) --use_direct_reads=true --use_direct_io_for_flush_and_compaction=true \
--ttl_seconds=$((60*60*24*30*12)) --partition_index=true --partition_index_and_filters=true --db=/media/nvme_fast/rocksdb_temp \
--use_existing_db=false --benchmarks=fillrandom
```

* `RamDisk`: --wal\_dir=/media/ramdisk is added to the command.
* `no-WAL`: --disable\_wal=true is added to the command.
* `Compress+`: --compress\_type=none is added to the command.
* `Comp+`: the number of *max_background_compactions* is increased to 4
* `Stall`: the number of *max_write_buffer_number* is increased to 16

(**RamDisk**) To you RamDisk as a WAL device, please follow the instructions below.
1. Add `ramdisk_size=8388608` (8GB) to the grub boot parameter in /etc/default/grub.
2. Reboot.
3. `$ modprobe brd rd_nr=1 rd_size=8388608 max_part=0`        -> /dev/ram0 is created.
4. `$ dd if=/dev/zero of=/dev/ram0 bs=1M count=8192`
5. `$ mkfs.ext4 /dev/ram0`
6. `$ mkdir -p /media/ramdisk; mount -t ext4 /dev/ram0 /media/ramdisk`


### 5-4. NPB

In this experiment, BCOZ identifies and addresses the bottleneck of compute-intensive (*integer sort*) workload. The number of OpenMp thread is 32 and the number of cores allocated to NPB is adjusted to mimic the actual optimization of the CPU scheduling off-CPU subclass. The baseline execution allocates a single core to NPB.

#### 5-4-1. Build

```
$ cd benchmarks/NPB
$ cp /usr/lib/x86_64-linux-gnu/libgomp.so.1 /usr/local/lib/glibc-testing/lib

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

Figure 15a and 15b show the profiling results for BCOZ. It can be reproduced with the following script.

```bash
$ ./npb_bcoz.sh
```

Load the generated '.coz' files into [plot](https://plasma-umass.org/coz/). Figure 15a and 15b are obtained from `profile_line-level.coz` and `profile_subclass-level-X.coz` (X=1,2,4,8,16,32), respectively.

Figure 15c shows the program speedup (relative in throughput) after allocating more cores. This can be calculated with the following script.

```bash
$ ./npb_perf.sh
```

**Note**: Figure 15c shows the actual performance improvement and virtual speedup results when the number of allocated cores is increased. The actual program speedup can be calculated from the throughput obtained by running `./npb_perf.sh`. If the throughput increased by a factor of X, the program speedup is (1-1/X) * 100 (%) (e.g., if X=4, the program speedup is 75%). The virtual speedup values in Figure 15c represent the program speedups for each plot in Figure 15b when the line speedup is 100%.

### 5-5. Overhead

In this experiment, we compared the overhead of bperf with existing profiling techniques: *tracing*, which profiles only off-CPU events (i.e., *sched_switch* and *sched_wakeup*) using Linux perf's tracing mode, and *sampling*, which samples only on-CPU events using Linux perf's sampling mode (i.e., *task-clock*). Furthermore, we measured the overhead of profiling application with BCOZ.

### 5-5-1. Overhead of bperf

Figure 16 shows the performance drop (percent reduction in throughput or latency) and CPU cycle increase compared to the baseline. The profiling overhead can be calculated using the following profiling commands. Assume that the profiling target is a.out. 

**Note**: with the exception of bperf, you must boot an original Linux kernel to make measurements.

```bash
[Baseline]
$ cat /proc/stat > start_stat.txt
$ ./a.out &> printed.txt
$ cat /proc/stat > end_stat.txt

[Overhead of profiling]
$ cat /proc/stat > start_stat.txt
$ ./a.out &> printed.txt &
$ app=$!
$ [Enter profiling command (see below)]
$ wait ${app}
$ cat /proc/stat > end_stat.txt

[Profiling command]
[1. Linux perf sampling (on-CPU only)]
$ perf record -g -e task-clock -c 1000000 --pid=${app}
[2. Linux perf tracing (off-CPU only)]
$ perf record -g -e sched:sched_switch,sched:sched_wakeup -c 1 --pid=${app}
[3. bperf sampling (both on- and off-CPU)]
$ bperf record -g -e task-clock -c 1000000 --weight --pid=${app}
```

Please refer to printed.txt to calculate performance drop. To measure the additional CPU cycles (i.e., system-jiffies), we captured `/proc/stats` file before and after the executing of the application. By calculating the difference between start\_stat.txt and end\_stat.txt, you can determine the additional CPU cycles consumption.

### 5-5-2. Overhead of BCOZ
Figure 17 shows the overhead of profiling applications with BCOZ. The BCOZ overhead is categorized into three parts: `startup`, `sampling`, and `delays`. We have already incorporated code to distinguish between the three types of delays at the end of execution. Upon completing the profiling with BCOZ, the following line is printed to the terminal.

```bash
Overhead breakdown. Startup: xxxxxx real_main_time: yyyyyy end-to-end: zzzzzz
```

You can calculate the overhead of BCOZ using the printed information.

### 5-5-3. Additional applications
We measured additional applications, *NPB-ep* and *hackbench*, to cover on-CPU-intensive and off-CPU-intensive cases, respectively. The profiled application code for NPB-ep is located in `benchmarks/NPB/` and *hackbench* is located in `benchmarks/hackbench`. We executed NPB-ep without CPU core restriction and hackbench with the command `./hackbench -s 512 -l 30000 -T`.

