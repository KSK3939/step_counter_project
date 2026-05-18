`timescale 1 ns / 1 ps

module myip_slave_lite_v1_0_S00_AXI #
(
    // Users to add parameters here

    // User parameters ends
    // Do not modify the parameters beyond this line

    // Width of S_AXI data bus
    parameter integer C_S_AXI_DATA_WIDTH	= 32,
    // Width of S_AXI address bus
    parameter integer C_S_AXI_ADDR_WIDTH	= 4
)
(
    // Users to add ports here
    output reg [7:0] tx_data_out,
    output reg tx_start,
    output wire [31:0] baud_div_out,
    
    input wire tx_busy,
    input wire tx_done,
        
    // RX 포트 (User ports 섹션)
    input  wire [7:0] rx_data_in,
    input  wire       rx_done,
    input  wire       rx_busy,
    input  wire       rx_error,
    
    // User ports ends
    // Do not modify the ports beyond this line

    // Global Clock Signal
    input wire  S_AXI_ACLK,
    // Global Reset Signal. This Signal is Active LOW
    input wire  S_AXI_ARESETN,
    // Write address (issued by master, acceped by Slave)
    input wire [C_S_AXI_ADDR_WIDTH-1 : 0] S_AXI_AWADDR,
    // Write channel Protection type. This signal indicates the
        // privilege and security level of the transaction, and whether
        // the transaction is a data access or an instruction access.
    input wire [2 : 0] S_AXI_AWPROT,
    // Write address valid. This signal indicates that the master signaling
        // valid write address and control information.
    input wire  S_AXI_AWVALID,
    // Write address ready. This signal indicates that the slave is ready
        // to accept an address and associated control signals.
    output wire  S_AXI_AWREADY,
    // Write data (issued by master, acceped by Slave) 
    input wire [C_S_AXI_DATA_WIDTH-1 : 0] S_AXI_WDATA,
    // Write strobes. This signal indicates which byte lanes hold
        // valid data. There is one write strobe bit for each eight
        // bits of the write data bus.    
    input wire [(C_S_AXI_DATA_WIDTH/8)-1 : 0] S_AXI_WSTRB,
    // Write valid. This signal indicates that valid write
        // data and strobes are available.
    input wire  S_AXI_WVALID,
    // Write ready. This signal indicates that the slave
        // can accept the write data.
    output wire  S_AXI_WREADY,
    // Write response. This signal indicates the status
        // of the write transaction.
    output wire [1 : 0] S_AXI_BRESP,
    // Write response valid. This signal indicates that the channel
        // is signaling a valid write response.
    output wire  S_AXI_BVALID,
    // Response ready. This signal indicates that the master
        // can accept a write response.
    input wire  S_AXI_BREADY,
    // Read address (issued by master, acceped by Slave)
    input wire [C_S_AXI_ADDR_WIDTH-1 : 0] S_AXI_ARADDR,
    // Protection type. This signal indicates the privilege
        // and security level of the transaction, and whether the
        // transaction is a data access or an instruction access.
    input wire [2 : 0] S_AXI_ARPROT,
    // Read address valid. This signal indicates that the channel
        // is signaling valid read address and control information.
    input wire  S_AXI_ARVALID,
    // Read address ready. This signal indicates that the slave is
        // ready to accept an address and associated control signals.
    output wire  S_AXI_ARREADY,
    // Read data (issued by slave)
    output wire [C_S_AXI_DATA_WIDTH-1 : 0] S_AXI_RDATA,
    // Read response. This signal indicates the status of the
        // read transfer.
    output wire [1 : 0] S_AXI_RRESP,
    // Read valid. This signal indicates that the channel is
        // signaling the required read data.
    output wire  S_AXI_RVALID,
    // Read ready. This signal indicates that the master can
        // accept the read data and response information.
    input wire  S_AXI_RREADY
);

// AXI4LITE signals
reg [C_S_AXI_ADDR_WIDTH-1 : 0] 	axi_awaddr;
reg  	axi_awready;
reg  	axi_wready;
reg [1 : 0] 	axi_bresp;
reg  	axi_bvalid;
reg [C_S_AXI_ADDR_WIDTH-1 : 0] 	axi_araddr;
reg  	axi_arready;
reg [1 : 0] 	axi_rresp;
reg  	axi_rvalid;

// Example-specific design signals
// local parameter for addressing 32 bit / 64 bit C_S_AXI_DATA_WIDTH
// ADDR_LSB is used for addressing 32/64 bit registers/memories
// ADDR_LSB = 2 for 32 bits (n downto 2)
// ADDR_LSB = 3 for 64 bits (n downto 3)
localparam integer ADDR_LSB = (C_S_AXI_DATA_WIDTH/32) + 1;
localparam integer OPT_MEM_ADDR_BITS = 1;
//----------------------------------------------
//-- Signals for user logic register space example
//------------------------------------------------
//-- Number of Slave Registers 4
reg [C_S_AXI_DATA_WIDTH-1:0]	slv_reg0;     // txdata
reg [C_S_AXI_DATA_WIDTH-1:0]	slv_reg1;     // 사용 x
reg [C_S_AXI_DATA_WIDTH-1:0]	slv_reg2;     // bauddiv
reg [C_S_AXI_DATA_WIDTH-1:0]	slv_reg3;     // ctrl
integer	 byte_index;

// I/O Connections assignments

assign S_AXI_AWREADY	= axi_awready;
assign S_AXI_WREADY	= axi_wready;
assign S_AXI_BRESP	= axi_bresp;
assign S_AXI_BVALID	= axi_bvalid;
assign S_AXI_ARREADY	= axi_arready;
assign S_AXI_RRESP	= axi_rresp;
assign S_AXI_RVALID	= axi_rvalid;
//state machine varibles 
reg [1:0] state_write;
reg [1:0] state_read;
//State machine local parameters
localparam Idle = 2'b00,Raddr = 2'b10,Rdata = 2'b11 ,Waddr = 2'b10,Wdata = 2'b11;

reg tx_done_flag;
reg rx_done_flag;
reg rx_error_flag;

reg [7:0]  rx_data_buf;   // 수신된 데이터 래치

wire tx_ready;
wire [31:0] status_reg;

assign tx_ready = ~tx_busy;
// status_reg에 RX 상태 추가
assign status_reg = {26'd0, rx_error_flag, rx_done_flag, rx_busy,
                     tx_done_flag, tx_ready, tx_busy}; 
assign baud_div_out = slv_reg2;

// Implement Write state machine
// Outstanding write transactions are not supported by the slave i.e., master should assert bready to receive response on or before it starts sending the new transaction
always @(posedge S_AXI_ACLK)                                 
  begin                                 
     if (S_AXI_ARESETN == 1'b0)                                 
       begin                                 
         axi_awready <= 1'b0;                                 
         axi_wready <= 1'b0;                                 
         axi_bvalid <= 1'b0;                                 
         axi_bresp <= 2'b00;                                 
         axi_awaddr <= {C_S_AXI_ADDR_WIDTH{1'b0}};                                 
         state_write <= Idle;                                 
       end                                 
     else                                  
       begin                                 
         case(state_write)                                 
           Idle:                                      
             begin                                                     
                   axi_awready <= 1'b1;                                 
                   axi_wready <= 1'b1;                                 
                   state_write <= Waddr;                                
             end                                 
           Waddr:        //At this state, slave is ready to receive address along with corresponding control signals and first data packet. Response valid is also handled at this state                                 
             begin                                 
               if (S_AXI_AWVALID && S_AXI_AWREADY)                                 
                  begin                                 
                    axi_awaddr <= S_AXI_AWADDR;                                 
                    if(S_AXI_WVALID)                                  
                      begin                                   
                        axi_awready <= 1'b1; 
                        axi_bresp <= 2'b00;                                
                        state_write <= Waddr;                                 
                        axi_bvalid <= 1'b1;                                 
                      end                                 
                    else                                  
                      begin                                 
                        axi_awready <= 1'b0;                                 
                        state_write <= Wdata;                                 
                        if (S_AXI_BREADY && axi_bvalid) axi_bvalid <= 1'b0;                                 
                      end                                 
                  end                                 
               else                                  
                  begin                                 
                    state_write <= state_write;                                 
                    if (S_AXI_BREADY && axi_bvalid) axi_bvalid <= 1'b0;                                 
                   end                                 
             end                                 
          Wdata:        //At this state, slave is ready to receive the data packets until the number of transfers is equal to burst length                                 
             begin                                 
               if (S_AXI_WVALID)                                 
                 begin                                 
                   state_write <= Waddr;                                 
                   axi_bvalid <= 1'b1;   
                   axi_bresp <= 2'b00;                              
                   axi_awready <= 1'b1;                                 
                 end                                 
                else                                  
                 begin                                 
                   state_write <= state_write;                                 
                   if (S_AXI_BREADY && axi_bvalid) axi_bvalid <= 1'b0;                                 
                 end                                              
             end      
             
             default : state_write <= Idle;                           
          endcase                                 
        end                                 
      end            
      
      wire write_fire;
      assign write_fire = S_AXI_WVALID && ((S_AXI_AWVALID && S_AXI_AWREADY) || (state_write == Wdata));                     
        
      wire [1:0] write_addr;
      assign write_addr = (S_AXI_AWVALID) ? S_AXI_AWADDR[ADDR_LSB + OPT_MEM_ADDR_BITS : ADDR_LSB] 
                           : axi_awaddr[ADDR_LSB + OPT_MEM_ADDR_BITS : ADDR_LSB];
// Implement memory mapped register select and write logic generation
// The write data is accepted and written to memory mapped registers when
// axi_awready, S_AXI_WVALID, axi_wready and S_AXI_WVALID are asserted. Write strobes are used to
// select byte enables of slave registers while writing.
// These registers are cleared when reset (active low) is applied.
// Slave register write enable is asserted when valid address and data are available
// and the slave is ready to accept the write address and write data.
 

always @( posedge S_AXI_ACLK )
begin
  if ( S_AXI_ARESETN == 1'b0 )
    begin
      slv_reg0 <= 32'd0;
      slv_reg1 <= 32'd0;
      slv_reg2 <= 32'd867;
      slv_reg3 <= 32'd0;
      tx_data_out <= 8'd0;
      tx_start <= 1'b0;
      tx_done_flag <= 1'b0;
      
      rx_done_flag <= 1'b0;
      rx_error_flag <= 1'b0;
      rx_data_buf  <= 8'd0;
    end 
  else begin
    tx_start <= 1'b0;
    
    if(tx_done)
       tx_done_flag <= 1'b1;
    
    if(rx_done) begin
        rx_done_flag <= 1'b1;
        rx_data_buf <= rx_data_in;
    end
    
    if(rx_error)
        rx_error_flag <= 1'b1;
    
//    if(write_fire && write_addr == 2'h3 && S_AXI_WDATA[1])
//       tx_done_flag <= 1'b0;
    
//    // RX 추가 
//    if (rx_done) begin
//        rx_done_flag <= 1'b1;
//        rx_data_buf  <= rx_data_in;   // 도착한 즉시 래치
//    end
//    // reg3 bit[2] write로 rx_done_flag 클리어
//    if (write_fire && write_addr == 2'h3 && S_AXI_WDATA[2])
//        rx_done_flag <= 1'b0;
    
    if (write_fire)
      begin
        case (write_addr)
          2'h0: begin
            for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 ) begin
              if ( S_AXI_WSTRB[byte_index] == 1 )
                // Respective byte enables are asserted as per write strobes 
                // Slave register 0
                slv_reg0[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
            end
            
            if(!tx_busy) begin
               tx_data_out <= S_AXI_WDATA[7:0];
               tx_start <= 1'b1;
            end
          end  
          2'h1: begin
            if(S_AXI_WDATA[2]) tx_done_flag <= 1'b0;
            if(S_AXI_WDATA[4]) rx_done_flag <= 1'b0;
            if(S_AXI_WDATA[5]) rx_error_flag <= 1'b0;
           // slv_reg1 <= slv_reg1;
          end  
          2'h2: begin
            for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 ) begin
              if ( S_AXI_WSTRB[byte_index] == 1 ) 
                // Respective byte enables are asserted as per write strobes 
                // Slave register 2
                slv_reg2[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
            end  
          end  
          2'h3: begin
//            for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 ) begin
//              if ( S_AXI_WSTRB[byte_index]) 
                // Respective byte enables are asserted as per write strobes 
                // Slave register 3
                //slv_reg3[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
                slv_reg3 <= slv_reg3;
            //end  
          end  
        endcase
      end
  end
end    

// Implement read state machine
  always @(posedge S_AXI_ACLK)                                       
    begin                                       
      if (S_AXI_ARESETN == 1'b0)                                       
        begin                                       
         //asserting initial values to all 0's during reset                                       
         axi_arready <= 1'b0;                                       
         axi_rvalid <= 1'b0;                                       
         axi_rresp <= 2'b00;                                       
         state_read <= Idle;                                       
        end                                       
      else                                       
        begin                                    
          case(state_read)                                       
            Idle:     //Initial state inidicating reset is done and ready to receive read/write transactions                                       
              begin                                                                                      
                    state_read <= Raddr;                                       
                    axi_arready <= 1'b1;                                                                          
              end                                       
            Raddr:        //At this state, slave is ready to receive address along with corresponding control signals                                       
              begin                                       
                if (S_AXI_ARVALID && S_AXI_ARREADY)                                       
                  begin                                       
                    state_read <= Rdata;                                       
                    axi_araddr <= S_AXI_ARADDR;                                       
                    axi_rvalid <= 1'b1;                                       
                    axi_arready <= 1'b0;                                       
                  end                                      
              end                                       
            Rdata:        //At this state, slave is ready to send the data packets until the number of transfers is equal to burst length                                       
              begin                                           
                if (S_AXI_RVALID && S_AXI_RREADY)                                       
                  begin                                       
                    axi_rvalid <= 1'b0;                                       
                    axi_arready <= 1'b1;                                       
                    state_read <= Raddr;                                       
                  end                                        
              end  
              
              default: state_read <= Idle;                                     
           endcase                                       
          end                                       
        end                                         
// Implement memory mapped register select and read logic generation
  assign S_AXI_RDATA = (axi_araddr[ADDR_LSB+OPT_MEM_ADDR_BITS:ADDR_LSB] == 2'h0) ? slv_reg0 :
                       (axi_araddr[ADDR_LSB+OPT_MEM_ADDR_BITS:ADDR_LSB] == 2'h1) ? status_reg :     // bit[7:0] = rx_data_buf로 변경 가
                       (axi_araddr[ADDR_LSB+OPT_MEM_ADDR_BITS:ADDR_LSB] == 2'h2) ? slv_reg2 : 
                       (axi_araddr[ADDR_LSB+OPT_MEM_ADDR_BITS:ADDR_LSB] == 2'h3) ? {24'd0, rx_data_buf} : 32'd0; 
// Add user logic here

// User logic ends

endmodule
