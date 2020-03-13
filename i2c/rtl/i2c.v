module i2c(
    input       clock,
    input       reset,
    input [6:0] addr,
    input       rdWr,
    input [7:0] inData,
    input       inValid,
    output      inReady,

    output [7:0]outData,
    output      outValid,
    input       outReady,

    inout       sda,
    inout       scl
);

wire i2c_oe, sda_in, sda_out, scl_in, scl_out;

assign sda = (sda_out | ~i2c_oe)    ? 1'bz : 1'b0;
assign scl = scl_out                ? 1'bz : 1'b0;
assign sda_in = sda;

localparam stateStart = 0, stateStop = 1, state