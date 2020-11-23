

//To ensure that the load and store instructions are working
//This program is going to declare multiple functions and do nested calling
//the this will proof that the stack is getting updated

int call_5(int r)
{
    return r + 0x30;
}
char call_4(int r)
{
    return (char)call_5(r);
}

char call_3(int r)
{
    return call_4(r);
}

int call_2(int r)
{
    return (int)call_3(r);
}

int call_1(int r)
{
    return call_2(r);
}

int main()
{
  int* display = (int*)0x10004;

  *display = call_1(0x7);
  return 0xffff;
}

