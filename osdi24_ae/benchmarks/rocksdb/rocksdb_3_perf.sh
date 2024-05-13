#!/bin/bash

# Baseline
sync
echo 3 > /proc/sys/vm/drop_caches

echo "Baseline"

sleep 2

./db_bench_perf --threads=16 --bloom_bits=10 --num=$((10*1024*1024)) --key_size=1000 --value_size=24 \
--cache_size=$((10*1024*1024*1024)) --use_direct_reads=true --use_direct_io_for_flush_and_compaction=true \
--ttl_seconds=$((60*60*24*30*12)) --partition_index=true --partition_index_and_filters=true --db=/media/nvme_fast/rocksdb_temp \
--use_existing_db=false --benchmarks=fillrandom > temp.txt

echo "Baseline" > rocksdb_1.txt
cat temp.txt | grep fillrandom >> rocksdb_1.txt

rm /media/nvme_fast/rocksdb_temp/*

# RamDisk
sync
echo 3 > /proc/sys/vm/drop_caches

echo "RamDisk"

sleep 2

./db_bench_perf --threads=16 --bloom_bits=10 --num=$((10*1024*1024)) --key_size=1000 --value_size=24 --wal_dir=/media/ramdisk \
--cache_size=$((10*1024*1024*1024)) --use_direct_reads=true --use_direct_io_for_flush_and_compaction=true \
--ttl_seconds=$((60*60*24*30*12)) --partition_index=true --partition_index_and_filters=true --db=/media/nvme_fast/rocksdb_temp \
--use_existing_db=false --benchmarks=fillrandom > temp.txt

echo "Ramdisk" >> rocksdb_1.txt
cat temp.txt | grep fillrandom >> rocksdb_1.txt

rm /media/nvme_fast/rocksdb_temp/*
rm /media/ramdisk/*

# no-WAL
sync
echo 3 > /proc/sys/vm/drop_caches

echo "no-WAL"

sleep 2

./db_bench_perf --threads=16 --bloom_bits=10 --num=$((10*1024*1024)) --key_size=1000 --value_size=24 --disable_wal \
--cache_size=$((10*1024*1024*1024)) --use_direct_reads=true --use_direct_io_for_flush_and_compaction=true \
--ttl_seconds=$((60*60*24*30*12)) --partition_index=true --partition_index_and_filters=true --db=/media/nvme_fast/rocksdb_temp \
--use_existing_db=false --benchmarks=fillrandom > temp.txt

echo "no-WAL" >> rocksdb_1.txt
cat temp.txt | grep fillrandom >> rocksdb_1.txt

rm /media/nvme_fast/rocksdb_temp/*

# Compress+
sync
echo 3 > /proc/sys/vm/drop_caches

echo "Compress+"

sleep 2

./db_bench_perf --threads=16 --bloom_bits=10 --num=$((10*1024*1024)) --key_size=1000 --value_size=24 --compress_type=none \
--cache_size=$((10*1024*1024*1024)) --use_direct_reads=true --use_direct_io_for_flush_and_compaction=true \
--ttl_seconds=$((60*60*24*30*12)) --partition_index=true --partition_index_and_filters=true --db=/media/nvme_fast/rocksdb_temp \
--use_existing_db=false --benchmarks=fillrandom > temp.txt

echo "Compress+" >> rocksdb_1.txt
cat temp.txt | grep fillrandom >> rocksdb_1.txt

rm /media/nvme_fast/rocksdb_temp/*

# Comp+
sync
echo 3 > /proc/sys/vm/drop_caches

echo "Comp+"

sleep 2

./db_bench_perf --threads=16 --bloom_bits=10 --num=$((10*1024*1024)) --key_size=1000 --value_size=24 --max_background_compactions=4 \
--cache_size=$((10*1024*1024*1024)) --use_direct_reads=true --use_direct_io_for_flush_and_compaction=true \
--ttl_seconds=$((60*60*24*30*12)) --partition_index=true --partition_index_and_filters=true --db=/media/nvme_fast/rocksdb_temp \
--use_existing_db=false --benchmarks=fillrandom > temp.txt

echo "Comp+" >> rocksdb_1.txt
cat temp.txt | grep fillrandom >> rocksdb_1.txt

rm /media/nvme_fast/rocksdb_temp/*

# Stall
sync
echo 3 > /proc/sys/vm/drop_caches

echo "Stall"

sleep 2

./db_bench_perf --threads=16 --bloom_bits=10 --num=$((10*1024*1024)) --key_size=1000 --value_size=24 --max_write_buffer_number=16 \
--cache_size=$((10*1024*1024*1024)) --use_direct_reads=true --use_direct_io_for_flush_and_compaction=true \
--ttl_seconds=$((60*60*24*30*12)) --partition_index=true --partition_index_and_filters=true --db=/media/nvme_fast/rocksdb_temp \
--use_existing_db=false --benchmarks=fillrandom > temp.txt

echo "Stall" >> rocksdb_1.txt
cat temp.txt | grep fillrandom >> rocksdb_1.txt

rm /media/nvme_fast/rocksdb_temp/*


rm temp.txt
