// 4-piece PCB perimeter frame rails with 45° miter ends + press-fit pegs
// - PCB slides into U-channel in each rail
// - Rails have 45° miter ends so corners meet cleanly
// - Each corner has alignment pegs + matching holes (press fit + optional glue)
// - Legs on ONLY the bottom rail so PCB stands vertical (slight lean adjustable)
//
// PCB: 90 x 70 x 1.5 mm
// Units: mm

// ---------------- PCB ----------------
pcb_x  = 90;
pcb_y  = 70;
pcb_t  = 1.5;

// ---------------- Channel fit ----------------
slot_clear = 0.35;        // clearance around PCB thickness
slot_depth = 6.0;         // insertion depth into rail (>= pcb_t)
rail_depth = 12.0;        // rail depth (front->back, Z)
outer_h    = 14.0;        // rail height (Y)
wall       = 3.0;         // rail wall thickness around slot
face_top   = 4.0;         // "picture frame" face above the slot (Y)

// ---------------- Corner miter / assembly ----------------
miter = 45;               // keep 45
corner_setback = 0.0;     // increase if you want a tiny gap at corners

// Pegs/holes for corners
peg_d = 2.6;              // peg diameter (tune for your printer)
peg_len = 4.0;            // peg protrusion
peg_clear = 0.20;         // hole clearance over peg_d
peg_offset = 6.0;         // from miter plane inward along length
peg_z = rail_depth*0.55;  // peg depth location in Z
peg_y = outer_h*0.50;     // peg height location in Y
pegs_per_corner = 2;      // 1 or 2

// ---------------- Legs (bottom rail only) ----------------
legs_enable = true;
leg_w   = 18.0;           // along rail length
leg_th  = 3.0;
leg_len = 45.0;           // sticks back in Z
leg_drop= 16.0;           // drops down in Y (toward table)
leg_inset_from_end = 18.0;// from rail end
lean_deg = 8;             // positive leans frame backward (more stable)

// ---------------- Rendering ----------------
part = "assembly"; // "top", "bottom", "left", "right", "assembly"

// ---------------- Derived ----------------
slot_w = pcb_t + 2*slot_clear;

// Miter makes each rail shorter by its cross-section thickness projected.
// We want the *inner opening* to match pcb_x/pcb_y, so we compute inner spans
inner_x = pcb_x;   // visible/fit opening span between left/right rails (X)
inner_y = pcb_y;   // span between top/bottom rails (Y)

// For simple mitered rectangle using rail thickness in X/Y plane,
// set each rail length = inner_span + 2*(outer_h/2)*tan? (messy).
// Instead: build rails to a target length and assemble by positioning off the PCB.
Lx = pcb_x + 2*wall + 2; // a little extra; miter ends handle exact look
Ly = pcb_y + 2*wall + 2;

// ---------------- Helpers ----------------
module rail_solid(L){
  // Rail blank (rect prism) with U-channel cut
  difference() {
    translate([0, outer_h/2, rail_depth/2])
      cube([L, outer_h, rail_depth], center=true);

    // U-channel slot (runs along X, opens at front Z=0)
    // Slot positioned lower in Y so you get a "frame face" above it.
    slot_yc = (face_top + wall) + slot_w/2;
    translate([0, slot_yc, slot_depth/2])
      cube([L+0.6, slot_w, slot_depth], center=true);

    // Slightly wider mouth for easier insertion
    translate([0, slot_yc, 1.2])
      cube([L+0.6, slot_w+0.6, 2.2], center=true);
  }
}

module miter_end_cut(L, side=+1){
  // Cuts a 45° plane at one end of the rail.
  // side=+1 cuts the +X end, side=-1 cuts the -X end.
  // Implemented by subtracting an angled big cube.
  translate([side*(L/2), 0, 0])
    rotate([0,0, side*45])
      translate([side*60, outer_h/2, rail_depth/2])
        cube([120, outer_h*3, rail_depth*3], center=true);
}

module add_pegs(L, end=+1, orientation="peg"){
  // Place pegs or holes near one end (miter plane region).
  // end=+1 => +X end, end=-1 => -X end
  // orientation="peg" or "hole"
  x0 = end*(L/2 - peg_offset);

  for (i=[0:pegs_per_corner-1]) {
    // stagger pegs slightly in Z to prevent rotation
    dz = (pegs_per_corner==1) ? 0 : (i==0 ? -2.2 : +2.2);

    if (orientation=="peg") {
      translate([x0, peg_y, peg_z + dz])
        rotate([0,90,0])
          cylinder(d=peg_d, h=peg_len, center=false, $fn=36);
    } else {
      translate([x0, peg_y, peg_z + dz])
        rotate([0,90,0])
          cylinder(d=peg_d + peg_clear, h=peg_len + 0.8, center=false, $fn=36);
    }
  }
}

module rail(L, is_bottom=false){
  // One rail with 45° miters both ends, and one-end pegs / other-end holes
  // so corners can press-fit.
  difference(){
    union(){
      rail_solid(L);
      // Pegs at +X end (male)
      add_pegs(L, end=+1, orientation="peg");
    }

    // Miters
    miter_end_cut(L, side=+1);
    miter_end_cut(L, side=-1);

    // Holes at -X end (female)
    add_pegs(L, end=-1, orientation="hole");
  }

  // Legs on bottom rail only
  if (is_bottom && legs_enable){
    // two legs near ends
    for (sx=[-1,1]) {
      x = sx*(L/2 - leg_inset_from_end);
      // leg block behind the rail
      translate([x, wall + slot_w/2 - leg_drop/2, rail_depth + leg_len/2])
        cube([leg_w, leg_drop, leg_len], center=true);

      // brace
      hull() {
        translate([x, wall + slot_w/2, rail_depth*0.55])
          cube([leg_w, leg_th, leg_th], center=true);
        translate([x, wall + slot_w/2 - leg_drop, rail_depth + leg_th])
          cube([leg_w, leg_th, leg_th], center=true);
      }
    }
  }
}

// ---------------- Assembly preview ----------------
module assembly(){
  // PCB preview
  color([0,0.6,0,0.35])
    cube([pcb_x, pcb_y, pcb_t], center=true);

  // Tilt frame slightly back by rotating rails/pcb as a group (preview only)
  rotate([lean_deg,0,0]) {

    // Top / Bottom rails (length along X)
    color("lightgray")  translate([0,  pcb_y/2, 0]) rail(Lx, is_bottom=false);
    color("gainsboro")  translate([0, -pcb_y/2, 0]) rotate([0,0,180]) rail(Lx, is_bottom=true);

    // Left / Right rails (length along Y): rotate rails 90° so their length runs in Y
    color("lightgray")  translate([-pcb_x/2, 0, 0]) rotate([0,0, 90]) rail(Ly, is_bottom=false);
    color("gainsboro")  translate([ pcb_x/2, 0, 0]) rotate([0,0,-90]) rail(Ly, is_bottom=false);
  }
}

// ---------------- Part outputs ----------------
if (part=="top")    rail(Lx, is_bottom=false);
if (part=="bottom") rail(Lx, is_bottom=true);
if (part=="left")   rotate([0,0, 90]) rail(Ly, is_bottom=false);
if (part=="right")  rotate([0,0,-90]) rail(Ly, is_bottom=false);
if (part=="assembly") assembly();
