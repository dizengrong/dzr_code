#ifndef THREAD_CTHREAD_H_
#define THREAD_CTHREAD_H_

#define WIN32

#ifdef WIN32
#include <Windows.h>
#include <process.h>
#else
#include <unistd.h>
#include <pthread.h>
#include <semaphore.h>
#include <sys/time.h>
#endif

class CThread
{

public:
	CThread(){thread_id_ = 0;};
	virtual ~CThread(){};
public:
	bool Start();
	bool Join();
	virtual void Run() = 0;
	inline unsigned long long GetThreadID() {return thread_id_;};
private:
	unsigned long long thread_id_;

};


class CSem
{
public:
	CSem();
	virtual ~CSem();
public:
	bool Create(int initcount);
	bool Wait(int timeout = 0);
	bool Post();

private:
#ifdef WIN32
	HANDLE sem_;
#else
	sem_t sem_;
	bool  is_created_;
#endif
};

void sleep(unsigned int ms);


#endif //THREAD_CTHREAD_H_