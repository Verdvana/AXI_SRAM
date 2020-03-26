//=============================================================================
//
//Module Name:					axi_slave_if.sv
//Department:					Xidian University
//Function Description:	        AXI总线从设备Instruction Fetch
//
//------------------------------------------------------------------------------
//
//Version 	Design		Coding		Simulata	  Review		Rel data
//V1.0		Verdvana	Verdvana	Verdvana		  			2020-3-19
//
//------------------------------------------------------------------------------
//
//Version	Modified History
//V1.0		将sram控制器连接到AXI总线;
//          生成sram控制信号：sram地址，rd / wr操作和片选信号等。
//
//=============================================================================

`timescale 1ns/1ns

module axi_slave_if#(
    parameter   DATA_WIDTH  = 64,             //数据位宽
                ADDR_WIDTH  = 32,               //地址位宽              
                ID_WIDTH    = 1,               //ID位宽
                USER_WIDTH  = 1,             //USER位宽
                STRB_WIDTH  = (DATA_WIDTH/8)    //STRB位宽
)(
    /********* 时钟&复位 *********/
	input                       ACLK,
	input      	                ARESETn,
	/******** AXI总线信号 ********/
    //写地址通道
//	input      [ID_WIDTH-1:0]   AWID,
	input	   [ADDR_WIDTH-1:0] AWADDR,
	input	   [7:0]            AWLEN,
	input	   [2:0]            AWSIZE,
	input	   [1:0]	        AWBURST,
//	input	  	                AWLOCK,
//	input	   [3:0]	        AWCACHE,
//	input	   [2:0]	        AWPROT,
//	input	   [3:0]	        AWQOS,
//	input	   [3:0]            AWREGION,
//	input	   [USER_WIDTH-1:0]	AWUSER,
	input	 	                AWVALID,
	output    	                AWREADY,
	//写数据通道                
//	input	   [ID_WIDTH-1:0]   WID,
	input	   [DATA_WIDTH-1:0] WDATA,
	input	   [STRB_WIDTH-1:0] WSTRB,
	input		                WLAST,
//	input	   [USER_WIDTH-1:0]	WUSER,
	input	  	                WVALID,
	output    	                WREADY,
	//写响应通道                
//	output     [ID_WIDTH-1:0]   BID,
	output     [1:0]            BRESP,
//	output     [USER_WIDTH-1:0]	BUSER,
	output    	                BVALID,
	input	  	                BREADY,
	//读地址地址                
//	input	   [ID_WIDTH-1:0]   ARID,
	input	   [ADDR_WIDTH-1:0] ARADDR,
	input	   [7:0]            ARLEN,
	input	   [2:0]	        ARSIZE,
	input	   [1:0]	        ARBURST,
//	input	  	                ARLOCK,
//	input	   [3:0]	        ARCACHE,
//	input	   [2:0]            ARPROT,
//	input	   [3:0]	        ARQOS,
//	input	   [3:0]	        ARREGION,
//	input	   [USER_WIDTH-1:0]	ARUSER,
	input	  	                ARVALID,
	output    	                ARREADY,
	//读数据通道                
//	output     [ID_WIDTH-1:0]	RID,
	output     [DATA_WIDTH-1:0]	RDATA,
	output     [1:0]	        RRESP,
	output    	                RLAST,
//	output     [USER_WIDTH-1:0] RUSER,
	output                      RVALID,
	input	 	                RREADY,
    /********* SRAM信号 *********/
	//数据输入
    input      [7:0]	        sram_q0, // 8bits
    input      [7:0]	        sram_q1,
    input      [7:0]	        sram_q2,
    input      [7:0]	        sram_q3,
    input      [7:0]	        sram_q4,
    input      [7:0]	        sram_q5,
    input      [7:0]	        sram_q6,
    input      [7:0]	        sram_q7,
	//控制信号
    output    	   	            sram_wen,      // 0:write, 1:read
    output     [12:0]	        sram_addr_out,
    output     [31:0]           sram_wdata,     //写sram数据
	output     [31:0]           sram_rdata,
    output     [3:0]	        bank0_csn,      //四字节可以单独写入
    output     [3:0]	        bank1_csn
);  

    //=========================================================
    //常量定义
    parameter   TCO     =   1;  //寄存器延时

    //=========================================================
    //中间信号
	logic					wen;
	logic [2:0]  			awsize;
	logic [15:0]			awaddr;
	logic [31:0]			wdata;

	logic					ren;
	logic [2:0] 			arsize;
	logic [15:0]			araddr;

    //=========================================================
    //sram信号
	logic [15:0]			sram_addr;	//读写地址
	logic [2:0]				sram_size;	//读写数据宽度
	logic 					bank_sel;	//两组sram片选
	logic [3:0]				sram_csn;	//四片sram片选

    //=========================================================
    //写通道例化
    axi_w_channel#(
		.DATA_WIDTH(DATA_WIDTH),
		.ADDR_WIDTH(ADDR_WIDTH),
		.ID_WIDTH(ID_WIDTH),
		.USER_WIDTH(USER_WIDTH),
		.STRB_WIDTH(DATA_WIDTH/8)
	)u_axi_w_channel(.*);

    //=========================================================
    //读通道例化
	axi_r_channel#(
		.DATA_WIDTH(DATA_WIDTH),
		.ADDR_WIDTH(ADDR_WIDTH),
		.ID_WIDTH(ID_WIDTH),
		.USER_WIDTH(USER_WIDTH),
		.STRB_WIDTH(DATA_WIDTH/8)
	)u_axi_r_channel(.*);


	//=========================================================
	//sram信号生成
	assign 	sram_wen 	= wen? 0 : 1;				//读写使能：0为写，1为读；默认为1
	assign  bank_sel = sram_addr[15]? 1'b0 : 1'b1;	//根据读写地址最高位判断是哪一组

	//=========================================================
	//读写mux
	assign	sram_addr 	= sram_wen ? araddr: awaddr;//读写地址
	assign 	sram_size	= sram_wen ? arsize: awsize;//读写数据宽度

	//=========================================================
	//片选
	always_comb begin
		if(sram_size == 3'b000)begin		//8bit
			case(sram_addr[1:0])
				2'b00: 	sram_csn = 4'b1110;
        		2'b01: 	sram_csn = 4'b1101;
        		2'b10: 	sram_csn = 4'b1011;
        		2'b11: 	sram_csn = 4'b0111;
				default:sram_csn = 4'b1111;
			endcase
		end
		else if(sram_size == 3'b001)begin	//16bit
			case(sram_addr[1])
				1'b0:	sram_csn = 4'b1100;
				1'b1:	sram_csn = 4'b0011;
				default:sram_csn = 4'b1111;
			endcase
		end
		else if(sram_size == 3'b010) 		//32bit
			sram_csn = '0;
		else
			sram_csn = '1;
	end

	assign	bank0_csn	= (sram_addr[15] == 1'b0) ? sram_csn : 4'b1111;
	assign	bank1_csn	= (sram_addr[15] == 1'b1) ? sram_csn : 4'b1111;

	//=========================================================
	//读写地址、数据
	assign 	sram_addr_out = sram_addr[14:2];
	assign 	sram_wdata 	= wdata;
	assign  sram_rdata 	= (bank_sel) ?  
                          {sram_q3, sram_q2, sram_q1, sram_q0} :
                          {sram_q7, sram_q6, sram_q5, sram_q4} ;


endmodule