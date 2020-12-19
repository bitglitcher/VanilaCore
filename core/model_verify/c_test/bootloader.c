#include <stdlib.h>
#include <stdio.h>

int main()
{
  int something = 10;
  char buffer [40];
  sprintf(buffer, "%d\n", something);

  return 0xffff;
}