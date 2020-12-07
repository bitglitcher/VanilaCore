

module fifo_tb();


logic clk;
logic rst;
logic empty;
logic full;
logic [$clog2(32)-1:0] count;
logic rd;
logic wr;
logic [31:0] dout;
logic [31:0] din;

fifo #(32, 32) fifo_0 
(
    //Syscon
    .clk(clk),
    .rst(rst),

    //Status
    .empty(empty),
    .full(full),
    .count(count),

    //Read
    .rd(rd),
    .dout(dout),

    //Write
    .wr(wr),
    .din(din)
);

task automatic push(int data);
    if(full)
    begin
        $display("Cant push fifo full");
    end
    else
    begin
        $display("Pushing ",data );
        wr = 1'b1;
        din = data;
        @(posedge clk);
        begin
            $display("Pushed ",data );
                wr = 0;
        end
    end
endtask //automatic

task automatic push_full(int size);
    $display("------------FILLING BUFFER------------");
    $display("DEEPTH %d", size);

    for (int i = 0; i < size -1; i++) begin
        push(i);  
        if(size == (i+1) & (count == size-1)) assert (full == 1) 
        else   $display("Error: Exepexcting full signal to be true");
    end

    $display("------------FILLING BUFFER TASK COMPLETED------------");
endtask

//On pop assert that the parameter num is equal to the returned data 
task automatic pop_assert(int num);
    if(empty)
    begin
        $display("Cant pop fifo empty");
    end
    else
    begin
        $display("Expecting %d", num);
        rd = 1;
        @(posedge clk);
        begin
            rd = 0;    
            $display("Poped %d", dout);
            assert (dout == num) 
            else   $display("Error Incorrect Data Poped", dout);
        end
    end
endtask //automatic

task automatic pop_empty_assert_inc(int size);
    @(posedge clk) assert (full == 1) 
    else  $display("Error: Expecting full buffer", $time);
    $display("------------EMPTYING BUFFER------------");
    $display("DEEPTH %d", size);

    for (int i = 0; i < size -1; i++) begin
        pop_assert(i);  
        if(size == (i+1) & (count == 0)) assert (empty == 1) 
        else $display("Error: Exepexcting empty signal to be true");
    end

    $display("------------EMPTYING BUFFER TASK COMPLETED------------");
endtask


initial begin
    clk = 0;
    rst = 0;
    empty = 0;
    full = 0;
    count = 0;
    rd = 0;
    wr = 0;
    dout = 0;
    din = 0;

    //Reset Signal
    #10
    rst = 1;
    #30
    rst = 0;

    push_full(32);
    pop_empty_assert_inc(32);
    push_full(32);
    pop_empty_assert_inc(32);
    push_full(32);
    //pop_empty_assert_inc(32);
    //push(30);
    //push(230);
    //push(210);
    //push(213);
    //push(113);
    //push(143);
    //pop_assert(30);
    //pop_assert(230);
    //pop_assert(210);
    //pop_assert(213);
    //pop_assert(113);
    //pop_assert(143);

    $stop;
end

always #10 clk = ~clk;



endmodule