
int main()
{
  int* display = 0x10004;
  char* string = "Hello World RISCV!";


  int cnt = 0;
  while(1)
  {
    *display = cnt;
    cnt++;
    print(string);
    for (int i = 0; i < 0xffff; i++)
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