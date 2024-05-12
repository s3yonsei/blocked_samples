#include <stdio.h>
#include <pthread.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <sys/time.h>
#include <time.h>
#include <signal.h>
#include <sys/syscall.h>
#include <unistd.h>

#define NUM_THREAD 1
#define FILE_SIZE 32768

static size_t get_time() {
	struct timespec ts;
	if (clock_gettime(CLOCK_REALTIME, &ts)) {
		perror("get_time():");
		abort();
	}
	return ts.tv_nsec + ts.tv_sec * 1000 * 1000 * 1000;
}

size_t wait(size_t ns) {
	if (ns == 0)	return 0;

	struct timespec ts;
	ts.tv_nsec = ns % (1000*1000*1000);
	ts.tv_sec = (ns - ts.tv_nsec) / (1000*1000*1000);

	size_t start_time = get_time();
	while (nanosleep(&ts, &ts) != 0) {}

	return get_time() - start_time;
}

void compute(int n) {
		while (n-- > 0)	{};
}

void io_light(int fd, int *buf) {
	write(fd, buf, 4 * FILE_SIZE);
	fsync(fd);
}

void io_heavy(int fd, int *buf) {
	int i = 0;

	for(i = 0; i < 3; i++) {
		write(fd, buf, 4 * FILE_SIZE);
		fsync(fd);
	}
}

void* t_function(void* arg)
{
	pid_t pid = getpid();
	pthread_t tid = pthread_self();
	long thread_index = (long)arg;
	int i = 0;
	int j = 0;
	char filename[32];
	int buf[FILE_SIZE];
	int fd;
	size_t start, end;
	start = get_time();

	for(i = 0; i < FILE_SIZE; i++) buf[i] = i;

	sprintf(filename, "/tmp/file-%ld", thread_index);
	fd = open(filename, O_WRONLY|O_CREAT, 0644);
	if(fd == -1) printf("fd error...\n");

	while(i < 50000) {
		compute(20000);
		
		io_light(fd, buf);
		io_heavy(fd, buf);

		i++;
	}
	close(fd);
	remove(filename);

	end = get_time();

	printf("Runtime (ns) of thread %lu: %lu\n", (size_t)pid, end - start);

	return arg;
}

int main()
{
	pthread_t p_thread[NUM_THREAD];
	pthread_attr_t attr;
	int thr_id[NUM_THREAD];
	long status;
	long i;
	int rc;
	size_t start, end;
	start = get_time();

	for(i = 0; i < NUM_THREAD; i++) {
		thr_id[i] = pthread_create(&p_thread[i], NULL, t_function, (void*)i);

		if(thr_id[i] < 0) {
			printf("thread create error : ");
			exit(0);
		}
	}

	for(i = 0; i < NUM_THREAD; i++) {
		rc = pthread_join(p_thread[i], (void**)&status);
		if(rc) {
			printf("thread join error : %ld:%d\n", i, rc);
			exit(0);
		}
	}

	end = get_time();

	printf("Total runtime (ns): %lu\n", end - start);

	return 0;
}
