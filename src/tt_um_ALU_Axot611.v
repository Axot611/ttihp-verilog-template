module tt_um_fsm_tinytapeout (
    input  wire [7:0] ui_in,
    output wire [7:0] uo_out
);

    // Asignación de señales de entrada
    wire clk    = ui_in[6];
    wire rst_n  = ui_in[4];
    wire ena    = ui_in[5];
    wire S      = ui_in[0];
    wire L1     = ui_in[1];
    wire L2     = ui_in[2];
    wire L3     = ui_in[3];

    // Señales internas
    reg [1:0] state;
    wire [1:0] next_state;
    wire GROUND, L1_out, L2_out, L3_out;
    wire VERDE, ROJO;

    // Lógica de transición de estados
    assign next_state[1] = (state[1] & ~S & ~L1 & ~L2 & L3) |
                           (state[1] & ~S & ~L1 & L2 & ~L3) |
                           (state[0] & ~S & ~L1) |
                           (state[0] & L3) |
                           (state[0] & L2) |
                           (state[0] & S & L1) |
                           (state[0] & state[1]);

    assign next_state[0] = (~state[1] & ~S & ~L1 & ~L2 & L3) |
                           (~state[0] & ~state[1] & ~S & ~L1 & L2 & ~L3) |
                           (state[1] & L2 & L3) |
                           (state[1] & S & L3) |
                           (state[1] & S & L2) |
                           (~state[1] & ~S & L1 & ~L2 & ~L3) |
                           (state[0] & ~state[1] & S & ~L1 & ~L2 & ~L3) |
                           (state[1] & L1 & L2) |
                           (state[1] & S & L1) |
                           (state[1] & ~S & ~L1 & ~L2 & ~L3) |
                           (~state[0] & state[1] & L1) |
                           (state[0] & state[1] & L3);

    // Flip-flops de estado
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            state <= 2'b00;
        else if (ena)
            state <= next_state;
    end

    // Lógica de salida
    assign GROUND = ~state[1] & ~state[0];
    assign L1_out = ~state[1] &  state[0];
    assign L2_out =  state[1] & ~state[0];
    assign L3_out =  state[1] &  state[0];

    // Indicadores LED
    assign VERDE = GROUND | L1_out | L2_out | L3_out;
    assign ROJO  = ~VERDE;

    // Asignación de salidas
    assign uo_out = {ROJO, VERDE, L3_out, L2_out, L1_out, GROUND, state[1], state[0]};

endmodule
