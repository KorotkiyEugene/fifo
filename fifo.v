`timescale 1ns/1ps

module fifo(i_clk, 
            i_rst_n, 
            i_push, 
            i_pop, 
            i_data, 
            o_data, 
            o_full, 
            o_empty,
            o_nearly_full,
            o_nearly_empty
            );

parameter FIFO_LENGTH = 16;
parameter DATA_WIDTH = 8;
localparam ADR_WIDTH = clogb2(FIFO_LENGTH);

input i_clk, i_rst_n, i_push, i_pop;
input [DATA_WIDTH-1:0] i_data;
output reg [DATA_WIDTH-1:0] o_data; 
output o_full, o_empty, o_nearly_full, o_nearly_empty;

reg [DATA_WIDTH-1:0] fifo_mem[FIFO_LENGTH-1:0];
reg [FIFO_LENGTH-1:0] r_ptr, w_ptr;
reg [FIFO_LENGTH:0]   counter;      // counter must hold 1..FIFO_LENGTH + empty state
reg was_push, was_pop;
wire add, sub, same;
integer i;

always @(posedge i_clk, negedge i_rst_n)
if(!i_rst_n) begin
  r_ptr <= {{(FIFO_LENGTH-1){1'b0}}, 1'b1};
  w_ptr <= {{(FIFO_LENGTH-1){1'b0}}, 1'b1};
end else begin
  if(i_push & !o_full)
    w_ptr <= {w_ptr[FIFO_LENGTH-2:0], w_ptr[FIFO_LENGTH-1]};
  if(i_pop & !o_empty)
    r_ptr <= {r_ptr[FIFO_LENGTH-2:0], r_ptr[FIFO_LENGTH-1]};  
end

assign add = was_push && !was_pop;
assign sub = was_pop && !was_push;
assign same = !(add || sub);
   
assign o_full = (counter[FIFO_LENGTH] && !sub) || (counter[FIFO_LENGTH-1] && add);
assign o_empty = (counter[0] && !add) || (counter[1] && sub);
assign o_nearly_full = (counter[FIFO_LENGTH-1] && same) || (counter[FIFO_LENGTH] && sub) || (counter[FIFO_LENGTH-2] && add);
assign o_nearly_empty = (counter[1] && same) || (counter[0] && add) || (counter[2] && sub);

always @(posedge i_clk, negedge i_rst_n)
if(!i_rst_n) begin
  counter <= {{FIFO_LENGTH{1'b0}}, 1'b1}; // fifo empty
  was_push <= 1'b0;
  was_pop <= 1'b0;
end else begin
  if(!o_full)
    was_push <= i_push;
  else
    was_push <= 1'b0;
 
  if(!o_empty)  
    was_pop <= i_pop;
  else
    was_pop <= 1'b0;
     
	if (add) begin
	    counter <= {counter[FIFO_LENGTH-1:0], 1'b0};
	 end else if (sub) begin
	    counter <= {1'b0, counter[FIFO_LENGTH:1]};
	 end
end
 
always @(posedge i_clk) begin
if(i_push)
  for(i=0;i<FIFO_LENGTH;i=i+1)
    if(w_ptr[i])
      fifo_mem[i] <= i_data;      
end 

always @* begin
o_data = 'x;
for(i=0;i<FIFO_LENGTH;i=i+1)
    if(r_ptr[i]) 
      o_data = fifo_mem[i]; 
end
   
function integer clogb2;
    input [31:0] value;
    begin
        value = value - 1;
        for (clogb2 = 0; value > 0; clogb2 = clogb2 + 1) begin
            value = value >> 1;
        end
    end
endfunction

endmodule
