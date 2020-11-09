
int main()
{
  char* string = "Hello World";
  int* terminal = 0x10000;
  char* ptr = string;

  while(ptr != 0)
  {
    *terminal = (int)ptr;
    ptr = ptr + 1; 
  }
  while(1);
  return 0xffff;
}
