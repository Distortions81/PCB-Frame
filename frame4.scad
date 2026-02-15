// 4-piece PCB picture-frame rails with U-channel + 45° miters + peg/hole corners
// - Correct assembly rotations/placement
// - Print plate layout: no intersections
// - Legs only on bottom rail (smaller)
//
// PCB: 90 x 70 x 1.5 mm
// Units: mm

// ---------------- PCB ----------------
pcb_x  = 90;
pcb_y  = 70;
pcb_t  = 1.5;

// ---------------- Channel fit ----------------
slot_clear = 0.35;        // clearance around PCB thickness
slot_depth = 7.0;         // how deep PCB edge seats into channel (inward from inner edge)

// Rail cross-section
rail_th   = 12.0;         // thickness in the frame plane (border thickness)
rail_depth= 12.0;         // depth out of the frame plane (front/back)
wall      = 3.0;          // wall around slot
face_top  = 4.0;          // material above slot (frame look)

// Slot (U-channel) opening width
slot_w = pcb_t + 2*slot_clear;

// ---------------- Miters ----------------
miter_deg = 45;

// ---------------- Pegs/Holes ----------------
peg_d      = 2.6;
peg_len    = 4.5;
peg_clear  = 0.25;     // hole diameter = peg_d + peg_clear
peg_offset = 7.0;      // from end inward along length
peg_sep_z  = 4.5;      // separation between two pegs along Z
pegs_per_end = 2;      // 1 or 2

// ---------------- Legs (bottom rail only) ----------------
legs_enable = true;
leg_w     = 14.0;      // along rail length
leg_th    = 3.0;
leg_len   = 28.0;      // sticks backward in Z
leg_drop  = 10.0;      // drops down in Y
leg_inset = 20.0;      // from each end

// ---------------- Output ----------------
part = "assembly"; // "top","bottom","left","right","print_plate","assembly"

// ============================================================================
// Local coords for a rail part (before placement):
// - Length runs along +X
// - INNER edge of the frame is at local Y=0 (touches PCB edge)
// - Frame material extends to +Y (outside)
// - Slot opens toward local -Y (so it can slide onto the PCB from the side)
// - Depth is along Z
// ============================================================================

// ---------------- Helpers ----------------
module peg_or_hole(is_peg=true){
  d = is_peg ? peg_d : (peg_d + peg_clear);
  rotate([0,90,0]) cylinder(d=d, h=(peg_len + (is_peg?0:0.8)), $fn=36);
}

module rail_blank(L){
  // Centered in X and Z; Y spans [0..rail_th]
  translate([0, rail_th/2, 0])
    cube([L, rail_th, rail_depth], center=true);
}

module rail_with_slot(L){
  // Cut a U-slot that opens to -Y, centered in Z
  difference(){
    rail_blank(L);

    // Slot center in Y: keep face_top above slot, plus wall
    slot_yc = (face_top + wall) + slot_w/2;

    // Main slot cut, protruding past inner edge (Y=0) so it's open
    translate([0, slot_yc - slot_depth/2 - 0.01, 0])
      cube([L+0.8, slot_w, rail_depth+0.8], center=true);

    // Slightly wider mouth near inner edge to ease insertion
    translate([0, 0.8, 0])
      cube([L+0.8, slot_w + 0.6, rail_depth+0.8], center=true);
  }
}

module miter_cut(L, end=+1){
  // end=+1 cuts +X end, end=-1 cuts -X end
  translate([end*(L/2), rail_th/2, 0])
    rotate([0,0,end*miter_deg])
      translate([end*80, 0, 0])
        cube([160, rail_th*4, rail_depth*4], center=true);
}

module add_end_features(L, end=+1, male=true){
  x = end*(L/2 - peg_offset);
  for(i=[0:pegs_per_end-1]){
    dz = (pegs_per_end==1) ? 0 : (i==0 ? -peg_sep_z/2 : +peg_sep_z/2);
    translate([x, rail_th*0.65, dz]) peg_or_hole(is_peg=male);
  }
}

module rail_part(L, male_end="+", female_end="-", is_bottom=false){
  difference(){
    union(){
      rail_with_slot(L);
      if (male_end == "+") add_end_features(L, end=+1, male=true);
      if (male_end == "-") add_end_features(L, end=-1, male=true);
    }

    // Miters
    miter_cut(L, end=+1);
    miter_cut(L, end=-1);

    // Holes
    if (female_end == "+") add_end_features(L, end=+1, male=false);
    if (female_end == "-") add_end_features(L, end=-1, male=false);
  }

  // Legs only on bottom rail
  if (is_bottom && legs_enable){
    for (sx=[-1,1]){
      x = sx*(L/2 - leg_inset);

      // rear foot
      translate([x, -leg_drop/2, rail_depth/2 + leg_len/2])
        cube([leg_w, leg_drop, leg_len], center=true);

      // brace
      hull(){
        translate([x, rail_th*0.55, rail_depth*0.25])
          cube([leg_w, leg_th, leg_th], center=true);
        translate([x, -leg_drop + leg_th/2, rail_depth/2 + leg_th/2])
          cube([leg_w, leg_th, leg_th], center=true);
      }
    }
  }
}

// ---------------- Rail lengths for proper miters ----------------
// For a mitered frame, each rail's overall length ≈ inner_span + rail_th
L_topbot = pcb_x + rail_th;
L_leftrt = pcb_y + rail_th;

// Peg/hole convention so corners mate:
// - Top:    male +X, female -X
// - Right:  male +X, female -X
// - Bottom: male -X, female +X
// - Left:   male -X, female +X
module top_rail()    { rail_part(L_topbot, male_end="+", female_end="-", is_bottom=false); }
module bottom_rail() { rail_part(L_topbot, male_end="-", female_end="+", is_bottom=true ); }
module right_rail()  { rail_part(L_leftrt, male_end="+", female_end="-", is_bottom=false); }
module left_rail()   { rail_part(L_leftrt, male_end="-", female_end="+", is_bottom=false); }

// ---------------- Assembly preview ----------------
module assembly(){
  // PCB preview (centered)
  color([0,0.6,0,0.35]) cube([pcb_x, pcb_y, pcb_t], center=true);

  // Place rails so their INNER edge (local Y=0) aligns to PCB edge.
  // Since inner edge is at local Y=0, we translate to PCB edge directly.

  // Top edge (+Y): slot should open inward (toward -Y), which is already local -Y.
  translate([0, +pcb_y/2, 0])
    top_rail();

  // Bottom edge (-Y): inward is +Y, so rotate 180° about Z to flip local -Y to +Y.
  translate([0, -pcb_y/2, 0])
    rotate([0,0,180])
      bottom_rail();

  // Right edge (+X): rail length must run along Y.
  // Need slot opening toward center (toward -X). We want local -Y => global -X.
  // rotate -90 about Z maps local -Y to global -X.
  translate([+pcb_x/2, 0, 0])
    rotate([0,0,-90])
      right_rail();

  // Left edge (-X): inward is +X. Need local -Y => global +X.
  // rotate +90 about Z maps local -Y to global +X.
  translate([-pcb_x/2, 0, 0])
    rotate([0,0, 90])
      left_rail();
}

// ---------------- Print layout (no intersections) ----------------
module print_plate(){
  gap = 12;

  // Put each part on the bed: since parts are centered in Z, lift by rail_depth/2.
  zlift = rail_depth/2;

  // Bounding sizes (rough) used for spacing:
  w_long = L_topbot;
  w_short= L_leftrt;
  h_y    = rail_th;

  translate([0, 0, zlift])                 top_rail();
  translate([0, -(h_y + gap), zlift])      bottom_rail();

  translate([0, +(h_y + gap), zlift])      right_rail();
  translate([0, +(2*(h_y + gap)), zlift])  left_rail();

  // If you want a more compact plate, I can pack them in a 2x2 grid.
}

// ---------------- Output switch ----------------
if (part=="top")         top_rail();
else if (part=="bottom") bottom_rail();
else if (part=="right")  right_rail();
else if (part=="left")   left_rail();
else if (part=="print_plate") print_plate();
else if (part=="assembly")    assembly();
