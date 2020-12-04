#include <stdlib.h>

void print(char* string)
{
  int* terminal = (int*)0x100000;
  char* ptr = string;
  while(*ptr != '\0')
  {
    *terminal = *ptr;
    ptr = ptr + 1;
  }
}

void printl(char* string)
{
    print(string);
    print("\n");
}

int main()
{
  int* display = (int*)0x1000000;
  char buffer [50];

  for(int i = 0;i <= 50;i++) buffer [i] = 0;

  int cnt = 0;
  while (1)
  {
    *display = cnt;
    itoa(cnt, buffer, 10);
    printl(buffer);
    cnt++;
    //for(int i = 0;i < 0x3fff;i++);
  }
  


  return 0xffff;
}