//****************************************************
//wrapper for ahb_sram_controller
//author: qlzhao
//version:0.0
//date:2009-8-3
//****************************************************

module sramc_wrapper(  
  AHB_if.slave  sramc_ahb, 
  input  sram_clk,
  input  dft_en,
  input  bist_en,
  output bist_done,
  output bist_fail
  );
		          
  //instance  ahb_sram_top
  
  sramc_top  
  sramc_top_u (
                .hclk        (sramc_ahb.clock     )                 
              , .sram_clk    (sram_clk            )                 
              , .hresetn     (sramc_ahb.reset_n   )           
              , .hsel        (sramc_ahb.hsel      )                   
              , .hwrite      (sramc_ahb.hwrite    )               
              , .hready      (sramc_ahb.hready_in )               
              , .hsize       (sramc_ahb.hsize     )                 
              , .hburst      (sramc_ahb.hburst    )                 
              , .htrans      (sramc_ahb.htrans    )               
              , .hwdata      (sramc_ahb.hwdata    )               
              , .haddr       (sramc_ahb.haddr     )                 
              , .dft_en      (dft_en              )                 
              , .bist_en     (bist_en             )                 
              , .hready_resp (sramc_ahb.hready_out)     
              , .hresp       (sramc_ahb.hresp     )               
              , .hrdata      (sramc_ahb.hrdata    )               
              , .bist_done   (bist_done           )               
              , .bist_fail   (bist_fail           )               
              );
endmodule
