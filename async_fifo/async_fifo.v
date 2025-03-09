//异步FIFO
module	async_fifo
#(
	parameter   DATA_WIDTH = 'd8  ,								//FIFO位宽
    parameter   DATA_DEPTH = 'd16 								//FIFO深度
)		
(		
//写数据		
	input							wr_clk		,				//写时钟
	input							wr_rst_n	,       		//低电平有效的写复位信号
	input							wr_en		,       		//写使能信号，高电平有效	
	input	[DATA_WIDTH-1:0]		data_in		,       		//写入的数据
//读数据			
	input							rd_clk		,				//读时钟
	input							rd_rst_n	,       		//低电平有效的读复位信号
	input							rd_en		,				//读使能信号，高电平有效						                                        
	output	reg	[DATA_WIDTH-1:0]	data_out	,				//输出的数据
//状态标志					
	output							empty		,				//空标志，高电平表示当前FIFO已被写满
	output							full		    			//满标志，高电平表示当前FIFO已被读空
);                                                              
 
//reg define
//用二维数组实现RAM
reg [DATA_WIDTH - 1 : 0]			fifo_buffer[DATA_DEPTH - 1 : 0];
	
reg [$clog2(DATA_DEPTH) : 0]		wr_ptr;						//写地址指针，二进制
reg [$clog2(DATA_DEPTH) : 0]		rd_ptr;						//读地址指针，二进制
reg	[$clog2(DATA_DEPTH) : 0]		rd_ptr_g_d1;				//读指针格雷码在写时钟域下同步1拍
reg	[$clog2(DATA_DEPTH) : 0]		rd_ptr_g_d2;				//读指针格雷码在写时钟域下同步2拍
reg	[$clog2(DATA_DEPTH) : 0]		wr_ptr_g_d1;				//写指针格雷码在读时钟域下同步1拍
reg	[$clog2(DATA_DEPTH) : 0]		wr_ptr_g_d2;				//写指针格雷码在读时钟域下同步2拍
	
//wire define
wire [$clog2(DATA_DEPTH) : 0]		wr_ptr_g;					//写地址指针，格雷码
wire [$clog2(DATA_DEPTH) : 0]		rd_ptr_g;					//读地址指针，格雷码
wire [$clog2(DATA_DEPTH) - 1 : 0]	wr_ptr_true;				//真实写地址指针，作为写ram的地址
wire [$clog2(DATA_DEPTH) - 1 : 0]	rd_ptr_true;				//真实读地址指针，作为读ram的地址
 
//地址指针从二进制转换成格雷码
assign 	wr_ptr_g = wr_ptr ^ (wr_ptr >> 1);					
assign 	rd_ptr_g = rd_ptr ^ (rd_ptr >> 1);
//读写RAM地址赋值
assign	wr_ptr_true = wr_ptr [$clog2(DATA_DEPTH) - 1 : 0];		//写RAM地址等于写指针的低DATA_DEPTH位(去除最高位)
assign	rd_ptr_true = rd_ptr [$clog2(DATA_DEPTH) - 1 : 0];		//读RAM地址等于读指针的低DATA_DEPTH位(去除最高位)
 
 
//写操作,更新写地址
always @ (posedge wr_clk or negedge wr_rst_n) begin
	if (!wr_rst_n)
		wr_ptr <= 0;
	else if (!full && wr_en)begin								//写使能有效且非满
		wr_ptr <= wr_ptr + 1'd1;
		fifo_buffer[wr_ptr_true] <= data_in;
	end	
end
//将读指针的格雷码同步到写时钟域，来判断是否写满
always @ (posedge wr_clk or negedge wr_rst_n) begin
	if (!wr_rst_n)begin
		rd_ptr_g_d1 <= 0;										//寄存1拍
		rd_ptr_g_d2 <= 0;										//寄存2拍
	end				
	else begin												
		rd_ptr_g_d1 <= rd_ptr_g;								//寄存1拍
		rd_ptr_g_d2 <= rd_ptr_g_d1;								//寄存2拍
	end	
end
//读操作,更新读地址
always @ (posedge rd_clk or negedge rd_rst_n) begin
	if (!rd_rst_n)
		rd_ptr <= 'd0;
	else if (rd_en && !empty)begin								//读使能有效且非空
		data_out <= fifo_buffer[rd_ptr_true];
		rd_ptr <= rd_ptr + 1'd1;
	end
end
//将写指针的格雷码同步到读时钟域，来判断是否读空
always @ (posedge rd_clk or negedge rd_rst_n) begin
	if (!rd_rst_n)begin
		wr_ptr_g_d1 <= 0;										//寄存1拍
		wr_ptr_g_d2 <= 0;										//寄存2拍
	end				
	else begin												
		wr_ptr_g_d1 <= wr_ptr_g;								//寄存1拍
		wr_ptr_g_d2 <= wr_ptr_g_d1;								//寄存2拍		
	end	
end
//更新指示信号
//当所有位相等时，读指针追到到了写指针，FIFO被读空
assign	empty = ( wr_ptr_g_d2 == rd_ptr_g ) ? 1'b1 : 1'b0;
//当高位相反且其他位相等时，写指针超过读指针一圈，FIFO被写满
//同步后的读指针格雷码高两位取反，再拼接上余下位
assign	full  = ( wr_ptr_g == { ~(rd_ptr_g_d2[$clog2(DATA_DEPTH) : $clog2(DATA_DEPTH) - 1])
				,rd_ptr_g_d2[$clog2(DATA_DEPTH) - 2 : 0]})? 1'b1 : 1'b0;
                
endmodule