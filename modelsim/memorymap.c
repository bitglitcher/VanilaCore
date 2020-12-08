/********************************************************************
 * Part of Mike Field's emulate-risc-v project.
 *
 * (c) 2018 Mike Field <hamster@snap.net.nz>
 *
 * See https://github.com/hamsternz/emulate-risc-v for licensing
 * and additional info
 *
 ********************************************************************/
#include <malloc.h>
#include <stdint.h>
#include <memory.h>
#include "region.h"
#include "ram.h"
#include <stdlib.h>
#include <string.h>
#include <stdio.h>

struct region *first_region = NULL;

/****************************************************************************/
static int add_region(uint32_t base, uint32_t size, 
  int  (*init)(struct region *r),
  int (*get)(struct region *r, uint32_t address, uint32_t *value),
  int (*set)(struct region *r, uint32_t address, uint8_t mask, uint32_t value),
  void (*free)(struct region *r),
  void (*dump)(struct region *r)) {
  struct region *r = NULL;

  /* Allocate space */
  r = malloc(sizeof(struct region));
  if(r == NULL) {
    return 0;
  }

  /* Initialise it */
  memset(r,0,sizeof(struct region));
  r->base = base;
  r->size = size;
  r->init = init;
  r->get  = get;
  r->set  = set;
  r->free = free;
  r->dump = dump;

  /* Add to list */
  if(first_region == NULL) {
    first_region = r;
    r->next = NULL;
  } else {
    struct region *c = first_region;
    while(c->next != NULL)
      c = c->next;
    c->next = r;
    r->next = NULL;
  }
  return 1;
}

/****************************************************************************/
int memorymap_aligned_read(uint32_t address, uint32_t *value) {
   struct region *r = first_region;

   /* Find the region */
   while(r != NULL) {
     if(address >= r->base && address < r->base+r->size)
       break;
     r = r->next;
   }

   /* If no region found then exit */
   if(r == NULL) {
     char buffer[128];
     sprintf(buffer, "Read of invalid address %08X",address);
     //display_log(buffer);
     return 0;
   }

   /* Trap a currently unhandled error */
   if(address+4 > r->base + r->size) {
     //display_log("Need to split the read of address as it crosses boundary");
     return 0;
   }
   return r->get(r, address-r->base, value);
}

/****************************************************************************/
int memorymap_aligned_write(uint32_t address, uint8_t mask, uint32_t value) {
   struct region *r = first_region;

   /* Find the region */
   while(r != NULL) {
     if(address >= r->base && address < r->base+r->size)
       break;
     r = r->next;
   }

   /* If no region found then exit */
   if(r == NULL) {
     char buffer[128];
     sprintf(buffer, "Write of invalid address %08X\n",address);
     printf(buffer);
     return 0;
   }

   /* Trap a currently unhandled error */
   if(address+4 > r->base + r->size) {
     printf("Write to split the read of address as it crosses boundary\n");
     return 0;
   }
   return r->set(r, address-r->base, mask, value);
}

/****************************************************************************/
int memorymap_initialise(char *image) {
  struct region *r;

  if(!add_region(0x00000000, 0xfffff, RAM_init, RAM_get, RAM_set, RAM_free, RAM_dump)) {
    printf("Unable to add regions\n");
    return 0;
  }

  r = first_region;
  while(r != NULL) {
    if(!r->init(r)) {
       fprintf(stderr,"Unable to initialize region 0x%08x\n", r->base);
       return 0;
    }
    r = r->next;
  } 
  printf("Memory map initialized\n");
  return 1;
}

/****************************************************************************/
int memorymap_read(uint32_t address, uint8_t width, uint32_t *value) {
   uint32_t v, v1, mask;

   /* Mask out data we don't want */
   switch(width) {
     case 1:
       mask = 0xFF;
       break; 
     case 2:
       mask = 0xFFFF;
       break; 
     case 4:
       mask = 0xFFFFFFFF;
       break; 
     default:
       printf("Invalid read width at address 0x%08x\n");
       return 0;
   }

   /* Read the memory region */
   switch(address & 3) {
     case 0:
       if(!memorymap_aligned_read(address+0, &v))  return 0;
       break;
     case 1:
       if(!memorymap_aligned_read(address-1, &v))  return 0;
       if(!memorymap_aligned_read(address+3, &v1)) return 0;
       v = (v>>8) | (v1 <<24);
       break;
     case 2:
       if(!memorymap_aligned_read(address-2, &v))  return 0;
       if(!memorymap_aligned_read(address+2, &v1)) return 0;
       v = (v>>16) | (v1 <<16);
       break;
     default:
       if(!memorymap_aligned_read(address-3, &v))  return 0;
       if(!memorymap_aligned_read(address+1, &v1)) return 0;
       v = (v>>24) | (v1 <<8);
       break;
   }
   /* Set the return value */
   *value = v & mask;
   return 1;
}

/****************************************************************************/
int memorymap_write(uint32_t address, uint32_t width, uint32_t value) {
   /* Read the memory region */
   switch(address & 3) {
     case 0:
       switch(width) {
	 case 0xFFFFFFFF:
	 case 0xF:
	 case 4:
           if(!memorymap_aligned_write(address+0, 0xF, value))  return 0;
	   return 1;
	 case 0xFFFF:
	 case 0x3:
	 case 2:
           if(!memorymap_aligned_write(address+0, 0x3, value))  return 0;
	   return 1;
	 case 0xFF:
	 case 1:
           if(!memorymap_aligned_write(address+0, 0x1, value))  return 0;
	   return 1;
       }
       break;
     case 1:
       switch(width) {
	 case 0xFFFFFFFF:
	 case 0xF:
	 case 4:
           if(!memorymap_aligned_write(address-1, 0xE, value<<8 ))  return 0;
           if(!memorymap_aligned_write(address+3, 0x1, value>>24))  return 0;
	   return 1;
	 case 0xFFFF:
	 case 3:
	 case 2:
           if(!memorymap_aligned_write(address-1, 0x6, value<<8 ))  return 0;
	   return 1;
	 case 0xFF:
	 case 1:
           if(!memorymap_aligned_write(address-1, 0x2, value<<8 ))  return 0;
	   return 1;
       }
       break;
     case 2:
       switch(width) {
	 case 0xFFFFFFFF:
	 case 0xF:
	 case 4:
           if(!memorymap_aligned_write(address-2, 0xC, value<<16))  return 0;
           if(!memorymap_aligned_write(address+2, 0x3, value>>16))  return 0;
	   return 1;
	 case 0xFFFF:
	 case 3:
	 case 2:
           if(!memorymap_aligned_write(address-2, 0xC, value<<16))  return 0;
	   return 1;
	 case 0xFF:
	 case 1:
           if(!memorymap_aligned_write(address-2, 0x4, value<<16))  return 0;
	   return 1;
       }
       break;
     default:
       switch(width) {
	 case 0xFFFFFFFF:
	 case 0xF:
	 case 4:
           if(!memorymap_aligned_write(address-3, 0x8, value<<24))  return 0;
           if(!memorymap_aligned_write(address+1, 0x7, value>>8 ))  return 0;
	   return 1;
	 case 0xFFFF:
	 case 3:
	 case 2:
           if(!memorymap_aligned_write(address-3, 0x8, value<<24))  return 0;
           if(!memorymap_aligned_write(address+1, 0x1, value>>8 ))  return 0;
	   return 1;
	 case 0xFF:
	 case 1:
           if(!memorymap_aligned_write(address-3, 0x8, value<<24))  return 0;
	   return 1;
       }
       break;
   }
   printf("Invalid write at address 0x%08x width %i value 0x%08x\n");
   return 0;
}

/****************************************************************************/
void memorymap_dump(void) {
   struct region *r = first_region;
#if 0
   printf("\n");
   printf("=========================================================================================================\n");
   printf("Memory dump\n");
   printf("-----------\n");
#endif
   while(r != NULL) {
      r->dump(r);
#if 0
      if(r->next != NULL)
	printf("\n");
#endif
      r = r->next;
   }
#if 0
   printf("\n");
   printf("=========================================================================================================\n");
#endif
}
/****************************************************************************/
void memorymap_finish(void) {
   while(first_region != NULL) {
      struct region *r = first_region;
      first_region = first_region->next;
      r->free(r);
      free(r);
   }
}
/****************************************************************************/
