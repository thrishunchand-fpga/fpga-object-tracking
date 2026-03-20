module bbox_overlay(
    input wire [9:0] x,
    input wire [9:0] y,
    input wire [9:0] cx,
    input wire [9:0] cy,
    output wire box
);

    wire [10:0] dx = (x > cx) ? (x - cx) : (cx - x);
    wire [10:0] dy = (y > cy) ? (y - cy) : (cy - y);
    
    wire in_outer = (dx <= 20) && (dy <= 20);
    wire in_inner = (dx < 18) && (dy < 18);
    
    wire cross = (dx == 0 && dy <= 5) || (dy == 0 && dx <= 5);
    
    assign box = (in_outer && !in_inner) || cross;

endmodule