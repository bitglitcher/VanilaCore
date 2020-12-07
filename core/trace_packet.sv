


class trace_packet;
    mailbox mbx;

    bit [6:0] opcode;
    bit [4:0] rd;
    bit [4:0] rs1;
    bit [4:0] rs2;


    function new(mailbox mbx);
        this.mbx = mbx;
    endfunction //new()

     
endclass //trace_packet