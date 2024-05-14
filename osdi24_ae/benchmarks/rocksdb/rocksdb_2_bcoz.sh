#!/bin/bash

ulimit -n 1048576

# I/O subclass
sync
echo 3 > /proc/sys/vm/drop_caches

echo "I/O subclass"

sleep 2

bcoz run --blocked-scope i --- ./db_bench_bcoz --threads=8 --cache_index_and_filter_blocks=true --bloom_bits=10 --partition_index=true \
--partition_index_and_filters=true --num=$((1024*1024*1024)) --reads=$((1024*1024)) --use_direct_reads=true \
--key_size=48 --value_size=43  --cache_numshardbits=-1 --db=/media/nvme_fast/rocksdb_partitioned --use_existing_db=1 \
--cache_size=$((128*1024*1024)) --benchmarks=mixgraph --keyrange_num=1 --value_k=0.2615 --value_sigma=25.45 \
--iter_k=2.517 --iter_sigma=14.236 --mix_get_ratio=1 --mix_put_ratio=0 --mix_seek_ratio=0 \
--sine_mix_rate_interval_milliseconds=5000 --sine_a=1000 --sine_b=0.000073 --sine_d=4500 --ttl_seconds=$((3600*24*365))

# GetFilterPartitionBlock
sync
echo 3 > /proc/sys/vm/drop_caches

echo "GetFilterPartitionBlock"

sleep 2

bcoz run --fixed-line partitioned_filter_block.cc:354 --- ./db_bench_bcoz --threads=8 --cache_index_and_filter_blocks=true --bloom_bits=10 --partition_index=true \
--partition_index_and_filters=true --num=$((1024*1024*1024)) --reads=$((1024*1024)) --use_direct_reads=true \
--key_size=48 --value_size=43  --cache_numshardbits=-1 --db=/media/nvme_fast/rocksdb_partitioned --use_existing_db=1 \
--cache_size=$((128*1024*1024)) --benchmarks=mixgraph --keyrange_num=1 --value_k=0.2615 --value_sigma=25.45 \
--iter_k=2.517 --iter_sigma=14.236 --mix_get_ratio=1 --mix_put_ratio=0 --mix_seek_ratio=0 \
--sine_mix_rate_interval_milliseconds=5000 --sine_a=1000 --sine_b=0.000073 --sine_d=4500 --ttl_seconds=$((3600*24*365))

# IndexBlockIter
sync
echo 3 > /proc/sys/vm/drop_caches

echo "IndexBlockIter"

sleep 2

bcoz run --fixed-line partitioned_index_iterator.cc:96 --- ./db_bench_bcoz --threads=8 --cache_index_and_filter_blocks=true --bloom_bits=10 --partition_index=true \
--partition_index_and_filters=true --num=$((1024*1024*1024)) --reads=$((1024*1024)) --use_direct_reads=true \
--key_size=48 --value_size=43  --cache_numshardbits=-1 --db=/media/nvme_fast/rocksdb_partitioned --use_existing_db=1 \
--cache_size=$((128*1024*1024)) --benchmarks=mixgraph --keyrange_num=1 --value_k=0.2615 --value_sigma=25.45 \
--iter_k=2.517 --iter_sigma=14.236 --mix_get_ratio=1 --mix_put_ratio=0 --mix_seek_ratio=0 \
--sine_mix_rate_interval_milliseconds=5000 --sine_a=1000 --sine_b=0.000073 --sine_d=4500 --ttl_seconds=$((3600*24*365))

# DataBlockIter
sync
echo 3 > /proc/sys/vm/drop_caches

echo "IndexBlockIter"

sleep 2

bcoz run --fixed-line block_based_table_reader.cc:2460 --- ./db_bench_bcoz --threads=8 --cache_index_and_filter_blocks=true --bloom_bits=10 --partition_index=true \
--partition_index_and_filters=true --num=$((1024*1024*1024)) --reads=$((1024*1024)) --use_direct_reads=true \
--key_size=48 --value_size=43  --cache_numshardbits=-1 --db=/media/nvme_fast/rocksdb_partitioned --use_existing_db=1 \
--cache_size=$((128*1024*1024)) --benchmarks=mixgraph --keyrange_num=1 --value_k=0.2615 --value_sigma=25.45 \
--iter_k=2.517 --iter_sigma=14.236 --mix_get_ratio=1 --mix_put_ratio=0 --mix_seek_ratio=0 \
--sine_mix_rate_interval_milliseconds=5000 --sine_a=1000 --sine_b=0.000073 --sine_d=4500 --ttl_seconds=$((3600*24*365))


mv profile.coz profile_rocksdb_2.coz
