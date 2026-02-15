// ============================================================
// PCB Picture-Frame Rails — 4 PART EXPORT (TOP/BOTTOM/LEFT/RIGHT)
// - Miters oriented correctly: INNER edge is SHORT, OUTER edge is LONG (picture-frame style)
// - PCB channel captures thickness in Z, opens at INNER edge (Y=0)
// - Short rails (LEFT/RIGHT) have PEGS on both ends
// - Long rails (TOP/BOTTOM) have matching HOLES on both ends
// - Bottom rail has angled legs (attached OUTSIDE, never intrudes into channel)
// - PART selector exports ONE part at a time or a 4-object print plate
//
// PCB: 88 x 68 x 1.5 mm (as you set)
// Units: mm
// ============================================================

// ---------------- EXPORT SELECTOR ----------------
PART = "PLATE";   // "TOP","BOTTOM","LEFT","RIGHT","PLATE"

// ---------------- PCB ----------------
pcb_x = 90-4;
pcb_y = 70-4;
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

// ---------------- Corner press-fit pegs/holes ----------------
// Pegs are on LEFT/RIGHT rails; holes are on TOP/BOTTOM rails.
// Peg axis is NORMAL to the miter face (in XY plane), so they press-fit as the miter closes.
peg_d       = 3;   // peg diameter
peg_len     = 6;   // protrusion length from miter face
peg_clear   = 0.3;  // hole extra diameter (hole_d = peg_d + peg_clear)
peg_inset   = 0.3;   // move peg slightly inward from the face (prevents breakout)
peg_count_z = 2;     // 1 or 2 pegs per end
peg_z_sep   = 5.0;   // separation between pegs along Z (if peg_count_z=2)

// ---------------- Legs (bottom rail only) ----------------
legs_enable   = true;
leg_w         = 10.0;
leg_th        = 4.0;
leg_len       = 40.0;
leg_inset     = 15.0;
leg_angle_deg = 15;
leg_y_out     = 1.25;
leg_y_span    = 4.0;

// ---------------- Inner-edge lengths define opening ----------------
Lx_in = pcb_x; // long rails (top/bottom)
Ly_in = pcb_y; // short rails (left/right)

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
// Pegs / Holes on miter faces
// ============================================================
//
// We place features near the midline of each miter face:
// +X end miter face midpoint ~ (L_in/2 + rail_w/2, rail_w/2)
// -X end miter face midpoint ~ (-L_in/2 - rail_w/2, rail_w/2)
//
// For press-fit, peg axis is normal to the miter face:
// +X face normal ~ ( +1, -1 )  => angle -45°
// -X face normal ~ ( -1, -1 )  => angle -135°
//
// Cylinder is aligned to X axis first (rotate Y 90), then rotated about Z.

module cyl_along_xy(angle_deg, d, h){
  rotate([0,0,angle_deg])
    rotate([0,90,0])
      cylinder(d=d, h=h, center=true, $fn=36);
}

module end_features(L_in, end=+1, make_pegs=true){
  // end=+1 => +X end, end=-1 => -X end
  x_mid = (end==+1) ? ( L_in/2 + rail_w/2) : (-L_in/2 - rail_w/2);
  y_mid = rail_w/2;

  // outward normal direction angle
  ang  = (end==+1) ? -45 : -135;

  d_use = make_pegs ? peg_d : (peg_d + peg_clear);
  h_use = make_pegs ? peg_len : (peg_len + 1.0);

  // small inward shift to avoid breaking out the surface
  // shift is along negative outward normal (i.e., inward)
  // inward direction angles: +X end inward is +135°, -X end inward is +45°
  in_ang = (end==+1) ? 135 : 45;
  dx_in = peg_inset * cos(in_ang);
  dy_in = peg_inset * sin(in_ang);

  for (i=[0:peg_count_z-1]){
    z = (peg_count_z==1) ? 0 : (i==0 ? -peg_z_sep/2 : +peg_z_sep/2);

    translate([x_mid + dx_in, y_mid + dy_in, z])
      cyl_along_xy(ang, d_use, h_use);
  }
}

module add_pegs(L_in){
  // Add pegs on both ends
  end_features(L_in, end=+1, make_pegs=true);
  end_features(L_in, end=-1, make_pegs=true);
}

module cut_holes(L_in){
  // Cut holes on both ends
  end_features(L_in, end=+1, make_pegs=false);
  end_features(L_in, end=-1, make_pegs=false);
}

// ============================================================
// Legs (bottom rail only) — attached OUTSIDE (Y > rail_w)
// ============================================================

module angled_leg_at(xpos){
  y0 = rail_w + leg_y_out;

  translate([xpos, y0, 0])
    rotate([leg_angle_deg,0,0])
      translate([0, -leg_y_span/2, rail_z/2 + leg_len/2])
        cube([leg_w, leg_y_span, leg_len], center=true);
}

// ============================================================
// Rail part builder with optional pegs/holes
// ============================================================

module rail_part(L_in, is_bottom=false, with_pegs=false, with_holes=false){
  difference(){
    union(){
      rail_with_channel(L_in);
      if (with_pegs) add_pegs(L_in);

      if (is_bottom && legs_enable){
        for (sx=[-1,1])
          angled_leg_at(sx*(L_in/2 - leg_inset));
      }
    }
    if (with_holes) cut_holes(L_in);
  }
}

// ============================================================
// Individual rails (4 parts)
// - TOP/BOTTOM (long) have HOLES
// - LEFT/RIGHT (short) have PEGS
// ============================================================

module top_rail()    { rail_part(Lx_in, false, with_pegs=false, with_holes=true ); }
module bottom_rail() { rail_part(Lx_in, true,  with_pegs=false, with_holes=true ); }
module left_rail()   { rail_part(Ly_in, false, with_pegs=true,  with_holes=false); }
module right_rail()  { rail_part(Ly_in, false, with_pegs=true,  with_holes=false); }

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
