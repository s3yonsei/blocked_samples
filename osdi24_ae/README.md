# OSDI'24 Artifacts Evaluation


## Title: Identifying On-/Off-CPU Bottlenecks Together with Blocked Samples


Author: Minwoo Ahn, Jeongmin Han, Youngjin Kwon, Jinkyu Jeong

Contact: Minwoo Ahn (mwahn402@gmail.com), Jinkyu Jeong (jinkyu@yonsei.ac.kr)

### Introduction

This repository is for reproduce the experimental results presented in the paper published at OSDI'24. Our evaluations are consists of 'motivational', 'RocksDB (*prefix_dist*, *allrandom*, *fillrandom*)', and 'NPB (*integer sort*)'. Furthermore, in this 

#### Motivational
Related figures: Figure 7, 9

#### RocksDB
Related figures: Figure 10, 12a, 12b, 13b, 13c, 14

#### NPB
Related figures: Figure 15

#### Overhead


### Artifacts components

Blocked samples is consists of two main components: Linux perf subsystem (Linux kernel), and BCOZ source codes (bperf is included in Linux kernel). Both are maintained in a single external repository (https://github.com/s3yonsei/blocked_samples).

### Configurations

| **Component** | **Specification**                  |
|---------------|------------------------------------|
| Processor     | Intel Xeon Gold 5218 2.30 GHz * 2, 32 physical cores |
| **SSD**       | |
| Memory        | DDR4 2666 MHz, 512 GB (32 GB x16)  |
| **OS**        | Ubuntu 20.04 Server |

Note that, to evaluate our artifacts, not all system configurations are mendatory. However,


## Getting Started Instructions

### Clone related repositories

### Linux kernel build

### bperf build

### BCOZ build

## Detailed Instructions





### Contents
1. Introduction
2. Configurations
3. Software components
4. Linux perf subsystem build
5. bperf build
6. BCOZ build
7. (Optional) glibc build
8. Application build
9. Report profiling results


### Getting Started Instructions

### Detailed Instructions
