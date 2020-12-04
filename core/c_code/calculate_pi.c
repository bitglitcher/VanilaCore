#include <stdlib.h>
#include <stdio.h>

void print(char* string)
{
  int* terminal = (int*)0x00100000;
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

    char buffer [20];

    int r[2800 + 1];
    int i, k;
    int b, d;
    int c = 0;

    for (i = 0; i < 2800; i++) {
        r[i] = 2000;
    }

    for (k = 2800; k > 0; k -= 14) {
        d = 0;

        i = k;
        for (;;) {
            d += r[i] * 10000;
            b = 2 * i - 1;

            r[i] = d % b;
            d /= b;
            i--;
            if (i == 0) break;
            d *= i;
        }
        sprintf(buffer, "%.4d", c + d / 10000);
        c = d % 10000;
    }
}