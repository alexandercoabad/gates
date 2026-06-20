/*
 * Copyright (c) 2024-2025 James Ross
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none

module tt_um_nvious_graphics(
    input  wire [ 7:0 ] ui_in,    // Dedicated inputs
    output wire [ 7:0 ] uo_out,   // Dedicated outputs
    input  wire [ 7:0 ] uio_in,   // IOs: Input path
    output wire [ 7:0 ] uio_out,  // IOs: Output path
    output wire [ 7:0 ] uio_oe,   // IOs: Enable path (active high: 0=input, 1=output)
    input  wire       ena,      // always 1 when the design is powered, so you can ignore it
    input  wire       clk,      // clock
    input  wire       rst_n     // reset_n - low to reset
);

    // VGA signals
    wire hsync;
    wire vsync;
    reg  [ 5:0 ] RGB;             
    wire video_active;
    wire [ 9:0 ] x;
    wire [ 9:0 ] y;

    // TinyVGA PMOD formatted with exact spacing constraints
    assign uo_out = {hsync, RGB [ 0 ], RGB [ 2 ], RGB [ 4 ], vsync, RGB [ 1 ], RGB [ 3 ], RGB [ 5 ]};

    // Suppress unused signals warning
    wire _unused_ok = &{ena, uio_in};

    reg show;
    reg [ 9:0 ] counter;
    
    // Always active scrolling state fallback
    wire [ 7:0 ] led = (ui_in [ 4:0 ] != 5'b00000) ? ui_in : countdown [ counter [ 8:5 ] ];

    reg [ 7:0 ] countdown [ 15:0 ];
    initial begin
        countdown [ 0 ]  = 8'b01110011; // P
        countdown [ 1 ]  = 8'b00000110; // I
        countdown [ 2 ]  = 8'b00111000; // L
        countdown [ 3 ]  = 8'b00000110; // I
        countdown [ 4 ]  = 8'b01110011; // P
        countdown [ 5 ]  = 8'b00000110; // I
        countdown [ 6 ]  = 8'b00110111; // N
        countdown [ 7 ]  = 8'b01110111; // A
        countdown [ 8 ]  = 8'b01101101; // S
        countdown [ 9 ]  = 8'b00111000; // L
        countdown [ 10 ] = 8'b01110111; // A
        countdown [ 11 ] = 8'b01101101; // S
        countdown [ 12 ] = 8'b01110111; // A
        countdown [ 13 ] = 8'b00111000; // L
        countdown [ 14 ] = 8'b00111000; // L
        countdown [ 15 ] = 8'b01111001; // E
    end

    // VGA output
    hvsync_generator hvsync_gen(
        .clk(clk),
        .reset(~rst_n),
        .hsync(hsync),
        .vsync(vsync),
        .display_on(video_active),
        .hpos(x),
        .vpos(y)
    );

    // ------------------------------------------------------------------------
    // LAYER 1: ORIGINAL 7-SEGMENT SPATIAL INTERSECTION GEOMETRY (Default View)
    // ------------------------------------------------------------------------
    wire a0 = y > 7;
    wire a1 = x < y + 392;
    wire a2 = 454 - x > y;
    wire a3 = y < 56;
    wire a4 = x > y + 185;
    wire a5 = x > 247 - y;
    wire a = a0 & a1 & a2 & a3 & a4 & a5;

    wire b0 = a1;
    wire b1 = x < 448;
    wire b2 = 662 - x > y;
    wire b3 = a4;
    wire b4 = x > 399;
    wire b5 = 455 - x < y;
    wire b = b0 & b1 & b2 & b3 & b4 & b5;

    wire c0 = x < y + 184;
    wire c1 = b1;
    wire c2 = 872 - x > y;
    wire c3 = x + 23 > y;
    wire c4 = b4;
    wire c5 = 663 - x < y;
    wire c = c0 & c1 & c2 & c3 & c4 & c5;

    wire d0 = y > 423;
    wire d1 = y > x + 24; 
    wire d2 = c2;
    wire d3 = y < 472;
    wire d4 = x > y - 232;
    wire d5 = c5;
    wire d = d0 & d1 & d2 & d3 & d4 & d5;

    wire e0 = d1;
    wire e1 = x < 240;
    wire e2 = b2;
    wire e3 = d4;
    wire e4 = x > 191;
    wire e5 = b5;
    wire e = e0 & e1 & e2 & e3 & e4 & e5;

    wire f0 = c0;
    wire f1 = e1;
    wire f2 = a2;
    wire f3 = c3;
    wire f4 = e4;
    wire f5 = a5;
    wire f = f0 & f1 & f2 & f3 & f4 & f5;

    wire g0 = y > 215;
    wire g1 = c0;
    wire g2 = b2;
    wire g3 = y < 262;
    wire g4 = f3;
    wire g5 = e5;
    wire g = g0 & g1 & g2 & g3 & g4 & g5;

    wire text_pixel = ((a & led [ 0 ]) | (b & led [ 1 ]) | (c & led [ 2 ]) | (d & led [ 3 ]) | (e & led [ 4 ]) | (f & led [ 5 ]) | (g & led [ 6 ]));

    // ------------------------------------------------------------------------
    // LAYER 2: UPGRADED LOGIC GATE GEOMETRY (Signed 32-bit Screen Space)
    // ------------------------------------------------------------------------
    
    // Convert 10-bit hardware wires to 32-bit signed integers for intermediate geometric math
    wire signed [ 31:0 ] xi = {22'b0, x};
    wire signed [ 31:0 ] yi = {22'b0, y};

    // Structural Input/Output connection wires
    wire wire_in         = (y >= 238 && y <= 242) && (x >= 160 && x < 240);
    wire wire_out_normal = (y >= 238 && y <= 242) && (x > 340 && x <= 420);
    wire wire_out_bubble = (y >= 238 && y <= 242) && (x > 355 && x <= 440);
    wire dual_in_wires   = (x >= 160 && x < 240) && ((y >= 208 && y <= 212) || (y >= 268 && y <= 272));

    // Standard round inversion bubble for NOT, NAND, NOR, XNOR (Radius = 8 -> 8^2 = 64)
    wire round_bubble = ((xi - 348) * (xi - 348) + (yi - 240) * (yi - 240)) <= 64; 

    // ------------------------------------------------------------------------
    // LAYER 3: DYNAMIC BOLD TEXT DATA INTERACTION (3-Pixel Wide Strokes)
    // ------------------------------------------------------------------------
    
    // --- SINGLE-INPUT LABELS (For Inverter Mode) ---
    wire s_in_box  = (x >= 134 && x <= 156) && (y >= 198 && y <= 222);
    wire s_in_char0  = s_in_box && ((x >= 134 && x <= 136) || (x >= 154 && x <= 156) || (y >= 198 && y <= 200) || (y >= 220 && y <= 222));
    wire s_in_char1  = s_in_box && (x >= 144 && x <= 146);

    // --- DUAL-INPUT LABELS (For NAND, NOR, etc. Modes) ---
    // Top Input Box Bounds (Centered vertically around Y = 210, horizontally at X = 135 to 155)
    wire top_in_box   = (x >= 134 && x <= 156) && (y >= 168 && y <= 192);
    wire top_in_char0 = top_in_box && ((x >= 134 && x <= 136) || (x >= 154 && x <= 156) || (y >= 168 && y <= 170) || (y >= 190 && y <= 192));
    wire top_in_char1 = top_in_box && (x >= 144 && x <= 146);

    // Bottom Input Box Bounds (Shifted up by 12 pixels from Y:248-272 to Y:236-260)
    wire bot_in_box   = (x >= 134 && x <= 156) && (y >= 236 && y <= 260);
    wire bot_in_char0 = bot_in_box && ((x >= 134 && x <= 136) || (x >= 154 && x <= 156) || (y >= 236 && y <= 238) || (y >= 258 && y <= 260));
    wire bot_in_char1 = bot_in_box && (x >= 144 && x <= 146);

    // --- COMMON OUTPUT LABEL ---
    wire out_text_box = (x >= 409 && x <= 431) && (y >= 198 && y <= 222);
    wire out_char0    = out_text_box && ((x >= 409 && x <= 411) || (x >= 429 && x <= 431) || (y >= 198 && y <= 200) || (y >= 220 && y <= 222));
    wire out_char1    = out_text_box && (x >= 419 && x <= 421);

    // Dynamic state signals assigned to color buses based on current gate type
    reg active_0_pixel;
    reg active_1_pixel;

    // 1. INVERTER (NOT) GATE WITH DYNAMIC INTERACTIVE LABELS
    wire inv_triangle = (x >= 240 && x <= 340) && (y >= 240 - (340 - x)/2) && (y <= 240 + (340 - x)/2);
    wire g_inverter   = wire_in || inv_triangle || round_bubble || wire_out_bubble;

    // 2. NAND GATE (Straight body extending into a smooth half-circle, Radius = 50 -> 50^2 = 2500)
    wire nand_straight = (x >= 240 && x <= 290) && (y >= 190 && y <= 290);
    wire nand_circle   = ((xi - 290) * (xi - 290) + (yi - 240) * (yi - 240)) <= 2500 && (x >= 290); 
    wire g_nand         = dual_in_wires || nand_straight || nand_circle || round_bubble || wire_out_bubble;

    // 3. NOR GATE (Flawless classic inward-curving crescent formulation)
    wire signed [ 31:0 ] dy = (yi > 240) ? (yi - 240) : (240 - yi);
    
    // Front sweeping point boundary equation
    wire nor_front = xi <= (340 - (dy * dy) / 25);
    // Concave back crescent wall equation (curves inward to the right)
    wire nor_back  = xi >= (265 - (dy * dy) / 100);
    
    wire nor_body  = (x >= 240 && x <= 340) && (y >= 190 && y <= 290) && nor_front && nor_back;
    wire g_nor     = dual_in_wires || nor_body || round_bubble || wire_out_bubble;

    // 4. XOR GATE (Reuses smooth NOR body with a perfectly matched separate back tracking wire)
    wire xor_track = (xi >= (245 - (dy * dy) / 100)) && (xi <= (253 - (dy * dy) / 100)) && (y >= 190 && y <= 290);
    wire g_xor     = dual_in_wires || xor_track || nor_body || wire_out_normal;

    // 5. XNOR GATE
    wire g_xnor    = dual_in_wires || xor_track || nor_body || round_bubble || wire_out_bubble;

    // ------------------------------------------------------------------------
    // DISPLAY ROUTING MIXER & COLOR ENGINE
    // ------------------------------------------------------------------------
    reg gate_shape;
    always @* begin
        if (ui_in [ 0 ])      gate_shape = g_inverter;
        else if (ui_in [ 1 ]) gate_shape = g_nand;
        else if (ui_in [ 2 ]) gate_shape = g_nor;
        else if (ui_in [ 3 ]) gate_shape = g_xnor;
        else if (ui_in [ 4 ]) gate_shape = g_xor;
        else                  gate_shape = 1'b0; 
    end

    // Direct logic generation combining live interface buttons for the text grid
    reg current_gate_out; // Real-time computed pure binary logic bit
    
    always @* begin
        // Safe default resets
        active_0_pixel   = 1'b0;
        active_1_pixel   = 1'b0;
        current_gate_out = 1'b0;

        if (ui_in [ 0 ]) begin
            // Inverter Mode
            current_gate_out = !ui_in [ 6 ];
            active_0_pixel   = ui_in [ 6 ] ? out_char0 : s_in_char0;
            active_1_pixel   = ui_in [ 6 ] ? s_in_char1  : out_char1;
        end else if (ui_in [ 1 ]) begin
            // NAND Gate Mode: Output = ~(ui_in & ui_in)
            current_gate_out = !(ui_in [ 6 ] && ui_in [ 7 ]);
            active_0_pixel   = (!ui_in [ 6 ] ? top_in_char0 : 1'b0) |
                               (!ui_in [ 7 ] ? bot_in_char0 : 1'b0) |
                               ((ui_in [ 6 ] && ui_in [ 7 ]) ? out_char0 : 1'b0);
            
            active_1_pixel   = (ui_in [ 6 ] ? top_in_char1 : 1'b0) |
                               (ui_in [ 7 ] ? bot_in_char1 : 1'b0) |
                               (!(ui_in [ 6 ] && ui_in [ 7 ]) ? out_char1 : 1'b0);
        end else if (ui_in [ 2 ]) begin
            // NOR Gate Mode: Output = ~(ui_in | ui_in)
            current_gate_out = !(ui_in [ 6 ] || ui_in [ 7 ]);
            active_0_pixel   = (!ui_in [ 6 ] ? top_in_char0 : 1'b0) |
                               (!ui_in [ 7 ] ? bot_in_char0 : 1'b0) |
                               ((ui_in [ 6 ] || ui_in [ 7 ]) ? out_char0 : 1'b0);
            
            active_1_pixel = (ui_in [ 6 ] ? top_in_char1 : 1'b0) |
                             (ui_in [ 7 ] ? bot_in_char1 : 1'b0) |
                             (!(ui_in [ 6 ] || ui_in [ 7 ]) ? out_char1 : 1'b0);
        end else if (ui_in [ 3 ]) begin
            // XNOR Gate Mode: Output = (ui_in == ui_in)
            current_gate_out = (ui_in [ 6 ] == ui_in [ 7 ]);
            active_0_pixel   = (!ui_in [ 6 ] ? top_in_char0 : 1'b0) |
                               (!ui_in [ 7 ] ? bot_in_char0 : 1'b0) |
                               ((ui_in [ 6 ] ^ ui_in [ 7 ]) ? out_char0 : 1'b0);
            
            active_1_pixel = (ui_in [ 6 ] ? top_in_char1 : 1'b0) |
                             (ui_in [ 7 ] ? bot_in_char1 : 1'b0) |
                             (!(ui_in [ 6 ] ^ ui_in [ 7 ]) ? out_char1 : 1'b0);
        end else if (ui_in [ 4 ]) begin
            // XOR Gate Mode: Output = (ui_in ^ ui_in)
            current_gate_out = (ui_in [ 6 ] ^ ui_in [ 7 ]);
            active_0_pixel   = (!ui_in [ 6 ] ? top_in_char0 : 1'b0) |
                               (!ui_in [ 7 ] ? bot_in_char0 : 1'b0) |
                               (!(ui_in [ 6 ] ^ ui_in [ 7 ]) ? out_char0 : 1'b0);
            
            active_1_pixel = (ui_in [ 6 ] ? top_in_char1 : 1'b0) |
                             (ui_in [ 7 ] ? bot_in_char1 : 1'b0) |
                             ((ui_in [ 6 ] ^ ui_in [ 7 ]) ? out_char1 : 1'b0);
        end
    end

    // ------------------------------------------------------------------------
    // HARDWARE ONBOARD 7-SEGMENT OUTPUT DRIVER (VIA uio_out CONTROLLER)
    // ------------------------------------------------------------------------
    wire gate_mode_active = (ui_in [ 4:0 ] != 5'b00000);
    
    // Drive '0' or '1' font if gate active, otherwise drive current character from scroll ROM
    assign uio_out = gate_mode_active ? (current_gate_out ? 8'b00000110 : 8'b00111111) 
                                      : countdown [ counter [ 8:5 ] ];
    
    // The bidirectional IO port should ALWAYS act as an active output bus now!
    assign uio_oe  = 8'b11111111;

    // Define raw color values (6-bit RGB format: RRRGGG)
    wire [ 5:0 ] color_black = 6'b000000;
    wire [ 5:0 ] color_cyan  = 6'b011111;
    wire [ 5:0 ] color_red   = 6'b110000;
    wire [ 5:0 ] color_green = 6'b001100;

    // Gated Multiplexer dealing with multiple color layer priorities
    always @* begin
        if (!video_active) begin
            RGB = color_black;
        end else begin
            // Render gate graphic ONLY if one of the selection pins is active
            if (gate_mode_active) begin
                if (active_0_pixel)      RGB = color_red;   
                else if (active_1_pixel) RGB = color_green; 
                else if (gate_shape)     RGB = color_cyan;  
                else                     RGB = color_black;
            // Immediate fallback to the 7-segment scroll pattern
            end else begin
                RGB = text_pixel ? color_cyan : color_black;
            end
        end
    end

    always @(posedge vsync, negedge rst_n) begin
        if (~rst_n) begin
            show <= 0;
            counter <= 0;
        end else begin
            show <= show | ui_in [ 0 ] | ui_in [ 1 ] | ui_in [ 2 ] | ui_in [ 3 ] | ui_in [ 4 ] | ui_in [ 5 ] | ui_in [ 6 ] | ui_in [ 7 ];
            counter <= counter + 1;
        end
    end

endmodule