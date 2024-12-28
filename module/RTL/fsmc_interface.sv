// `define DEBUG

// module fsmc_interface(
//     // 接口端口定义
//     inout [17:0] AD,          // 地址数据复用线
//     input NADV,               // 地址有效信号
//     input NWE,                // 写有效信号
//     input NOE,                // 读有效信号
//     input reset,              // 复位信号
//     input clk,                // 时钟信号
//     input  reg[15:0] module_out,
//     output reg[15:0] module_in,
//     output reg[3:0] cs
//     // // 为了调试
// `ifdef DEBUG
//     ,output [3:0] debug_state
// `endif
// );

//     // 地址数据复用线的方向控制
//     logic ad_dir;
//     reg [17:0] ad_out;
//     wire [17:0] ad_in;
//     logic [2:0]addr_cs;

//     // 将AD设置为三态输出
//     assign ad_in = AD;
//     assign AD = ad_dir ? ad_out : 18'bz;

//     // 状态机状态定义
//     // 每个状态与相邻状态之间只有一位不同，从而减少竞争条件和潜在的逻辑毛刺。
//     typedef enum logic [3:0] { // 使用3位足以表示7个状态，避免资源浪费
//         IDLE,                  // 初始状态：空闲状态，等待开始新操作
//         ADDR_DECODE_PRE, 
//         ADDR_DECODE,           // 状态转换：从IDLE进入地址解码状态
//         WR_JUDGE,
//         MCU_READ_MODULE_WRITE_PRE,// 状态转换：从ADDR_DECODE进入MCU读取模块写入预处理状态
//         MCU_READ_MODULE_WRITE, // 状态转换：从ADDR_DECODE进入MCU读取模块写入状态
//         MCU_WRITE_MODULE_READ_PRE,
//         MCU_WRITE_MODULE_READ , // 状态转换：从ADDR_DECODE进入MCU写入模块读取状态
//         DELAY // 状态转换：完成MCU读取模块写入操作
        
//     } state_t;
//     // 状态机当前状态和下一个状态
//     state_t state, next_state;


//     logic delay_done;
//     // reg [7:0]delay_cnt;


//     // 控制逻辑
//     always_ff @(posedge clk or negedge reset) begin
//         if (!reset)
//             state <= IDLE;
//         else
//             state <= next_state;
//     end

//     // 状态转换
//     always_comb begin
//         case(state)
//             IDLE:begin
//                 if(NADV)begin
//                     next_state = IDLE;
//                 end else begin
//                     next_state = ADDR_DECODE_PRE;
//                 end
//             end
//             ADDR_DECODE_PRE: begin
//                 if(NADV) begin
//                     // 进入解码
//                     next_state = ADDR_DECODE;
//                 end else begin
//                     next_state = ADDR_DECODE_PRE;
//                 end
//             end
//             ADDR_DECODE: begin
//                 // 此时一定是NADV上升沿
//                 case(addr_cs)
//                     3'b000,3'b001,3'b010: begin
//                         next_state = WR_JUDGE;
//                     end
//                     default: begin
//                         next_state = IDLE;
//                     end
//                 endcase
//             end
//             WR_JUDGE: begin
//                 if(NWE)begin
//                     next_state = MCU_READ_MODULE_WRITE_PRE;
//                 end else begin
//                     next_state = MCU_WRITE_MODULE_READ_PRE;
//                 end
//             end
//             MCU_READ_MODULE_WRITE_PRE: begin
//                 if(NOE)begin
//                     next_state = MCU_READ_MODULE_WRITE_PRE;
//                 end else begin
//                     // 等待低电平
//                     next_state = MCU_READ_MODULE_WRITE;
//                 end    
//             end
//             MCU_READ_MODULE_WRITE: begin
//                 if(NOE)begin
//                     next_state = DELAY;
//                 end else begin
//                     next_state = MCU_READ_MODULE_WRITE;
//                 end
//             end
//             MCU_WRITE_MODULE_READ_PRE: begin
//                 if(NWE)begin
//                     // 上升沿处读取数据
//                     next_state = MCU_WRITE_MODULE_READ;
//                 end else begin
//                     next_state = MCU_WRITE_MODULE_READ_PRE;
//                 end
//             end
//             MCU_WRITE_MODULE_READ: begin
//                 next_state = IDLE;
//             end
//             DELAY: begin
//                 if(delay_done)begin
//                     next_state = IDLE;
//                 end else begin
//                     next_state = DELAY;
//                 end
//             end
//             endcase
//     end


//     // 地址译码
//     always_ff @( posedge clk or negedge reset ) begin
//         if(!reset) begin
//             ad_dir <= 1'b0;
//             cs <= 4'b000;
//             addr_cs <= 3'b000;
//             // delay_cnt <= 8'd0;
//             delay_done <= 1'b0;
//         end
//         else begin
//             case(state)
//                 IDLE:begin
//                     // 【调试】
//                     ad_dir <= 1'b0;
//                     cs <= 4'b000;
//                     // delay_cnt <= 8'd0;
//                     delay_done <= 1'b0;
//                 end
//                 ADDR_DECODE_PRE:begin
//                     if(NADV)begin
//                         // 上升沿采样
//                         module_in <= ad_in[15:0];
//                         addr_cs <= ad_in[17:15];
//                     end
//                 end
//                 ADDR_DECODE: begin
//                     case(addr_cs)
//                         3'b000: begin
//                             cs <= 4'b0001;
//                         end
//                         3'b001: begin
//                             cs <= 4'b0010;
//                         end
//                         3'b010:begin
//                             cs <= 4'b0100;
//                         end
//                         default: begin
//                             cs <= 4'b0000;
//                         end
//                     endcase
//                 end
//                 MCU_READ_MODULE_WRITE_PRE:begin
//                     if(!NOE)begin
//                         ad_dir <= 1'b1;
//                         ad_out <= module_out;
//                     end
//                 end
//                 MCU_READ_MODULE_WRITE: begin
//                     ad_dir <= 1'b1;
//                     ad_out <= module_out;
//                 end
//                 MCU_WRITE_MODULE_READ_PRE: begin
//                     if(NWE)begin
//                         module_in <= ad_in[15:0];
//                     end
//                 end
//                 DELAY: begin
//                     // 什么都不做
//                     delay_done <= 1;
//                     // if(delay_cnt >= 8'd0)begin
//                     //     delay_done <= 1;
//                     // end else begin
//                     //     delay_cnt <= delay_cnt + 1;
//                     // end
//                 end
//                 default: begin
//                     // 什么都不做
//                     // delay_cnt <= 8'd0;
//                     delay_done <= 1'b0;
//                 end
//             endcase
//         end
//     end
        
//    // 12.25
//    // 现在的问题是，读写时序我已经基本能掌握了，主要是ADC的读取，我使用仿真和实际示波器测量的并不一致。那必然是代码错了

//     // assign module_in = ad_buffer[15:0];
// `ifdef DEBUG
//     assign debug_state = state;

// `endif
// endmodule


// 说明：
// 1，为了让其他模块可以在cs上升沿时读取地址，我把解码过程延迟了一个周期
// 2,为了让其他模块可以在cs下降沿时读取数据，我把写过程延迟了一个周期
// `define DEBUG

module fsmc_interface(
    // 接口端口定义
    inout [17:0] AD,          // 地址数据复用线
    input NADV,               // 地址有效信号
    input NWE,                // 写有效信号
    input NOE,                // 读有效信号
    input reset,              // 复位信号
    input clk,                // 时钟信号
    input  reg[15:0] module_out,
    output reg[15:0] module_in,
    output reg[3:0] cs
    // // 为了调试
`ifdef DEBUG
    ,output [3:0] debug_state
`endif
);

    // 地址数据复用线的方向控制
    logic ad_dir;
    reg [17:0] ad_out;
    wire [17:0] ad_in;
    logic [2:0]addr_cs;

    // 将AD设置为三态输出
    assign ad_in = AD;
    assign AD = ad_dir ? ad_out : 18'bz;



    // 同步化异步输入信号
    logic nadv_sync,nadv_sync_d1;
    logic nwe_sync,nwe_sync_d1;
    logic noe_sync,noe_sync_d1;




    // 时钟沿检测与同步化
    always_ff @(posedge clk or negedge reset) begin
        if (!reset)begin
            nadv_sync<=0;
            nwe_sync<=0;
            noe_sync<=0;
            nadv_sync_d1<=0;
            nwe_sync_d1<=0;
            noe_sync_d1<=0;
        end else begin
            // 同步化
            nadv_sync <= NADV;
            nwe_sync <= NWE;
            noe_sync <= NOE;
            // 下一级延迟
            nadv_sync_d1 <= nadv_sync;
            nwe_sync_d1 <= nwe_sync;
            noe_sync_d1 <= noe_sync;
        end
    end



    // 地址和数据捕获
    logic ready_to_decode;
    logic ready_to_write_data;
    logic [2:0]cs_latch;
	always_ff @(posedge clk or negedge reset) begin
		if (!reset) begin
			module_in <= 16'hFFFF;
			cs_latch <= 0;
            // ready_to_decode <= 0;
            // ready_to_write_data <= 0;
		end else begin
			// 上升沿处捕获地址或数据
			if (~nadv_sync_d1 & nadv_sync) begin
				module_in <= ad_in[15:0]; // 地址捕获
                cs_latch <= ad_in[17:15];
                ready_to_decode <= 1;
			end else if (~nwe_sync_d1 & nwe_sync) begin
				module_in <= ad_in[15:0]; // 数据捕获
                ready_to_write_data <= 1;
            end else begin
                ready_to_decode <= 0;
                ready_to_write_data <= 0;
            end
		end
	end




    // 写入控制
	logic write_enable;
    logic decode_success;// 解码成功

    // 片选信号更新
	always_ff @(posedge clk or negedge reset) begin
		if (!reset) begin
			cs <= 4'b0000;
			write_enable <= 0;
			ad_dir <= 0;
			ad_out <= 0;
            decode_success <= 0;
		end else begin
			// 根据地址捕获结果更新cs
			if (ready_to_decode) begin
				case(cs_latch)
					3'b000:begin
                        cs <= 4'b0001;decode_success <= 1;
                    end
					3'b001:begin
                        cs <= 4'b0010;decode_success <= 1;
                    end
					3'b010:begin
                        cs <= 4'b0100;decode_success <= 1;
                    end
					3'b011:begin
                        cs <= 4'b1000;decode_success <= 1;
                    end
					default:begin
                        cs <= 4'b0000;decode_success <= 0;
                    end
				endcase
			end

			// noe的下降沿触发写入
			if (noe_sync_d1 & ~noe_sync & decode_success) begin
				write_enable <= 1;
			end else if (noe_sync) begin
				write_enable <= 0;
			end

            // nwe的上升沿重置片选后的一个周期或noe上升沿触发重置
            if(ready_to_write_data | ~noe_sync_d1 & noe_sync)begin
                cs <= 4'b0000;
            end

			// 低电平持续写入
			if (write_enable) begin
				ad_dir <= 1;
				ad_out[15:0] <= module_out;
                decode_success <= 0;    // 清除decode_success
			end else begin
				ad_dir <= 0;
			end  
		end
	end







`ifdef DEBUG
    assign debug_state = write_enable;
    
`endif

endmodule