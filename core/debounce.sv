

//Author: Benjamin Herrera Navarro
//9:05PM
//11/08/2020
//If only buttons didn't bounce fuckingbouhe ufbsad

module debounce
(
    input clk,
    input debounce,
    output debounced
);


logic [31:0] new_slow_clock;

reg dff_1;
reg dff_2;

always@(posedge clk)
begin
    new_slow_clock = new_slow_clock + 1;
    if(new_slow_clock == 32'hfffff)
    begin
        dff_1 = debounce;
        dff_2 = dff_1;
        new_slow_clock = 32'h0;
    end
end

assign debounced = dff_2;


endmodule