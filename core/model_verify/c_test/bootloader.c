#include <stdlib.h>
#include <stdio.h>
#include <string.h>

int main()
{
  //char* buffer [200];
  //float a = 3.345f;
  //sprintf(buffer, "%f\n", a);
  int sum;
  int a = 0xbfbf0000;
  __asm__("srai %0, %1, 16 " : "=r" (sum) : "r" (a));

  return 23;
}