`timescale 1ns/1ps
module tb_sync_fifo_cnt();

// Parameters
parameter DATA_WIDTH = 8;
parameter DATA_DEPTH = 16;

// Signals
reg clk;
reg rst_n;
reg [DATA_WIDTH-1:0] data_in;
reg wr_en;
reg rd_en;
wire [DATA_WIDTH-1:0] data_out;
wire empty;
wire full;
wire [$clog2(DATA_DEPTH):0] fifo_cnt;

// Instantiate DUT
sync_fifo_cnt #(
    .DATA_WIDTH(DATA_WIDTH),
    .DATA_DEPTH(DATA_DEPTH)
) u_sync_fifo_cnt (
    .clk(clk),
    .rst_n(rst_n),
    .data_in(data_in),
    .rd_en(rd_en),
    .wr_en(wr_en),
    .data_out(data_out),
    .empty(empty),
    .full(full),
    .fifo_cnt(fifo_cnt)
);

// Clock generation
always #5 clk = ~clk;

// Test stimulus
initial begin
    // Initialize signals
    clk = 0;
    rst_n = 0;
    data_in = 0;
    wr_en = 0;
    rd_en = 0;
    
    // Reset sequence
    #20 rst_n = 1;
    
    // Test Case 1: Basic write and read
    $display("=== Test Case 1: Single Write/Read ===");
    write_data(8'hAA);
    read_data();
    #20;
    
    // Test Case 2: Fill FIFO completely
    $display("\n=== Test Case 2: Fill FIFO ===");
    fill_fifo();
    #20;
    
    // Test Case 3: Read FIFO completely
    $display("\n=== Test Case 3: Empty FIFO ===");
    empty_fifo();
    #20;
    
    // Test Case 4: Simultaneous read/write
    $display("\n=== Test Case 4: Simultaneous R/W ===");
    sim_rw_ops();
    #20;
    
    // Test Case 5: Overflow/Underflow test
    $display("\n=== Test Case 5: Overflow/Underflow ===");
    overflow_test();
    underflow_test();
    #20;
    
    $display("\nAll tests completed!");
    $finish;
end

// Test tasks
task write_data;
    input [DATA_WIDTH-1:0] data;
    begin
        @(negedge clk);
        wr_en = 1;
        data_in = data;
        $display("[%t] WRITE: Data=0x%h", $time, data);
        @(negedge clk);
        wr_en = 0;
    end
endtask

task read_data;
    begin
        @(negedge clk);
        rd_en = 1;
        #1; // Allow output to update
        $display("[%t] READ: Data=0x%h", $time, data_out);
        @(negedge clk);
        rd_en = 0;
    end
endtask

task fill_fifo;
    integer i;
    begin
        for(i=0; i<DATA_DEPTH; i=i+1) begin
            write_data(i);
            if(full && i==DATA_DEPTH-1) 
                $display("FIFO Full reached at count=%0d", i+1);
        end
        // Attempt overflow write
        write_data(8'hFF);
        if(full) $display("Overflow prevented");
    end
endtask

task empty_fifo;
    integer i;
    begin
        for(i=0; i<DATA_DEPTH; i=i+1) begin
            read_data();
            if(empty && i==DATA_DEPTH-1) 
                $display("FIFO Empty reached at count=%0d", i+1);
        end
        // Attempt underflow read
        read_data();
        if(empty) $display("Underflow prevented");
    end
endtask

task sim_rw_ops;
    integer i;
    begin
        // Fill half FIFO
        for(i=0; i<DATA_DEPTH/2; i=i+1)
            write_data(i+10);
            
        // Perform 10 simultaneous operations
        repeat(10) begin
            @(negedge clk);
            wr_en = 1;
            rd_en = 1;
            data_in = $random;
            #1;
            $display("[%t] SIM-RW: Wrote=0x%h Read=0x%h Count=%0d", 
                    $time, data_in, data_out, fifo_cnt);
            @(negedge clk);
            wr_en = 0;
            rd_en = 0;
        end
    end
endtask

task overflow_test;
    begin
        fill_fifo();
        write_data(8'hFF);
        if(fifo_cnt == DATA_DEPTH) 
            $display("Overflow test passed");
    end
endtask

task underflow_test;
    begin
        empty_fifo();
        read_data();
        if(fifo_cnt == 0) 
            $display("Underflow test passed");
    end
endtask

// Monitor
always @(posedge clk) begin
    $display("[%t] STATUS: Count=%0d Empty=%b Full=%b",
            $time, fifo_cnt, empty, full);
end

endmodule