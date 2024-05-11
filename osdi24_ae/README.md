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

We recommend that follow the instructions below after you complete the [Getting Started with Blocked Samples](https://github.com/s3yonsei/blocked_samples/).

#### Motivational
Related figures: Figure 7, 9

#### RocksDB

##### *prefix\_dist* (Section 4.2 - Optimization 1)

Related figures: Figure 10

##### *allrandom* (Section 4.2 - Optimization 2)

Related figures: Figure 12a, 12b

##### *fillrandom* (Section 4.3 - Optimization 3)

Related figures: Figure 13b, 13c, 14

#### NPB
Related figures: Figure 15

#### Overhead
Related figures: Figure 16, 17


## 2. Artifacts components

Blocked samples is consists of two main components: Linux perf subsystem (Linux kernel), and BCOZ source codes (bperf is included in Linux kernel). Both are maintained in *bcoz* and *blocked\_samples* directories in this repository, respectively (https://github.com/s3yonsei/blocked\_samples).

## 3. Configurations

| **Component** | **Specification**                  |
|---------------|------------------------------------|
| Processor     | Intel Xeon Gold 5218 2.30 GHz * 2, 32 physical cores |
| **SSD**       | |
| Memory        | DDR4 2666 MHz, 512 GB (32 GB x16)  |
| **OS**        | Ubuntu 20.04 Server |

Note that, to evaluate our artifacts, not all system configurations are mendatory. However,


## 4. Getting Started Instructions
Please follow the instructions in [Getting Started with Blocked Samples](https://github.com/s3yonsei/blocked_samples/).

## 5. Detailed Instructions

## 6. Conclusion
