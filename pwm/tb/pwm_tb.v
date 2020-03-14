`timescale 1ns/1ps
module pwm_tb
#(parameter N = 8)
();

localparam Tclk = 10;
reg   clock, reset;
reg   [N-1:0] dataHighStart, dataHighEnd;
wire  out_pwm;

pwm #(N) DUT (reset, clock, dataHighStart, dataHighEnd, out_pwm);


initial begin
  reset <= 1'b1;
  #(3*Tclk);
  reset <= 1'b0;
  #(2*Tclk);
  dataHighStart <= 50;
  dataHighEnd   <= 60;
  #(3*2**N*Tclk);
  dataHighStart <= 50;
  dataHighEnd   <= 150;
  #(3*2**N*Tclk);
  dataHighStart <= 60;
  dataHighEnd   <= 50;
  #(3*2**N*Tclk);
  dataHighStart <= 0;
  dataHighEnd   <= 45;
  #(3*2**N*Tclk);
  $finish;
end

always begin
  clock <= 1'b1;
  #(Tclk/2);
  clock <= 1'b0;
  #(Tclk/2);  
end
endmodule