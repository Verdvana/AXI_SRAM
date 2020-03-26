//=============================================================================
//
//Module Name:					axi_r_channel.sv
//Department:					Xidian University
//Function Description:	        AXI总线从设备读通道
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

module axi_r_channel#(
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
	output reg	                ARREADY,
	//读数据通道                
//	output reg [ID_WIDTH-1:0]	RID,
	output reg [DATA_WIDTH-1:0]	RDATA,
	output reg [1:0]	        RRESP,
	output reg	                RLAST,
//	output reg [USER_WIDTH-1:0] RUSER,
	output reg                  RVALID,
	input	 	                RREADY,
	/********** 输入信号 **********/
    input      [31:0]	        sram_rdata,
	/********** 输出信号 **********/
	output reg					ren,
	output reg [2:0]			arsize,
	output reg [15:0]			araddr
);  

    //=========================================================
    //常量定义
    parameter   TCO     =   1;  //寄存器延时

	//=========================================================
    //中间信号
	logic	[15:0]	araddr_start;	//起始地址
	logic	[15:0]	araddr_stop;	//终止地址（不加起始地址）
	logic	[15:0]	araddr_cnt;		//地址计数器
	logic	[8:0]	araddr_step;	//地址步进长度
	logic			araddr_cnt_flag;//地址累加标志
	logic   [7:0]	arlen;			//awlen


    //======================================================================
    //握手

	//----------------------------------------------------------------------
    //ARREADY响应
	always_ff@(posedge ACLK, negedge ARESETn)begin
		if(!ARESETn)
			ARREADY	<= #TCO '0;
		else if(ARVALID&&!ARREADY)
			ARREADY <= #TCO '1;
		else
			ARREADY	<= #TCO '0;
	end

	//----------------------------------------------------------------------
    //RVALID输出
	always_ff@(posedge ACLK, negedge ARESETn)begin
		if(!ARESETn)
			RVALID	<= #TCO '0;
		else if(ARREADY)
			RVALID	<= #TCO '1;
		else if(RLAST)
			RVALID	<= #TCO '0;
		else
			RVALID	<= #TCO '0;
	end

    //======================================================================
    //参数寄存	
	always_ff@(posedge ACLK, negedge ARESETn)begin
		if(!ARESETn)begin
			araddr_start	<= #TCO '0;
			arlen			<= #TCO '0;
			arsize			<= #TCO '0;
		end
		else if(ARVALID)begin
			araddr_start	<= #TCO ARADDR[15:0];	//起始地址寄存
			arlen			<= #TCO ARLEN;			//突发长度寄存
			arsize			<= #TCO ARSIZE;			//数据宽度寄存
		end
		else begin
			araddr_start	<= #TCO araddr_start;
			arlen			<= #TCO arlen;
			arsize			<= #TCO arsize;
		end
	end


	//----------------------------------------------------------------------
    //RLAST输出
	always_ff@(posedge ACLK, negedge ARESETn)begin
		if(!ARESETn)
			RLAST	<= #TCO '0;
		else if(RREADY)
			if(araddr_cnt==araddr_stop)
				RLAST	<= #TCO '1;
			else
				RLAST	<= #TCO '0;
		else
			RLAST	<= #TCO '0;
	end

	//======================================================================
    //读地址累加
	//assign	araddr_step	= 2**arsize;        	//计算步进
	always_comb begin
		case(arsize)
			3'h0:	araddr_step = 16'h1;
			3'h1:	araddr_step = 16'h2;
			3'h2:	araddr_step = 16'h4;
			default:araddr_step = 16'h1;
		endcase
	end

	//assign	araddr_stop = arlen*araddr_step;	//计算步进次数
	always_comb begin
		case(arsize)
			3'h0:	araddr_stop = {8'h0,arlen};
			3'h1:	araddr_stop = {7'h0,arlen,1'b0};
			3'h2:	araddr_stop = {6'h0,arlen,2'b0};
			default:araddr_stop = {8'h0,arlen};
		endcase
	end

	always_ff@(posedge ACLK, negedge ARESETn)begin
		if(!ARESETn)
			araddr_cnt_flag	<= #TCO '0;
		else if(ARVALID)
			araddr_cnt_flag	<= #TCO '1;
		else if(arlen=='0)
			araddr_cnt_flag	<= #TCO '0;
		else if(araddr_cnt==araddr_stop)
			araddr_cnt_flag	<= #TCO '0;
	end

	always_ff@(posedge ACLK, negedge ARESETn)begin
		if(!ARESETn)
			araddr_cnt	<= #TCO '0;
		else if(araddr_cnt_flag)
			araddr_cnt	<= #TCO araddr_cnt + araddr_step;
		else
			araddr_cnt	<= #TCO '0;
	end


    //======================================================================
    //输出信号
	
	//----------------------------------------------------------------------
    //使能
	always_ff@(posedge ACLK, negedge ARESETn)begin
		if(!ARESETn)
			ren	<= #TCO '0;
		else if(RREADY&&(araddr_cnt==arlen))
			ren	<= #TCO '0;
		else if(ARVALID)
			ren	<= #TCO '1;
		else
			ren	<= #TCO ren;
	end


	//----------------------------------------------------------------------
    //读地址

	always_comb begin
		araddr = araddr_start + araddr_cnt;
	end

	//----------------------------------------------------------------------
    //读数据
	always_ff@(posedge ACLK, negedge ARESETn)begin
		if(!ARESETn)
			RDATA	<= #TCO '0;
		else if(RREADY)
			RDATA	<= #TCO sram_rdata;
		else
			RDATA	<= #TCO RDATA;
	end

	//======================================================================
	//其他信号

	//----------------------------------------------------------------------
    //回应
	always_comb begin
		RRESP = '0;
	end

endmodule                                     