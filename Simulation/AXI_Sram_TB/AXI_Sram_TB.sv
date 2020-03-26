//=============================================================================
//
//Module Name:					AXI_Sram_TB.sv
//Department:					Xidian University
//Function Description:	        AXI总线测试
//
//------------------------------------------------------------------------------
//
//Version 	Design		Coding		Simulata	  Review		Rel data
//V1.0		Verdvana	Verdvana	Verdvana		  			2020-3-26
//
//------------------------------------------------------------------------------
//
//Version	Modified History
//V1.0		
//
//=============================================================================

`timescale 1ns/1ns

module AXI_Sram_TB;

    parameter   DATA_WIDTH  = 32,             //数据位宽
                ADDR_WIDTH  = 16,               //地址位宽              
                ID_WIDTH    = 1,               //ID位宽
                USER_WIDTH  = 1,             //USER位宽
                STRB_WIDTH  = (DATA_WIDTH/8);   //STRB位宽

	logic                       ACLK;
	logic   	                ARESETn;
//	logic   [ID_WIDTH-1:0]      AWID;
	logic   [ADDR_WIDTH-1:0]    AWADDR;
	logic   [7:0]               AWLEN;
	logic   [2:0]               AWSIZE;
	logic   [1:0]	            AWBURST;
//	logic                       AWLOCK;
//	logic   [3:0]	            AWCACHE;
//	logic   [2:0]	            AWPROT;
//	logic   [3:0]	            AWQOS;
//	logic   [3:0]               AWREGION;
//	logic   [USER_WIDTH-1:0]	AWUSER;
	logic                       AWVALID;
	logic                       AWREADY;
//	logic   [ID_WIDTH-1:0]      WID;
	logic   [DATA_WIDTH-1:0]    WDATA;
	logic   [STRB_WIDTH-1:0]    WSTRB;
	logic                       WLAST;
//	logic   [USER_WIDTH-1:0]	WUSER;
	logic                       WVALID;
	logic                       WREADY;
//	logic   [ID_WIDTH-1:0]      BID;
	logic   [1:0]               BRESP;
//	logic   [USER_WIDTH-1:0]	BUSER;
	logic                       BVALID;
	logic                       BREADY;
//	logic   [ID_WIDTH-1:0]      ARID;
	logic   [ADDR_WIDTH-1:0]    ARADDR;
	logic   [7:0]               ARLEN;
	logic   [2:0]	            ARSIZE;
	logic   [1:0]	            ARBURST;
//	logic                       ARLOCK;
//	logic   [3:0]	            ARCACHE;
//	logic   [2:0]               ARPROT;
//	logic   [3:0]	            ARQOS;
//	logic   [3:0]	            ARREGION;
//	logic   [USER_WIDTH-1:0]	ARUSER;
	logic                       ARVALID;
	logic                       ARREADY;          
//	logic   [ID_WIDTH-1:0]	    RID;
	logic   [DATA_WIDTH-1:0]	RDATA;
	logic   [1:0]	            RRESP;
	logic                       RLAST;
//	logic   [USER_WIDTH-1:0]    RUSER;
	logic                       RVALID;
	logic                       RREADY;

    logic                       bist_en;
    logic                       dft_en;
    logic                       bist_done;
    logic   [7:0]               bist_fail;

    logic                       en_w;
    logic                       en_r;
    logic    [7:0]              awlen;
    logic    [7:0]              arlen;
    logic  [ADDR_WIDTH-1:0]     addr_start;

    logic [DATA_WIDTH-1:0]      data_r;

    assign                      AWLEN = awlen;
    assign                      ARLEN = arlen;

    AXI_Master#(
		.DATA_WIDTH(DATA_WIDTH),
		.ADDR_WIDTH(ADDR_WIDTH),
		.ID_WIDTH(ID_WIDTH),
		.USER_WIDTH(USER_WIDTH),
		.STRB_WIDTH(DATA_WIDTH/8)
	)u1_AXI_Master(.*);

    AXI_Sram#(
		.DATA_WIDTH(DATA_WIDTH),
		.ADDR_WIDTH(ADDR_WIDTH),
		.ID_WIDTH(ID_WIDTH),
		.USER_WIDTH(USER_WIDTH),
		.STRB_WIDTH(DATA_WIDTH/8)
	)u1_AXI_Sram(.*);


    //=========================================================
    //常量
    parameter   PERIOD  =   20, //时钟周期
                TCO     =   1;  //寄存器延迟

    //=========================================================
    //时钟激励
    initial begin
        ACLK = '0;
        forever #(PERIOD/2) ACLK = ~ACLK;
    end

    //=========================================================
    //复位&初始化任务
    task task_init;
        ARESETn     = '0;
        //初始化
        en_w        = '0;
        en_r        = '0;
        awlen       = 8'b0000_1111;    //写入/读取数据次数
        addr_start  = '0;
        AWSIZE      = 2;
        ARSIZE      = 2;
        bist_en     = '0;
        dft_en      = '0;


        //复位
        #PERIOD;#PERIOD;
        ARESETn = '1;
        #PERIOD;#PERIOD;
        #2;//输入延迟
    endtask

    //=========================================================
    //0号主机写任务
    task task_m_w(  input [ADDR_WIDTH-1:0] addr,
                    input [7:0] len);
    begin
        addr_start = addr;
        awlen      = len;
        en_w       = '1;
        #PERIOD;
        en_w       = '0;
        #200;
    end
    endtask

    //=========================================================
    //0号主机读任务
    task task_m_r(  input [ADDR_WIDTH-1:0] addr,
                    input [7:0] len);
    begin
        addr_start = addr;
        arlen      = len;
        en_r       = '1;
        #PERIOD;
        en_r       = '0;
        #200;
    end
    endtask
        initial begin
        //复位&初始化
        task_init;

        //0号主机给0号从机写入和读取
        task_m_w(5,0);

        task_m_w(32772,3);

        task_m_w(45,7);



        task_m_r(5,0);

        task_m_r(32772,3);



        #400;
        $stop;
    end


endmodule