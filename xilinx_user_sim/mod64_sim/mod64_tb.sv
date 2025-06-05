
`define CLK_PERIOD          (10ns)

module mod64_tb();

timeunit 1ns;
timeprecision 1ps;

logic clk, nrst, en, rdy;
logic [63:0] din, m, mod_out;

mod64 DUT (.*);

always #(`CLK_PERIOD/2) clk = ~clk;


task automatic send_calc(input bit[63:0] inword, mword);
begin
    @(posedge clk) begin
        en <= '1;
        din <= inword;
        m <= mword;
    end
    wait(rdy === 1'b0);
    do @(posedge clk); while (!rdy);
    @(posedge clk) en <= '0;
end
endtask


initial begin
    {clk, nrst, en, rdy} = '0;

    repeat(10) @(posedge clk);
    @(posedge clk) nrst <= '1;

    repeat(10) @(posedge clk);

    send_calc(100, 110);

    #10ns;
    if (mod_out != 100) begin
        $display("Error: expected %0d, received %0d", 100, mod_out);
    end else begin
        $display("Success!!!");
    end

    //
    repeat(10) @(posedge clk);

    send_calc(101, 11);

    #10ns;
    if (mod_out != (101%11)) begin
        $display("Error: expected %0d, received %0d", (101%11), mod_out);
    end else begin
        $display("Success!!!");
    end


    //
    repeat(10) @(posedge clk);

    send_calc(202, 33);

    #10ns;
    if (mod_out != (202%33)) begin
        $display("Error: expected %0d, received %0d", (202%33), mod_out);
    end else begin
        $display("Success!!!");
    end


    //
    repeat(10) @(posedge clk);

    send_calc(555, 999999);

    #10ns;
    if (mod_out != (555)) begin
        $display("Error: expected %0d, received %0d", (555), mod_out);
    end else begin
        $display("Success!!!");
    end


    //
    repeat(10) @(posedge clk);
    send_calc(859770326, 826537);
    #10ns;
    if (mod_out != (859770326%826537)) begin
        $display("Error: expected %0d, received %0d", (859770326%826537), mod_out);
    end else begin
        $display("Success!!!");
    end


    //
    repeat(10) @(posedge clk);
    send_calc(7970024, 0);
    #10ns;
    if (mod_out != (7970024)) begin
        $display("Error: expected %0d, received %0d", (7970024), mod_out);
    end else begin
        $display("Success!!!");
    end



    #100ns;
    $finish();

end


endmodule