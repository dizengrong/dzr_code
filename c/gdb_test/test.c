#include <stdio.h>

dummy_function(){
	unsigned char *ptr = 0x00;
	*ptr = 0x00;
}

int main(void)
{
	dummy_function();

	return 0;
}
