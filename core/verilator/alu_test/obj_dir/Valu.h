// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Primary design header
//
// This header should be included by all source files instantiating the design.
// The class here is then constructed to instantiate the design.
// See the Verilator manual for examples.

#ifndef _Valu_H_
#define _Valu_H_

#include "verilated.h"

class Valu__Syms;

//----------

VL_MODULE(Valu) {
  public:
    
    // PORTS
    // The application code writes and reads these signals to
    // propagate new values into/out from the Verilated model.
    // Begin mtask footprint  all: 
    VL_IN8(func3,2,0);
    VL_IN8(func7,6,0);
    VL_IN(ra_d,31,0);
    VL_IN(rb_d,31,0);
    VL_OUT(rd_d,31,0);
    
    // LOCAL SIGNALS
    // Internals; generally not touched by application code
    
    // LOCAL VARIABLES
    // Internals; generally not touched by application code
    
    // INTERNAL VARIABLES
    // Internals; generally not touched by application code
    Valu__Syms* __VlSymsp;  // Symbol table
    
    // PARAMETERS
    // Parameters marked /*verilator public*/ for use by application code
    
    // CONSTRUCTORS
  private:
    VL_UNCOPYABLE(Valu);  ///< Copying not allowed
  public:
    /// Construct the model; called by application code
    /// The special name  may be used to make a wrapper with a
    /// single model invisible with respect to DPI scope names.
    Valu(const char* name="TOP");
    /// Destroy the model; called (often implicitly) by application code
    ~Valu();
    
    // API METHODS
    /// Evaluate the model.  Application must call when inputs change.
    void eval();
    /// Simulation complete, run final blocks.  Application must call on completion.
    void final();
    
    // INTERNAL METHODS
  private:
    static void _eval_initial_loop(Valu__Syms* __restrict vlSymsp);
  public:
    void __Vconfigure(Valu__Syms* symsp, bool first);
  private:
    static QData _change_request(Valu__Syms* __restrict vlSymsp);
  public:
    static void _combo__TOP__1(Valu__Syms* __restrict vlSymsp);
  private:
    void _ctor_var_reset();
  public:
    static void _eval(Valu__Syms* __restrict vlSymsp);
  private:
#ifdef VL_DEBUG
    void _eval_debug_assertions();
#endif // VL_DEBUG
  public:
    static void _eval_initial(Valu__Syms* __restrict vlSymsp);
    static void _eval_settle(Valu__Syms* __restrict vlSymsp);
} VL_ATTR_ALIGNED(128);

#endif // guard
