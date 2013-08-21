#include <iostream>
#include <signal.h>
#include "cthread.h"

using namespace std;

bool is_interrupted = false;

class MyWork: public CThread
{
public:
	MyWork(){}
	~MyWork() {}
	bool Start(){
		//创建信号量来控制等待创建的线程初始化完毕
		csem_.Create(0);
		bool ret = CThread::Start();
		return ret && csem_.Wait(3000);
	}
	virtual void Run() {
		csem_.Post();
		while(!is_interrupted){
			std::cout<< "in work thread" << std::endl;
			sleep(1000);
		}
	}
private:
	CSem csem_;
};

void sighandler(int sig){
	std::cout << "Signal " << sig << " caught... work thread is interrupted" << endl;
	is_interrupted = true;
}

int main(int argc, char const *argv[])
{
	std::cout << "Hello, World!" << std::endl;

	// signal(SIGABRT, &sighandler);
	// signal(SIGTERM, &sighandler);
	signal(SIGINT, &sighandler);

	MyWork work;
	bool is_started = work.Start();
	if (! is_started)
	{
		std::cout << "start failed\n";
	}
	work.Join();

	system("pause");
	return 0;
}