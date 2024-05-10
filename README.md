# Blocked Samples

[Blocked Samples](https://github.com/s3yonsei/blocked_samples) is a profiling technique based on sampling, that encompasses both on- and off-CPU events simultaneously. Based on blocked samples, we present two profiler: *bperf*, an easy-to-use sampling-based profiler and *BCOZ*, a causal profiler that profiles both on- and off-CPU events simultaneously and estimates potential speedup of optimizations.

This repository consists of three subdirectories: bcoz (source code of BCOZ), blocked\_samples (source code of Linux kernel with bperf), osdi24\_ae (OSDI'24 artifacts evaluation).

Description of each subdirectories are as follows.

### bcoz
This directory includes source code of BCOZ. BCOZ is a causal profiler that leverages the concept of virtual speedup for both on-/off-CPU events using blocked samples. At its core, BCOZ utilizes on- and off-CPU evnets profiles collected by blocked samples and estimates performance improvement through virtual speedup. BCOZ is built on top of [COZ](https://github.com/plasma-umass/coz) (SOSP'15).

### blocked\_samples
This directory includes extended Linux perf subsystem for blocked samples. Blocked samples is a profiling technique based on sampling, that encompasses both on- and off-CPU events simultaneously. Furthermore, the original Linux perf tool is replaced with bperf (blocked\_samples/tools/perf).

### osdi24\_ae
This directory is for OSDI'24 artifacts evaluation. It includes instructions for reproducing experimental results in the paper.

## Quick start guide

### 0. Ubuntu version
The Linux kernel version of blocked samples is 5.3.7 and may not compile on Ubuntu versions newer than Ubuntu 20.04 (Ubuntu 20.04 LTS server is recommended). We will port the blocked samples to a newer kernel in the near future.

### 1. Linux kernel build
To enable blocked samples, you need to utilize the Linux kernel we provide.
The process of building the Linux kernel is as follows.

#### 1-1. Install packages
Before building the kernel, ensure the following packages are installed.

```bash
$ apt-get update
$ apt-get install build-essential libncurses5 libncurses5-dev bin86 kernel-package libssl-dev bison flex libelf-dev dwarves
```

#### 1-2. Kernel configurations
To profiling kernel debug information the following configurations should be set.

```bash
CONFIG_DEBUG_INFO=y
CONFIG_DEBUG_INFO_DWARF4=y
CONFIG_FRAME_POINTER=y
CONFIG_UNWINDER_FRAME_POINTER=y
```

#### 1-3. Miscelleneous

Disable 'CONFIG_SYSTEM_TRUSTED_KEYS' and 'CONFIG_SYSTEM_REVOCATION_KEYS'.

```bash
$ sudo scripts/config --disable SYSTEM_TRUSTED_KEYS
$ sudo scripts/config --disable SYSTEM_REVOCATION_KEYS
```

#### 1-4. Build the kernel

```bash
$ sudo make -j$(nproc) && sudo make modules -j$(nproc) && sudo make INSTALL_MOD_STRIP=1 modules_install -j$(nproc) && sudo make install -j$(nproc)
```

#### grub update and reboot

```bash
$ sudo update-grub
```

After update grub, reboot your machine and make sure that newly built kernel is booted.

### 2. glibc build
To preserve entire callchain from user to kernel, glibc is should be rebuild with 'fno-omit-frame-pointer' flag. Brief instruction of rebuild glibc library is as follows. For the more detailed instruction, please refer to [this](http://www.yl.is.s.u-tokyo.ac.jp/~tosh/kml/how_to_build_and_use_glibc.html). We verified frame pointer is preserved in glibc-2.30.

```bash
[Download glibc-2.30]
$ cd ~/
$ wget http://ftp.gnu.org/pub/gnu/glibc/glibc-2.30.tar.gz
$ tar -xf glibc-2.30.tar.gz

[Make build directory]
$ mkdir glibc-build
$ cd glibc-build
$ ../glibc-2.30/configure --prefix=/usr/local/lib/glibc-testing --with-tls --enable-add-ons=nptl

[make and install]
$ make
$ make install

[Install dynamic loader]
$ mkdir -p /trusted/local/lib/glibc-testing/lib
$ cd /trusted/local/lib/glibc-testing/lib
$ cp /usr/local/lib/glibc-testing/lib/ld-2.30.so ./
$ ln -s ld-2.30.so ld-linux.so.2
```



### 3. bperf build

#### 3-1. Install packages
To enable features of Linux perf tool, following packages are needed.

```bash
$ apt-get update
$ apt-get install libdw-dev systemtap-sdt-dev libunwind-dev libslang2-dev libperl-dev libzstd-dev libcap-dev libnuma-dev libbabeltrace-dev libbabeltrace-ctf-dev libcapstone-dev libpfm4-dev libtraceevent-dev libbfd-dev
```

#### 3-2. Build bperf source code
```bash
$ cd blocked_samples/tools/perf
$ make clean && make
$ mv perf bperf
```

#### 3-3. Set environment variable

```bash
export PATH=[path/to/bperf]:$PATH
```

### 4. BCOZ build


## About paper

For the detailed description, please refer to the paper:

**Identifying On-/Off-CPU Bottlenecks Together with Blocked Samples**.

Author: Minwoo Ahn, Jeongmin Han, Youngjin Kwon, Jinkyu Jeong.

*18th USENIX Symposium on Operating Systems Design and Implementation (OSDI'24)*.

Contact: Minwoo Ahn (mwahn402@gmail.com), Jinkyu Jeong (jinkyu@yonsei.ac.kr)
