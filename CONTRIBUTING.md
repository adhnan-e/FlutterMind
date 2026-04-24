# Contributing to FlutterMind 🤖

First of all — thank you for considering a contribution to FlutterMind. This project exists because of makers, developers, and tinkerers who believe intelligent robotics should be accessible to everyone, not just well-funded labs.

This document is your complete guide to getting involved — whether you're fixing a typo, printing a hand, or training a new AI model.

---

## Table of Contents

- [Code of Conduct](#code-of-conduct)
- [Ways to Contribute](#ways-to-contribute)
- [Before You Start](#before-you-start)
- [Development Setup](#development-setup)
- [Project Structure](#project-structure)
- [Contribution Workflows](#contribution-workflows)
  - [Reporting a Bug](#reporting-a-bug)
  - [Suggesting a Feature](#suggesting-a-feature)
  - [Submitting Code](#submitting-code)
  - [Submitting STL Files](#submitting-stl-files)
  - [Improving Documentation](#improving-documentation)
  - [Sharing Your Build](#sharing-your-build)
- [Coding Standards](#coding-standards)
- [Commit Message Format](#commit-message-format)
- [Pull Request Checklist](#pull-request-checklist)
- [Good First Issues](#good-first-issues)
- [Recognition](#recognition)

---

## Code of Conduct

FlutterMind is an inclusive project. We expect all contributors to:

- Be respectful and constructive in all discussions
- Welcome contributors of all skill levels — beginners are especially encouraged
- Give credit where it is due
- Focus feedback on the work, not the person

Violations can be reported by opening a private issue or emailing the maintainer directly. We take this seriously.

---

## Ways to Contribute

You do not need to write code to make a meaningful contribution. Here are all the ways you can help:

| Role | How you help |
|---|---|
| 🖨️ **Maker** | Build the robot, document issues, suggest hardware improvements |
| 👨‍💻 **Flutter dev** | Improve the app, add features, fix bugs |
| ⚡ **Arduino dev** | Improve firmware, add new servo configurations |
| 🤖 **AI / ML** | Improve fine-tuning, add datasets, optimize inference |
| 🎨 **3D designer** | Improve STL files, design new body parts or mounts |
| 📝 **Writer** | Improve docs, write tutorials, translate to other languages |
| 🧪 **Tester** | Test on different phones and hardware, report edge cases |
| 🌐 **Community** | Answer questions on Discord, help new builders |

---

## Before You Start

### Check existing issues first

Before opening a new issue or starting work on a feature, search the [existing issues](https://github.com/adhnan-e/fluttermind/issues) and [discussions](https://github.com/adhnan-e/fluttermind/discussions). Someone may already be working on it.

### For large changes — discuss first

If you want to make a significant change (new screen in the app, new body part STL, new AI pipeline), please open a GitHub Discussion or comment on an existing issue before writing code. This avoids duplicate effort and ensures the change fits the project direction.

### For small changes — just open a PR

Typos, doc fixes, small bug fixes, and minor UI improvements do not need a prior discussion. Just open a pull request.

---

## Development Setup

### Flutter app

```bash
# 1. Fork the repo and clone your fork
git clone https://github.com/YOUR_USERNAME/fluttermind.git
cd fluttermind/app

# 2. Install dependencies
flutter pub get

# 3. Run on your connected Android device
flutter run

# 4. Run tests
flutter test
```

**Minimum requirements:**
- Flutter 3.x / Dart 3.x
- Android device with USB debugging enabled (Android 10+)
- USB-C OTG cable for hardware testing (not needed for UI-only changes)

### Arduino firmware

```bash
# Open Arduino IDE 2.x
# File → Open → arduino/upper_body/upper_body.ino

# Required libraries (install via Library Manager):
#   - Servo (built-in)
#   - Wire (built-in)

# Board: Arduino Nano
# Processor: ATmega328P (Old Bootloader) — for most cheap Nano clones
# Port: your USB port
```

### AI / Python scripts

```bash
cd ai
python -m venv venv
source venv/bin/activate        # Windows: venv\Scripts\activate
pip install -r requirements.txt

# Run dataset preparation
python prepare_dataset.py
```

---

## Project Structure

```
fluttermind/
├── app/                        # Flutter app (Dart)
│   ├── lib/
│   │   ├── main.dart
│   │   ├── services/           # USB, LLM, voice, state
│   │   ├── models/             # RobotPose, RobotCommand
│   │   ├── screens/            # UI screens
│   │   └── widgets/            # Reusable UI components
│   └── test/                   # Widget + unit tests
│
├── arduino/                    # Arduino firmware (C++)
│   ├── upper_body/             # Right arm + head controller
│   └── lower_body/             # Left arm + torso controller
│
├── ai/                         # Python — training + fine-tuning
│   ├── prepare_dataset.py
│   ├── fine_tune.py
│   └── requirements.txt
│
├── stl/                        # 3D printable files
│   ├── hand/
│   ├── arm/
│   ├── torso/
│   └── head/
│
└── docs/                       # Documentation
    ├── WIRING.md
    ├── PRINTING.md
    ├── AI_TRAINING.md
    └── PROTOCOL.md
```

---

## Contribution Workflows

### Reporting a Bug

1. Go to [Issues → New Issue](https://github.com/adhnan-e/fluttermind/issues/new)
2. Choose the **Bug Report** template
3. Fill in all sections — especially:
   - Your phone model and Android version
   - Arduino model and firmware version
   - Steps to reproduce (be specific)
   - What you expected vs what happened
   - Any error messages or logs

**For Flutter crashes**, include the output of:
```bash
flutter logs
```

**For Arduino issues**, include the Serial Monitor output.

---

### Suggesting a Feature

1. Go to [Discussions → Ideas](https://github.com/adhnan-e/fluttermind/discussions)
2. Describe the feature and **why it belongs in FlutterMind**
3. If the discussion gets positive response, it becomes a tracked issue

Good feature suggestions answer: _"What problem does this solve for a maker building FlutterMind?"_

---

### Submitting Code

**Step 1 — Fork and branch**

```bash
# Fork the repo on GitHub, then:
git clone https://github.com/YOUR_USERNAME/fluttermind.git
cd fluttermind

# Create a branch named for what you're changing
git checkout -b fix/usb-reconnect-crash
git checkout -b feature/pose-recorder-screen
git checkout -b docs/wiring-diagram-update
```

**Step 2 — Make your changes**

Keep changes focused — one branch per fix or feature. If you find an unrelated bug while working, open a separate issue rather than fixing it in the same PR.

**Step 3 — Test your changes**

For Flutter code:
```bash
flutter test                  # Run unit tests
flutter analyze               # Check for lint issues
flutter format lib/           # Auto-format code
```

For Arduino code:
- Compile in Arduino IDE (Sketch → Verify)
- Test on real hardware if possible
- Document any changes to the serial protocol in `docs/PROTOCOL.md`

**Step 4 — Commit and push**

```bash
git add .
git commit -m "fix: handle USB reconnect crash on Android 13"
git push origin fix/usb-reconnect-crash
```

**Step 5 — Open a pull request**

- Go to your fork on GitHub and click **New Pull Request**
- Fill in the PR template completely
- Link to the related issue with `Closes #123`
- Add screenshots or a short video for UI changes
- Mark as **Draft** if it is still a work in progress

---

### Submitting STL Files

3D design contributions are especially valuable. Before submitting:

- Design files must be parametric and editable (Fusion 360 `.f3d` or FreeCAD `.FCStd` preferred alongside the STL)
- Test print the part yourself before submitting — include a photo
- Note your print settings (infill, supports, layer height)
- Place files in the correct subfolder: `stl/hand/`, `stl/arm/`, etc.
- Name files clearly: `right_index_proximal_phalanx_v2.stl`
- Add a short description of what changed vs the previous version in your PR

---

### Improving Documentation

Documentation lives in the `docs/` folder and the root `README.md`. All docs are written in Markdown.

Things we especially need:
- Translations (Malayalam, Arabic, Spanish, German, French)
- Build logs and photos from your own build
- Video walkthroughs
- Clearer wiring diagrams
- More detailed print settings per body part

For translations, create a new file like `docs/translations/README_ml.md` (ml = Malayalam ISO code).

---

### Sharing Your Build

Built FlutterMind (or part of it)? This is one of the most valuable contributions of all.

Please share:
- Photos of your build at each stage
- Any hardware modifications you made
- Problems you ran into and how you solved them
- Your total cost in your local currency

You can share via:
- GitHub Discussions → **Show and Tell**
- Discord `#builds` channel
- Open a PR to add your build to `docs/BUILDS.md`

Your build will be featured in the project gallery.

---

## Coding Standards

### Flutter / Dart

- Follow the official [Dart style guide](https://dart.dev/guides/language/effective-dart/style)
- Run `flutter format lib/` before committing
- Run `flutter analyze` and fix all warnings before opening a PR
- All public methods and classes should have doc comments
- Use `const` constructors wherever possible
- Prefer `final` over `var`
- Name files and folders in `snake_case`

```dart
// Good
class RobotPose {
  /// Current angle of the right elbow servo (0–180°).
  final double rElbow;

  const RobotPose({required this.rElbow});
}

// Avoid
class robotPose {
  var RElbow;
}
```

### Arduino / C++

- Keep functions short and single-purpose
- Use named constants instead of magic numbers
- Add a comment for every servo pin assignment
- Always call `constrain(angle, 0, 180)` before writing to a servo

```cpp
// Good
const int PIN_R_ELBOW = 4;
const int SERVO_MIN = 0;
const int SERVO_MAX = 180;

void setElbow(int angle) {
  angle = constrain(angle, SERVO_MIN, SERVO_MAX);
  rElbow.write(angle);
}

// Avoid
void f(int a) { s.write(a); }
```

### Python (AI scripts)

- Follow [PEP 8](https://pep8.org)
- Use type hints on all function signatures
- Include a `requirements.txt` update if you add a new dependency

---

## Commit Message Format

We follow [Conventional Commits](https://www.conventionalcommits.org):

```
<type>: <short description>

[optional body]
[optional footer — Closes #issue]
```

**Types:**

| Type | Use for |
|---|---|
| `feat` | New feature |
| `fix` | Bug fix |
| `docs` | Documentation only |
| `style` | Formatting, no logic change |
| `refactor` | Code restructure, no feature change |
| `test` | Adding or fixing tests |
| `hardware` | Arduino firmware changes |
| `stl` | 3D file additions or changes |
| `ai` | Training scripts or model changes |

**Examples:**

```bash
feat: add pose recorder to manual control screen
fix: handle null USB port on initial connect
docs: add Malayalam translation of README
hardware: increase baud rate to 115200 on both Arduinos
stl: redesign right index finger knuckle joint for better range of motion
ai: add IRND dataset preprocessing script
```

---

## Pull Request Checklist

Before marking your PR as ready for review, confirm:

- [ ] My branch is up to date with `main`
- [ ] `flutter analyze` passes with no errors or warnings
- [ ] `flutter test` passes
- [ ] I have tested the change on a real Android device (for hardware-related changes)
- [ ] I have updated relevant documentation
- [ ] My commit messages follow the Conventional Commits format
- [ ] I have linked the related issue with `Closes #N`
- [ ] I have added screenshots or a video for UI changes

---

## Good First Issues

New to FlutterMind? Look for issues tagged [`good first issue`](https://github.com/adhnan-e/fluttermind/issues?q=label%3A%22good+first+issue%22) on GitHub. These are small, well-defined tasks that are a great way to get familiar with the codebase.

Current good first issues include:

- Add a "Rest position" button to the gesture screen
- Show battery percentage of connected power bank in the app status bar
- Add haptic feedback when a gesture command is sent
- Write unit tests for `RobotPose.toCommands()`
- Translate README to Malayalam

If you are not sure where to start, ask in the Discord `#new-contributors` channel — we are happy to guide you.

---

## Recognition

Every contributor matters. Here is how we acknowledge contributions:

- All contributors are listed in [`docs/CONTRIBUTORS.md`](docs/CONTRIBUTORS.md)
- Significant contributors are credited in release notes
- Build contributors are featured in the project gallery
- Translators are credited at the top of their translation file

FlutterMind was started by **Adhnan** from Kerala, India. The project is built on the shoulders of the InMoov, Gemma, and Flutter open-source communities.

---

<div align="center">

**Thank you for making FlutterMind better. 🙏**

_Every servo tightened, every line of code written, every doc improved — it all counts._

</div>
