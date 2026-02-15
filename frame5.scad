// 4-piece PCB picture-frame rails (mitered) + print plate layout (no intersections)
// PCB: 90 x 70 x 1.5 mm
// Units: mm

// ---------------- PCB ----------------
pcb_x  = 90;
pcb_y  = 70;
pcb_t  = 1.5;

// ---------------- Rail cross-section ----------------
// Local rail coords:
// - Length along X
// - Inner edge at Y=0 (touches PCB edge), rail extends to +Y (outside border)
// - Thickness along Z, centered at Z=0
rail_w = 12.0;   // border width (Y)
rail_z = 10.0;   // thickness (Z)

// ---------------- Channel (correct axis) ----------------
slot_clear = 0.35;
slot_z     = pcb_t + 2*slot_clear; // captures PCB thickness (Z)
slot_depth = 6.5;                  // seats inward from inner edge (Y)

// keep some material above/below slot in Z
slot_z_center = 0; // center the slot in Z (simple)

// ---------------- Miters ----------------
miter_deg = 45;

// ---------------- Legs (optional, bottom rail only) ----------------
legs_enable = true;
leg_w   = 14.0;
leg_th  = 3.0;
leg_len = 28.0;
leg_drop= 10.0;
leg_inset = 20.0;

// ---------------- Output ----------------
mode = "print_plate"; // "print_plate", "assembly_preview", "top","bottom","left","right"

// ---------------- Derived rail lengths for square mitered frame ----------------
// For a classic mitered frame, each rail overall length = inner_span + rail_w
Lx = pcb_x + rail_w;
Ly = pcb_y + rail_w;

// ---------------- Core rail geometry ----------------
module rail_block(L){
  // Rail is a rectangular prism: length L in X, width rail_w in Y (from 0..rail_w), thickness rail_z in Z
  translate([0, rail_w/2, 0]) cube([L, rail_w, rail_z], center=true);
}

module rail_with_channel(L){
  difference(){
    rail_block(L);

    // Channel: open at inner edge (Y=0), extends inward +Y by slot_depth,
    // and has height slot_z in Z (captures PCB thickness).
    // Make it protrude past Y=0 so it's truly open.
    translate([0, slot_depth/2 - 0.01, slot_z_center])
      cube([L+1, slot_depth+0.2, slot_z], center=true);

    // Slightly flared mouth for easier insertion
    translate([0, 0.6, slot_z_center])
      cube([L+1, 1.4, slot_z+0.6], center=true);
  }
}

module miter_cut(L, end=+1){
  // Cut a 45° miter that produces a square outer corner when assembled.
  // We subtract a large rotated block at each end.
  // end=+1 => +X end, end=-1 => -X end
  translate([end*(L/2), rail_w/2, 0])
    rotate([0,0,end*miter_deg])
      translate([end*80, 0, 0])
        cube([160, rail_w*4, rail_z*4], center=true);
}

module rail_part(L, is_bottom=false){
  difference(){
    rail_with_channel(L);

    // Miters on both ends
    miter_cut(L, end=+1);
    miter_cut(L, end=-1);
  }

  // Simple legs on bottom rail only (optional)
  if (is_bottom && legs_enable){
    for (sx=[-1,1]){
      x = sx*(L/2 - leg_inset);
      // rear foot in +Z
      translate([x, -leg_drop/2, rail_z/2 + leg_len/2])
        cube([leg_w, leg_drop, leg_len], center=true);

      // brace
      hull(){
        translate([x, rail_w*0.55, rail_z*0.20])
          cube([leg_w, leg_th, leg_th], center=true);
        translate([x, -leg_drop + leg_th/2, rail_z/2 + leg_th/2])
          cube([leg_w, leg_th, leg_th], center=true);
      }
    }
  }
}

// Named parts
module top_rail()    { rail_part(Lx, is_bottom=false); }
module bottom_rail() { rail_part(Lx, is_bottom=true ); }
module left_rail()   { rail_part(Ly, is_bottom=false); }
module right_rail()  { rail_part(Ly, is_bottom=false); }

// ---------------- Assembly preview (optional) ----------------
module assembly_preview(){
  // PCB preview
  color([0,0.6,0,0.35]) translate([0,0,0]) cube([pcb_x, pcb_y, pcb_t], center=true);

  // Rails around PCB edges (inner edge Y=0 must touch PCB boundary)
  // Place and rotate so each rail's inner edge faces inward.

  // Top: inner edge should face downward (toward -Y), so rotate 180° about Z and place at +pcb_y/2
  translate([0, +pcb_y/2, 0]) rotate([0,0,180]) top_rail();

  // Bottom: inner edge should face upward (toward +Y), place at -pcb_y/2 (no rotation needed)
  translate([0, -pcb_y/2, 0]) bottom_rail();

  // Right: rotate -90 so rail length runs along Y, inner edge faces left (-X), place at +pcb_x/2
  translate([+pcb_x/2, 0, 0]) rotate([0,0,-90]) right_rail();

  // Left: rotate +90 so inner edge faces right (+X), place at -pcb_x/2
  translate([-pcb_x/2, 0, 0]) rotate([0,0, 90]) left_rail();
}

// ---------------- Print plate layout (guaranteed non-overlap) ----------------
module print_plate(){
  // Lay out 4 parts separated. All parts are centered at Z=0; lift by rail_z/2 to sit on bed.
  zlift = rail_z/2;

  gap = 20; // extra spacing between bounding boxes

  // Bounding box sizes (conservative):
  // Long rail bbox: [Lx, rail_w + legs? (in Y), rail_z + legs? (in Z)]
  // We only separate in X/Y, so use footprint sizes:
  long_x = Lx;
  short_x= Ly;
  foot_y = rail_w + (legs_enable ? leg_drop : 0); // bottom rail footprint extends into -Y by leg_drop
  plain_y= rail_w;

  // Place in a 2x2 grid with generous gaps
  // Row 1: top + bottom
  translate([0, 0, zlift])                     top_rail();
  translate([0, -(max(plain_y,foot_y)+gap), zlift]) bottom_rail();

  // Row 2: left + right, shifted in X so no overlap with row 1 parts
  xshift = max(long_x, short_x) + gap;
  translate([xshift, 0, zlift])                left_rail();
  translate([xshift, -(plain_y+gap), zlift])   right_rail();
}

// ---------------- Switch ----------------
if (mode=="print_plate")        print_plate();
else if (mode=="assembly_preview") assembly_preview();
else if (mode=="top")           top_rail();
else if (mode=="bottom")        bottom_rail();
else if (mode=="left")          left_rail();
else if (mode=="right")         right_rail();
