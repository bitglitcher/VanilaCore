//Benjamin Herrera Navarro.
//11:15PM
//12/17/2020



module spi_controller(WB4.slave wb);




//Memory Map
//0x00 DATA  
//0x01 Count
//0x02 Config

//Config Register Bits
// Bit N   ON State         OFF STATE       Description
// Bit 0   1 - LSB First    0 - MSB First    
// Bit 1   1 - 8Bit Data    0 - 16Bit Data
// Bit 2   x                x               CPOL
// Bit 3   x                x               CPHA

typedef enum logic [3:0] { IDDLE, SEND_DATA } states_t;

states_t SPI_MASTE_STATES;

always@(posedge clk)
begin
    unique case(SPI_MASTE_STATES)
        IDDLE:
        begin
            
        end
        SEND_DATA:
        begin
            
        end
    endcase
end


endmodule