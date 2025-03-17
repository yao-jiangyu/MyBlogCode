module mod_2_n(
    input clk,
    input rst_n,
    output MyFlag
);

reg [5:0] data_cnt;
reg [5:0] rd_addr;
reg [5:0] wr_addr;

always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        data_cnt <= 6'd0;
    end else begin
        data_cnt <= data_cnt + 1;
    end
end

always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        rd_addr <=  6'd0;
        wr_addr <=  6'd0;
    end else begin
        rd_addr = (48 + data_cnt) % 64;
        wr_addr = (48 + data_cnt) & 6'h3F; // 与63(111111)进行位与操作
    end
end

assign MyFlag = wr_addr == rd_addr;

endmodule