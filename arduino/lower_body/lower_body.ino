/**
 * FlutterMind — Arduino #2 Firmware
 * Controls: Left arm (4), Left hand (5), Torso (2) = 11 servos
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
#define ARDUINO_ID       "LOWER"

// ─────────────────────────────────────────────
// PIN ASSIGNMENTS
// ─────────────────────────────────────────────
const int PIN_L_SHOULDER_X = 2;
const int PIN_L_SHOULDER_Y = 3;
const int PIN_L_ELBOW      = 4;
const int PIN_L_WRIST      = 5;
const int PIN_L_THUMB      = 6;
const int PIN_L_INDEX      = 7;
const int PIN_L_MIDDLE     = 8;
const int PIN_L_RING       = 9;
const int PIN_L_PINKY      = 10;
const int PIN_SPINE_BEND   = 11;
const int PIN_WAIST_ROTATE = 12;

// ─────────────────────────────────────────────
// SERVO SAFE RANGES
// ─────────────────────────────────────────────
const int L_SHOULDER_X_MIN = 0,   L_SHOULDER_X_MAX = 180, L_SHOULDER_X_REST = 90;
const int L_SHOULDER_Y_MIN = 0,   L_SHOULDER_Y_MAX = 180, L_SHOULDER_Y_REST = 90;
const int L_ELBOW_MIN      = 0,   L_ELBOW_MAX      = 150, L_ELBOW_REST      = 90;
const int L_WRIST_MIN      = 0,   L_WRIST_MAX      = 180, L_WRIST_REST      = 90;
const int FINGER_MIN       = 0,   FINGER_MAX        = 175, FINGER_REST       = 0;
const int THUMB_MIN        = 0,   THUMB_MAX         = 170, THUMB_REST        = 0;
const int SPINE_BEND_MIN   = 60,  SPINE_BEND_MAX    = 120, SPINE_BEND_REST   = 90;
const int WAIST_MIN        = 45,  WAIST_MAX         = 135, WAIST_REST        = 90;

// ─────────────────────────────────────────────
// SERVO OBJECTS
// ─────────────────────────────────────────────
Servo lShoulderX, lShoulderY;
Servo lElbow, lWrist;
Servo lThumb, lIndex, lMiddle, lRing, lPinky;
Servo spineBend, waistRotate;

// ─────────────────────────────────────────────
// STATE
// ─────────────────────────────────────────────
String inputBuffer = "";
unsigned long lastPingTime = 0;
const unsigned long PING_TIMEOUT_MS = 5000;

// ─────────────────────────────────────────────
// SETUP
// ─────────────────────────────────────────────
void setup() {
  Serial.begin(115200);

  lShoulderX.attach(PIN_L_SHOULDER_X);
  lShoulderY.attach(PIN_L_SHOULDER_Y);
  lElbow.attach(PIN_L_ELBOW);
  lWrist.attach(PIN_L_WRIST);
  lThumb.attach(PIN_L_THUMB);
  lIndex.attach(PIN_L_INDEX);
  lMiddle.attach(PIN_L_MIDDLE);
  lRing.attach(PIN_L_RING);
  lPinky.attach(PIN_L_PINKY);
  spineBend.attach(PIN_SPINE_BEND);
  waistRotate.attach(PIN_WAIST_ROTATE);

  goToRest();
  delay(500);

  Serial.println("EVENT:READY");
  lastPingTime = millis();
}

// ─────────────────────────────────────────────
// MAIN LOOP
// ─────────────────────────────────────────────
void loop() {
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

  if (millis() - lastPingTime > PING_TIMEOUT_MS) {
    goToRest();
    lastPingTime = millis();
  }
}

// ─────────────────────────────────────────────
// COMMAND PARSER
// ─────────────────────────────────────────────
void parseAndExecute(String cmd) {

  if (cmd == "PING") {
    lastPingTime = millis();
    Serial.println("PONG");
    return;
  }

  if (cmd == "STOP") {
    goToRest();
    Serial.println("ACK:STOP");
    return;
  }

  if (cmd == "STATUS") {
    Serial.print("STATUS:OK:SERVOS:11:FW:");
    Serial.println(FIRMWARE_VERSION);
    return;
  }

  if (cmd.startsWith("HELLO:")) {
    Serial.print("HELLO:ARDUINO:");
    Serial.println(FIRMWARE_VERSION);
    return;
  }

  if (cmd.startsWith("JOINT:")) {
    handleJointCommand(cmd);
    return;
  }

  if (cmd.startsWith("GESTURE:")) {
    String gesture = cmd.substring(8);
    handleGestureCommand(gesture);
    return;
  }

  if (cmd.startsWith("POSE:")) {
    handlePoseCommand(cmd.substring(5));
    return;
  }

  if (cmd.startsWith("SPEED:")) {
    Serial.print("ACK:");
    Serial.println(cmd);
    return;
  }

  Serial.print("ERR:UNKNOWN_CMD:");
  Serial.println(cmd);
}

// ─────────────────────────────────────────────
// JOINT COMMAND HANDLER
// ─────────────────────────────────────────────
void handleJointCommand(String cmd) {
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
// ─────────────────────────────────────────────
bool setJoint(String name, int angle) {
  if      (name == "L_SHOULDER_X") { lShoulderX.write(constrain(angle, L_SHOULDER_X_MIN, L_SHOULDER_X_MAX)); }
  else if (name == "L_SHOULDER_Y") { lShoulderY.write(constrain(angle, L_SHOULDER_Y_MIN, L_SHOULDER_Y_MAX)); }
  else if (name == "L_ELBOW")      { lElbow.write(constrain(angle, L_ELBOW_MIN, L_ELBOW_MAX)); }
  else if (name == "L_WRIST")      { lWrist.write(constrain(angle, L_WRIST_MIN, L_WRIST_MAX)); }
  else if (name == "L_THUMB")      { lThumb.write(constrain(angle, THUMB_MIN, THUMB_MAX)); }
  else if (name == "L_INDEX")      { lIndex.write(constrain(angle, FINGER_MIN, FINGER_MAX)); }
  else if (name == "L_MIDDLE")     { lMiddle.write(constrain(angle, FINGER_MIN, FINGER_MAX)); }
  else if (name == "L_RING")       { lRing.write(constrain(angle, FINGER_MIN, FINGER_MAX)); }
  else if (name == "L_PINKY")      { lPinky.write(constrain(angle, FINGER_MIN, FINGER_MAX)); }
  else if (name == "SPINE_BEND")   { spineBend.write(constrain(angle, SPINE_BEND_MIN, SPINE_BEND_MAX)); }
  else if (name == "WAIST_ROTATE") { waistRotate.write(constrain(angle, WAIST_MIN, WAIST_MAX)); }
  else { return false; }
  return true;
}

// ─────────────────────────────────────────────
// POSE COMMAND
// Order: l_shoulder_x, l_shoulder_y, l_elbow,
//        l_wrist, l_thumb, l_index, l_middle,
//        l_ring, l_pinky, spine_bend, waist_rotate
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

  lShoulderX.write(constrain(angles[0],  L_SHOULDER_X_MIN, L_SHOULDER_X_MAX));
  lShoulderY.write(constrain(angles[1],  L_SHOULDER_Y_MIN, L_SHOULDER_Y_MAX));
  lElbow.write(constrain(angles[2],      L_ELBOW_MIN,      L_ELBOW_MAX));
  lWrist.write(constrain(angles[3],      L_WRIST_MIN,      L_WRIST_MAX));
  lThumb.write(constrain(angles[4],      THUMB_MIN,        THUMB_MAX));
  lIndex.write(constrain(angles[5],      FINGER_MIN,       FINGER_MAX));
  lMiddle.write(constrain(angles[6],     FINGER_MIN,       FINGER_MAX));
  lRing.write(constrain(angles[7],       FINGER_MIN,       FINGER_MAX));
  lPinky.write(constrain(angles[8],      FINGER_MIN,       FINGER_MAX));
  spineBend.write(constrain(angles[9],   SPINE_BEND_MIN,   SPINE_BEND_MAX));
  waistRotate.write(constrain(angles[10],WAIST_MIN,        WAIST_MAX));

  Serial.println("ACK:POSE");
}

// ─────────────────────────────────────────────
// GESTURE HANDLER
// ─────────────────────────────────────────────
void handleGestureCommand(String gesture) {
  if      (gesture == "OPEN")     { gestureOpen();    }
  else if (gesture == "GRIP")     { gestureGrip();    }
  else if (gesture == "POINT")    { gesturePoint();   }
  else if (gesture == "PINCH")    { gesturePinch();   }
  else if (gesture == "THUMBSUP") { gestureThumbsUp();}
  else if (gesture == "PEACE")    { gesturePeace();   }
  else if (gesture == "CLAP")     { gestureClap();    }
  else if (gesture == "REST")     { goToRest();       }
  else if (gesture == "WAVE")     {
    // Wave is right arm only — acknowledge and skip
    Serial.println("ACK:GESTURE:WAVE");
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
  lThumb.write(THUMB_REST);
  lIndex.write(FINGER_REST);
  lMiddle.write(FINGER_REST);
  lRing.write(FINGER_REST);
  lPinky.write(FINGER_REST);
}

void gestureGrip() {
  lThumb.write(THUMB_MAX);
  delay(100);
  lIndex.write(FINGER_MAX);
  lMiddle.write(FINGER_MAX);
  lRing.write(FINGER_MAX);
  lPinky.write(FINGER_MAX);
}

void gesturePoint() {
  gestureOpen();
  delay(200);
  lThumb.write(THUMB_MAX);
  lMiddle.write(FINGER_MAX);
  lRing.write(FINGER_MAX);
  lPinky.write(FINGER_MAX);
}

void gesturePinch() {
  gestureOpen();
  delay(200);
  lThumb.write(90);
  lIndex.write(90);
}

void gestureThumbsUp() {
  lIndex.write(FINGER_MAX);
  lMiddle.write(FINGER_MAX);
  lRing.write(FINGER_MAX);
  lPinky.write(FINGER_MAX);
  lThumb.write(THUMB_REST);
}

void gesturePeace() {
  gestureGrip();
  delay(300);
  lIndex.write(FINGER_REST);
  lMiddle.write(FINGER_REST);
}

void gestureClap() {
  // Both arms swing in: left shoulder forward
  gestureOpen();
  lShoulderX.write(150);
  delay(400);
  lShoulderX.write(L_SHOULDER_X_REST);
  delay(300);
  lShoulderX.write(150);
  delay(400);
  lShoulderX.write(L_SHOULDER_X_REST);
}

// ─────────────────────────────────────────────
// REST POSITION
// ─────────────────────────────────────────────
void goToRest() {
  lShoulderX.write(L_SHOULDER_X_REST);
  lShoulderY.write(L_SHOULDER_Y_REST);
  lElbow.write(L_ELBOW_REST);
  lWrist.write(L_WRIST_REST);
  lThumb.write(THUMB_REST);
  lIndex.write(FINGER_REST);
  lMiddle.write(FINGER_REST);
  lRing.write(FINGER_REST);
  lPinky.write(FINGER_REST);
  spineBend.write(SPINE_BEND_REST);
  waistRotate.write(WAIST_REST);
}
