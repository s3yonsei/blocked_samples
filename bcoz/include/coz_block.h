/*
 * Copyright (c) 2015, Charlie Curtsinger and Emery Berger,
 *                     University of Massachusetts Amherst
 * This file is part of the Coz project. See LICENSE.md file at the top-level
 * directory of this distribution and at http://github.com/plasma-umass/coz.
 */

#if !defined(COZ_BLOCK_H)
#define COZ_BLOCK_H

#ifndef __USE_GNU
#  define __USE_GNU
#endif

#ifndef _GNU_SOURCE
#  define _GNU_SOURCE
#endif

#include <dlfcn.h>
#include <stdint.h>
#include <string.h> /* for memcpy hack below */
#include <stdio.h>
#if defined(__cplusplus)
extern "C" {
#endif

typedef void (*coz_enable_bcoz_t)(void);
typedef void (*coz_disable_bcoz_t)(void);
typedef void (*coz_pre_block_t)(void);
typedef void (*coz_post_block_0_t)(void);
typedef void (*coz_post_block_1_t)(void);
typedef void (*coz_catch_up_t)(void);

// Enable bcoz
static void _call_enable_bcoz() {
	static unsigned char _initialized = 0;
	static coz_enable_bcoz_t fn;
	if (!_initialized) {
		void *p = dlsym(RTLD_DEFAULT, "_coz_enable_bcoz");

		memcpy(&fn, &p, sizeof(p));

		_initialized = 1;
	}

	if (fn)	fn();
	else	return;
}

// Disable bcoz
static void _call_disable_bcoz() {
	static unsigned char _initialized = 0;
	static coz_disable_bcoz_t fn;
	if (!_initialized) {
		void *p = dlsym(RTLD_DEFAULT, "_coz_disable_bcoz");

		memcpy(&fn, &p, sizeof(p));

		_initialized = 1;
	}

	if (fn)	fn();
	else	return;
}

// Invoke pre_block
static void _call_pre_block() {
	static unsigned char _initialized = 0;
	static coz_pre_block_t fn;
	if (!_initialized) {
		//if (dlsym) {
			void* p = dlsym(RTLD_DEFAULT, "_coz_pre_block");

			memcpy(&fn, &p, sizeof(p));
		//}

		_initialized = 1;
	}

	if (fn)	fn();
	else	return;
}

// Invoke post_block_0 : timed-out.
static void _call_post_block_0() {
	static unsigned char _initialized = 0;
	static coz_post_block_0_t fn;

	if (!_initialized) {
		//if (dlsym) {
			void* p = dlsym(RTLD_DEFAULT, "_coz_post_block_0");

			memcpy(&fn, &p, sizeof(p));
		//}		

		_initialized = 1;
	}

	if (fn)	fn();
	else	return;
}

// Invoke post_block_1
static void _call_post_block_1() {
	static unsigned char _initialized = 0;
	static coz_post_block_1_t fn;

	if (!_initialized) {
		if (dlsym) {
			void* p = dlsym(RTLD_DEFAULT, "_coz_post_block_1");

			memcpy(&fn, &p, sizeof(p));
		}		

		_initialized = 1;
	}

	if (fn)	fn();
	else	return;
}

// Invoke catch_up
static void _call_catch_up() {
	static unsigned char _initialized = 0;
	static coz_catch_up_t fn;

	if (!_initialized) {
		if (dlsym) {
			void* p = dlsym(RTLD_DEFAULT, "_coz_catch_up");

			memcpy(&fn, &p, sizeof(p));
		}		

		_initialized = 1;
	}

	if (fn)	fn();
	else	return;
}

#define COZ_ENABLE_BCOZ		_call_enable_bcoz()
#define COZ_DISABLE_BCOZ	_call_disable_bcoz()
#define COZ_PRE_BLOCK		_call_pre_block()
#define COZ_POST_BLOCK_0	_call_post_block_0()
#define COZ_POST_BLOCK_1	_call_post_block_1()
#define COZ_CATCH_UP		_call_catch_up()

#if defined(__cplusplus)
}
#endif

#endif
