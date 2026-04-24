# FlutterMind 🤖

**An open-source AI robot powered entirely by your smartphone.**

> Build a 3D printed humanoid robot arm that thinks, sees, and responds to voice — using only your Android phone as the brain, a USB-C cable, and ~₹7,000 in parts.

<br/>

[![License: MIT](https://img.shields.io/badge/License-MIT-purple.svg)](LICENSE)
[![Flutter](https://img.shields.io/badge/Flutter-3.x-blue.svg)](https://flutter.dev)
[![Arduino](https://img.shields.io/badge/Arduino-Nano-teal.svg)](https://arduino.cc)
[![Gemma](https://img.shields.io/badge/Gemma_4-E4B-orange.svg)](https://ai.google.dev/gemma)
[![Stars](https://img.shields.io/github/stars/yourusername/fluttermind?style=social)](https://github.com/yourusername/fluttermind)

---

## What is FlutterMind?

FlutterMind is a fully open-source robotic skeleton controlled by a Flutter app running on your Android phone. The phone connects to an Arduino motor controller via a USB-C OTG cable, which drives 22 servo motors across a 3D printed humanoid upper body.

The phone is not just a remote — it **is** the brain. Gemma 4 E4B runs directly on the phone's processor. No cloud. No Raspberry Pi. No laptop.

```
Your voice
    │
    ▼
Whisper STT (on phone)
    │
    ▼
Gemma 4 E4B LLM (on phone, offline)
    │
    ▼
Flutter app → USB-C OTG cable
    │
    ▼
Arduino Nano × 2 → PWM signals
    │
    ▼
22 × MG90S servos → 3D printed skeleton
```

---

## Why FlutterMind?

Every existing open-source robot (InMoov, pib, Berkeley Humanoid Lite) requires a Raspberry Pi, a PC, or a cloud API as the brain. FlutterMind eliminates all of that.

| Feature | InMoov | pib | FlutterMind |
|---|---|---|---|
| Brain | PC | Raspberry Pi | **Android phone** |
| AI | Cloud API | Cloud API | **On-device, offline** |
| Control app | Generic | Generic | **Custom Flutter app** |
| Vision + voice | Separate modules | Separate modules | **One model (Gemma 4)** |
| Cost | ~₹15,000+ | ~₹20,000+ | **~₹7,000** |
| Works offline | ❌ | ❌ | ✅ |

---

## Demo

> 📹 _Video coming in Phase 2 — contribute your build videos!_

**Gesture demo:** Voice command `"pick up the bottle"` → Gemma 4 decides `GRIP` → Arduino moves all 5 finger servos → hand closes.

**Vision demo:** Phone camera sees a red ball → Gemma 4 describes it → robot points toward it.

---

## Hardware

### What you need

| Part | Quantity | Approx. cost (INR) |
|---|---|---|
| MG90S micro servo | 22 | ₹3,300 |
| Arduino Nano | 2 | ₹800 |
| USB-C OTG to USB-A cable | 1 | ₹150 |
| PLA filament (1kg rolls) | 2 | ₹1,400 |
| 5V 3A power bank (for servos) | 1 | ₹800 |
| 2mm steel rods (joint pins) | 1 pack | ₹200 |
| Jumper wires + connectors | — | ₹400 |
| **Total** | | **~₹7,050** |

### Servo layout

```
Head:      neck_pan, neck_tilt                    (2 servos)
Right arm: shoulder_x, shoulder_y, elbow, wrist   (4 servos)
Right hand: thumb, index, middle, ring, pinky      (5 servos)
Left arm:  shoulder_x, shoulder_y, elbow, wrist   (4 servos)
Left hand: thumb, index, middle, ring, pinky       (5 servos)
Torso:     spine_bend, waist_rotate               (2 servos)
                                           Total: 22 servos
```

### Wiring diagram

```
Android phone (USB-C OTG host mode)
        │
        │ USB-C to USB-A
        │
  ┌─────┴──────────────────────────┐
  │  USB hub (optional)            │
  └─────┬────────────┬─────────────┘
        │            │
  Arduino #1         Arduino #2
  (right arm+head)   (left arm+torso)
        │                   │
  PWM signals         PWM signals
        │                   │
  servos 1–11          servos 12–22
        │                   │
        └────────────────────┘
                  │
            Power bank 5V
         (separate from Arduino)
```

> ⚠️ **Important:** Never power servos from the Arduino 5V pin — they draw too much current. Always use a separate power bank.

---

## 3D Printing

FlutterMind uses modified [InMoov](https://inmoov.fr) STL files as the base skeleton. InMoov is an open-source, fully 3D printable humanoid robot by Gaël Langevin.

### Print settings

| Setting | Value |
|---|---|
| Material | PLA |
| Infill | 30% |
| Layer height | 0.2mm |
| Supports | Yes (arm joints) |
| Nozzle | 0.4mm |

### Build order

Start with the hand — it's the most satisfying and lets you test the full pipeline early.

```
Week 1: Right hand (finger segments, knuckles, palm housing)
Week 2: Right forearm + elbow joint
Week 3: Right upper arm + shoulder bracket
Week 4: Left arm (mirror of right)
Week 5: Torso cage + phone/Arduino mount
Week 6: Head shell (camera + mic cutouts)
```

STL files are in the `/stl` folder of this repo. See [PRINTING.md](docs/PRINTING.md) for detailed instructions.

---

## Software

### Requirements

- Android phone (Android 10+, 4GB+ RAM recommended)
- Flutter 3.x / Dart 3.x
- Arduino IDE 2.x
- Gemma 4 E4B model (downloaded on-device)

### Project structure

```
fluttermind/
├── app/                        # Flutter app
│   ├── lib/
│   │   ├── main.dart
│   │   ├── services/
│   │   │   ├── usb_robot_service.dart
│   │   │   ├── llm_brain_service.dart
│   │   │   ├── voice_service.dart
│   │   │   └── robot_state_service.dart
│   │   ├── models/
│   │   │   ├── robot_pose.dart
│   │   │   └── robot_command.dart
│   │   └── screens/
│   │       ├── home_screen.dart
│   │       ├── manual_control_screen.dart
│   │       ├── gesture_screen.dart
│   │       └── ai_mode_screen.dart
│   └── pubspec.yaml
│
├── arduino/                    # Arduino firmware
│   ├── upper_body/
│   │   └── upper_body.ino      # Right arm + head
│   └── lower_body/
│       └── lower_body.ino      # Left arm + torso
│
├── ai/                         # AI / fine-tuning
│   ├── prepare_dataset.py      # Convert IRND CSV → JSONL
│   ├── fine_tune.py            # Unsloth + LoRA training
│   └── Modelfile               # Ollama model definition
│
├── stl/                        # 3D printable files
│   ├── hand/
│   ├── arm/
│   ├── torso/
│   └── head/
│
├── docs/
│   ├── PRINTING.md
│   ├── WIRING.md
│   ├── AI_TRAINING.md
│   └── CONTRIBUTING.md
│
└── README.md
```

---

## Getting Started

### 1. Flash Arduino firmware

```bash
# Clone the repo
git clone https://github.com/yourusername/fluttermind.git
cd fluttermind

# Open in Arduino IDE
# Flash arduino/upper_body/upper_body.ino to Arduino #1
# Flash arduino/lower_body/lower_body.ino to Arduino #2
```

### 2. Set up Flutter app

```bash
cd app
flutter pub get
flutter run
```

The app will detect your Arduino automatically when connected via USB-C OTG.

### 3. Set up Gemma 4 on-device

The app uses [Google AI Edge](https://ai.google.dev/edge) to run Gemma 4 E4B directly on the phone. On first launch, it will prompt you to download the model (~2.5GB). Requires Wi-Fi for the initial download only — after that, everything runs offline.

### 4. Connect and test

```
1. Connect USB-C OTG cable from phone to Arduino
2. Open FlutterMind app
3. Tap "Connect" — should show green USB status
4. Try a quick gesture: tap "Open Hand"
5. Try voice: hold the mic button → say "wave hello"
```

---

## Flutter App Features

| Screen | Description |
|---|---|
| Manual control | Individual sliders for all 22 joints |
| Gesture presets | One-tap: Open, Grip, Point, Pinch, Wave, Thumbs up |
| AI mode | Hold mic → speak → Gemma 4 decides the action |
| Vision mode | Phone camera → Gemma 4 sees and reacts in real time |
| Pose recorder | Save and replay custom joint angle sequences |

---

## AI Training (Optional)

The default model is Gemma 4 E4B with a robot-specific system prompt — this works well out of the box.

For better performance on your specific robot and environment, you can fine-tune using the [Indoor Robot Navigation Dataset (IRND)](https://www.kaggle.com/datasets/narayananpp/indoor-robot-navigation-dataset-irnd).

```bash
cd ai

# 1. Download IRND dataset from Kaggle
kaggle datasets download -d narayananpp/indoor-robot-navigation-dataset-irnd

# 2. Convert CSV to Gemma 4 training format
python prepare_dataset.py

# 3. Fine-tune on Google Colab (free T4 GPU)
# Upload fine_tune.py to Colab and run
# Takes ~2-3 hours

# 4. Export to GGUF and deploy via Ollama
# See docs/AI_TRAINING.md for full walkthrough
```

---

## Serial Protocol

The Flutter app communicates with Arduino using a simple newline-delimited text protocol over USB serial at 115200 baud.

```
# Single joint control
JOINT:R_ELBOW:90\n          → set right elbow to 90°

# Named gesture
GESTURE:WAVE\n              → trigger wave sequence

# Fine finger control
JOINT:R_INDEX:160\n         → curl right index finger

# Emergency stop
STOP\n                      → all servos to rest position

# Arduino replies
ACK:JOINT:R_ELBOW:90\n      → confirm command received
ERR:UNKNOWN_CMD\n           → unknown command
```

Full protocol reference: [docs/PROTOCOL.md](docs/PROTOCOL.md)

---

## Roadmap

- [x] Project architecture and documentation
- [ ] Phase 1 — Single hand working via Flutter sliders
- [ ] Phase 2 — Full arm + Whisper voice control
- [ ] Phase 3 — Full skeleton + Gemma 4 vision
- [ ] Phase 4 — Fine-tuned model + open-source launch
- [ ] Phase 5 — Wireless mode (Wi-Fi, cut the cable)
- [ ] Phase 6 — Glove mirroring (wear a glove, robot mirrors your hand)
- [ ] Phase 7 — iOS support

---

## Contributing

FlutterMind is at an early stage and welcomes contributors of all kinds.

**Ways to contribute:**

- 🖨️ **Makers** — Build it, document your experience, suggest hardware improvements
- 👨‍💻 **Flutter devs** — Improve the app UI, add features, fix bugs
- 🤖 **AI/ML** — Improve the fine-tuning pipeline, add new datasets
- 🎨 **Designers** — Improve STL files, design a better chassis
- 📝 **Writers** — Improve docs, write tutorials, translate to other languages

Please read [CONTRIBUTING.md](docs/CONTRIBUTING.md) before opening a pull request.

---

## Community

- 💬 **Discord** — [discord.gg/fluttermind](#) _(coming soon)_
- 🐛 **Issues** — [GitHub Issues](https://github.com/yourusername/fluttermind/issues)
- 💡 **Ideas** — [GitHub Discussions](https://github.com/yourusername/fluttermind/discussions)
- 🌐 **Instructables** — Full step-by-step build guide _(coming in Phase 1)_
- 📰 **Hackaday** — Project page _(coming in Phase 2)_

---

## Acknowledgements

- [InMoov](https://inmoov.fr) by Gaël Langevin — the open-source humanoid skeleton this project builds on
- [Google Gemma 4](https://ai.google.dev/gemma) — the on-device LLM powering the robot brain
- [IRND Dataset](https://www.kaggle.com/datasets/narayananpp/indoor-robot-navigation-dataset-irnd) — indoor robot navigation training data
- [Unsloth](https://github.com/unslothai/unsloth) — fast LLM fine-tuning

---

## License

- **Flutter app code** — [MIT License](LICENSE)
- **Arduino firmware** — [MIT License](LICENSE)
- **AI training scripts** — [Apache 2.0](LICENSE-APACHE)
- **Modified STL files** — [Creative Commons BY 4.0](LICENSE-CC)

The original InMoov STL files are licensed under [Creative Commons BY-NC](https://creativecommons.org/licenses/by-nc/4.0/) by Gaël Langevin. Commercial use of the STL files requires a separate agreement with InMoov.

---

<div align="center">

**Built with ❤️ in Kerala, India**

_If FlutterMind helped you, please give it a ⭐ on GitHub_

</div>
