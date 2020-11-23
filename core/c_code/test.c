#include <stdlib.h>

int main()
{
  int* display = 0x10004;
  char* string = "Hello World RISCV!";
  print(string);
  char buffer [50];

  int cnt = 0;
  while(1)
  {
    *display = cnt;
    cnt++;
    //char *  itoa ( int value, char * str, int base );
    itoa(cnt, buffer, 10);
    print(buffer);
    for (int i = 0; i < 0x1; i++)
    {
      /* code */
    }
    
  }
  return 0xffff;
}

void print(char* string)
{
  int* terminal = 0x10000;
  char* ptr = string;
  while(*ptr != '\0')
  {
    *terminal = *ptr;
    ptr = ptr + 1;
  }
}