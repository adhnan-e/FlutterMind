/**
 * FlutterMind — Arduino #1 Firmware
 * Controls: Right arm (4), Right hand (5), Head (2) = 11 servos
 *
 * Communication: USB Serial at 115200 baud
 * Protocol:      Newline-terminated ASCII commands
 * See:           docs/PROTOCOL.md for full command reference
 *
 * Hardware:      Arduino Nano (ATmega328P)
 * Power:         Servos powered from external 5V power bank
 *                NEVER from Arduino 5V pin
 */

#include <Servo.h>

// ─────────────────────────────────────────────
// FIRMWARE VERSION
// ─────────────────────────────────────────────
#define FIRMWARE_VERSION "v1.0"
#define ARDUINO_ID       "UPPER"

// ─────────────────────────────────────────────
// PIN ASSIGNMENTS
// ─────────────────────────────────────────────
const int PIN_NECK_PAN      = 2;
const int PIN_NECK_TILT     = 3;
const int PIN_R_SHOULDER_X  = 4;
const int PIN_R_SHOULDER_Y  = 5;
const int PIN_R_ELBOW       = 6;
const int PIN_R_WRIST       = 7;
const int PIN_R_THUMB       = 8;
const int PIN_R_INDEX       = 9;
const int PIN_R_MIDDLE      = 10;
const int PIN_R_RING        = 11;
const int PIN_R_PINKY       = 12;

// ─────────────────────────────────────────────
// SERVO SAFE RANGES (min, max, rest)
// ─────────────────────────────────────────────
const int NECK_PAN_MIN     = 0,   NECK_PAN_MAX     = 180, NECK_PAN_REST     = 90;
const int NECK_TILT_MIN    = 60,  NECK_TILT_MAX    = 120, NECK_TILT_REST    = 90;
const int R_SHOULDER_X_MIN = 0,   R_SHOULDER_X_MAX = 180, R_SHOULDER_X_REST = 90;
const int R_SHOULDER_Y_MIN = 0,   R_SHOULDER_Y_MAX = 180, R_SHOULDER_Y_REST = 90;
const int R_ELBOW_MIN      = 0,   R_ELBOW_MAX      = 150, R_ELBOW_REST      = 90;
const int R_WRIST_MIN      = 0,   R_WRIST_MAX      = 180, R_WRIST_REST      = 90;
const int FINGER_MIN       = 0,   FINGER_MAX        = 175, FINGER_REST       = 0;
const int THUMB_MIN        = 0,   THUMB_MAX         = 170, THUMB_REST        = 0;

// ─────────────────────────────────────────────
// SERVO OBJECTS
// ─────────────────────────────────────────────
Servo neckPan, neckTilt;
Servo rShoulderX, rShoulderY;
Servo rElbow, rWrist;
Servo rThumb, rIndex, rMiddle, rRing, rPinky;

// ─────────────────────────────────────────────
// STATE
// ─────────────────────────────────────────────
String inputBuffer = "";
bool gestureRunning = false;
unsigned long lastPingTime = 0;
const unsigned long PING_TIMEOUT_MS = 5000;

// ─────────────────────────────────────────────
// SETUP
// ─────────────────────────────────────────────
void setup() {
  Serial.begin(115200);

  // Attach all servos
  neckPan.attach(PIN_NECK_PAN);
  neckTilt.attach(PIN_NECK_TILT);
  rShoulderX.attach(PIN_R_SHOULDER_X);
  rShoulderY.attach(PIN_R_SHOULDER_Y);
  rElbow.attach(PIN_R_ELBOW);
  rWrist.attach(PIN_R_WRIST);
  rThumb.attach(PIN_R_THUMB);
  rIndex.attach(PIN_R_INDEX);
  rMiddle.attach(PIN_R_MIDDLE);
  rRing.attach(PIN_R_RING);
  rPinky.attach(PIN_R_PINKY);

  // Move to safe rest position on boot
  goToRest();
  delay(500);

  // Signal ready
  Serial.println("EVENT:READY");
  lastPingTime = millis();
}

// ─────────────────────────────────────────────
// MAIN LOOP
// ─────────────────────────────────────────────
void loop() {
  // Read serial input character by character
  while (Serial.available() > 0) {
    char c = (char)Serial.read();
    if (c == '\n') {
      inputBuffer.trim();
      if (inputBuffer.length() > 0) {
        parseAndExecute(inputBuffer);
      }
      inputBuffer = "";
    } else {
      inputBuffer += c;
    }
  }

  // Safety: if no ping received for PING_TIMEOUT_MS, go to rest
  if (millis() - lastPingTime > PING_TIMEOUT_MS) {
    goToRest();
    lastPingTime = millis(); // Reset to avoid spamming rest
  }
}

// ─────────────────────────────────────────────
// COMMAND PARSER
// ─────────────────────────────────────────────
void parseAndExecute(String cmd) {

  // ── PING ──────────────────────────────────
  if (cmd == "PING") {
    lastPingTime = millis();
    Serial.println("PONG");
    return;
  }

  // ── STOP ──────────────────────────────────
  if (cmd == "STOP") {
    gestureRunning = false;
    goToRest();
    Serial.println("ACK:STOP");
    return;
  }

  // ── STATUS ────────────────────────────────
  if (cmd == "STATUS") {
    Serial.print("STATUS:OK:SERVOS:11:FW:");
    Serial.println(FIRMWARE_VERSION);
    return;
  }

  // ── HELLO (version handshake) ─────────────
  if (cmd.startsWith("HELLO:")) {
    Serial.print("HELLO:ARDUINO:");
    Serial.println(FIRMWARE_VERSION);
    return;
  }

  // ── JOINT:NAME:ANGLE ──────────────────────
  if (cmd.startsWith("JOINT:")) {
    handleJointCommand(cmd);
    return;
  }

  // ── GESTURE:NAME ──────────────────────────
  if (cmd.startsWith("GESTURE:")) {
    String gesture = cmd.substring(8);
    handleGestureCommand(gesture);
    return;
  }

  // ── POSE:a0,a1,...,a10 (11 angles) ────────
  if (cmd.startsWith("POSE:")) {
    handlePoseCommand(cmd.substring(5));
    return;
  }

  // ── SPEED:level ───────────────────────────
  if (cmd.startsWith("SPEED:")) {
    // Speed is handled in gesture sequences
    // Store globally if needed in future versions
    Serial.print("ACK:");
    Serial.println(cmd);
    return;
  }

  // Unknown command
  Serial.print("ERR:UNKNOWN_CMD:");
  Serial.println(cmd);
}

// ─────────────────────────────────────────────
// JOINT COMMAND HANDLER
// Format: JOINT:R_ELBOW:90
// ─────────────────────────────────────────────
void handleJointCommand(String cmd) {
  // Find first colon after "JOINT:"
  int firstColon = cmd.indexOf(':', 6);
  if (firstColon < 0) {
    Serial.println("ERR:PARSE_FAIL:JOINT_FORMAT");
    return;
  }

  String jointName = cmd.substring(6, firstColon);
  int angle = cmd.substring(firstColon + 1).toInt();

  if (!setJoint(jointName, angle)) {
    Serial.print("ERR:INVALID_JOINT:");
    Serial.println(jointName);
    return;
  }

  Serial.print("ACK:");
  Serial.println(cmd);
}

// ─────────────────────────────────────────────
// SET INDIVIDUAL JOINT
// Returns true if joint name recognised
// ─────────────────────────────────────────────
bool setJoint(String name, int angle) {
  if (name == "NECK_PAN") {
    neckPan.write(constrain(angle, NECK_PAN_MIN, NECK_PAN_MAX));
  } else if (name == "NECK_TILT") {
    neckTilt.write(constrain(angle, NECK_TILT_MIN, NECK_TILT_MAX));
  } else if (name == "R_SHOULDER_X") {
    rShoulderX.write(constrain(angle, R_SHOULDER_X_MIN, R_SHOULDER_X_MAX));
  } else if (name == "R_SHOULDER_Y") {
    rShoulderY.write(constrain(angle, R_SHOULDER_Y_MIN, R_SHOULDER_Y_MAX));
  } else if (name == "R_ELBOW") {
    rElbow.write(constrain(angle, R_ELBOW_MIN, R_ELBOW_MAX));
  } else if (name == "R_WRIST") {
    rWrist.write(constrain(angle, R_WRIST_MIN, R_WRIST_MAX));
  } else if (name == "R_THUMB") {
    rThumb.write(constrain(angle, THUMB_MIN, THUMB_MAX));
  } else if (name == "R_INDEX") {
    rIndex.write(constrain(angle, FINGER_MIN, FINGER_MAX));
  } else if (name == "R_MIDDLE") {
    rMiddle.write(constrain(angle, FINGER_MIN, FINGER_MAX));
  } else if (name == "R_RING") {
    rRing.write(constrain(angle, FINGER_MIN, FINGER_MAX));
  } else if (name == "R_PINKY") {
    rPinky.write(constrain(angle, FINGER_MIN, FINGER_MAX));
  } else {
    return false; // Joint not on this Arduino
  }
  return true;
}

// ─────────────────────────────────────────────
// POSE COMMAND HANDLER
// Format: POSE:90,90,90,90,90,90,0,0,0,0,0
// Order:  neck_pan, neck_tilt, r_shoulder_x,
//         r_shoulder_y, r_elbow, r_wrist,
//         r_thumb, r_index, r_middle, r_ring, r_pinky
// ─────────────────────────────────────────────
void handlePoseCommand(String data) {
  int angles[11];
  int count = 0;
  int startIdx = 0;

  for (int i = 0; i <= data.length() && count < 11; i++) {
    if (i == data.length() || data[i] == ',') {
      angles[count++] = data.substring(startIdx, i).toInt();
      startIdx = i + 1;
    }
  }

  if (count < 11) {
    Serial.println("ERR:PARSE_FAIL:POSE_COUNT");
    return;
  }

  neckPan.write(constrain(angles[0],  NECK_PAN_MIN,     NECK_PAN_MAX));
  neckTilt.write(constrain(angles[1], NECK_TILT_MIN,    NECK_TILT_MAX));
  rShoulderX.write(constrain(angles[2], R_SHOULDER_X_MIN, R_SHOULDER_X_MAX));
  rShoulderY.write(constrain(angles[3], R_SHOULDER_Y_MIN, R_SHOULDER_Y_MAX));
  rElbow.write(constrain(angles[4],   R_ELBOW_MIN,      R_ELBOW_MAX));
  rWrist.write(constrain(angles[5],   R_WRIST_MIN,      R_WRIST_MAX));
  rThumb.write(constrain(angles[6],   THUMB_MIN,        THUMB_MAX));
  rIndex.write(constrain(angles[7],   FINGER_MIN,       FINGER_MAX));
  rMiddle.write(constrain(angles[8],  FINGER_MIN,       FINGER_MAX));
  rRing.write(constrain(angles[9],    FINGER_MIN,       FINGER_MAX));
  rPinky.write(constrain(angles[10],  FINGER_MIN,       FINGER_MAX));

  Serial.println("ACK:POSE");
}

// ─────────────────────────────────────────────
// GESTURE COMMAND HANDLER
// ─────────────────────────────────────────────
void handleGestureCommand(String gesture) {
  if (gesture == "OPEN")     { gestureOpen();     }
  else if (gesture == "GRIP")     { gestureGrip();     }
  else if (gesture == "POINT")    { gesturePoint();    }
  else if (gesture == "PINCH")    { gesturePinch();    }
  else if (gesture == "WAVE")     { gestureWave();     }
  else if (gesture == "THUMBSUP") { gestureThumbsUp(); }
  else if (gesture == "PEACE")    { gesturePeace();    }
  else if (gesture == "HELLO")    { gestureHello();    }
  else if (gesture == "REST")     { goToRest();        }
  else if (gesture == "NOD")      { gestureNod();      }
  else if (gesture == "SHAKE")    { gestureShake();    }
  else if (gesture == "CLAP")     {
    // CLAP requires both arms — acknowledge only, left Arduino handles it
    Serial.println("ACK:GESTURE:CLAP");
    return;
  }
  else {
    Serial.print("ERR:UNKNOWN_GESTURE:");
    Serial.println(gesture);
    return;
  }

  Serial.print("ACK:GESTURE:");
  Serial.println(gesture);
  Serial.print("EVENT:GESTURE_DONE:");
  Serial.println(gesture);
}

// ─────────────────────────────────────────────
// GESTURE IMPLEMENTATIONS
// ─────────────────────────────────────────────

void gestureOpen() {
  rThumb.write(THUMB_REST);
  rIndex.write(FINGER_REST);
  rMiddle.write(FINGER_REST);
  rRing.write(FINGER_REST);
  rPinky.write(FINGER_REST);
}

void gestureGrip() {
  rThumb.write(THUMB_MAX);
  delay(100);
  rIndex.write(FINGER_MAX);
  rMiddle.write(FINGER_MAX);
  rRing.write(FINGER_MAX);
  rPinky.write(FINGER_MAX);
}

void gesturePoint() {
  gestureOpen();
  delay(200);
  rThumb.write(THUMB_MAX);
  rMiddle.write(FINGER_MAX);
  rRing.write(FINGER_MAX);
  rPinky.write(FINGER_MAX);
}

void gesturePinch() {
  gestureOpen();
  delay(200);
  rThumb.write(90);
  rIndex.write(90);
}

void gestureThumbsUp() {
  // Curl all fingers except thumb
  rIndex.write(FINGER_MAX);
  rMiddle.write(FINGER_MAX);
  rRing.write(FINGER_MAX);
  rPinky.write(FINGER_MAX);
  rThumb.write(THUMB_REST);
}

void gesturePeace() {
  gestureGrip();
  delay(300);
  rIndex.write(FINGER_REST);
  rMiddle.write(FINGER_REST);
}

void gestureWave() {
  // Raise elbow, open hand, wave wrist side to side 3 times
  gestureOpen();
  rElbow.write(60);
  rShoulderY.write(120);
  delay(400);
  for (int i = 0; i < 3; i++) {
    rWrist.write(30);  delay(350);
    rWrist.write(150); delay(350);
  }
  rWrist.write(90);
  delay(300);
  goToRest();
}

void gestureHello() {
  gestureOpen();
  rShoulderY.write(150);
  rElbow.write(45);
  delay(300);
  for (int i = 0; i < 2; i++) {
    rWrist.write(40);  delay(300);
    rWrist.write(140); delay(300);
  }
  rWrist.write(90);
  delay(500);
  goToRest();
}

void gestureNod() {
  for (int i = 0; i < 2; i++) {
    neckTilt.write(NECK_TILT_MIN + 5);  delay(400);
    neckTilt.write(NECK_TILT_MAX - 5);  delay(400);
  }
  neckTilt.write(NECK_TILT_REST);
}

void gestureShake() {
  for (int i = 0; i < 3; i++) {
    neckPan.write(60);  delay(300);
    neckPan.write(120); delay(300);
  }
  neckPan.write(NECK_PAN_REST);
}

// ─────────────────────────────────────────────
// REST POSITION — safe neutral for all joints
// ─────────────────────────────────────────────
void goToRest() {
  neckPan.write(NECK_PAN_REST);
  neckTilt.write(NECK_TILT_REST);
  rShoulderX.write(R_SHOULDER_X_REST);
  rShoulderY.write(R_SHOULDER_Y_REST);
  rElbow.write(R_ELBOW_REST);
  rWrist.write(R_WRIST_REST);
  rThumb.write(THUMB_REST);
  rIndex.write(FINGER_REST);
  rMiddle.write(FINGER_REST);
  rRing.write(FINGER_REST);
  rPinky.write(FINGER_REST);
}
