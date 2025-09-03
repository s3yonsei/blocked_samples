# Blocked Samples

[Blocked Samples](https://github.com/s3yonsei/blocked_samples) is a profiling technique based on sampling, that encompasses both on- and off-CPU events simultaneously. Based on blocked samples, we present two profilers: *bperf*, an easy-to-use sampling-based profiler and *BCOZ*, a causal profiler that profiles both on- and off-CPU events simultaneously and estimates potential speedup of optimizations.

## Related Paper

For the detailed description, please refer to the paper:

**Identifying On-/Off-CPU Bottlenecks Together with Blocked Samples**, Minwoo Ahn, Jeongmin Han, Youngjin Kwon, Jinkyu Jeong. *The 18th USENIX Symposium on Operating Systems Design and Implementation (OSDI'24)*, Santa Clara, CA, US, July 10-12, 2024

~~~~
@inproceedings {298760,
author = {Minwoo Ahn and Jeongmin Han and Youngjin Kwon and Jinkyu Jeong},
title = {Identifying {On-/Off-CPU} Bottlenecks Together with Blocked Samples},
booktitle = {18th USENIX Symposium on Operating Systems Design and Implementation (OSDI 24)},
year = {2024},
isbn = {978-1-939133-40-3},
address = {Santa Clara, CA},
pages = {893--910},
url = {https://www.usenix.org/conference/osdi24/presentation/ahn},
publisher = {USENIX Association},
month = jul
}
~~~~

**Contacts**: Please contact us if you have any questions. [Minwoo Ahn](mailto:mwahn402@gmail.com), [Jinkyu Jeong](mailto:jinkyu@yonsei.ac.kr), [Scalable Systems Software Lab](https://cslab.yonsei.ac.kr), Yonsei University, South Korea


## About Repository
This repository consists of three subdirectories: bcoz (source code of BCOZ), blocked\_samples (source code of Linux kernel with bperf), and osdi24\_ae (OSDI'24 artifacts evaluation).

Descriptions of each subdirectories are as follows.

### bcoz
This directory includes source code of BCOZ. BCOZ is a causal profiler that leverages the concept of virtual speedup for both on-/off-CPU events using blocked samples. At its core, BCOZ utilizes on- and off-CPU events profiles collected by blocked samples and estimates performance improvement through virtual speedup. BCOZ is built on top of [COZ](https://github.com/plasma-umass/coz) (SOSP'15).

### blocked\_samples
This directory includes extended Linux perf subsystem for blocked samples. Blocked samples is a profiling technique based on sampling, that encompasses both on- and off-CPU events simultaneously. Furthermore, the original Linux perf tool is replaced with bperf (blocked\_samples/tools/perf).

### osdi24\_ae
This directory is for OSDI'24 artifacts evaluation. It includes instructions for reproducing experimental results in the paper.

## Getting Started with Blocked Samples

We assume that this repository is located in user's home directory.

### 0. Ubuntu version
The Linux kernel version of blocked samples is 5.3.7 and may not compiled on Ubuntu versions newer than Ubuntu 20.04 (Ubuntu 20.04 LTS server is recommended). We will port the blocked samples to a newer kernel in the near future.

### 1. Linux kernel build
To enable blocked samples, you need to utilize the Linux kernel that we provided.
The process of building the Linux kernel is as follows.

#### 1-1. Install packages
Before building the kernel, ensure the following packages are installed.

```bash
$ sudo apt-get update
$ sudo apt-get install build-essential libncurses5 libncurses5-dev bin86 kernel-package libssl-dev bison flex libelf-dev dwarves
```

#### 1-2. Kernel configurations

```bash
$ cd ~/blocked_samples/blocked_samples
$ sudo make menuconfig
```

To profiling kernel debug information the following configurations should be set.

```bash
CONFIG_DEBUG_INFO=y
CONFIG_DEBUG_INFO_DWARF4=y
CONFIG_FRAME_POINTER=y
CONFIG_UNWINDER_FRAME_POINTER=y
```

#### 1-3. Miscelleneous

Disable 'CONFIG\_SYSTEM\_TRUSTED\_KEYS' and 'CONFIG\_SYSTEM\_REVOCATION\_KEYS'.

```bash
$ sudo scripts/config --disable SYSTEM_TRUSTED_KEYS
$ sudo scripts/config --disable SYSTEM_REVOCATION_KEYS
```

#### 1-4. Build the kernel

```bash
$ sudo make menuconfig
$ sudo make -j$(nproc) && sudo make modules -j$(nproc) && sudo make INSTALL_MOD_STRIP=1 modules_install -j$(nproc) && sudo make install -j$(nproc)
```

#### 1-5. grub update and reboot

```bash
$ sudo update-grub
```

After update grub, reboot your machine and make sure that newly built kernel is booted.

### 2. glibc build
To preserve entire callchain from user to kernel, glibc is should be rebuild with 'fno-omit-frame-pointer' flag. Brief instruction of rebuild glibc library is as follows. For the more detailed instruction, please refer to [this](http://www.yl.is.s.u-tokyo.ac.jp/~tosh/kml/how_to_build_and_use_glibc.html). We verified frame pointer is preserved in glibc-2.30.

**Do not use "/usr" directory as --prefix, since the original glibc will be overwritten.**

Recommended gcc version is lower or equal than 9.4.0 (we verified on 9.4.0).

```bash
[Download glibc-2.30]
$ cd ~/
$ wget http://ftp.gnu.org/pub/gnu/glibc/glibc-2.30.tar.gz
$ tar -xf glibc-2.30.tar.gz

[Make build directory (recommended gcc version<=9.4.0)]
$ mkdir glibc-build
$ cd glibc-build
$ ../glibc-2.30/configure --prefix=/usr/local/lib/glibc-testing --with-tls --enable-add-ons=nptl --enable-cet CFLAGS='-O3 -g -gdwarf-4 -fno-omit-frame-pointer' CXXFLAGS='-O3 -g -gdwarf-4 -fno-omit-frame-pointer' CPPFLAGS='-O3 -g -gdwarf-4 -fno-omit-frame-pointer'

[make and install]
$ sudo make
$ sudo make install

[Install dynamic loader]
$ sudo mkdir -p /trusted/local/lib/glibc-testing/lib
$ cd /trusted/local/lib/glibc-testing/lib
$ sudo cp /usr/local/lib/glibc-testing/lib/ld-2.30.so ./
$ sudo ln -s ld-2.30.so ld-linux.so.2
```

### 3. bperf build

#### 3-1. Install packages
To enable features of Linux perf tool, following packages are needed.

```bash
$ sudo apt-get update
$ sudo apt-get install libdw-dev systemtap-sdt-dev libunwind-dev libslang2-dev libgtk2.0-dev libperl-dev python-dev binutils-dev libiberty-dev liblzma-dev libzstd-dev libnuma-dev libbabeltrace-ctf-dev libaudit-dev
```

#### 3-2. Build bperf source code
```bash
$ cd ~/blocked_samples/blocked_samples/tools/perf
$ sudo make clean && sudo make
$ sudo mv perf bperf
$ sudo cp bperf /usr/bin
$ sudo sh -c 'echo 0 > /proc/sys/kernel/kptr_restrict'
$ sudo sh -c 'echo 1 > /proc/sys/kernel/perf_event_paranoid'
```

#### 3-3. Simple test for bperf

```bash
$ bperf record -g -e task-clock -c 1000000 --weight sleep 5
[ perf record: Woken up x times to write data ]
[ perf record: Captured and wrote x MB perf.data (5000 samples) ]
```

This command records task-clock event and the sample is recorded every 1M events. Note that, the task-clock event is counted every 1ns, which means 1M events indicates that the sampling period is 1ms.
If the number of the recorded samples after record is nearly **5000**, blockes samples is correctly imported with bperf (5000 samples indicates 5 sec).


### 4. BCOZ build
Instructions for building BCOZ is not much different from original COZ. For the more detailed instruction, please refer to [install guide for COZ](https://github.com/plasma-umass/coz).

#### 4-1. Install packages

```bash
$ sudo apt-get update
$ sudo apt-get install libdwarf-dev libelfin-dev
$ sudo apt-get install build-essential cmake docutils-common git python3 pkg-config
$ sudo apt-get install nodejs npm
```

#### 4-2. Build BCOZ

```bash
$ cd ~/blocked_samples/bcoz
$ make clean && make
$ sudo make install
$ sudo cp bcoz /usr/bin
```

#### 4-3. Change 'perf\_event\_paranoid'

```bash
$ sudo sh -c 'echo 1 > /proc/sys/kernel/perf_event_paranoid'
```

### 5. Profiling with blocked samples

#### 5-1. Compile application with additional flags

To profile the application with bperf and BCOZ, additional compile flags are needed. Following flags are needed to compile application and libraries that loaded dynamically. However, it is hard to compile all loaded libraries. Note that, to take full advantage of BCOZ (and COZ), libraries belonging to symbols in frequently sampled callchains must be compiled with the following flags. Otherwise, the results of virtual speedup will not be meaningful, or the predicted results will be inaccurate.

```bash
(Flags for CFLAGS and CXXFLAGS) -g -gdwarf-4 -fno-omit-frame-pointer
(Flags for LDFLAGS) -Wl,--no-as-needed -ldl -Wl,--rpath=/usr/local/lib/glibc-testing/lib -Wl,--dynamic-linker=/trusted/local/lib/glibc-testing/lib/ld-linux.so.2
```

* `-g -gdwarf-4` is for debug information. Especially, gdwarf-4 is needed for BCOZ (and COZ).
* `-fno-omit-frame-pointer` is for preserve frame pointer.
* `-Wl,--no-as-needed -ldl -Wl,--rpath -Wl,--dynamic-linker` is for use newly built glibc library. *rpath* and *dynamic-linker* are directories of newly built glibc and dynamic loader in [glibc build](#2-glibc-build), respectively. If you followed instructions in part 2, you can use as written above.

**Note**: When you compile and run your application as above, you may get an error that some shared libraries are not found, even though they exist. In this case, find the location of shared library by using `$ locate` and copying it to `/usr/local/lib/glibc-testing/lib`.

#### 5-2. bperf

Note that, blocked samples are extension of recording task-clock event. Other than chaging the recording target, you can utilize all of the existing features of the Linux perf tool. Typical use cases are as follows.

##### 5-2-1. Sampling IP only

```bash
[Record command]
$ bperf record -e task-clock -c 1000000 --weight [command]

[Record specific task]
$ bperf record -e task-clock -c 1000000 --weight --tid=[tids]

or

$ bperf record -e task-clock -c 1000000 --weight --pid=[pids]
```

##### 5-2-2. Sampling both IP and callchain
```bash
[Record command]
$ bperf record -g -e task-clock -c 1000000 --weight [command]

[Record specific task]
$ bperf record -g -e task-clock -c 1000000 --weight --tid=[tids]

or

$ bperf record -g -e task-clock -c 1000000 --weight --pid=[pids]
```

##### 5-2-3. Collect every single samples

Note that, *weight* option is used to avoid repeated samples in a single off-CPU event (Section 3.1 in the paper). However, you may need all of the individual samples for certain post-processing (e.g., plotting [Flamegraph](https://github.com/brendangregg/FlameGraph)). Brendan Gregg introduces the Flamegraph and how to plot [hot/cold Flamegraph](https://www.brendangregg.com/FlameGraphs/hotcoldflamegraphs.html) based on tracing results, bperf results also can plotted as the end-to-end visualized callstack using Flamegraph. Following instructions are guide for drawing hot/cold Flamegraph with bperf.

```bash
[Record (command as an example)]
$ bperf record -g -e task-clock -c 1000000 [command]

[Print individual samples]
$ bperf script > out.perf

[Post-processing samples folded format]
$ ./stackcollapse-perf.pl out.perf > out.folded

[Render a SVG]
$ ./flamegraph.pl out.folded > hotcold.svg
```

Two scripts (stackcollapse-perf.pl and flamegraph.pl) can be obtained in [Flamegraph](https://github.com/brendangregg/FlameGraph).

#### 5-3. BCOZ

##### 5-3-1. Add *Progress Point*

The counting progress point of BCOZ (and COZ) should be inserted into repeatedly executed code line of the application.
For example, start (or end) of the iterative loop, repeated query, etc. In our paper, we incremented the progress point counter at the arrival of the every queries in the RocksDB, and the RocksDB experiment increments the progress point counter at arrival of the every queries, and the innermost loop of the main computation loop.

Counting progress point is defined in bcoz/include/coz.h. Please copy this header file into your application, and add COZ\_PROGRESS in appropriate location in the application.

##### 5-3-2. Run application with BCOZ

Note that, you can utilize all of the existing features of the original COZ. Furthermore, there is additional type of run in BCOZ. Typical use cases are as follows.

* Default - Run with BCOZ fully enabled. Execution is divided into unit of conducting virtual speedup called *experiment*. Multiple virtual speedup results are accumulated in a single run.

* End-to-end - Run with BCOZ to conduct a single end-to-end virtual speedup. Virtual speedup target line and the size of the speedup is randomly selected. If you want specific target and the size of the speedup, you can use fixed-line and fixed-speedup with end-to-end option.

* Fixed-line - Run with BCOZ to conduct virtual speedup with fixed target code line. Fixed-line option can be used with any other options (or default run). 

* Fixed-speedup - Run with BCOZ to conduct virtual speedup with fixed sized speedup. Fixed-speedup option can be used with any other options (or default run).

* (BCOZ only) Fixed-subclass - Run with BCOZ to conduct virtual speedup with fixed target off-CPU subclass. Fixed-offcpu-subclass option can be used with any other options (or default run), except for the fixed-line. BCOZ can measure the impact of the blocking I/O, lock-waiting, CPU scheduling, and other off-CPU events, individually.

```bash
[Default run]
$ bcoz run [--end-to-end] [--fixed-line] <file:line> [--fixed-speedup] <speedup (0-100)> --- [command]

[Fixed-subclass run]
$ bcoz run [--end-to-end] [--fixed-speedup] <speedup (0-100)> [--blocked-scope] <subclass (I/O=i, lock-waiting=l, CPU scheduling=s, others=b> --- [command]
```

#### 5-4. Example application

Here is the example profiling results of the microbenchmark in osdi24\_ae/benchmarks/simple\_test.

test\_io.c is a single-threaded microbenchmark that executes integer decrement (line 78: *compute()*) and blocking I/Os (line 80: *io_light()*, and line 81: *io_heavy()*). Inside of the two I/O functions, there are invocation of the *write()* and *fsync()*. *io_heavy()* executes four times more I/Os. The main off-CPU events are blocking I/O caused by *fsync()* (line 46 in *io_light()*, and line 54 in *io_heavy()*).

test\_io\_coz.c is same with test\_io.c except for the progress point in line 87.

##### 5-4-1. Build

We provided Makefile inside of the simple\_test. Make sure that rpath and dynamic-linker are appropriate.

```bash
$ cd ~/blocked_samples/osdi24_ae/benchmarks/simple_test
$ make clean && make
```

##### 5-4-1. bperf

```bash
[Record]
$ bperf record -g -e task-clock -c 1000000 --weight ./test_io

[Change the name of the output file]
$ mv perf.data perf_weight.data
```

It is recommended to change the name of generated perf.data file, otherwise it will be overwritten.

After recording, you can report the perf result.

```bash
[With callchain]
$ bperf report -i perf_weight.data

[IP only]
$ bperf report -i perf_weight.data --no-children
```

##### 5-4-2. BCOZ

As mentioned in [Profiling with blocked samples](#5-profiling-with-blocked-samples), some shared libraries should copied to `/usr/local/lib/glibc-testing/lib`.

```bash
$ sudo cp /usr/lib/x86_64-linux-gnu/libdwarf++.so.0 /usr/local/lib/glibc-testing/lib
$ sudo cp /usr/lib/x86_64-linux-gnu/libelf++.so.0 /usr/local/lib/glibc-testing/lib
$ sudo cp /usr/lib/x86_64-linux-gnu/libstdc++.so.6 /usr/local/lib/glibc-testing/lib
$ sudo cp /usr/lib/x86_64-linux-gnu/libgcc_s.so.1 /usr/local/lib/glibc-testing/lib
```

The instructions below will generate a profile.coz file. Note that, as you run it repeatedly, the profile.coz will accumulate virtual speedup results, allowing you to see more causal profiling results.

```bash
[Default run]
$ bcoz run --- ./test_io_bcoz

[Fixed-subclass (I/O)]
$ bcoz run --blocked-scope i --- ./test_io_bcoz

[Fixed-line run]
$ bcoz run --fixed-line test_io_coz.c:55 --- ./test_io_bcoz
```

Load the generated profile.coz file into [COZ plotter](https://plasma-umass.org/coz/).

**Note**: profile.coz file is where virtual speedup results are accumulated, so be careful with filename management to avoid unintentionally writing results to the same file.

##### 5-4-3. Results

<img src="https://github.com/s3yonsei/blocked_samples/blob/main/osdi24_ae/benchmarks/simple_test/example_results/example-bperf.PNG " width="100%">

Off-CPU events' subclass is denoted in symbol section, inside the square brackets. Dot('.') and 'k' indicate on-CPU events, user and kernel, respectively, and 'I', 'L', 'S', and 'B' indicate off-CPU events, blocking I/O, lock-waiting, CPU scheduling, and other off-CPU events (e.g., *sleep*), respectively. In this microbenchmark, *fsync* is differentiated in on-CPU event ([.]), blocking I/O event ([I]), and other off-CPU events ([B]).

<img src="https://github.com/s3yonsei/blocked_samples/blob/main/osdi24_ae/benchmarks/simple_test/example_results/example-bcoz.PNG " width="100%">

BCOZ shows virtual speedup results results for lines of application code that contain off-CPU events. The first figure shows the performance improvement estimates for improving blocking I/O only (fixed-subclass run), and the next two figures show the performance improvement estimates for improving *fsync()* calls contained in *io\_heavy()* and *io\_light()*, respectively. Note that, the behavior of *fsync()* shows higher virtual speedup results because it inclues on-CPU events from the application-level to the kernel I/O stack and off-CPU events corresponding to blocking I/O. Also, the virutal speedup result for *fsync()* with *io\_heavy()* is higher than with *io\_light()*.
