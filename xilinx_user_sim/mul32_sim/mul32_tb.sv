
`define CLK_PERIOD      (10ns)

module mul32_tb();


//Variables
logic clk, nrst, en, ready;
logic [31:0] a, b;
logic [63:0] result;

//DUT
mul32 DUT (.*);


//Clock
always #(`CLK_PERIOD/2) clk = ~clk;


//Tests
task automatic run_mul(input bit [31:0] mul_a, mul_b);
begin
    @(posedge clk) begin
       a <= mul_a;
       b <= mul_b;
       en <= '1;
    end

    do @(posedge clk); while (!ready);
    @(posedge clk) en <= '0;

    do @(posedge clk); while (ready);

end
endtask //automatic


initial begin
    bit [31:0] a_q [$];
    bit [31:0] b_q [$];
    bit [31:0] a_tmp, b_tmp;
    bit [63:0] result_tmp;
    int err_cnt = 0;

    {clk, nrst, en, a, b} = '0;

    repeat(10) @(posedge clk);
    nrst = '1;
    repeat(10) @(posedge clk);


    //Generate random values
    repeat(20) begin
        a_q.push_back($urandom());
        b_q.push_back($urandom());
    end
    
    while (a_q.size()) begin
        a_tmp = a_q.pop_front();
        b_tmp = b_q.pop_front();
        result_tmp = a_tmp * b_tmp;
        //
        run_mul(a_tmp, b_tmp);
        if (result != result_tmp) begin
            $error("Expected value %0d, but received %0d", result_tmp, result);
            $display("Input values: a = %0d, b = %0d", a_tmp, b_tmp);
            err_cnt++;
        end
    end

    $display("Received %0d error(s)", err_cnt);
    if (err_cnt)
        $error("Test failed!");
    else
        $display("Text success!");
    
    $finish();
end

endmodule