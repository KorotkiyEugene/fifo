`timescale 1ns/1ps

module fifo_tb;

parameter FIFO_LENGTH = 4;
parameter DATA_WIDTH = 8;
parameter PERIOD = 10;
parameter MAX_DELAY_READ = 40; // maximum delay in clock cycles between consequtive reads from fifo
parameter MAX_DELAY_WRITE = 10;

parameter DETAILS=1;    //details to console

parameter SEED_DELAY_WRITE = 1; //seed for $random that generates delay
parameter SEED_DELAY_READ = 20;
parameter SEED_DATA = 3; //seed for $random that generates data

parameter RANDOM_DELAY = 1;
parameter RANDOM_DATA = 1;

reg clk, rst_n, push, pop;
reg [DATA_WIDTH-1:0] data_in;
wire [DATA_WIDTH-1:0] data_out;
wire full, empty;

reg [DATA_WIDTH-1:0] written_data[$]; //data written to hardware fifo
reg [DATA_WIDTH-1:0] written_data_tmp;

reg [DATA_WIDTH:0] read_count;  //number of words read from fifo

integer i;
integer random_delay_write, random_delay_read;
integer seed_delay_read = SEED_DELAY_READ;
integer seed_delay_write = SEED_DELAY_WRITE;
integer seed_data = SEED_DATA;

fifo #(.FIFO_LENGTH(FIFO_LENGTH), .DATA_WIDTH(DATA_WIDTH)) 
     dut(.i_clk(clk), 
         .i_rst_n(rst_n), 
         .i_push(push), 
         .i_pop(pop), 
         .i_data(data_in), 
         .o_data(data_out), 
         .o_full(full), 
         .o_empty(empty)
          );

initial begin
 clk = 0;
 forever clk = #(PERIOD/2) !clk; 
end

initial begin
  rst_n = 1'b0;
  push = 1'b0;
  pop = 1'b0; 
  repeat(5) @(negedge clk);
  rst_n = 1'b1;
  $display("*******************************************");
  $display("*          TEST OF FIFO: START            *");
  $display("*            RANDOM_DELAY=%0d             *", RANDOM_DELAY);
  $display("*             RANDOM_DATA=%0d             *", RANDOM_DATA);
  $display("*******************************************");  
  fork
    test_write;
    test_read;
  join
  
  $display("*******************************************");
  $display("*      TEST OF FIFO: SUCCESSFULL END      *");
  $display("*******************************************");
  $finish;
end

task test_write; // this test is for fifos with DATA_WIDTH <= 32
  for(i=0;i<2**DATA_WIDTH;i++) begin
    if(RANDOM_DELAY)begin
      random_delay_write = {$random(seed_delay_write)}%MAX_DELAY_WRITE; // random delay in clock cycles
      repeat(random_delay_write) @(negedge clk);
    end
    if(full===1'b1)begin
      if(DETAILS)$display("------>FIFO FULL<-------");
      wait(!full);
    end
    @(negedge clk);
    push = 1'b1;
    if(RANDOM_DATA) 
      data_in = $random(seed_data);
    else
      data_in = i;
    written_data.push_back(data_in);
    if(DETAILS)
      $display("%0t Writing %0d to fifo", $time, data_in);
    @(negedge clk);  
    push = 1'b0;  
  end
endtask

task test_read;  // this test is for fifos with DATA_WIDTH <= 32
  read_count = 0;
  wait(!empty);
  while(read_count < 2**DATA_WIDTH) begin
    if(RANDOM_DELAY)begin
      random_delay_read = {$random(seed_delay_read)}%MAX_DELAY_READ; // random delay in clock cycles
      repeat(random_delay_read) @(negedge clk);
    end    
    if(empty===1'b1) begin
      if(DETAILS)$display("------>FIFO EMPTY<-------");
      wait(!empty);
    end  
    @(negedge clk);
    pop = 1'b1;
    written_data_tmp = written_data.pop_front;
    if(data_out !== written_data_tmp) begin
      $display("ERROR! Written data=%d  Read data=%d", written_data_tmp, data_out);
      $finish;
    end
    if(DETAILS)
      $display("%0t Reading %0d from fifo", $time,  data_out);
    @(negedge clk);
    pop = 1'b0;
    read_count++;
  end  
endtask

endmodule