#include <stdlib.h>
#include <stdio.h>
#include <string.h>

char banner[] =                                                                     
" _   _             _ _       _____                \n\
| | | |           (_) |     /  __ \\               \n\
| | | | __ _ _ __  _| | __ _| /  \\/ ___  _ __ ___  \n\
| | | |/ _` | '_ \\| | |/ _` | |    / _ \\| '__/ _ \\ \n\
\\ \\_/ / (_| | | | | | | (_| | \\__/\\ (_) | | |  __/ \n\
 \\___/ \\__,_|_| |_|_|_|\\__,_|\\____/\\___/|_|  \\___| ";
                                                  
int* uart_reciever_count = (int*)0x10000004;
int* uart_reciever_data =  (int*)0x10000000;

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

void print_char(char data)
{
  int* terminal = (int*)0x100000;
  *terminal = data;
}

void printl(char* string)
{
    print(string);
    print("\n");
}


void receive_buffer()
{
    int index = 0;
    char buffer [200]; //8 Character hexadecimal value = 32bit value 
    while(1)
    {
        if(1)
        {
            char data = 'a';
            if(data == '*') //Stop character
            {
                buffer [index] = '\0';   
                index++;
                break;
            }
            else
            {
                buffer [index] = data;   
                index++;
            }
        }
    }

    char hexstring [9];
    int number = 0;
    char temp [20];
    for(unsigned int i = 0;i < (unsigned)strlen(buffer);i += 8)
    {
        strncpy(hexstring, buffer+i, 8);
        hexstring[8] = '\0';
        //Now 
        number = strtol(hexstring, NULL, 16);
        itoa(number, temp, 10);
        print(temp);
    }
}

#define BUFFER_START 0
#define BUFFER_END   1
char* commands [] = {"BUFFER_START", "BUFFER_END"};
#define N_COMMANDS   2

int main()
{
    printl(banner);
    printl("Bootloader level 0");
    
    //Input buffer
    char input_buffer [20];
    int index = 0;
    int command_okay = 0;
    
    while(1)
    {
      //Read input buffer lenght
      if(*uart_reciever_count > 0)
      {
        //Read Recieved data
        int data = *uart_reciever_data;
        char data_c = data & 0xff;
        
        //Print back character
        print_char(data_c);
        input_buffer[index] = data_c;
        index++;
        if(index > 20)
        {
          printl("\nError: Line too long\n");
          //Clean buffer
          for(int i = 0;i < 20;i++)
          {
            input_buffer [i] = '\0';
          }
          index = 0;
        }

        if(data_c == '\r')
        {
            //To eliminate the new line
            if(index != 0) input_buffer[index-1] = '\0';
            else input_buffer[index] = '\0';

          for(int i = 0; i < N_COMMANDS;i++)
          {
            if(strcmp(input_buffer, commands[i]) == 0)
            {
                command_okay = 1;
                printl("Command Detected");
              switch (i)
              {
              case BUFFER_START:
                printl("Buffer start command\nOK");
                break;
              case BUFFER_END:
                printl("Buffer end command\nOK");
                break;
              default:
                break;
              }
            }
          }
          if(command_okay == 0)
          {
              print("Command Not recognized: ");
              printl(input_buffer);
              print("String lenght: ");
              char bfr [20];
              itoa(strlen(input_buffer), bfr, 10);
              printl(bfr);
          }
          index = 0;
            input_buffer[index] = '\0';
          print("\\> ");
        }

        command_okay = 0;

        if(data_c == 'p')
        {
            print_char('\n');
            print("Index: ");
            char bfr [20];
            itoa(index, bfr, 10);
            printl(bfr);
            print("Buffer: ");
            printl(input_buffer);
        }
        
        *((int*)0x01000000) = *uart_reciever_count; 
      }
      //For stability
      for(int i = 0;i < 0x1000;i++);
    }
}