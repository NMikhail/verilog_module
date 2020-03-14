module i2c(
    input       clock,
    input       reset,
    input [6:0] addr,
    input       rdWr,
    input       startTxRx,
    input [7:0] inData,
    input       inValid,
    output      inReady,

    output [7:0]outData,
    output      outValid,
    input       outReady,

    inout       sda,
    inout       scl
);

wire i2c_oe, sdaIn, sda_out, sclIn, sclOut;

assign sda = (sda_out | ~i2c_oe)    ? 1'bz : 1'b0;
assign scl = sclOut                 ? 1'bz : 1'b0;
assign sdaIn = sda;
assign sclIn = scl;

localparam  stateIdle = 0, stateStart = 1, stateAddr = 2, stateAck = 3, 
            stateNack = 4, stateTx = 5, stateRx = 6, stateStop = 7;

reg [2:0] state;
wire transactionStart, startDone, addrDone, ackOk, rdwrOp, rxDone, txDone, stopDone;
always @(posedge clock or posedge reset) begin
    if (reset)
        state <= stateIdle;
    else begin
        case (state)
            stateIdle:  if (transactionStart)
                            state <= stateStart;
                        else
                            state <= stateIdle;

            stateStart: if (startDone)
                            state <= stateAddr;
                        else
                            state <= stateStart;

            stateAddr:  if (addrDone)
                            if (ackOk)
                                state <= stateAck;
                            else
                                state <= stateNack;
                        else
                            state <= stateAddr;

            stateAck:   if (transactionDone)
                            state <= stateStop;
                        else
                            if (rdwrOp)
                                state <= stateRx;
                            else
                                state <= stateTx;

            stateNack:  state <= stateStop;

            stateRx:    if (rxDone)
                            if (ackOk)
                                state <= stateAck;
                            else
                                state <= stateNack;
                        else
                            state <= stateRx;

            stateTx:    if (txDone)
                            if (ackOk)
                                state <= stateAck;
                            else
                                state <= stateNack;
                        else
                            state <= stateTx;
            
            stateStop:  if (stopDone)
                            state <= stateIdle;
                        else
                            state <= stateStop;
        endcase
    end
end

//*****scl generation*****
reg [9:0] cntScl;                       //For clock = 100 MHz, scl = 100/1024 MHz
always @(posedge clock) begin
    if (state == stateIdle)
        cntScl <= 10'd0;
    else    
        if (~sclOut | sclIn)            //Check that the pin scl is "1"
            cntScl <= cntScl + 10'd1;
        else
            cntScl <= cntScl;
end
assign sclOut = ~cntScl[9];
assign transactionStart = (stobeStart & sdaIn & sclIn);
assign startDone = ((state == stateStart) & ~sclIn);
assign addrDone = (cntAddr == 4'd9);
assign 

endmodule