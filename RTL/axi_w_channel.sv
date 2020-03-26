//=============================================================================
//
//Module Name:					axi_w_channel.sv
//Department:					Xidian University
//Function Description:	        AXI总线从设备写通道
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

module axi_w_channel#(
    parameter   DATA_WIDTH  = 64,             	//数据位宽
                ADDR_WIDTH  = 32,               //地址位宽              
                ID_WIDTH    = 1,               	//ID位宽
                USER_WIDTH  = 1,             	//USER位宽
                STRB_WIDTH  = (DATA_WIDTH/8)	//STRB位宽
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
	output reg	                AWREADY,
	//写数据通道                
//	input	   [ID_WIDTH-1:0]   WID,
	input	   [DATA_WIDTH-1:0] WDATA,
	input	   [STRB_WIDTH-1:0] WSTRB,
	input		                WLAST,
//	input	   [USER_WIDTH-1:0]	WUSER,
	input	  	                WVALID,
	output reg	                WREADY,
	//写响应通道                
//	output reg [ID_WIDTH-1:0]   BID,
	output reg [1:0]            BRESP,
//	output reg [USER_WIDTH-1:0]	BUSER,
	output reg	                BVALID,
	input	  	                BREADY,
	/********** 输出信号 **********/
	output reg					wen,
	output reg [2:0]			awsize,
	output reg [15:0]			awaddr,
	output reg [31:0]			wdata
);  

    //=========================================================
    //常量定义
    parameter   TCO     =   1;  	//寄存器延时

	//=========================================================
    //中间信号
	logic	[15:0]	awaddr_start;	//起始地址
	logic	[15:0]	awaddr_stop;	//终止地址（不加起始地址）
	logic	[15:0]	awaddr_cnt;		//地址计数器
	logic	[8:0]	awaddr_step;	//地址步进长度
	logic			awaddr_cnt_flag;//地址累加标志
	logic   [7:0]	awlen;			//awlen



    //======================================================================
    //握手

	//----------------------------------------------------------------------
    //AWREADY回应
	always_ff@(posedge ACLK, negedge ARESETn)begin
		if(!ARESETn)
			AWREADY	<= #TCO '0;
		else if(AWVALID&&!AWREADY)
			AWREADY	<= #TCO '1;
		else
			AWREADY	<= #TCO '0;
	end

	//----------------------------------------------------------------------
    //WREADY回应
	always_ff@(posedge ACLK, negedge ARESETn)begin
		if(!ARESETn)
			WREADY	<= #TCO '0;
		else if(AWREADY)
			WREADY	<= #TCO '1;
		else if(WVALID&&WLAST)
			WREADY	<= #TCO '0;	
		else
			WREADY	<= #TCO WREADY;
	end

	//----------------------------------------------------------------------
    //BVALID回应
	always_ff@(posedge ACLK, negedge ARESETn)begin
		if(!ARESETn)
			BVALID	<= #TCO '0;
		else if(~BVALID&&WLAST)
			BVALID	<= #TCO '1;
		else
			BVALID	<= #TCO '0;
	end

    //======================================================================
    //参数寄存	
	always_ff@(posedge ACLK, negedge ARESETn)begin
		if(!ARESETn)begin
			awaddr_start	<= #TCO '0;
			awlen			<= #TCO '0;
			awsize			<= #TCO '0;
		end
		else if(AWVALID)begin
			awaddr_start	<= #TCO AWADDR[15:0];	//起始地址寄存
			awlen			<= #TCO AWLEN;			//突发长度寄存
			awsize			<= #TCO AWSIZE;			//数据宽度寄存
		end
		else begin
			awaddr_start	<= #TCO awaddr_start;
			awlen			<= #TCO awlen;
			awsize			<= #TCO awsize;
		end
	end


	//======================================================================
    //写地址累加
	//assign	awaddr_step	= 2**awsize;			//计算步进
	always_comb begin
		case(awsize)
			3'h0:	awaddr_step = 16'h1;
			3'h1:	awaddr_step = 16'h2;
			3'h2:	awaddr_step = 16'h4;
			default:awaddr_step = 16'h1;
		endcase
	end

	//assign	awaddr_stop = awlen*awaddr_step;	//计算步进次数
	always_comb begin
		case(awsize)
			3'h0:	awaddr_stop = {8'h0,awlen};
			3'h1:	awaddr_stop = {7'h0,awlen,1'b0};
			3'h2:	awaddr_stop = {6'h0,awlen,2'b0};
			default:awaddr_stop = {8'h0,awlen};
		endcase
	end


	always_ff@(posedge ACLK, negedge ARESETn)begin
		if(!ARESETn)
			awaddr_cnt_flag	<= #TCO '0;
		else if(AWVALID)
			awaddr_cnt_flag = #TCO '1;
		else if(awlen=='0)
			awaddr_cnt_flag = #TCO '0;
		else if(awaddr_cnt==awaddr_stop)
			awaddr_cnt_flag = #TCO '0;
	end

	always_ff@(posedge ACLK, negedge ARESETn)begin
		if(!ARESETn)
			awaddr_cnt	<= #TCO '0;
		else if(awaddr_cnt_flag)
			awaddr_cnt	<= #TCO awaddr_cnt + awaddr_step;
		else
			awaddr_cnt	<= #TCO '0;
	end


	//======================================================================
	//输出信号

	//----------------------------------------------------------------------
    //使能
	always_ff@(posedge ACLK, negedge ARESETn)begin
		if(!ARESETn)
			wen	<= #TCO '0;
		else if(WLAST)
			wen	<= #TCO '0;
		else if(AWREADY)
			wen	<= #TCO '1;
		else
			wen	<= #TCO wen;
	end

	//----------------------------------------------------------------------
    //写数据
	always_comb begin
		case(awsize)
			3'b000:	wdata = {24'b0,WDATA[7:0]};	//8bit
			3'b001:	wdata = {16'b0,WDATA[15:0]};//16bit
			3'b010:	wdata = WDATA[31:0];		//32bit
			default:wdata = WDATA[31:0];
		endcase
	end


	//----------------------------------------------------------------------
    //写地址
	always_ff@(posedge ACLK, negedge ARESETn)begin
		if(!ARESETn)
			awaddr	<= #TCO '0;
		else
			awaddr 	<= #TCO  awaddr_start + awaddr_cnt;
	end

	//======================================================================
	//其他信号

	//----------------------------------------------------------------------
    //回应
	always_comb begin
		BRESP = '0;
	end

	


  
endmodule                                     