`timescale 1ns/1ps
module i2c_tb();
localparam Tclk = 10;



reg clock, reset;
reg [6:0] addr;
reg [7:0] lenMsg;
reg rdWr, startTxRx;
reg [7:0] inData;
reg inValid;
wire inReady;
wire [7:0] outData;
wire outValid;
reg outReady;
wire sda, scl;
wire i2c_sda_oe;
wire i2c_scl_oe;
reg sda_slave;

i2c DUT (clock, reset, addr, lenMsg, rdWr, startTxRx, inData, inValid, inReady, outData, outValid, outReady, sda, scl, i2c_sda_oe, i2c_scl_oe);

assign sda = ~i2c_sda_oe ? sda_slave : 1'bz;
assign scl = i2c_scl_oe ? 1'b1 : 1'bz;

always begin
	clock = 1'b1;
	#(Tclk/2);
	clock = 1'b0;
	#(Tclk/2);
end

initial begin
	reset = 1'b1;
	addr 	= 7'b000_0000; lenMsg = 8'b0000_0000; rdWr = 0; startTxRx = 0; 	sda_slave = 1'b1;//addr
	inData = 8'b0000_0000; inValid = 1'b0; 																//tx
	outReady = 1'b1;																											//rx		
	#(2*Tclk);
	reset = 1'b0;
	#(10*Tclk);
	//Transaction #1 without ack
	addr 	= 7'b001_0000; lenMsg = 8'b0000_0001; rdWr = 0; startTxRx = 1; 	sda_slave = 1'b1;//addr
	inData = 8'b0100_1010; inValid = 1'b1;																//tx
	#(Tclk);
	addr 	= 7'b001_0000; lenMsg = 8'b0000_0001; rdWr = 0; startTxRx = 0; 					//addr
	//Transaction #2 with ack and tx one msg
	#(1024*20*Tclk);
	addr 	= 7'b001_0000; lenMsg = 8'b0000_0001; rdWr = 0; startTxRx = 1; 	sda_slave = 1'b0;//addr
	inData = 8'b0100_1010; inValid = 1'b1;																//tx
	#(Tclk);
	addr 	= 7'b001_0000; lenMsg = 8'b0000_0001; rdWr = 0; startTxRx = 0; 					//addr
	#(1024*40*Tclk);
	sda_slave = 1'b1;//addr
	#(2*Tclk);
	//Transaction #3 with ack and tx two msg
	addr 	= 7'b001_0000; lenMsg = 8'b0000_0010; rdWr = 0; startTxRx = 1; 	sda_slave = 1'b0;//addr
	inData = 8'b0100_1010; inValid = 1'b1;																//tx
	#(Tclk);
	addr 	= 7'b001_0000; lenMsg = 8'b0000_0010; rdWr = 0; startTxRx = 0; 					//addr
	#(1024*60*Tclk);
	sda_slave = 1'b1;//addr
	#(2*Tclk);
	//Transaction #4 with ack and rx msg
	addr 	= 7'b001_0000; lenMsg = 8'b0000_0010; rdWr = 1; startTxRx = 1; 	sda_slave = 1'b1;//addr
	inData = 8'b0100_1010; inValid = 1'b1;																//tx
	#(Tclk);
	addr 	= 7'b001_0000; lenMsg = 8'b0000_0010; rdWr = 1; startTxRx = 0; 					//addr
	#(512*Tclk);
	#(1024*8*Tclk);	sda_slave = 1'b0; //Ack
	#(1024*1*Tclk); sda_slave = 1'b1;
	#(1024*1*Tclk); sda_slave = 1'b0;
	#(1024*1*Tclk); sda_slave = 1'b0;
	#(1024*1*Tclk); sda_slave = 1'b1;
	#(1024*1*Tclk); sda_slave = 1'b0;
	#(1024*1*Tclk); sda_slave = 1'b1;
	#(1024*1*Tclk); sda_slave = 1'b1;
	#(1024*1*Tclk); sda_slave = 1'b1;
	#(1024*60*Tclk);
	sda_slave = 1'b1;//addr
	#(2*Tclk);
end

endmodule