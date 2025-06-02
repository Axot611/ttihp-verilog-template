// Top module para Tiny Tapeout
module tt_um_ALU_Axot611 (
    input  wire        clk,      // no usado, pero requerido
    input  wire        rst_n,    // no usado, pero requerido
    input  wire        ena,      // no usado, pero requerido
    input  wire [7:0]  ui_in,    // Entradas: A[7:4], B[3:0], SEL[2:0] (SEL y B comparten bits)
    input  wire [7:0]  uio_in,   // no usado
    output wire [7:0]  uo_out,   // Resultado ALU
    output wire [7:0]  uio_out,  // no usado
    output wire [7:0]  uio_oe    // habilita salida en uio_out (0 = entrada, 1 = salida)
);
    wire [3:0] A = ui_in[7:4];
    wire [3:0] B = ui_in[3:0];
    wire [2:0] SEL = ui_in[2:0];

    wire [7:0] A_ext = {4'b0000, A};
    wire [7:0] B_ext = {4'b0000, B};

    wire [7:0] RESULT;
    wire ZERO, NEGATIVE, CARRY;

    alu_8bit alu (
        .A(A_ext),
        .B(B_ext),
        .SEL(SEL),
        .RESULT(RESULT),
        .ZERO(ZERO),
        .NEGATIVE(NEGATIVE),
        .CARRY(CARRY)
    );

    assign uo_out  = RESULT;
    assign uio_out = 8'b00000000; // No se usa, así que en 0
    assign uio_oe  = 8'b00000000; // Desactiva todos los pines de uio como salida
endmodule

// ALU completa
module alu_8bit (
    input wire [7:0] A,
    input wire [7:0] B,
    input wire [2:0] SEL,
    output wire [7:0] RESULT,
    output wire ZERO,
    output wire NEGATIVE,
    output wire CARRY
);
    wire [7:0] SUMA_RESTA;
    wire [7:0] AND_OUT;
    wire [7:0] OR_OUT;
    wire [7:0] SL_OUT;
    wire [7:0] SR_OUT;
    wire COUT;

    alu_suma_resta_8bit sr_unit (.A(A), .B(B), .SEL(SEL[2]), .RESULT(SUMA_RESTA), .COUT(COUT));
    and_8bit and_unit (.A(A), .B(B), .Y(AND_OUT));
    or_8bit or_unit (.A(A), .B(B), .Y(OR_OUT));
    shift_left_8bit sl_unit (.A(A), .Y(SL_OUT));
    shift_right_8bit sr_unit2 (.A(A), .Y(SR_OUT));

    alu_mux mux_unit (
        .SEL(SEL),
        .SUMA_RESTA(SUMA_RESTA),
        .AND_OUT(AND_OUT),
        .OR_OUT(OR_OUT),
        .SL_OUT(SL_OUT),
        .SR_OUT(SR_OUT),
        .RESULT(RESULT)
    );

    FlagsUnit flags_unit (.RESULT(RESULT), .COUT(COUT), .ZERO(ZERO), .NEGATIVE(NEGATIVE), .CARRY(CARRY));
endmodule

// Suma/Resta 8 bits
module alu_suma_resta_8bit (
    input wire [7:0] A,
    input wire [7:0] B,
    input wire SEL,
    output wire [7:0] RESULT,
    output wire COUT
);
    wire [7:0] B_xor;
    wire CIN;

    assign B_xor = B ^ {8{SEL}};
    assign CIN = SEL;

    PrefixAdder8bit adder (
        .A(A),
        .B(B_xor),
        .CIN(CIN),
        .SUM(RESULT),
        .COUT(COUT)
    );
endmodule

// AND 8 bits
module and_8bit (
    input wire [7:0] A,
    input wire [7:0] B,
    output wire [7:0] Y
);
    assign Y = A & B;
endmodule

// OR 8 bits
module or_8bit (
    input wire [7:0] A,
    input wire [7:0] B,
    output wire [7:0] Y
);
    assign Y = A | B;
endmodule

// Shift Left 8 bits
module shift_left_8bit (
    input wire [7:0] A,
    output wire [7:0] Y
);
    assign Y = A << 1;
endmodule

// Shift Right 8 bits
module shift_right_8bit (
    input wire [7:0] A,
    output wire [7:0] Y
);
    assign Y = A >> 1;
endmodule

// Mux de salida ALU
module alu_mux (
    input wire [2:0] SEL,
    input wire [7:0] SUMA_RESTA,
    input wire [7:0] AND_OUT,
    input wire [7:0] OR_OUT,
    input wire [7:0] SL_OUT,
    input wire [7:0] SR_OUT,
    output reg [7:0] RESULT
);
    always @(*) begin
        case (SEL)
            3'b000: RESULT = SUMA_RESTA;
            3'b001: RESULT = AND_OUT;
            3'b010: RESULT = OR_OUT;
            3'b011: RESULT = SL_OUT;
            3'b100: RESULT = SR_OUT;
            default: RESULT = 8'b00000000;
        endcase
    end
endmodule

// Unidad de Banderas
module FlagsUnit (
    input wire [7:0] RESULT,
    input wire COUT,
    output wire ZERO,
    output wire NEGATIVE,
    output wire CARRY
);
    assign ZERO = (RESULT == 8'b00000000) ? 1'b1 : 1'b0;
    assign NEGATIVE = RESULT[7];
    assign CARRY = COUT;
endmodule

// Sumador Prefix 8 bits
module PrefixAdder8bit (
    input wire [7:0] A,
    input wire [7:0] B,
    input wire CIN,
    output wire [7:0] SUM,
    output wire COUT
);
    wire [7:0] G, P, C;

    assign G = A & B;
    assign P = A ^ B;

    assign C[0] = CIN;
    assign C[1] = G[0] | (P[0] & C[0]);
    assign C[2] = G[1] | (P[1] & C[1]);
    assign C[3] = G[2] | (P[2] & C[2]);
    assign C[4] = G[3] | (P[3] & C[3]);
    assign C[5] = G[4] | (P[4] & C[4]);
    assign C[6] = G[5] | (P[5] & C[5]);
    assign C[7] = G[6] | (P[6] & C[6]);
    assign COUT = G[7] | (P[7] & C[7]);

    assign SUM[0] = P[0] ^ C[0];
    assign SUM[1] = P[1] ^ C[1];
    assign SUM[2] = P[2] ^ C[2];
    assign SUM[3] = P[3] ^ C[3];
    assign SUM[4] = P[4] ^ C[4];
    assign SUM[5] = P[5] ^ C[5];
    assign SUM[6] = P[6] ^ C[6];
    assign SUM[7] = P[7] ^ C[7];
endmodule
