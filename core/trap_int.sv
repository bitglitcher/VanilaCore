
//This interface is links together the control unit and the csr unit.
interface TRAP_INT;
    logic [31:0] ip; //Interrupt Pending signal, each wire is enabled if the interrupt is enabled 
    logic [31:0] cause; //Cause, this signal comes from the control unit
    logic trap_return; //This signal restores the instruction state that was interrupted
    logic exeption; //This signal tell the CSR_Unit to save the current instruction state 
    logic interrupt; //This signal tell the CSR_unit that there is an incoming interrupt
    logic illegal_address; //Illegal address signal, telling the control unit that the CSR is not implemented
    logic [1:0] cpm; //Current Privilege mode
    modport cu ( //Control Unit Modport
        input ip,
        output cause,
        output trap_return,
        output exeption, 
        output interrupt,
        input illegal_address,
        input cpm
    );
    modport csru ( //CSR unit modport
        output ip,
        output cause,
        input trap_return,
        input exeption, 
        input interrupt,
        output cpm
    );
endinterface //TRAP_INT