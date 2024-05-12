//  Copyright (c) 2011-present, Facebook, Inc.  All rights reserved.
//  This source code is licensed under both the GPLv2 (found in the
//  COPYING file in the root directory) and Apache 2.0 License
//  (found in the LICENSE.Apache file in the root directory).
//
// Copyright (c) 2011 The LevelDB Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file. See the AUTHORS file for names of contributors.
#include "table/block_based/index_reader_common.h"

#include "aio/myaio.h"
extern std::vector<aio*> *top_filter_list;
extern unsigned long long init_start;
extern int NUM_THREADS;
extern int flag;

namespace ROCKSDB_NAMESPACE {
Status BlockBasedTable::IndexReaderCommon::ReadIndexBlock(
    const BlockBasedTable* table, FilePrefetchBuffer* prefetch_buffer,
    const ReadOptions& read_options, bool use_cache, GetContext* get_context,
    BlockCacheLookupContext* lookup_context,
    CachableEntry<Block>* index_block) {
  PERF_TIMER_GUARD(read_index_block_nanos);

  assert(table != nullptr);
  assert(index_block != nullptr);
  assert(index_block->IsEmpty());

  const Rep* const rep = table->get_rep();
  assert(rep != nullptr);

  const Status s = table->RetrieveBlock(
      prefetch_buffer, read_options, rep->footer.index_handle(),
      UncompressionDict::GetEmptyDict(), index_block, BlockType::kIndex,
      get_context, lookup_context, /* for_compaction */ false, use_cache,
      /* wait_for_cache */ true);
/*  
  if(flag == 1){
	  int aio_id = gettid()%NUM_THREADS;
	  if(aio_id == 0 && !top_filter_list[aio_id].empty()){
		  unsigned long long end=0, lo, hi;
		  asm volatile("rdtsc" : "=a" (lo), "=d" (hi));
		  end = ((unsigned long long)hi << 32) | lo;
		  printf("Index Block cnt %d latency %llu\n", top_filter_list[aio_id].front()->cnt, (end-init_start)/2600);
	  }
  }
*/
  return s;
}

Status BlockBasedTable::IndexReaderCommon::GetOrReadIndexBlock(
    bool no_io, GetContext* get_context,
    BlockCacheLookupContext* lookup_context,
    CachableEntry<Block>* index_block) const {
  assert(index_block != nullptr);

  if (!index_block_.IsEmpty()) {
    index_block->SetUnownedValue(index_block_.GetValue());
    return Status::OK();
  }

  ReadOptions read_options;
  if (no_io) {
    read_options.read_tier = kBlockCacheTier;
  }

  return ReadIndexBlock(table_, /*prefetch_buffer=*/nullptr, read_options,
                        cache_index_blocks(), get_context, lookup_context,
                        index_block);
}
}  // namespace ROCKSDB_NAMESPACE
