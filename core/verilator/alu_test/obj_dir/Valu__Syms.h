// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Symbol table internal header
//
// Internal details; most calling programs do not need this header

#ifndef _Valu__Syms_H_
#define _Valu__Syms_H_

#include "verilated.h"

// INCLUDE MODULE CLASSES
#include "Valu.h"

// SYMS CLASS
class Valu__Syms : public VerilatedSyms {
  public:
    
    // LOCAL STATE
    const char* __Vm_namep;
    bool __Vm_didInit;
    
    // SUBCELL STATE
    Valu*                          TOPp;
    
    // CREATORS
    Valu__Syms(Valu* topp, const char* namep);
    ~Valu__Syms() {}
    
    // METHODS
    inline const char* name() { return __Vm_namep; }
    
} VL_ATTR_ALIGNED(64);

#endif // guard
