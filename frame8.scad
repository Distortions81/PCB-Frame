// ============================================================
// PCB Picture-Frame Rails — 4 PART EXPORT (TOP/BOTTOM/LEFT/RIGHT)
// - Miters oriented correctly: INNER edge is SHORT, OUTER edge is LONG (picture-frame style)
// - PCB channel captures thickness in Z, opens at INNER edge (Y=0)
// - Bottom rail has angled legs (attached OUTSIDE, never intrudes into channel)
// - PART selector exports ONE part at a time or a 4-object print plate
//
// PCB: 90 x 70 x 1.5 mm
// Units: mm
// ============================================================

// ---------------- EXPORT SELECTOR ----------------
PART = "PLATE";   // "TOP","BOTTOM","LEFT","RIGHT","PLATE"

// ---------------- PCB ----------------
pcb_x = 88;
pcb_y = 68;
pcb_t = 1.5;

// ---------------- Rail cross-section ----------------
// Local coords (before placement):
// X = length
// Y = border width (inner edge at Y=0, outer at Y=rail_w)
// Z = thickness (centered)
rail_w = 10.0;
rail_z = 10.0;

// ---------------- Channel ----------------
// Captures PCB thickness in Z, open at inner edge (Y=0), seats into +Y
slot_clear = 0.10;
slot_z     = pcb_t + 2*slot_clear;
slot_depth = 3.0;

// ---------------- Legs (bottom rail only) ----------------
legs_enable   = true;
leg_w         = 10.0;
leg_th        = 4.0;
leg_len       = 40.0;
leg_inset     = 15.0;
leg_angle_deg = 5;
leg_y_out     = 0.0;
leg_y_span    = 4.0;

// ---------------- Inner-edge lengths define opening ----------------
Lx_in = pcb_x;
Ly_in = pcb_y;

// ============================================================
// RAIL GEOMETRY — correct miter direction (inner short, outer long)
// ============================================================

module rail_outline_2d(L_in){
  // Inner edge (Y=0) length = L_in (SHORT)
  // Outer edge (Y=rail_w) length = L_in + 2*rail_w (LONG)
  polygon(points=[
    [-L_in/2,           0],
    [ L_in/2,           0],
    [ L_in/2 + rail_w,  rail_w],
    [-L_in/2 - rail_w,  rail_w]
  ]);
}

module rail_solid(L_in){
  linear_extrude(height=rail_z, center=true)
    rail_outline_2d(L_in);
}

module rail_with_channel(L_in){
  difference(){
    rail_solid(L_in);

    // Channel cut: make it long enough to cover the full outer length
    L_outer = L_in + 2*rail_w;

    // Main channel: open at Y=0, seats into +Y by slot_depth, height slot_z in Z.
    translate([0, slot_depth/2 - 0.01, 0])
      cube([L_outer + 4, slot_depth + 0.2, slot_z], center=true);

    // Flared mouth
    translate([0, 0.6, 0])
      cube([L_outer + 4, 1.4, slot_z + 0.6], center=true);
  }
}

// ============================================================
// Legs (bottom rail only) — attached OUTSIDE (Y > rail_w)
// ============================================================

module angled_leg_at(xpos){
  y0 = rail_w + leg_y_out;

  // Leg body (tilted backward)
  translate([xpos, y0, 0])
    rotate([leg_angle_deg,0,0])
      translate([0, -leg_y_span/2, rail_z/2 + leg_len/2])
        cube([leg_w, leg_y_span, leg_len], center=true);

}

module rail_part(L_in, is_bottom=false){
  rail_with_channel(L_in);

  if (is_bottom && legs_enable){
    // Legs positioned relative to INNER length; safe and consistent
    for (sx=[-1,1])
      angled_leg_at(sx*(L_in/2 - leg_inset));
  }
}

// ============================================================
// Individual rails (4 parts)
// ============================================================

module top_rail()    { rail_part(Lx_in, false); }
module bottom_rail() { rail_part(Lx_in, true ); }
module left_rail()   { rail_part(Ly_in, false); }
module right_rail()  { rail_part(Ly_in, false); }

// ============================================================
// Print orientation: channel faces UP (+Z)
// Rotate so +Y becomes +Z. Then lift by rail_w so it's on the bed.
// ============================================================

module top_print()    { translate([0,0,rail_w]) rotate([-90,0,0]) top_rail(); }
module bottom_print() { translate([0,0,rail_w]) rotate([-90,0,0]) bottom_rail(); }
module left_print()   { translate([0,0,rail_w]) rotate([-90,0,0]) left_rail(); }
module right_print()  { translate([0,0,rail_w]) rotate([-90,0,0]) right_rail(); }

// ============================================================
// Print plate (4 separate objects in one STL)
// ============================================================

module plate_print(){
  gap = 18;

  // Conservative spacing
  xshift = max(Lx_in + 2*rail_w, Ly_in + 2*rail_w) + gap;
  yshift = rail_z + gap + 25; // room for legs

  top_print();
  translate([0, -yshift, 0]) bottom_print();
  translate([xshift, 0, 0]) left_print();
  translate([xshift, -yshift, 0]) right_print();
}

// ============================================================
// OUTPUT SELECTOR
// ============================================================

if (PART == "TOP")         top_print();
else if (PART == "BOTTOM") bottom_print();
else if (PART == "LEFT")   left_print();
else if (PART == "RIGHT")  right_print();
else                       plate_print();  // "PLATE"
