#pragma once

#define CACHE		1
#define DEVICE		2
#define IO_COMPLETE 3
#define INDEX_CACHE			4
#define INDEX_DEVICE		5
#define INDEX_IO_COMPLETE 	6

#define TOP_FILTER	1
#define PART_FILTER 2
#define TOP_INDEX	3
#define PART_INDEX	4

#define IO_SIZE 64

#include <list>
#include <aio.h>
#include <mutex>
#include <libaio.h>
#include <unistd.h>
#include <sys/syscall.h>
#include <cstdio>
#include <libaio.h>
#include <atomic>
#include <liburing/src/include/liburing.h>
#define gettid() syscall(SYS_gettid)


#include "db/version_edit.h"
#include "table/get_context.h"
#include "table/block_based/filter_block.h"

//#define CACHE_ALIGN __attribute__(aligned(CACHE_LINE_SIZE))

using namespace ROCKSDB_NAMESPACE;

struct aio{
	struct iocb iocb;
	unsigned int HitFileLevel;
	FileMetaData* file_meta;
	char* used_buf;
	char* buf;	// if aio buf is not nullptr
	char* bufstart;
	size_t alignment;
//	size_t cursize;
	size_t capacity;
//	unsigned long long start;
	int read_type;	/* init 0 from cache 1  from device 2 */
	bool ok;
	bool may_match;
	bool timer_enabled;
	bool HitFileLastInLevel;
	unsigned long long cnt;
//	FilterBlockReader* filter;
};

struct free_node{
	//struct iocb* iocb;
	unsigned long long cnt;
	char* buf;
};

/*
uint64_t rdtsc(){
	unsigned int lo, hi;
	__asm__ __volatile__ ("rdtsc" : "=a" (lo), "=d" (hi));
	return ((uint64_t)hi << 32) | lo;
}
*/
//std::list<aio<ParsedFullFilterBlock>> top_filter_list;
//std::list<aio<ParsedFullFilterBlock>> partition_filter_list;
//std::list<aio<ParsedFullFilterBlock>> top_index_list;
//std::list<aio<ParsedFullFilterBlock>> partition_index_list;
