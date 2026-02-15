// ============================================================
// PCB Picture-Frame Rails (4 separate objects in one STL)
// - Inside-referenced 45° miters
// - PCB channel captures thickness in Z, opens inward
// - Bottom rail has angled legs (outside channel)
// - Channel faces UP for FDM printing
//
// PCB: 90 x 70 x 1.5 mm
// Units: mm
// ============================================================

// ---------------- PCB ----------------
pcb_x = 90;
pcb_y = 70;
pcb_t = 1.5;

// ---------------- Rail cross-section ----------------
rail_w = 5.0;   // border width (Y)
rail_z = 5.0;   // thickness (Z)

// ---------------- Channel ----------------
slot_clear = 0.10;
slot_z     = pcb_t + 2*slot_clear;
slot_depth = 3.0;

// ---------------- Legs (bottom rail only) ----------------
legs_enable   = true;
leg_w         = 5.0;
leg_th        = 2.0;
leg_len       = 20.0;
leg_inset     = 15.0;
leg_angle_deg = 12;
leg_y_out     = 3.0;
leg_y_span    = 2.0;

// ---------------- Derived ----------------
Lx = pcb_x;
Ly = pcb_y;

// ---------------- Rail geometry ----------------
module rail_outline_2d(L){
  polygon(points=[
    [-L/2,        0],
    [ L/2,        0],
    [ L/2-rail_w, rail_w],
    [-L/2+rail_w, rail_w]
  ]);
}

module rail_solid(L){
  linear_extrude(height=rail_z, center=true)
    rail_outline_2d(L);
}

module rail_with_channel(L){
  difference(){
    rail_solid(L);

    // PCB channel
    translate([0, slot_depth/2 - 0.01, 0])
      cube([L+2, slot_depth+0.2, slot_z], center=true);

    // flared mouth
    translate([0, 0.6, 0])
      cube([L+2, 1.4, slot_z+0.6], center=true);
  }
}

// ---------------- Angled leg ----------------
module angled_leg(xpos){
  y0 = rail_w + leg_y_out;

  translate([xpos, y0, 0])
    rotate([leg_angle_deg,0,0])
      translate([0, -leg_y_span/2, rail_z/2 + leg_len/2])
        cube([leg_w, leg_y_span, leg_len], center=true);

  hull(){
    translate([xpos, rail_w*0.9, rail_z*0.15])
      cube([leg_w, leg_th, leg_th], center=true);
    translate([xpos, y0, rail_z/2 + leg_th/2])
      cube([leg_w, leg_th, leg_th], center=true);
  }
}

module rail_part(L, is_bottom=false){
  rail_with_channel(L);

  if (is_bottom && legs_enable){
    for (sx=[-1,1])
      angled_leg(sx*(L/2 - leg_inset));
  }
}

// ---------------- Rails ----------------
module top_rail()    { rail_part(Lx, false); }
module bottom_rail() { rail_part(Lx, true ); }
module left_rail()   { rail_part(Ly, false); }
module right_rail()  { rail_part(Ly, false); }

// ============================================================
// PRINT ORIENTATION: channel faces UP (+Z)
// ============================================================
module top_print(){
  translate([0,0,rail_w]) rotate([-90,0,0]) top_rail();
}
module bottom_print(){
  translate([0,0,rail_w]) rotate([-90,0,0]) bottom_rail();
}
module left_print(){
  translate([0,0,rail_w]) rotate([-90,0,0]) left_rail();
}
module right_print(){
  translate([0,0,rail_w]) rotate([-90,0,0]) right_rail();
}

// ============================================================
// PRINT PLATE — 4 SEPARATE OBJECTS
// ============================================================
module print_plate_channel_up(){
  gap = 18;
  xshift = max(Lx, Ly) + gap;
  yshift = rail_z + gap + 25; // room for legs

  top_print();
  translate([0, -yshift, 0]) bottom_print();

  translate([xshift, 0, 0]) left_print();
  translate([xshift, -yshift, 0]) right_print();
}

// ---------------- OUTPUT ----------------
print_plate_channel_up();