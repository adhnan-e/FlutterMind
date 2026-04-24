# Serial Communication Protocol 📡

The FlutterMind protocol defines how the Flutter app talks to the Arduino firmware over USB serial. It is intentionally simple — plain text, newline-terminated, human-readable — so you can test it manually with any Serial Monitor.

---

## Connection Parameters

| Parameter | Value |
|---|---|
| Baud rate | 115200 |
| Data bits | 8 |
| Stop bits | 1 |
| Parity | None |
| Line ending | `\n` (LF only — not CRLF) |
| Encoding | ASCII |

---

## Message Format

Every message is a single line ending with `\n`.

```
COMMAND:PARAM1:PARAM2\n
```

- Commands are **UPPERCASE**
- Parameters are separated by `:`
- No spaces anywhere in a message
- Arduino always replies with `ACK:` or `ERR:`

---

## Commands — Flutter → Arduino

### JOINT — Set a single joint angle

Set one servo to a specific angle.

```
JOINT:<joint_name>:<angle>\n
```

| Field | Type | Range |
|---|---|---|
| joint_name | string | See joint name table below |
| angle | integer | 0–180 (degrees) |

**Examples:**
```
JOINT:R_ELBOW:90\n          → right elbow to 90°
JOINT:NECK_PAN:45\n         → turn head left
JOINT:R_INDEX:180\n         → curl right index finger fully
JOINT:L_SHOULDER_X:60\n     → left shoulder forward
```

**Arduino reply:**
```
ACK:JOINT:R_ELBOW:90\n
```

---

### GESTURE — Execute a named gesture

Run a pre-programmed multi-joint movement sequence stored in Arduino firmware.

```
GESTURE:<gesture_name>\n
```

| Gesture | Description |
|---|---|
| `OPEN` | Open both hands fully |
| `GRIP` | Close both hands into fist |
| `POINT` | Extend right index finger, curl others |
| `PINCH` | Thumb and index touch, others curled |
| `WAVE` | Raise right hand, wave side to side |
| `THUMBSUP` | Extend right thumb, curl fingers |
| `PEACE` | Extend index and middle, curl others |
| `HELLO` | Raise arm, open hand, wave |
| `CLAP` | Both arms swing toward each other |
| `REST` | All joints return to neutral position |
| `NOD` | Head nods up and down twice |
| `SHAKE` | Head shakes left and right twice |

**Example:**
```
GESTURE:WAVE\n
```

**Arduino reply:**
```
ACK:GESTURE:WAVE\n
```

---

### POSE — Set all joints at once

Send all 22 joint angles in one message for smooth coordinated movement.

```
POSE:<a1>,<a2>,<a3>,...,<a22>\n
```

Angles are comma-separated integers in this fixed order:

```
Index  Joint
  0    neck_pan
  1    neck_tilt
  2    r_shoulder_x
  3    r_shoulder_y
  4    r_elbow
  5    r_wrist
  6    r_thumb
  7    r_index
  8    r_middle
  9    r_ring
 10    r_pinky
 11    l_shoulder_x
 12    l_shoulder_y
 13    l_elbow
 14    l_wrist
 15    l_thumb
 16    l_index
 17    l_middle
 18    l_ring
 19    l_pinky
 20    spine_bend
 21    waist_rotate
```

**Example — neutral rest pose:**
```
POSE:90,90,90,90,90,90,0,0,0,0,0,90,90,90,90,0,0,0,0,0,90,90\n
```

**Arduino reply:**
```
ACK:POSE\n
```

---

### SPEED — Set global movement speed

Controls how fast all servos move to their target positions. Does not affect POSE commands (which move immediately).

```
SPEED:<value>\n
```

| Value | Behaviour |
|---|---|
| 1 | Very slow — careful, precise |
| 5 | Normal speed (default) |
| 10 | Fast — snappy movements |

**Example:**
```
SPEED:3\n
```

**Arduino reply:**
```
ACK:SPEED:3\n
```

---

### STOP — Emergency stop

Immediately halts all servo movement and holds current position.

```
STOP\n
```

**Arduino reply:**
```
ACK:STOP\n
```

> This command is also sent automatically by the Flutter app when it detects the USB connection is interrupted.

---

### PING — Check connection alive

Heartbeat check. Flutter app sends this every 2 seconds to confirm connection.

```
PING\n
```

**Arduino reply:**
```
PONG\n
```

If Flutter app receives no `PONG` within 3 seconds, it shows a connection warning in the UI and sends `STOP`.

---

### STATUS — Request Arduino state

Ask Arduino to report its current state.

```
STATUS\n
```

**Arduino reply:**
```
STATUS:OK:BATT:4.2:TEMP:32:SERVOS:22\n
```

| Field | Description |
|---|---|
| `OK` or `ERR` | Overall health |
| `BATT:x.x` | Power bank voltage (if ADC connected) |
| `TEMP:xx` | Arduino temperature (°C) |
| `SERVOS:xx` | Number of servos responding |

---

## Arduino → Flutter Messages

### ACK — Acknowledgement

Sent after every successfully executed command.

```
ACK:<original_command>\n
```

### ERR — Error

Sent when a command cannot be executed.

```
ERR:<error_code>:<detail>\n
```

| Error code | Meaning |
|---|---|
| `UNKNOWN_CMD` | Command not recognised |
| `INVALID_JOINT` | Joint name not found |
| `OUT_OF_RANGE` | Angle outside 0–180 |
| `PARSE_FAIL` | Message could not be parsed |
| `BUSY` | Gesture sequence already running |

**Example:**
```
ERR:UNKNOWN_CMD:FLYAWAY\n
ERR:OUT_OF_RANGE:R_ELBOW:220\n
```

### PONG — Heartbeat reply

```
PONG\n
```

### EVENT — Async notification from Arduino

Arduino can push events to the phone without being asked.

```
EVENT:<event_type>:<detail>\n
```

| Event | Meaning |
|---|---|
| `GESTURE_DONE:<name>` | Gesture sequence completed |
| `STALL:<joint>` | Servo stall detected (overcurrent) |
| `READY` | Arduino has finished booting |

**Example:**
```
EVENT:GESTURE_DONE:WAVE\n
EVENT:STALL:R_ELBOW\n
EVENT:READY\n
```

---

## Joint Name Reference

Complete list of all valid joint names for `JOINT:` commands:

| Joint name | Body part | Arduino # |
|---|---|---|
| `NECK_PAN` | Head left/right | 1 |
| `NECK_TILT` | Head up/down | 1 |
| `R_SHOULDER_X` | Right shoulder forward/back | 1 |
| `R_SHOULDER_Y` | Right shoulder raise/lower | 1 |
| `R_ELBOW` | Right elbow bend | 1 |
| `R_WRIST` | Right wrist rotate | 1 |
| `R_THUMB` | Right thumb | 1 |
| `R_INDEX` | Right index finger | 1 |
| `R_MIDDLE` | Right middle finger | 1 |
| `R_RING` | Right ring finger | 1 |
| `R_PINKY` | Right pinky finger | 1 |
| `L_SHOULDER_X` | Left shoulder forward/back | 2 |
| `L_SHOULDER_Y` | Left shoulder raise/lower | 2 |
| `L_ELBOW` | Left elbow bend | 2 |
| `L_WRIST` | Left wrist rotate | 2 |
| `L_THUMB` | Left thumb | 2 |
| `L_INDEX` | Left index finger | 2 |
| `L_MIDDLE` | Left middle finger | 2 |
| `L_RING` | Left ring finger | 2 |
| `L_PINKY` | Left pinky finger | 2 |
| `SPINE_BEND` | Torso forward/back | 2 |
| `WAIST_ROTATE` | Torso twist left/right | 2 |

---

## Example Session

A complete session from power-on to wave gesture:

```
← Arduino boots
→ EVENT:READY\n

← Flutter app connects, sends heartbeat
→ PING\n
← PONG\n

← App checks status
→ STATUS\n
← STATUS:OK:BATT:4.8:TEMP:28:SERVOS:22\n

← App sets rest pose on startup
→ GESTURE:REST\n
← ACK:GESTURE:REST\n
← EVENT:GESTURE_DONE:REST\n

← User taps "Wave" button
→ GESTURE:WAVE\n
← ACK:GESTURE:WAVE\n
← EVENT:GESTURE_DONE:WAVE\n

← User moves right elbow slider
→ JOINT:R_ELBOW:120\n
← ACK:JOINT:R_ELBOW:120\n

← User speaks "open hand"
→ GESTURE:OPEN\n
← ACK:GESTURE:OPEN\n
← EVENT:GESTURE_DONE:OPEN\n

← User disconnects USB
→ [connection lost]
← Arduino detects no ping for 5 seconds → GESTURE:REST automatically
```

---

## Testing with Serial Monitor

You can test the full protocol without the Flutter app using any serial monitor (Arduino IDE, PuTTY, screen):

```bash
# On Linux/Mac
screen /dev/ttyUSB0 115200

# Then type commands manually (press Enter after each):
PING
GESTURE:WAVE
JOINT:R_ELBOW:90
STATUS
STOP
```

---

## Protocol Version

Current protocol version: **v1.0**

The Flutter app sends its protocol version on connect:

```
HELLO:FLUTTERMIND:v1.0\n
```

Arduino replies:

```
HELLO:ARDUINO:v1.0\n
```

If versions mismatch, the app shows a firmware update warning.

---

## Extending the Protocol

To add a new command:

1. Add the command to `parseAndExecute()` in the Arduino sketch
2. Add the corresponding method to `USBRobotService` in the Flutter app
3. Document the new command in this file
4. Open a PR with all three changes together

See [CONTRIBUTING.md](../CONTRIBUTING.md) for the PR process.
