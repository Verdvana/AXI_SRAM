//=============================================================================
//
//Module Name:					AXI_Sram.sv
//Department:					Xidian University
//Function Description:	        AXI总线协议SRAM
//
//------------------------------------------------------------------------------
//
//Version 	Design		Coding		Simulata	  Review		Rel data
//V1.0		Verdvana	Verdvana	Verdvana		  			2020-3-25
//
//------------------------------------------------------------------------------
//
//Version	Modified History
//V1.0		AXI协议的8k×8的SRAM
//
//=============================================================================

`timescale 1ns/1ns

module AXI_Sram#(
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
	/********** DFT信号 **********/
	input						bist_en,
	input						dft_en,
	output						bist_done,
	output		[7:0]			bist_fail
);  

	//=========================================================
    //中间信号
	logic			sram_wen;
	logic	[12:0]	sram_addr_out;
	logic	[31:0]	sram_wdata;
	logic	[31:0]	sram_rdata;
    logic   [7:0]	sram_q0;
    logic   [7:0]	sram_q1;
    logic   [7:0]	sram_q2;
    logic   [7:0]	sram_q3;
    logic   [7:0]	sram_q4;
    logic   [7:0]	sram_q5;
    logic   [7:0]	sram_q6;
    logic   [7:0]	sram_q7;
	logic	[3:0]	bank0_csn;
	logic	[3:0]	bank1_csn;
    
    //=========================================================
    //AXI总线从设备Instruction Fetch例化
    axi_slave_if#(
		.DATA_WIDTH(DATA_WIDTH),
		.ADDR_WIDTH(ADDR_WIDTH),
		.ID_WIDTH(ID_WIDTH),
		.USER_WIDTH(USER_WIDTH),
		.STRB_WIDTH(DATA_WIDTH/8)
	)u_axi_slave_if(.*);


    //=========================================================
    //SRAM例化
	sram_core u_sram_core(
        .hclk(ACLK),
        .sram_clk(~ACLK),
        .hresetn(ARESETn),

		.sram_addr    (sram_addr_out),
		.sram_wdata_in(sram_wdata),
		.sram_wen     (sram_wen),
		.bank0_csn   (bank0_csn),
		.bank1_csn   (bank1_csn),
    
		.bist_en     (bist_en),
		.dft_en      (dft_en),

        .sram_q0    (sram_q0),
        .sram_q1    (sram_q1),
        .sram_q2    (sram_q2),
        .sram_q3    (sram_q3),
        .sram_q4    (sram_q4),
        .sram_q5    (sram_q5),
        .sram_q6    (sram_q6),
        .sram_q7    (sram_q7),
        .bist_done  (bist_done),
        .bist_fail  (bist_fail)
        );


endmodule