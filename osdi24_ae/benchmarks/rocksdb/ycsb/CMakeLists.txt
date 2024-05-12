
PROJECT(ycsb)

SET(CMAKE_CXX_FLAGS  " -Wl,--rpath=./lib/ -m64 -Wall -o0 -g -pthread -std=c++17 -fPIC")
set(CMAKE_CXX_STANDARD_LIBRARIES "-lpthread -lrt -ldl -laio -luring -lsnappy -lgflags -lz -lbz2 -llz4 -lzstd -lnuma -ltbb -ltcmalloc")
#set(LINK_FLAGS "-lpthread -laio -luring")
SET(SRC_LIST src/test.cc src/rocksdb_client.cc core/core_workload.cc)

#INCLUDE_DIRECTORIES(${PROJECT_SOURCE_DIR}/../build/include)
INCLUDE_DIRECTORIES(${PROJECT_SOURCE_DIR}/../include)
INCLUDE_DIRECTORIES($ENV{DPDK_INCLUDE})
include_directories(${PROJECT_SOURCE_DIR})
include_directories(/home/spdk/spdk)
#include_directories(/home/jeongmin/spdk/)


#LINK_DIRECTORIES(${PROJECT_SOURCE_DIR}/../build/lib64)
LINK_DIRECTORIES(${PROJECT_SOURCE_DIR}/../)
LINK_DIRECTORIES(${$ENV{DPDK_LIB}})

ADD_SUBDIRECTORY(core)

ADD_EXECUTABLE(test ${SRC_LIST})

TARGET_LINK_LIBRARIES(test rocksdb)


