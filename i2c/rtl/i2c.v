module i2c(
    input       clock,
    input       reset,

    input [6:0] addr,
    input [7:0] lenMsg,
    input       rdWr,
    input       startTxRx,

    input [7:0] inData,
    input       inValid,
    output      reg inReady,

    output reg [7:0]	outData,
    output      reg outValid,
    input       outReady,

    inout       sda,
    inout       scl
);

wire i2c_oe, sdaIn, sclIn;
reg sclOut, sdaOut;

assign sda = (sdaOut | ~i2c_oe)    ? 1'b1 : 1'b0;   //for debug only
assign scl = sclOut                 ? 1'b1 : 1'b0;  //for debug only
// assign sda = (sdaOut | ~i2c_oe)    ? 1'bz : 1'b0;
// assign scl = sclOut                 ? 1'bz : 1'b0;
assign sdaIn = sda;
assign sclIn = scl;

localparam  stateIdle = 0, stateStart = 1, stateAddr = 2, stateAck = 3, 
            stateNack = 4, stateTx = 5, stateRx = 6, stateStop = 7;

reg [2:0] state;
wire transactionStart, transactionDone, startDone, addrDone, rxDone, txDone;
reg rdwrOp, ackOk, stopDone;
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
reg sclOutDelay, sclLowStrobe, sclHighStrobe;

always @(posedge clock) begin
    if (state == stateIdle) begin
        cntScl <= 10'd0;
        sclOut <= 1'b1;
    end
    else begin
        if (~sclOut | sclIn)            //Check that the pin scl is "1"
            cntScl <= cntScl + 10'd1;
        else
            cntScl <= cntScl;
        sclOut      <= ~cntScl[9];
        sclOutDelay <= sclOut;
        sclLowStrobe<= ~sclOut & sclOutDelay;
        sclHighStrobe<= sclOut & ~sclOutDelay;
    end
end

//*****addr and rdwr signal capture*****
//addr transaction regs
reg [7:0] addrReg;
reg [7:0] lenMsgReg;
reg [7:0] cntMsg;
reg [3:0] cntAddr;
//rx transaction regs
reg [7:0] rxReg;
reg [3:0] cntRx;
//tx transaction regs
reg [7:0] txReg;
reg [3:0] cntTx;

assign i2c_oe = (((cntAddr < 4'd9) & (state == stateAddr) | (state == stateStart)) | ((cntTx < 4'd8) & (state == stateTx))) ? 1'b1 : 1'b0;

always @(posedge clock) begin
    case (state)
        stateIdle:  begin
                        stopDone <= 1'b0;
                        cntAddr <= 4'd0;
                        addrReg <= 8'h00;
                        cntMsg  <= 8'd0;
                        lenMsgReg<= 8'd0;
                        rdwrOp  <= 1'b0;
                        if (transactionStart) begin
                            cntAddr <= 4'd0;
                            addrReg <= {addr, rdWr};
                            cntMsg  <= 8'd0;
                            lenMsgReg<= lenMsg;
                            rdwrOp  <= rdWr;
                        end
                    end

        stateStart: begin
                        sdaOut <= 1'b0;
                    end

        stateAddr:  begin
                        if (sclHighStrobe)
                            cntAddr <= cntAddr + 4'd1;
                        if (sclLowStrobe) begin                            
                            if (cntAddr < 4'd8) begin
                                addrReg <= {addrReg[6:0], 1'b0};
                                sdaOut  <= addrReg[7];
                            end
                        end
                        if (sclHighStrobe & (cntAddr == 4'd9)) begin
                            cntAddr <= cntAddr + 4'd1;
                            ackOk <= ~sdaIn;
                        end
                    end

        stateAck:   begin
                        cntRx <= 4'd0;
                        cntTx <= 4'd0;
                        if (inValid)
                            txReg <= inData;
                        inReady <= 1'b1; 
                        outValid<= 1'b0;
                    end

        stateRx:    if (sclHighStrobe) begin 
                        cntRx <= cntRx + 4'd1;
                        if (cntRx < 4'd8)  
                            rxReg <= {rxReg[6:0], sdaIn};
                        else begin
                            ackOk <= ~sdaIn;
                            if (outReady) begin
                                outValid<= 1'b1;
                                outData <= rxReg;
                            end
                        end
                    end

        stateTx:    begin
                        inReady <= 1'b0;
                        if (sclLowStrobe) begin
                            cntTx <= cntTx + 4'd1;
                            if (cntTx < 4'd8) begin
                                txReg <= {txReg[6:0], 1'b0};
                                sdaOut<= txReg[7];
                            end
                        end
                        if (sclHighStrobe & (cntTx == 4'd8)) begin
                            cntMsg<= cntMsg + 4'd1;
                            cntTx <= cntTx + 4'd1;
                            ackOk <= ~sdaIn;
                        end
                    end

        stateStop:  begin
                        if (sclLowStrobe)
                            sdaOut <= 1'b0;
                        if (sclHighStrobe) begin
                            sdaOut <= 1'b1;
                            stopDone <= 1'b1;
                        end
                    end
    endcase
end

//*****control signal generation*****
assign transactionStart = (startTxRx & sdaIn & sclIn);
assign startDone = ((state == stateStart) & ~sclIn);
assign addrDone = (cntAddr == 4'd10);
assign transactionDone = ((rdwrOp == 1'b0) & cntMsg == lenMsgReg);
assign rxDone   = (cntRx == 4'd10);
assign txDone   = (cntTx == 4'd10);

endmodule                                                                                