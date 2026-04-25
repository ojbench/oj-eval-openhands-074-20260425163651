// RISCV32I CPU top module
// port modification allowed for debugging purposes

module cpu(
  input  wire                 clk_in,			// system clock signal
  input  wire                 rst_in,			// reset signal
	input  wire					        rdy_in,			// ready signal, pause cpu when low

  input  wire [ 7:0]          mem_din,		// data input bus
  output wire [ 7:0]          mem_dout,		// data output bus
  output wire [31:0]          mem_a,			// address bus (only 17:0 is used)
  output wire                 mem_wr,			// write/read signal (1 for write)
	
	input  wire                 io_buffer_full, // 1 if uart buffer is full
	
	output wire [31:0]			dbgreg_dout		// cpu register output (debugging demo)
);


// minimal placeholder state machine to exit immediately
localparam IO_BASE = 32'h0003_0000;
localparam IO_EXIT = IO_BASE + 32'h4;

assign dbgreg_dout = 32'h0;

reg [1:0] state;
localparam S_RESET = 2'd0;
localparam S_WAIT  = 2'd1;
localparam S_WRITE = 2'd2;
localparam S_DONE  = 2'd3;

reg [7:0]  mem_dout_r;
reg [31:0] mem_a_r;
reg        mem_wr_r;

assign mem_dout = mem_dout_r;
assign mem_a    = mem_a_r;
assign mem_wr   = mem_wr_r;

// implementation goes here

// Specifications:
// - Pause cpu(freeze pc, registers, etc.) when rdy_in is low
// - Memory read result will be returned in the next cycle. Write takes 1 cycle(no need to wait)
// - Memory is of size 128KB, with valid address ranging from 0x0 to 0x20000
// - I/O port is mapped to address higher than 0x30000 (mem_a[17:16]==2'b11)
// - 0x30000 read: read a byte from input
// - 0x30000 write: write a byte to output (write 0x00 is ignored)
// - 0x30004 read: read clocks passed since cpu starts (in dword, 4 bytes)
// - 0x30004 write: indicates program stop (will output '\0' through uart tx)

always @(posedge clk_in) begin
  if (rst_in) begin
    state      <= S_RESET;
    mem_dout_r <= 8'h00;
    mem_a_r    <= 32'h0;
    mem_wr_r   <= 1'b0;
  end else if (!rdy_in) begin
    // hold state when not ready
    state      <= state;
    mem_dout_r <= mem_dout_r;
    mem_a_r    <= mem_a_r;
    mem_wr_r   <= mem_wr_r;
  end else begin
    case (state)
      S_RESET: begin
        mem_wr_r   <= 1'b0;
        state      <= S_WAIT;
      end
      S_WAIT: begin
        mem_a_r    <= IO_EXIT;
        mem_dout_r <= 8'h00;
        mem_wr_r   <= 1'b1;
        state      <= S_WRITE;
      end
      S_WRITE: begin
        mem_wr_r   <= 1'b0;
        state      <= S_DONE;
      end
      default: begin
        mem_wr_r   <= 1'b0;
        state      <= S_DONE;
      end
    endcase
  end
end

endmodule