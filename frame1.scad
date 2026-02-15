// 4-piece PCB perimeter frame: 4 U-channel rails (glue-on)
// - PCB slides into the U on each rail
// - Print 2x plain rails + 2x leg rails
// - Configure which sides get legs by printing the leg variant for those sides
//
// PCB: 90 x 70 x 1.5 mm
// Units: mm

// ---------------- PCB ----------------
pcb_x  = 90;
pcb_y  = 70;
pcb_t  = 1.5;

// ---------------- Fit ----------------
slot_clear_xy = 0.35;   // clearance for PCB thickness slot width (per side in slot)
slot_clear_z  = 0.25;   // clearance depth-wise (not critical here)
end_clear     = 0.2;    // extra length so rail doesn't bind at ends

// ---------------- Rail geometry ----------------
rail_len_x = pcb_x + end_clear;  // rail length for top/bottom pieces
rail_len_y = pcb_y + end_clear;  // rail length for left/right pieces

rail_depth = 10.0;      // how far rail extends "back" (Z direction) from PCB plane
rail_face  = 3.0;       // front lip thickness (toward viewer)
rail_wall  = 3.0;       // wall thickness around slot
slot_depth = 6.0;       // how deep PCB inserts into the rail (>= pcb_t)

// Slot (U-channel) size
slot_w = pcb_t + 2*slot_clear_xy;        // opening thickness for PCB
slot_h = slot_depth + slot_clear_z;      // insertion depth into rail

// ---------------- Legs (optional on two rails) ----------------
leg_enable = true;
leg_width  = 18.0;   // along rail length
leg_th     = 3.0;    // thickness
leg_len    = 35.0;   // how far it sticks out behind (Z)
leg_drop   = 12.0;   // how far down (Y-) the foot goes
leg_offset = 20.0;   // from rail end toward center

// ---------------- Rendering ----------------
part = "assembly"; // "rail_plain_x", "rail_plain_y", "rail_leg_x", "rail_leg_y", "assembly"

// ------------- Core rail (length L) -------------
// Coordinate system for rail:
// X = along rail length
// Y = vertical (up/down when standing)
// Z = depth (front/back). PCB sits at Z=0 plane; rail extends +Z behind.
module rail(L, with_leg=false) {

  // Outer box of rail
  // Height in Y: make it look like a picture frame edge
  outer_y = rail_face + rail_wall + slot_w + rail_wall; // total "height" around slot
  outer_z = rail_depth;                                  // depth/back

  // Slot center in Y: keep some "face" above the slot so it looks framed
  // Slot runs along X, at Z near the front.
  slot_y0 = rail_face + rail_wall; // bottom of slot region in Y
  slot_z0 = 0.0;                   // slot starts at front face (Z=0)

  difference() {
    // outer solid
    translate([0, outer_y/2, outer_z/2])
      cube([L, outer_y, outer_z], center=true);

    // carve slot (U-channel) from the front (Z=0) into depth
    translate([0, slot_y0 + slot_w/2, slot_h/2])
      cube([L+0.6, slot_w, slot_h], center=true);

    // open the front window area so PCB can slide in from side ends cleanly
    // (small chamfer substitute by widening mouth a bit)
    translate([0, slot_y0 + slot_w/2, 1.0])
      cube([L+0.6, slot_w + 0.6, 2.0], center=true);
  }

  // Optional leg feature (a simple rear foot)
  if (with_leg && leg_enable) {
    // place two legs near ends for stability
    for (sx = [-1, 1]) {
      x = sx*(L/2 - leg_offset);

      // foot plate behind rail
      translate([x, (rail_face + rail_wall) - leg_drop/2, rail_depth + leg_len/2])
        cube([leg_width, leg_drop, leg_len], center=true);

      // small brace up to the rail (triangulated-ish via hull)
      hull() {
        translate([x, (rail_face + rail_wall), rail_depth*0.55])
          cube([leg_width, leg_th, leg_th], center=true);
        translate([x, (rail_face + rail_wall) - leg_drop, rail_depth + leg_th])
          cube([leg_width, leg_th, leg_th], center=true);
      }
    }
  }
}

// ------------- Assembly preview -------------
module assembly_preview() {
  // Show PCB as a translucent plate in the middle
  color([0,0.6,0,0.35])
    translate([0,0,0])
      cube([pcb_x, pcb_y, pcb_t], center=true);

  // Place rails around PCB edges (glue-on concept)
  // Top rail (X length)
  color("lightgray")
    translate([0, pcb_y/2, 0])
      rotate([0,0,0])
        rail(rail_len_x, with_leg=true); // choose legs on top/bottom OR left/right

  // Bottom rail
  color("lightgray")
    translate([0, -pcb_y/2, 0])
      rotate([0,0,180])
        rail(rail_len_x, with_leg=true);

  // Left rail (Y length) - rotate 90 degrees
  color("gainsboro")
    translate([-pcb_x/2, 0, 0])
      rotate([0,0,90])
        rail(rail_len_y, with_leg=false);

  // Right rail
  color("gainsboro")
    translate([pcb_x/2, 0, 0])
      rotate([0,0,-90])
        rail(rail_len_y, with_leg=false);
}

// ------------- Part selection -------------
if (part == "rail_plain_x") rail(rail_len_x, with_leg=false);
if (part == "rail_plain_y") rail(rail_len_y, with_leg=false);
if (part == "rail_leg_x")   rail(rail_len_x, with_leg=true);
if (part == "rail_leg_y")   rail(rail_len_y, with_leg=true);
if (part == "assembly")     assembly_preview();
