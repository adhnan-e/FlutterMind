# Wiring Guide 🔌

Complete wiring reference for the FlutterMind robot skeleton. Read this fully before connecting any components.

---

## Safety First

> ⚠️ **Always disconnect power before rewiring.**
> ⚠️ **Never power servos from Arduino's 5V pin** — they draw up to 700mA each. With 11 servos on one Arduino, that is up to 7.7A. The Arduino 5V regulator handles 500mA maximum. Use a dedicated power bank.
> ⚠️ **Share GND between Arduino and power bank.** Without a common ground, servos will behave erratically.
> ⚠️ **Double-check polarity** on every servo connector before powering on. Reversed polarity destroys servos instantly.

---

## Overview

FlutterMind uses two Arduino Nanos — one for the right arm, right hand, and head; one for the left arm, left hand, and torso. Both connect to the phone via a USB hub on a single USB-C OTG cable.

```
Android Phone
     │
     │ USB-C OTG cable
     │
  USB Hub (powered)
     │         │
     │         │
Arduino #1   Arduino #2
Upper Right  Lower Left
+ Head       + Torso
     │              │
  PWM pins       PWM pins
     │              │
Servos 1–11    Servos 12–22
     │              │
     └──────┬────────┘
            │
       Power bank 5V
       (separate supply)
```

---

## Components List

| Component | Quantity | Notes |
|---|---|---|
| Arduino Nano | 2 | ATmega328P, CH340 USB chip |
| MG90S micro servo | 22 | Metal gear recommended |
| Powered USB hub | 1 | Needed for 2 Arduinos on one cable |
| USB-C OTG adapter | 1 | Phone must support OTG host mode |
| Power bank 5V 3A+ | 1 | Dedicated servo power — NOT phone charging |
| 22 AWG wire | 3m | Signal wires for servos |
| 20 AWG wire | 2m | Power rails for servo VCC and GND |
| Dupont connectors | 1 set | Female 3-pin for servo headers |
| Terminal block | 2 | For cleaner power distribution |

---

## Arduino #1 — Right Side + Head

Handles: right hand (5), right arm (4), head (2) = **11 servos**

### Pin Assignment

| Pin | Servo | Joint | Range |
|---|---|---|---|
| D2 | neck_pan | Head left/right | 0°–180° (90° = center) |
| D3 | neck_tilt | Head up/down | 60°–120° (90° = center) |
| D4 | r_shoulder_x | Right shoulder forward/back | 0°–180° |
| D5 | r_shoulder_y | Right shoulder up/down | 0°–180° |
| D6 | r_elbow | Right elbow bend | 0°–150° |
| D7 | r_wrist | Right wrist rotate | 0°–180° |
| D8 | r_thumb | Right thumb curl | 0°–170° |
| D9 | r_index | Right index finger | 0°–180° |
| D10 | r_middle | Right middle finger | 0°–180° |
| D11 | r_ring | Right ring finger | 0°–180° |
| D12 | r_pinky | Right pinky finger | 0°–180° |

### Wiring Diagram — Arduino #1

```
                    Arduino Nano #1
                   ┌──────────────┐
               D2  │●             │ VIN
               D3  │●             │ GND ──── Power bank GND
               D4  │●             │ RST
               D5  │●             │ +5V  ← DO NOT connect servos here
               D6  │●             │ A7
               D7  │●             │ A6
               D8  │●             │ A5
               D9  │●             │ A4
              D10  │●             │ A3
              D11  │●             │ A2
              D12  │●             │ A1
              D13  │●             │ A0
              GND  │●             │ REF
               +5V │●             │ 3V3
                   └──────────────┘
                       USB Mini-B
                           │
                      USB Hub port 1
                           │
                      USB-C OTG
                           │
                       Phone

Each servo connects to:
  Signal (orange/yellow) ──── Arduino PWM pin (D2–D12)
  VCC    (red)           ──── Power bank positive rail
  GND    (brown/black)   ──── Shared GND rail
                              (Power bank GND + Arduino GND tied together)
```

---

## Arduino #2 — Left Side + Torso

Handles: left hand (5), left arm (4), torso (2) = **11 servos**

### Pin Assignment

| Pin | Servo | Joint | Range |
|---|---|---|---|
| D2 | l_shoulder_x | Left shoulder forward/back | 0°–180° |
| D3 | l_shoulder_y | Left shoulder up/down | 0°–180° |
| D4 | l_elbow | Left elbow bend | 0°–150° |
| D5 | l_wrist | Left wrist rotate | 0°–180° |
| D6 | l_thumb | Left thumb curl | 0°–170° |
| D7 | l_index | Left index finger | 0°–180° |
| D8 | l_middle | Left middle finger | 0°–180° |
| D9 | l_ring | Left ring finger | 0°–180° |
| D10 | l_pinky | Left pinky finger | 0°–180° |
| D11 | spine_bend | Torso forward/back | 60°–120° |
| D12 | waist_rotate | Torso left/right twist | 45°–135° |

---

## Power Rail Wiring

This is the most critical part. Wire it wrong and servos will behave erratically or burn out.

```
Power bank (5V output)
        │
        ├──── Positive rail (red wire, 20 AWG)
        │           │
        │     ┌─────┴──────────────────────────────────┐
        │     │  Terminal block (servo power bus)       │
        │     └─┬──┬──┬──┬──┬──┬──┬──┬──┬──┬──┬──┬──┘
        │       │  │  │  │  │  │  │  │  │  │  │
        │    Servo VCC connections (all 22 servos)
        │
        └──── Negative rail (black wire, 20 AWG)
                    │
              ┌─────┴─────────────────────────────────┐
              │  Shared GND bus                        │
              └─┬──┬──┬──┬──┬──┬──┬──┬──┬──┬──┬──┬─┘
                │  │  │  │  │  │  │  │  │  │  │
             Servo GND + Arduino #1 GND + Arduino #2 GND
```

---

## Servo Connector Pinout

MG90S and most standard servos use a 3-pin JST connector:

```
┌─────────────────────────────┐
│  1      2        3          │
│  GND    VCC(5V)  Signal     │
│  Brown  Red      Orange     │
└─────────────────────────────┘
```

> ⚠️ Some servo brands swap GND and Signal. Always verify with a multimeter before connecting.

---

## USB OTG Wiring

```
Android phone (USB-C port — OTG host mode)
        │
        │  USB-C OTG cable (must be OTG spec, not charge-only)
        │
   Powered USB hub
        │          │
        │          │
   Mini-USB    Mini-USB
   Arduino #1  Arduino #2
```

**Enable OTG on your phone:**
- Settings → Connected devices → USB → OTG (toggle on)
- Some phones enable OTG automatically when an OTG cable is detected
- Test OTG support with a USB flash drive first

**Recommended USB hub:** Any 4-port powered hub with individual power switches per port. This lets you power cycle each Arduino independently without unplugging.

---

## Verifying the Wiring

Before running the Flutter app, verify each connection step by step:

### Step 1 — Test one servo in isolation

```cpp
// Upload this minimal test sketch to Arduino #1
#include <Servo.h>
Servo test;

void setup() {
  test.attach(9);   // Right index finger pin
}

void loop() {
  test.write(0);    delay(1000);   // Open
  test.write(180);  delay(1000);   // Close
}
```

If the servo moves smoothly: ✅ Power and signal wiring is correct.
If the servo vibrates/jitters: ❌ Check GND connection between Arduino and power bank.
If the servo does not move: ❌ Check VCC and signal wire connections.

### Step 2 — Test serial communication

```cpp
// Upload this to Arduino #1, then open Serial Monitor at 115200 baud
void setup() { Serial.begin(115200); }
void loop() {
  if (Serial.available()) {
    String cmd = Serial.readStringUntil('\n');
    Serial.println("ACK:" + cmd);
  }
}
```

Send `HELLO\n` from Serial Monitor. You should see `ACK:HELLO` back.

### Step 3 — Test from Flutter app

Connect via USB-C OTG, open the app, go to Manual Control, and move one slider. Watch the Serial Monitor for incoming commands.

---

## Troubleshooting

| Symptom | Likely cause | Fix |
|---|---|---|
| Servo jitters continuously | No common GND | Connect Arduino GND to power bank GND |
| Servo moves once then stops | USB power drop | Use a powered USB hub |
| App does not detect Arduino | OTG not enabled | Enable OTG in phone settings |
| All servos drift to center | Signal wire noise | Add 100nF capacitor across servo VCC/GND |
| Arduino resets when servo moves | Power bank can't deliver current | Use a higher amperage power bank (3A+) |
| One servo runs hot | Mechanical jam | Check for 3D printed parts blocking joint rotation |
| Serial garbled characters | Baud rate mismatch | Ensure both Arduino and Flutter app use 115200 |

---

## Cable Management Tips

- Route signal wires (22 AWG) separately from power wires (20 AWG) to reduce noise
- Use cable sleeves or spiral wrap inside the arm to keep wiring tidy
- Leave 20% extra wire length at each joint — joints need slack to move
- Label each servo connector with a paint marker before assembly
- Zip-tie wires to the 3D printed frame every 5cm to prevent snagging

---

## Next Steps

- Flash Arduino firmware: see [arduino/upper_body/upper_body.ino](../arduino/upper_body/upper_body.ino)
- Set up the Flutter app: see [README.md](../README.md#getting-started)
- Serial command reference: see [PROTOCOL.md](PROTOCOL.md)
