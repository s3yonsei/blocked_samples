#!/bin/bash

ulimit -n 1048576

# Without fixed-line
sync
echo 3 > /proc/sys/vm/drop_caches

sleep 2

bcoz run --- ./db_bench_bcoz --threads=16 --num=$((10*1024*1024)) --key_size=1000 --value_size=24 --writes=$((1*1024*1024)) \
--use_direct_reads=true --use_direct_io_for_flush_and_compaction=true \
--ttl_seconds=$((60*60*24*30*12)) --db=/media/nvme_fast/rocksdb_temp \
--use_existing_db=false --benchmarks=fillrandom > temp.txt

mv profile.coz profile_rocksdb_3.coz

### Compaction thread
# ProcessKeyValueCompaction
for((i=0;i<=100;i+=10))
do
	sync
	echo 3 > /proc/sys/vm/drop_caches

	echo "ProcessKeyValueCompaction"

	sleep 2

	bcoz run --fixed-line compaction_job.cc:730 --end-to-end --fixed-speedup ${i} --- ./db_bench_bcoz --threads=16 --num=$((10*1024*1024)) --key_size=1000 --value_size=24 --writes=$((1*1024*1024)) \
--use_direct_reads=true --use_direct_io_for_flush_and_compaction=true \
--ttl_seconds=$((60*60*24*30*12)) --db=/media/nvme_fast/rocksdb_temp \
--use_existing_db=false --benchmarks=fillrandom > temp.txt
done

# CompressBlock
for((i=0;i<=100;i+=10))
do
	sync
	echo 3 > /proc/sys/vm/drop_caches

	echo "CompressBlock"

	sleep 2

	bcoz run --fixed-line block_based_table_builder.cc:1154 --end-to-end --fixed-speedup ${i} --- ./db_bench_bcoz --threads=16 --num=$((10*1024*1024)) --key_size=1000 --value_size=24 --writes=$((1*1024*1024)) \
--use_direct_reads=true --use_direct_io_for_flush_and_compaction=true \
--ttl_seconds=$((60*60*24*30*12)) --db=/media/nvme_fast/rocksdb_temp \
--use_existing_db=false --benchmarks=fillrandom > temp.txt
done

# pread
for((i=0;i<=100;i+=10))
do
	sync
	echo 3 > /proc/sys/vm/drop_caches

	echo "pread"

	sleep 2

	bcoz run --fixed-line random_access_file_reader.cc:139 --end-to-end --fixed-speedup ${i} --- ./db_bench_bcoz --threads=16 --num=$((10*1024*1024)) --key_size=1000 --value_size=24 --writes=$((1*1024*1024)) \
--use_direct_reads=true --use_direct_io_for_flush_and_compaction=true \
--ttl_seconds=$((60*60*24*30*12)) --db=/media/nvme_fast/rocksdb_temp \
--use_existing_db=false --benchmarks=fillrandom > temp.txt
done

# pwrite
for((i=0;i<=100;i+=10))
do
	sync
	echo 3 > /proc/sys/vm/drop_caches

	echo "pwrite"

	sleep 2

	bcoz run --fixed-line io_posix.cc:129 --end-to-end --fixed-speedup ${i} --- ./db_bench_bcoz --threads=16 --num=$((10*1024*1024)) --key_size=1000 --value_size=24 --writes=$((1*1024*1024)) \
--use_direct_reads=true --use_direct_io_for_flush_and_compaction=true \
--ttl_seconds=$((60*60*24*30*12)) --db=/media/nvme_fast/rocksdb_temp \
--use_existing_db=false --benchmarks=fillrandom > temp.txt
done


### Worker thread

# JoinBatchGroup
for((i=0;i<=100;i+=10))
do
	sync
	echo 3 > /proc/sys/vm/drop_caches

	echo "JoinBatchGroup"

	sleep 2

	bcoz run --fixed-line write_thread.cc:187 --end-to-end --fixed-speedup ${i} --- ./db_bench_bcoz --threads=16 --num=$((10*1024*1024)) --key_size=1000 --value_size=24 --writes=$((1*1024*1024)) \
--use_direct_reads=true --use_direct_io_for_flush_and_compaction=true \
--ttl_seconds=$((60*60*24*30*12)) --db=/media/nvme_fast/rocksdb_temp \
--use_existing_db=false --benchmarks=fillrandom > temp.txt
done

## DelayWrite
#for((i=0;i<=100;i+=10))
#do
#	sync
#	echo 3 > /proc/sys/vm/drop_caches
#
#	echo "DelayWrite"
#
#	sleep 2
#
#	bcoz run --fixed-line db_impl_write.cc:1663 --end-to-end --fixed-speedup ${i} --- ./db_bench_bcoz --threads=16 --num=$((10*1024*1024)) --key_size=1000 --value_size=24 --writes=$((1*1024*1024)) \
#--use_direct_reads=true --use_direct_io_for_flush_and_compaction=true \
#--ttl_seconds=$((60*60*24*30*12)) --db=/media/nvme_fast/rocksdb_temp \
#--use_existing_db=false --benchmarks=fillrandom > temp.txt
#done

# WAL
for((i=0;i<=100;i+=10))
do
	sync
	echo 3 > /proc/sys/vm/drop_caches

	echo "WAL"

	sleep 2

	bcoz run --fixed-line db_impl_write.cc:1241 --end-to-end --fixed-speedup ${i} --- ./db_bench_bcoz --threads=16 --num=$((10*1024*1024)) --key_size=1000 --value_size=24 --writes=$((1*1024*1024)) \
--use_direct_reads=true --use_direct_io_for_flush_and_compaction=true \
--ttl_seconds=$((60*60*24*30*12)) --db=/media/nvme_fast/rocksdb_temp \
--use_existing_db=false --benchmarks=fillrandom > temp.txt
done


mv profile.coz profile_rocksdb_3_fixed.coz
