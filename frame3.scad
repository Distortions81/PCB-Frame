// 4-piece PCB picture-frame rails (U-channel) with 45° miters + peg/hole corners
// Fixes:
// - Assembly preview uses correct rail placement (no weird rotations)
// - "print_plate" lays all parts out separated so nothing intersects for printing
//
// PCB: 90 x 70 x 1.5 mm
// Units: mm

// ---------------- PCB ----------------
pcb_x  = 90;
pcb_y  = 70;
pcb_t  = 1.5;

// ---------------- Channel fit ----------------
slot_clear = 0.35;        // clearance around PCB thickness
slot_depth = 7.0;         // how deep PCB edge seats into channel (inward)
outer_depth = 12.0;       // rail depth (out of PCB plane)
outer_w = 14.0;           // rail face width (from inside edge outward)
outer_th = 12.0;          // rail thickness (in PCB plane, i.e., "border thickness")

// Slot geometry (U-channel)
slot_w = pcb_t + 2*slot_clear; // channel opening width

// ---------------- Miters ----------------
miter_deg = 45;

// ---------------- Pegs/Holes ----------------
peg_d     = 2.6;
peg_len   = 4.5;
peg_clear = 0.25;   // hole diameter = peg_d + peg_clear
peg_offset = 7.0;   // from miter plane inward
peg_sep   = 4.5;    // separation between the 2 pegs along depth
pegs_per_end = 2;   // 1 or 2

// ---------------- Legs (bottom rail only) ----------------
legs_enable = true;
leg_w   = 18.0;   // along rail length
leg_th  = 3.0;
leg_len = 50.0;   // sticks backward
leg_drop= 18.0;   // drops down (for stability)
leg_inset = 18.0; // from each end

// ---------------- Output ----------------
part = "assembly"; // "top","bottom","left","right","print_plate","assembly"

// ============================================================================
// Coordinate system for rails:
// - Rail length is along +X (in its local space)
// - PCB edge inserts along local -Y into the slot (slot opens to -Y)
// - Rail "border thickness" is along +Y (outside of PCB)
// - Rail depth (front/back) is along +Z
//
// Assembly places the PCB centered at origin in XY plane, thickness in Z.
// Rails are placed around PCB edges with their slot opening facing inward.
// ============================================================================

// ---------------- Helpers ----------------
module peg_or_hole(is_peg=true){
  d = is_peg ? peg_d : (peg_d + peg_clear);
  // peg/hole runs in X direction (into the mating rail end)
  rotate([0,90,0]) cylinder(d=d, h=(peg_len + (is_peg?0:0.8)), $fn=36);
}

module rail_blank(L){
  // Solid block: [L, outer_th, outer_depth] with the inside edge at Y=0
  // We build centered in Z, but with Y spanning [0..outer_th]
  translate([0, outer_th/2, 0])
    cube([L, outer_th, outer_depth], center=true);
}

module rail_with_slot(L){
  // Cut a U-channel that opens to -Y (inward) so the rail slides onto PCB edge
  difference(){
    rail_blank(L);

    // Slot position: near the inside edge (Y=0), centered in Z
    // Slot opens to -Y, so we subtract a box that protrudes past Y=0.
    translate([0, slot_depth/2 - 0.01, 0])
      cube([L+0.6, slot_w, outer_depth+0.6], center=true);

    // Make the mouth slightly wider for easier start
    translate([0, 0.8, 0])
      cube([L+0.6, slot_w + 0.6, outer_depth+0.6], center=true);
  }
}

module miter_cut(L, end=+1){
  // end=+1 cuts +X end, end=-1 cuts -X end
  // subtract an angled cutter
  translate([end*(L/2), outer_th/2, 0])
    rotate([0,0,end*miter_deg])
      translate([end*80, 0, 0])
        cube([160, outer_th*4, outer_depth*4], center=true);
}

module add_end_features(L, end=+1, male=true){
  // male=true => pegs, male=false => holes
  // place near the miter plane, inside the rail thickness
  x = end*(L/2 - peg_offset);

  for(i=[0:pegs_per_end-1]){
    dz = (pegs_per_end==1) ? 0 : (i==0 ? -peg_sep/2 : +peg_sep/2);
    translate([x, outer_th*0.68, dz])
      peg_or_hole(is_peg=male);
  }
}

module rail_part(L, male_end="+", female_end="-", is_bottom=false){
  // male_end / female_end: "+" means +X end, "-" means -X end
  difference(){
    union(){
      rail_with_slot(L);

      // Male pegs
      if (male_end == "+") add_end_features(L, end=+1, male=true);
      if (male_end == "-") add_end_features(L, end=-1, male=true);
    }

    // Miters
    miter_cut(L, end=+1);
    miter_cut(L, end=-1);

    // Female holes
    if (female_end == "+") add_end_features(L, end=+1, male=false);
    if (female_end == "-") add_end_features(L, end=-1, male=false);
  }

  // Legs only on bottom rail
  if (is_bottom && legs_enable){
    for (sx=[-1,1]){
      x = sx*(L/2 - leg_inset);
      // foot behind the rail (positive Z)
      translate([x, -leg_drop/2, outer_depth/2 + leg_len/2])
        cube([leg_w, leg_drop, leg_len], center=true);

      // brace
      hull(){
        translate([x, outer_th*0.55, outer_depth*0.25])
          cube([leg_w, leg_th, leg_th], center=true);
        translate([x, -leg_drop + leg_th/2, outer_depth/2 + leg_th/2])
          cube([leg_w, leg_th, leg_th], center=true);
      }
    }
  }
}

// ---------------- Specific rails ----------------
// Lengths are exactly PCB edge lengths; miters define corner join.
L_topbot = pcb_x;
L_leftrt = pcb_y;

// Convention for peg/hole directions so corners mate:
// - Top:    male at +X, female at -X
// - Right:  male at +X, female at -X   (after rotation, still consistent)
// - Bottom: male at -X, female at +X   (flipped)
// - Left:   male at -X, female at +X   (flipped)

module top_rail() {
  rail_part(L_topbot, male_end="+", female_end="-", is_bottom=false);
}
module bottom_rail() {
  rail_part(L_topbot, male_end="-", female_end="+", is_bottom=true);
}
module right_rail() {
  rail_part(L_leftrt, male_end="+", female_end="-", is_bottom=false);
}
module left_rail() {
  rail_part(L_leftrt, male_end="-", female_end="+", is_bottom=false);
}

// ---------------- Assembly preview ----------------
module assembly(){
  // PCB preview (flat)
  color([0,0.6,0,0.35]) cube([pcb_x, pcb_y, pcb_t], center=true);

  // Place rails around PCB edges.
  // Rails slide onto PCB edges: slot opens inward toward PCB.
  // For top rail, inward is -Y in rail local space, so we rotate it so -Y points toward PCB center.
  //
  // Top edge at +pcb_y/2:
  //   rotate rail 180° about Z so its slot opening faces downward (toward center).
  translate([0, +pcb_y/2, 0])
    rotate([0,0,180])
      top_rail();

  // Bottom edge at -pcb_y/2: slot already opens -Y, so keep as-is (toward center is +Y),
  // rotate 0 and translate; but we need inward to point +Y, so rotate 0 about Z is wrong.
  // Easiest: rotate 0? Actually slot opens -Y; we want it to open toward center which is +Y from bottom.
  // So rotate 180° about X flips Y direction:
  translate([0, -pcb_y/2, 0])
    rotate([180,0,0])
      bottom_rail();

  // Right edge at +pcb_x/2: rotate rail 90° so its length runs along Y.
  // Slot opens -Y (rail local), we want it to open toward center which is -X from right.
  translate([+pcb_x/2, 0, 0])
    rotate([0,0,90])
      right_rail();

  // Left edge at -pcb_x/2: slot should open toward center which is +X from left.
  translate([-pcb_x/2, 0, 0])
    rotate([0,0,-90])
      left_rail();
}

// ---------------- Print layout ----------------
module print_plate(){
  // Lay parts flat, separated, no intersections.
  // Rails sit with their "back" face on the bed (Z is thickness; we place at Z=outer_depth/2).
  gap = 18;

  translate([0, 0, 0])                 top_rail();
  translate([0, -(outer_th+gap), 0])   bottom_rail();

  translate([0, +(outer_th+gap), 0])   rotate([0,0,0]) right_rail();
  translate([0, +(2*(outer_th+gap)),0])rotate([0,0,0]) left_rail();
}

// ---------------- Output switch ----------------
if (part=="top")    top_rail();
if (part=="bottom") bottom_rail();
if (part=="right")  right_rail();
if (part=="left")   left_rail();
if (part=="print_plate") print_plate();
if (part=="assembly") assembly();
