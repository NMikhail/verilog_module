module pwm
#(parameter N = 8)
(
  input             reset,
  input             clock,
  input [N-1:0]     dataHighStart,
  input [N-1:0]     dataHighEnd,
  output        reg out_pwm
);

reg [N-1:0] cnt, dataRegHighStart, dataRegHighEnd;

always @(posedge clock or posedge reset) begin
  if (reset) begin
    cnt               <= 'b0;
    dataRegHighStart  <= 'b0;
    dataRegHighEnd    <= 'b0;
  end
  else begin
    cnt <= cnt + 'b01;
    if (cnt == 'b00) begin
      dataRegHighStart<= dataHighStart;
      dataRegHighEnd  <= dataHighEnd;
    end
    if (dataRegHighStart == dataRegHighEnd)
      out_pwm <= 1'b0;
    else if (cnt == dataRegHighStart)
      out_pwm <= 1'b1;
    else if (cnt == dataRegHighEnd)
      out_pwm <= 1'b0;
  end
end

endmodule;