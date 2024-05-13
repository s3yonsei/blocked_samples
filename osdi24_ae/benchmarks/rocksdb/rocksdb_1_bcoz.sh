#!/bin/bash

# ReadBlockContents
sync
echo 3 > /proc/sys/vm/drop_caches

echo "ReadBlockContents"

sleep 2

bcoz run --fixed-line block_based_table_reader.cc:1576 --- ./db_bench_bcoz --threads=8 --cache_index_and_filter_blocks=true --bloom_bits=10 --partition_index=true \
--partition_index_and_filters=true --num=$((1024*1024*1024)) --reads=$((2*1024*1024)) --use_direct_reads=true \
--key_size=48 --value_size=43  --cache_numshardbits=0 --db=/media/nvme_slow/rocksdb_partitioned --use_existing_db=1 \
--cache_size=$((10*1024*1024*1024)) --benchmarks=mixgraph --key_dist_a=0.002312 --key_dist_b=0.3467 \
--keyrange_dist_a=14.18 --keyrange_dist_b=-2.917 --keyrange_dist_c=0.0164 --keyrange_dist_d=-0.08082 \
--keyrange_num=30 --mix_get_ratio=1 --mix_put_ratio=0 --mix_seek_ratio=0 --value_k=0.2615 --value_sigma=25.45 \
--iter_k=2.517 --iter_sigma=14.236  --sine_mix_rate_interval_milliseconds=5000 --sine_a=1000 --sine_b=0.000073 --sine_d=4500 --ttl_seconds=$((3600*24*365))

# GetDataBlockFromCache
sync
echo 3 > /proc/sys/vm/drop_caches

echo "GetDataBlockFromCache"

sleep 2

bcoz run --fixed-line block_based_table_reader.cc:1519  --- ./db_bench_bcoz --threads=8 --cache_index_and_filter_blocks=true --bloom_bits=10 --partition_index=true \
--partition_index_and_filters=true --num=$((1024*1024*1024)) --reads=$((2*1024*1024)) --use_direct_reads=true \
--key_size=48 --value_size=43  --cache_numshardbits=0 --db=/media/nvme_slow/rocksdb_partitioned --use_existing_db=1 \
--cache_size=$((10*1024*1024*1024)) --benchmarks=mixgraph --key_dist_a=0.002312 --key_dist_b=0.3467 \
--keyrange_dist_a=14.18 --keyrange_dist_b=-2.917 --keyrange_dist_c=0.0164 --keyrange_dist_d=-0.08082 \
--keyrange_num=30 --mix_get_ratio=1 --mix_put_ratio=0 --mix_seek_ratio=0 --value_k=0.2615 --value_sigma=25.45 \
--iter_k=2.517 --iter_sigma=14.236  --sine_mix_rate_interval_milliseconds=5000 --sine_a=1000 --sine_b=0.000073 --sine_d=4500 --ttl_seconds=$((3600*24*365))
