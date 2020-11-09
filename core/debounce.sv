

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


logic [21:0] new_slow_clock;

always@(posedge clk)
begin
    new_slow_clock = new_slow_clock + 1;
end

reg dff_1;
reg dff_2;

always@(posedge new_slow_clock [21:21])
begin
    dff_1 = debounce;
    dff_2 = dff_1;
end

assign debounced = dff_2;


endmodule