#include <iostream>
#include "cthread.h"

#ifdef WIN32
static unsigned int WINAPI  ThreadProc(LPVOID lpParam);
#else
static void * ThreadProc(void * pParam);
#endif


bool CThread::Start()
{
#ifdef WIN32
	unsigned long long ret = _beginthreadex(NULL, 0, ThreadProc, (void *) this, 0, NULL);

	if (ret == -1 || ret == 1  || ret == 0)
	{
		return false;
	}
	std::cout<< "start thread" << std::endl;
	thread_id_ = ret;
#else
	pthread_t ptid = 0;
	int ret = pthread_create(&ptid, NULL, ThreadProc, (void*)this);
	if (ret != 0)
	{
		return false;
	}
	thread_id_ = ptid;

#endif
	return true;
}
bool CThread::Join()
{
#ifdef WIN32
	if (WaitForSingleObject((HANDLE)thread_id_, INFINITE) != WAIT_OBJECT_0)
	{
		return false;
	}
#else
	if (pthread_join((pthread_t)thread_id_, NULL) != 0)
	{
		return false;
	}
#endif
	return true;
}


#ifdef WIN32
unsigned int WINAPI ThreadProc(LPVOID lpParam)
{
	CThread * p = (CThread *) lpParam;
	p->Run();
	_endthreadex(0);
	return 0;
}
#else
void * ThreadProc(void * pParam)
{
	CThread * p = (CThread *) pParam;
	p->Run();
	return NULL;
}
#endif


void sleep(unsigned int ms)
{
#ifdef WIN32
	::Sleep(ms);
#else
	usleep(1000*ms);
#endif
}

CSem::CSem()
{
#ifdef WIN32
	sem_ = NULL;
#else
	is_created_ = false;
#endif
}
CSem::~CSem()
{
#ifdef WIN32
	if (sem_ != NULL)
	{
		CloseHandle(sem_);
		sem_ = NULL;
	}
#else
	if (is_created_)
	{
		is_created_ = false;
		sem_destroy(&sem_);
	}
#endif
}
bool CSem::Create(int initcount)
{
	if (initcount < 0)
	{
		initcount = 0;
	}
#ifdef WIN32
	if (initcount > 64)
	{
		return false;
	}
	sem_ = CreateSemaphore(NULL, initcount, 64, NULL);
	if (sem_ == NULL)
	{
		return false;
	}
#else
	if (sem_init(&sem_, 0, initcount) != 0)
	{
		return false;
	}
	is_created_ = true;
#endif
	return true;

}
bool CSem::Wait(int timeout)
{
#ifdef WIN32
	if (timeout <= 0)
	{
		timeout = INFINITE;
	}
	if (WaitForSingleObject(sem_, timeout) != WAIT_OBJECT_0)
	{
		return false;
	}
#else
	if (timeout <= 0)
	{
		return (sem_wait(&sem_) == 0);
	}
	else
	{
		timespec ts;
		ts.tv_sec += time(NULL) + timeout/1000;
		ts.tv_nsec += (timeout%1000)*1000000;
		return (sem_timedwait(&sem_, &ts) == 0);
	}
#endif
	return true;
}
bool CSem::Post()
{
#ifdef WIN32
	return ReleaseSemaphore(sem_, 1, NULL) ? true : false;
#else
	return (sem_post(&sem_) == 0);
#endif
}
