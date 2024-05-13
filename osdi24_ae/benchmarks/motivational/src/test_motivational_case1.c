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
#include <errno.h>


#define NUM_THREAD 2
#define FILE_SIZE 32768

pthread_mutex_t shared_mutex;
pthread_cond_t cond = PTHREAD_COND_INITIALIZER;
int barrier_thread_count = 0;

int fd;
void *read_buf;
void *write_buf;

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

void compute_light() {
	int n = 500000;
	while (n-- > 0)	{};
}

void compute_heavy() {
	int n = 40000000;	//case1: 40000000, case2: 50000000
	while (n-- > 0)	{};
}

void io_heavy() {
	int i, j;
	int ret = 0;

	for(i = 0; i < 200; i++) {	
		ret = pwrite(fd, write_buf, (size_t)(4 * FILE_SIZE), (off_t)(4 * FILE_SIZE * i));
		if (ret < 0)	printf("%dth iter nothing written.. errno: %d\n", i, errno);
		//fsync(fd);

		for (j = 0; j < 8; j++) {
			ret = pread(fd, read_buf, (size_t)(FILE_SIZE / 2), (off_t)(4 * FILE_SIZE * i + FILE_SIZE / 2 * j));
			if (ret < 0)	printf("Nothing read..\n");
		}		
	}
}

void funcA() {
	compute_light();
	io_heavy();
}

void funcB() {	
	compute_heavy(); 
}

void barrier(pthread_cond_t *c, pthread_mutex_t *m) {
	pthread_mutex_lock(m);
	barrier_thread_count++;

	if (barrier_thread_count == NUM_THREAD) {
		barrier_thread_count = 0;
		pthread_cond_signal(c);//pthread_cond_broadcast(c);
	} else {
		//while (pthread_cond_wait(c, m) != 0);
		pthread_cond_wait(c, m);
	}
	pthread_mutex_unlock(m);
}

void* t_function1(void* arg)
{
	pid_t pid = getpid();
	pthread_t tid = pthread_self();
	long thread_index = (long)arg;
	int i = 0;
	char filename[32];
	size_t start, end;
	start = get_time();

	read_buf = aligned_alloc(512, FILE_SIZE);
	write_buf = aligned_alloc(512, 4 * FILE_SIZE);
		
	for(i = 0; i < 4 * FILE_SIZE; i++) *((char *)(write_buf) + i) = (char)(i % 256);
	
	sprintf(filename, "/media/nvme_fast/file-%ld", thread_index);
	fd = open(filename, O_RDWR|O_CREAT|O_DIRECT|O_SYNC, 0644);
	if(fd == -1) printf("fd error...\n");

	i = 0;

	//barrier(&cond, &shared_mutex);

	while(i < 1000) {
		
		funcA();
		printf("thread 1 iteration %d\n", i);

		barrier(&cond, &shared_mutex);
        //pthread_cond_wait(&cond, &shared_mutex);
        //pthread_cond_signal(&cond);
		i++;
	}
	close(fd);
	remove(filename);

	end = get_time();

	printf("Runtime (ns) of thread %lu: %lu\n", (size_t)pid, end - start);

	return arg;
}

void* t_function2(void* arg)
{
	pid_t pid = getpid();
	pthread_t tid = pthread_self();
	long thread_index = (long)arg;
	int i = 0;
	size_t start, end;
	start = get_time();

	//barrier(&cond, &shared_mutex);
	
	while(i < 1000) {
		compute_heavy();

		printf("thread 2 iteration %d\n", i);

		barrier(&cond, &shared_mutex);
		//pthread_cond_signal(&cond);//barrier(&cond, &shared_mutex);
        //pthread_cond_wait(&cond, &shared_mutex);
		
		i++;
	}

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

	pthread_mutex_init(&shared_mutex, NULL);

	thr_id[0] = pthread_create(&p_thread[0], NULL, t_function1, NULL);

	if(thr_id[0] < 0) {
		printf("thread create error : 0");
		exit(0);
	}

	thr_id[1] = pthread_create(&p_thread[1], NULL, t_function2, (void *)1);

	if(thr_id[1] < 0) {
		printf("thread create error : 1");
		exit(0);
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

