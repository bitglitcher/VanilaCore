#include <stdlib.h>

char banner[] =                                                                     
" _   _             _ _       _____                \n\
| | | |           (_) |     /  __ \\               \n\
| | | | __ _ _ __  _| | __ _| /  \\/ ___  _ __ ___  \n\
| | | |/ _` | '_ \\| | |/ _` | |    / _ \\| '__/ _ \\ \n\
\\ \\_/ / (_| | | | | | | (_| | \\__/\\ (_) | | |  __/ \n\
 \\___/ \\__,_|_| |_|_|_|\\__,_|\\____/\\___/|_|  \\___| ";
                                                  
                                                  
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
    printl(banner);
    printl("Bootloader level 0");
    while(1);
}