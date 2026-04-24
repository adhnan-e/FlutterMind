# 3D Printing Guide 🖨️

Everything you need to print the FlutterMind skeleton — settings, order, tips, and troubleshooting.

---

## Overview

FlutterMind's skeleton is based on modified [InMoov](https://inmoov.fr) STL files. InMoov is the world's first open-source, fully 3D printable humanoid robot, designed by French sculptor Gaël Langevin. We use its hand, arm, and torso designs as a starting point and modify them to mount a phone holder and simplify the servo arrangement.

You do not need a large printer. Every part fits within a **12 × 12 × 12 cm** print volume — the same constraint InMoov was designed around.

---

## Printer Requirements

| Requirement | Minimum | Recommended |
|---|---|---|
| Build volume | 12 × 12 × 12 cm | 22 × 22 × 25 cm |
| Nozzle diameter | 0.4mm | 0.4mm |
| Material | PLA | PLA or PETG |
| Heated bed | Not required | Yes (reduces warping) |
| Layer resolution | 0.2mm | 0.15–0.2mm |

**Compatible printers (tested):** Ender 3, Ender 3 Pro, Bambu Lab A1 Mini, Creality K1, Prusa Mini.

---

## Print Settings

Use these settings for all structural parts unless stated otherwise.

| Setting | Value | Why |
|---|---|---|
| Layer height | 0.2mm | Balance of strength and speed |
| Infill | 30% | Enough for servo loads |
| Infill pattern | Gyroid or grid | Gyroid gives better isotropic strength |
| Perimeters / walls | 3 | Critical for joint strength |
| Top/bottom layers | 4 | Smooth surface finish |
| Print speed | 40–60mm/s | Slower = stronger joints |
| Supports | Yes (where noted) | Required for arm joints |
| Support style | Tree supports | Easier to remove |
| Brim | 5mm on large parts | Prevents warping |

---

## Material Guide

### PLA (recommended for beginners)

- Easy to print, no enclosure needed
- Good enough strength for all joints
- Slightly brittle under repeated stress — replace worn joints after 6–12 months of heavy use
- Best colour: **white or light grey** (easier to paint or see internal channels)
- Brand recommendation: eSUN PLA+, Polymaker PLA Pro

### PETG (recommended for durability)

- Tougher and more flexible than PLA — joints last much longer
- Slightly harder to print — needs higher temps and slower speed
- Use for finger joints and elbow — high-stress areas
- Settings adjustment: 230°C nozzle, 70°C bed, 30mm/s

### TPU (for fingertips only)

- Flexible — gives the hand a better grip on objects
- Print only the fingertip caps in TPU, rest in PLA
- Settings: 220°C, no cooling fan, 20mm/s, direct drive extruder required

---

## File Structure

```
stl/
├── hand/
│   ├── right_thumb_proximal.stl
│   ├── right_thumb_distal.stl
│   ├── right_index_proximal.stl
│   ├── right_index_distal.stl
│   ├── right_middle_proximal.stl
│   ├── right_middle_distal.stl
│   ├── right_ring_proximal.stl
│   ├── right_ring_distal.stl
│   ├── right_pinky_proximal.stl
│   ├── right_pinky_distal.stl
│   ├── right_palm.stl
│   └── right_palm_servo_cover.stl
│   └── [mirror left_ versions of all above]
│
├── arm/
│   ├── right_forearm_shell_a.stl
│   ├── right_forearm_shell_b.stl
│   ├── right_elbow_joint.stl
│   ├── right_upper_arm.stl
│   ├── right_shoulder_bracket.stl
│   └── [mirror left_ versions of all above]
│
├── torso/
│   ├── chest_front.stl
│   ├── chest_back.stl
│   ├── spine_joint.stl
│   ├── waist_ring.stl
│   ├── arduino_tray.stl          ← holds both Arduinos + wiring
│   └── phone_mount_bracket.stl   ← FlutterMind addition
│
└── head/
    ├── skull_front.stl
    ├── skull_back.stl
    ├── neck_servo_mount.stl
    └── camera_bezel.stl
```

---

## Build Order

Print in this order. Each phase gives you something functional to test before moving to the next.

### Phase 1 — Right Hand (Week 1)

Start here. The hand is the most complex but also the most satisfying — and it lets you test the full software pipeline with just 5 servos.

```
Print order:
1. right_palm.stl                 (~4 hrs)
2. right_palm_servo_cover.stl     (~1 hr)
3. right_index_proximal.stl × 1   (~40 min)
4. right_index_distal.stl × 1     (~30 min)
5. right_middle_proximal.stl × 1
6. right_middle_distal.stl × 1
7. right_ring_proximal.stl × 1
8. right_ring_distal.stl × 1
9. right_pinky_proximal.stl × 1
10. right_pinky_distal.stl × 1
11. right_thumb_proximal.stl × 1  (needs supports)
12. right_thumb_distal.stl × 1

Hardware needed for assembly:
- 5 × MG90S servos
- 10 × 2mm × 15mm steel rods (joint pivot pins)
- 20 × M2 × 8mm screws
- Fishing line or 0.5mm nylon cord (finger tendons)
```

### Phase 2 — Right Arm (Week 2–3)

```
Print order:
1. right_forearm_shell_a.stl      (no supports needed)
2. right_forearm_shell_b.stl      (no supports needed)
3. right_elbow_joint.stl          (needs supports)
4. right_upper_arm.stl
5. right_shoulder_bracket.stl     (needs supports)

Hardware needed:
- 4 × MG90S servos (shoulder x2, elbow, wrist)
- M3 × 10mm screws × 12
- 3mm × 20mm steel rod × 2 (elbow pivot)
```

### Phase 3 — Left Arm (Week 3–4)

Mirror images of all right arm parts. Most slicers can mirror STLs automatically — no need to print separate files.

In your slicer: **Load right arm STL → Mirror on X axis → Save as left arm**.

### Phase 4 — Torso (Week 4–5)

```
Print order:
1. chest_front.stl                (~6 hrs, no supports)
2. chest_back.stl                 (~6 hrs, no supports)
3. spine_joint.stl                (needs supports)
4. waist_ring.stl
5. arduino_tray.stl               (no supports)
6. phone_mount_bracket.stl        (no supports — FlutterMind addition)
```

The phone mount bracket holds your Android phone at the top-front of the torso, camera facing forward, USB-C port accessible from below.

### Phase 5 — Head (Week 5–6)

```
Print order:
1. skull_front.stl                (~5 hrs)
2. skull_back.stl                 (~5 hrs)
3. neck_servo_mount.stl
4. camera_bezel.stl               (optional — phone camera is primary)
```

---

## Assembly Hardware

Per full build:

| Hardware | Size | Quantity |
|---|---|---|
| Steel pivot rods | 2mm × 15mm | 20 |
| Steel pivot rods | 3mm × 20mm | 4 |
| Machine screws | M2 × 8mm | 40 |
| Machine screws | M3 × 10mm | 30 |
| Machine screws | M3 × 16mm | 10 |
| Nyloc nuts | M2 | 20 |
| Nyloc nuts | M3 | 20 |
| Nylon fishing line | 0.5mm | 1m |
| Servo horn screws | M2 × 5mm | 22 |

---

## Joint Assembly Tips

### Finger joints

Finger joints use 2mm steel rods as pivot pins. The rod should fit snugly — tight enough to stay in place, loose enough to rotate freely.

```
If rod is too loose: apply a small drop of cyanoacrylate (superglue) on one end only
If rod is too tight: lightly sand the rod with 400-grit sandpaper
```

### Tendons (finger pull wires)

Fingers are pulled closed by servo-driven tendons — nylon fishing line or 0.5mm nylon cord routed through the palm.

```
1. Thread fishing line through the hollow finger channel
2. Tie to the fingertip distal phalanx with a double overhand knot
3. Route through the knuckle guides
4. Tie to the servo horn
5. Tension: finger should fully open when servo is at 0°
            finger should fully close when servo is at 170°
6. Secure knots with a drop of superglue
```

### Servo mounting

MG90S servos fit into press-fit pockets in the palm and arm shells.

```
1. Press servo into pocket — should fit snugly without screws
2. Add M2 × 8mm screws to secure if loose
3. Attach servo horn AFTER threading tendons
4. Set servo to 90° (neutral) before attaching horn
   → In Arduino: servo.write(90); delay(1000);
   → Then attach horn in neutral position
```

---

## Troubleshooting Common Print Issues

| Issue | Cause | Fix |
|---|---|---|
| Pivot hole too small for rod | Printer undershoots holes | Scale STL up by 101% in slicer, or drill with 2mm drill bit |
| Servo pocket too tight | Shrinkage | Lightly sand pocket walls with 220-grit paper |
| Finger cracks at knuckle | Low infill | Reprint at 40% infill with 4 perimeters |
| Warping on palm | No brim | Add 8mm brim, print slower, 60°C bed |
| Layer delamination on shoulder | Cold print | Increase nozzle temp by 5°C |
| Stringing inside channels | High temp + fast speed | Lower temp 5°C, enable combing in slicer |
| Support won't remove | Tight gap | Set support gap to 0.25mm in slicer settings |

---

## Post-Processing

After printing each part:

1. **Remove supports** — use flush cutters or needle-nose pliers
2. **Clean pivot holes** — run a 2mm drill bit through by hand to clear any stringing
3. **Test fit before assembly** — dry fit all parts before adding screws or glue
4. **Light sanding** — 220-grit on mating surfaces for smooth movement
5. **Optional paint** — prime with grey spray primer, then acrylic paint

---

## Estimated Print Times

| Assembly | Print time | Filament |
|---|---|---|
| Right hand | ~12 hours | ~80g |
| Right arm | ~10 hours | ~120g |
| Left hand | ~12 hours | ~80g |
| Left arm | ~10 hours | ~120g |
| Torso | ~18 hours | ~200g |
| Head | ~10 hours | ~100g |
| **Total** | **~72 hours** | **~780g** |

At 8 hours of printing per day, the full skeleton takes about **9 days** of print time.

---

## Next Steps

- Wiring guide: [WIRING.md](WIRING.md)
- Flash Arduino firmware: [arduino/upper_body/upper_body.ino](../arduino/upper_body/upper_body.ino)
- Set up Flutter app: [README.md](../README.md)
