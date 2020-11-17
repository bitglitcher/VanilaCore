
int main()
{
    while(1)
    {
        int* vga = 0x20000;
        for(int y = 0;y <= 640*480;y++)
        {
            *(vga + y) = 0xffff;
        }
    }
    
    return 0xffff;
}
