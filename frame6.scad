// Updated: legs moved to OUTER side (Y>rail_w) so they never intrude into the PCB channel,
// and legs are angled for stability.
//
// Only the bottom rail has legs.

pcb_x = 90;
pcb_y = 70;
pcb_t = 1.5;

rail_w = 5;
rail_z = 5;

slot_clear = 0.1;
slot_z     = pcb_t + 2*slot_clear;
slot_depth = 3;

// Legs (bottom rail only)
legs_enable = true;
leg_w     = 5.0;   // along rail length (X)
leg_th    = 2.0;    // thickness (Y direction for brace pieces)
leg_len   = 20.0;   // how far back in Z
leg_drop  = 0.0;    // unused now (kept for compatibility)
leg_inset = 15.0;   // from each end
leg_angle_deg = 12; // tilt legs backward (more stable)
leg_y_out = 3.0;    // how far OUTSIDE the frame (beyond rail_w) the leg root sits
leg_y_span= 2.0;   // leg "height" in Y (downward/foot extent)

mode = "print_plate"; // "print_plate","assembly_preview","top","bottom","left","right"

Lx = pcb_x;
Ly = pcb_y;

module rail_outline_2d(L){
  polygon(points=[
    [-L/2,           0],
    [ L/2,           0],
    [ L/2 - rail_w,  rail_w],
    [-L/2 + rail_w,  rail_w]
  ]);
}

module rail_solid(L){
  linear_extrude(height=rail_z, center=true)
    rail_outline_2d(L);
}

module rail_with_channel(L){
  difference(){
    rail_solid(L);

    // Channel: open at inner edge (Y=0), extends to +Y by slot_depth, height slot_z in Z.
    translate([0, slot_depth/2 - 0.01, 0])
      cube([L + 2, slot_depth + 0.2, slot_z], center=true);

    // Flared mouth
    translate([0, 0.6, 0])
      cube([L + 2, 1.4, slot_z + 0.6], center=true);
  }
}

// Angled leg: attaches OUTSIDE the rail (Y > rail_w), never crosses Y=0..slot_depth region.
module angled_leg_at(xpos){
  // Root position on the OUTER side of the rail
  y0 = rail_w + leg_y_out;
  z0 = rail_z/2; // start near back surface

  // Leg is a rectangular prism rotated about X to tilt backward.
  // Rotate around X changes Y/Z, giving a more stable base.
  translate([xpos, y0, 0])
    rotate([leg_angle_deg, 0, 0])
      translate([0, -leg_y_span/2, rail_z/2 + leg_len/2])
        cube([leg_w, leg_y_span, leg_len], center=true);

  // Brace (a small triangular-ish hull) from outer rail face to leg
  hull(){
    translate([xpos, rail_w*0.90, rail_z*0.15])
      cube([leg_w, leg_th, leg_th], center=true);
    translate([xpos, y0, rail_z/2 + leg_th/2])
      cube([leg_w, leg_th, leg_th], center=true);
  }
}

module rail_part(L, is_bottom=false){
  rail_with_channel(L);

  if (is_bottom && legs_enable){
    for (sx=[-1,1]){
      x = sx*(L/2 - leg_inset);
      angled_leg_at(x);
    }
  }
}

module top_rail()    { rail_part(Lx, is_bottom=false); }
module bottom_rail() { rail_part(Lx, is_bottom=true ); }
module left_rail()   { rail_part(Ly, is_bottom=false); }
module right_rail()  { rail_part(Ly, is_bottom=false); }

module assembly_preview(){
  color([0,0.6,0,0.35]) cube([pcb_x, pcb_y, pcb_t], center=true);

  translate([0, +pcb_y/2, 0]) top_rail();
  translate([0, -pcb_y/2, 0]) rotate([0,0,180]) bottom_rail();
  translate([+pcb_x/2, 0, 0]) rotate([0,0,-90]) right_rail();
  translate([-pcb_x/2, 0, 0]) rotate([0,0, 90]) left_rail();
}

module print_plate(){
  zlift = rail_z/2;
  gap = 26;

  y_plain = rail_w;
  y_leg   = rail_w + leg_y_out + leg_y_span + 2; // conservative

  translate([0, 0, zlift]) top_rail();
  translate([0, -(max(y_plain,y_leg)+gap), zlift]) bottom_rail();

  xshift = max(Lx, Ly) + gap;
  translate([xshift, 0, zlift]) left_rail();
  translate([xshift, -(y_plain+gap), zlift]) right_rail();
}

if (mode=="print_plate")           print_plate();
else if (mode=="assembly_preview") assembly_preview();
else if (mode=="top")              top_rail();
else if (mode=="bottom")           bottom_rail();
else if (mode=="left")             left_rail();
else if (mode=="right")            right_rail();
