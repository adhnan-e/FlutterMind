# AI Training Guide 🤖🧠

How to fine-tune Gemma 4 E4B for FlutterMind — from raw dataset to a deployed model running on your phone.

---

## Overview

FlutterMind uses **Gemma 4 E4B** as its on-device brain. Out of the box, Gemma 4 works well for basic voice control via its system prompt alone. Fine-tuning makes it significantly better at:

- Understanding robot-specific commands
- Making safe navigation decisions from sensor data
- Responding correctly in your specific environment
- Calling robot tool functions reliably and consistently

Fine-tuning is **optional but recommended** after Phase 2 of your build.

---

## The Training Stack

| Tool | Purpose |
|---|---|
| **Gemma 4 E4B** | Base model (4B active params, edge-optimised) |
| **Unsloth** | Fast fine-tuning with 4-bit quantisation |
| **LoRA** | Efficient adapter training (trains only ~1% of weights) |
| **Google Colab** | Free T4 GPU (16GB) — sufficient for this setup |
| **IRND Dataset** | Indoor Robot Navigation Dataset (Kaggle) |
| **GGUF + Ollama** | Export format for on-device deployment |

---

## Understanding LoRA

Full fine-tuning retrains every parameter in the model — requiring hundreds of GB of GPU memory. LoRA (Low-Rank Adaptation) is a smarter approach: it freezes the original model and trains small adapter layers inserted at key points.

```
Full fine-tuning: Rewrite the entire textbook
LoRA:             Add sticky notes to the important pages

Result:           Same performance improvement
Memory needed:    100× less
Training time:    10× faster
```

The LoRA adapters are then merged into the base model for deployment.

---

## Datasets

### 1. IRND — Indoor Robot Navigation Dataset

The [Indoor Robot Navigation Dataset](https://www.kaggle.com/datasets/narayananpp/indoor-robot-navigation-dataset-irnd) contains real sensor readings from a robot navigating indoor environments across smooth and rough surfaces.

Use this to teach FlutterMind safe navigation behaviour from real-world data.

**Download:**
```bash
pip install kaggle
kaggle datasets download -d narayananpp/indoor-robot-navigation-dataset-irnd
unzip indoor-robot-navigation-dataset-irnd.zip -d data/irnd/
```

### 2. Your own interaction data

After your robot is built and running, collect your own data using the built-in logger in the Flutter app (Settings → Data Collection → Enable logging). Every voice command and robot action is logged locally as a JSONL file you can export and use for training.

Your own data is more valuable than the IRND dataset for your specific environment — use both.

---

## Step 1 — Prepare the Dataset

Convert raw CSV sensor data into the Gemma 4 conversation format.

```python
# ai/prepare_dataset.py
import pandas as pd
import json
import random

def sensor_row_to_prompt(row: pd.Series) -> str:
    """Convert one row of sensor data into a natural language description."""
    return (
        f"Robot sensor readings:\n"
        f"- Front obstacle distance: {row['ultrasonic_front']:.1f} cm\n"
        f"- Left side distance:      {row['ultrasonic_left']:.1f} cm\n"
        f"- Right side distance:     {row['ultrasonic_right']:.1f} cm\n"
        f"- Acceleration X/Y/Z:      {row['imu_accel_x']:.2f}, "
        f"{row['imu_accel_y']:.2f}, {row['imu_accel_z']:.2f}\n"
        f"- Angular velocity:        {row['imu_gyro_z']:.2f} rad/s\n"
        f"- Surface type:            {row['surface']}\n\n"
        f"What action should the robot take?"
    )

def action_to_tool_call(action: str) -> dict:
    action_map = {
        "forward":    {"direction": "forward",  "speed": 0.6},
        "backward":   {"direction": "backward", "speed": 0.4},
        "turn_left":  {"direction": "left",     "speed": 0.5},
        "turn_right": {"direction": "right",    "speed": 0.5},
        "stop":       {"direction": "stop",     "speed": 0.0},
    }
    args = action_map.get(action.lower().strip(), {"direction": "stop", "speed": 0.0})
    return {"name": "move_robot", "arguments": args}

SYSTEM_PROMPT = (
    "You are the navigation brain of a 3D printed humanoid robot called FlutterMind. "
    "You receive sensor data and must decide the safest action to take. "
    "Always use the move_robot tool to act. "
    "Stop immediately if front distance is under 20cm. "
    "Prefer turning over reversing when blocked."
)

def convert_csv_to_jsonl(csv_path: str, surface: str) -> list:
    df = pd.read_csv(csv_path)
    df["surface"] = surface
    examples = []
    for _, row in df.iterrows():
        tool_call = action_to_tool_call(row["action"])
        example = {
            "messages": [
                {"role": "system",    "content": SYSTEM_PROMPT},
                {"role": "user",      "content": sensor_row_to_prompt(row)},
                {
                    "role": "assistant",
                    "content": None,
                    "tool_calls": [{"type": "function", "function": tool_call}]
                }
            ]
        }
        examples.append(example)
    return examples

if __name__ == "__main__":
    smooth = convert_csv_to_jsonl("data/irnd/smooth_surface/sensor_readings.csv", "smooth")
    rough  = convert_csv_to_jsonl("data/irnd/rough_surface/sensor_readings.csv",  "rough")
    all_data = smooth + rough
    random.shuffle(all_data)

    split = int(len(all_data) * 0.9)
    train, val = all_data[:split], all_data[split:]

    def save_jsonl(data, path):
        with open(path, "w") as f:
            for item in data:
                f.write(json.dumps(item) + "\n")

    save_jsonl(train, "data/robot_train.jsonl")
    save_jsonl(val,   "data/robot_val.jsonl")
    print(f"✅ Train: {len(train)} | Val: {len(val)}")
```

Run it:
```bash
cd ai
python prepare_dataset.py
```

---

## Step 2 — Fine-tune on Google Colab

Open [Google Colab](https://colab.research.google.com) and create a new notebook. Select **Runtime → Change runtime type → T4 GPU**.

```python
# Cell 1 — Install dependencies
!pip install unsloth trl datasets transformers -q

# Cell 2 — Upload your dataset files
from google.colab import files
files.upload()   # upload robot_train.jsonl and robot_val.jsonl

# Cell 3 — Load model
from unsloth import FastLanguageModel

model, tokenizer = FastLanguageModel.from_pretrained(
    model_name     = "google/gemma-4-e4b-it",
    max_seq_length = 2048,
    load_in_4bit   = True,
    dtype          = None,
)

# Cell 4 — Add LoRA adapters
model = FastLanguageModel.get_peft_model(
    model,
    r              = 16,
    target_modules = [
        "q_proj", "k_proj", "v_proj", "o_proj",
        "gate_proj", "up_proj", "down_proj"
    ],
    lora_alpha   = 16,
    lora_dropout = 0.05,
    bias         = "none",
    use_gradient_checkpointing = True,
)

# Cell 5 — Prepare dataset
from datasets import load_dataset

def format_example(example):
    text = tokenizer.apply_chat_template(
        example["messages"],
        tokenize=False,
        add_generation_prompt=False
    )
    return {"text": text}

dataset = load_dataset("json", data_files={
    "train":      "robot_train.jsonl",
    "validation": "robot_val.jsonl"
})
dataset = dataset.map(format_example)

# Cell 6 — Train
from trl import SFTTrainer
from transformers import TrainingArguments

trainer = SFTTrainer(
    model              = model,
    tokenizer          = tokenizer,
    train_dataset      = dataset["train"],
    eval_dataset       = dataset["validation"],
    dataset_text_field = "text",
    max_seq_length     = 2048,
    args = TrainingArguments(
        output_dir                  = "fluttermind_gemma4",
        per_device_train_batch_size = 2,
        gradient_accumulation_steps = 4,
        num_train_epochs            = 3,
        learning_rate               = 2e-4,
        warmup_ratio                = 0.1,
        lr_scheduler_type           = "cosine",
        fp16                        = True,
        evaluation_strategy         = "steps",
        eval_steps                  = 100,
        save_steps                  = 200,
        logging_steps               = 25,
        load_best_model_at_end      = True,
        metric_for_best_model       = "eval_loss",
    ),
)

trainer.train()
print("✅ Training complete!")

# Cell 7 — Export to GGUF for Ollama / on-device
model.save_pretrained_gguf(
    "fluttermind_gguf",
    tokenizer,
    quantization_method = "q4_k_m"   # 4-bit — best for 8GB RAM
)
print("✅ GGUF exported!")

# Cell 8 — Download the model
from google.colab import files
import os
gguf_file = "fluttermind_gguf/model-q4_k_m.gguf"
files.download(gguf_file)
```

**Expected training time on Colab T4:**
- ~2,000 examples: ~1.5 hours
- ~5,000 examples: ~3 hours
- ~10,000 examples: ~6 hours

Watch the `eval_loss` — it should decrease steadily. If it rises after epoch 1, the model is overfitting — reduce `num_train_epochs` to 2.

---

## Step 3 — Deploy with Ollama

### Option A — On Jetson Orin Nano Super (wired brain)

```bash
# Copy GGUF to Jetson
scp fluttermind_gguf/model-q4_k_m.gguf jetson@192.168.x.x:~/models/

# SSH into Jetson
ssh jetson@192.168.x.x

# Create Modelfile
cat > ~/models/Modelfile << 'EOF'
FROM /home/jetson/models/model-q4_k_m.gguf

SYSTEM """
You are FlutterMind — the brain of a 3D printed humanoid robot.
You are trained on real indoor navigation data.
Always use tools to act. Never narrate — execute.
Stop if front sensor reads under 20cm.
Respond to voice commands in English and Malayalam.
"""

PARAMETER temperature 0.15
PARAMETER top_p 0.9
PARAMETER num_ctx 1024
EOF

# Register and test
ollama create fluttermind -f ~/models/Modelfile
ollama run fluttermind "Front distance is 15cm. What do I do?"
```

### Option B — On Android phone (on-device via MediaPipe / LiteRT)

For full on-device inference on the phone itself (no Jetson needed):

```bash
# Convert GGUF to LiteRT format for Android
pip install ai-edge-torch

python -c "
import ai_edge_torch
# Convert Gemma 4 LoRA weights to TFLite format
# See: https://ai.google.dev/edge/mediapipe/solutions/genai/llm_inference
"
```

> Full MediaPipe LLM inference setup is documented at [ai.google.dev/edge](https://ai.google.dev/edge/mediapipe/solutions/genai/llm_inference/android).

---

## Step 4 — Evaluate the Fine-tuned Model

Before deploying, test the model against your validation set:

```python
# ai/evaluate.py
import ollama, json

def evaluate(model_name: str, val_path: str):
    correct = 0
    total   = 0

    with open(val_path) as f:
        examples = [json.loads(line) for line in f]

    for example in examples[:100]:   # Test first 100
        user_msg = example["messages"][1]["content"]
        expected = example["messages"][2]["tool_calls"][0]["function"]

        response = ollama.chat(
            model   = model_name,
            messages = example["messages"][:2],  # system + user only
            tools   = [...]   # your tool definitions
        )

        predicted = response["message"].get("tool_calls", [{}])[0] \
                                       .get("function", {})

        if predicted.get("name") == expected["name"]:
            correct += 1
        total += 1

    print(f"Accuracy: {correct}/{total} = {correct/total*100:.1f}%")

evaluate("fluttermind", "data/robot_val.jsonl")
```

**Target accuracy:** 85%+ on navigation decisions. Below 70% means you need more training data.

---

## Collecting Your Own Training Data

After Phase 1 of your build, enable data collection in the Flutter app:

**Settings → Data Collection → Enable**

Every interaction is saved to:
```
/sdcard/FlutterMind/logs/interactions_YYYYMMDD.jsonl
```

Each log entry looks like:
```json
{
  "timestamp": "2025-09-14T10:32:11",
  "voice_input": "pick up the bottle",
  "sensor_data": {"front": 45.2, "left": 88.1, "right": 92.3},
  "llm_decision": {"action": "GRIP", "confidence": 0.94},
  "outcome": "success"
}
```

Export logs via the app (Settings → Export training data) and add them to your next fine-tuning run.

**Aim for:** 200+ successful interactions before your first fine-tune cycle. After that, retrain every 500 new interactions.

---

## Combining Datasets

```python
# ai/combine_datasets.py
import json, random

def load_jsonl(path):
    with open(path) as f:
        return [json.loads(line) for line in f]

irnd_data = load_jsonl("data/robot_train.jsonl")       # General navigation
your_data = load_jsonl("data/my_interactions.jsonl")   # Your environment

# Weight your own data 3× — it's more relevant to your specific robot
combined = irnd_data + (your_data * 3)
random.shuffle(combined)

with open("data/combined_train.jsonl", "w") as f:
    for item in combined:
        f.write(json.dumps(item) + "\n")

print(f"Combined: {len(combined)} training examples")
```

---

## Training Iterations

Fine-tuning is not a one-time event. Plan for iterative improvement:

```
Iteration 0 — Base Gemma 4 with system prompt only
              Good enough for Phase 1 testing

Iteration 1 — Fine-tune on IRND dataset
              Better navigation decisions from sensor data
              ~2-3 hours on Colab T4

Iteration 2 — Fine-tune on IRND + your Phase 1/2 logs
              Knows your specific home/workspace
              ~3-4 hours

Iteration 3 — Fine-tune on all collected data
              Handles edge cases, responds to Malayalam
              Ongoing — retrain every few weeks
```

---

## Troubleshooting

| Issue | Cause | Fix |
|---|---|---|
| `CUDA out of memory` | Batch size too large | Reduce `per_device_train_batch_size` to 1 |
| Loss not decreasing | Learning rate too low | Increase `learning_rate` to 3e-4 |
| Loss spikes after epoch 1 | Overfitting | Reduce to 2 epochs, add more data |
| Model ignores tool calls | Tool format wrong | Check your JSONL tool_call structure matches Gemma 4 spec |
| Colab disconnects mid-training | Session timeout | Enable Colab Pro or save checkpoints every 50 steps |
| GGUF too large for phone | q4 still too big | Use `q2_k` quantisation (lower quality but smaller) |

---

## Resources

- [Gemma 4 model card](https://ai.google.dev/gemma/docs/model_card_4)
- [Unsloth documentation](https://github.com/unslothai/unsloth)
- [LoRA paper](https://arxiv.org/abs/2106.09685)
- [IRND Dataset on Kaggle](https://www.kaggle.com/datasets/narayananpp/indoor-robot-navigation-dataset-irnd)
- [Google AI Edge — on-device LLM](https://ai.google.dev/edge/mediapipe/solutions/genai/llm_inference/android)
- [Ollama Modelfile reference](https://ollama.com/docs/modelfile)

---

## Next Steps

- Wire up your robot: [WIRING.md](WIRING.md)
- Print the skeleton: [PRINTING.md](PRINTING.md)
- Serial protocol: [PROTOCOL.md](PROTOCOL.md)
- Contribute back: [CONTRIBUTING.md](../CONTRIBUTING.md)
