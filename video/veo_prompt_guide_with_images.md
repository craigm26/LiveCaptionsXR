# 🎥 Google Veo Flow 3 Prompt Guide (w/ Real-World Image Anchors)

This file outlines a cinematic prompt structure for Google Flow / Veo 3, including direct references to image assets to enhance realism and identity. Each prompt chunk includes image-based grounding and compositional intention.

---

## 🔧 Asset References

| Asset ID               | Description                              | Suggested Filename                |
|------------------------|------------------------------------------|-----------------------------------|
| `hero_craig`           | Main character headshot or portrait      | `craig_hero.jpg`                  |
| `craig_ots`            | Over-the-shoulder photo w/ glasses       | `craig_ots.jpg`                   |
| `sunglasses_standalone`| Glasses as XR stand-in                   | `sunglasses.png`                  |
| `barista_scene`        | Barista or counter-person image          | `barista.jpg`                     |
| `drone_cityshot`       | City drone backdrop or establishing shot | `city_drone.jpg`                  |
| `closeup_indoor`       | Indoor soft-light emotional portrait     | `craig_emotion.jpg`               |
| `caption_ui_mockup`    | UI overlay for caption bubbles           | `caption_ui.png`                  |
| `gemma_logo`           | Gemma 3n logo PNG                        | `gemma3n_logo.png`                |
| `android_xr_logo`      | Android XR branding                      | `androidxr_logo.png`              |
| `friend_photo`         | Companion or family member image         | `friend_smile.jpg`                |

---

## ✅ Scene 1 – Establishing the Scene

**Image Anchors:** `hero_craig`, `sunglasses_standalone`, `barista_scene`

**Prompt:**  
Wide shot of a busy, bustling coffee shop. People are talking, and the sound of an espresso machine is audible.
The camera finds Craig, wearing modern sunglasses (a stand-in for XR glasses), at a small table. He is not ordering, but observing the environment.
Slow push-in on Craig.
**Mood:** Modern, observational, slightly chaotic.

---

## ✅ Scene 2 – Conversation in a Busy Café

**Image Anchors:** `hero_craig`, `friend_photo`, `caption_ui_mockup`

**Prompt:**
Medium shot of Craig sitting at the table. A friend (`friend_photo`) sits opposite him, leaning in to speak. The ambient noise is high, with clattering dishes and overlapping conversations.
The AR caption bubble appears, anchored to the friend's position:
> "It's so loud in here, can you even hear me?"
Craig smiles and nods, looking at the caption, demonstrating clear comprehension despite the noise.
**Mood:** Connection, clarity in chaos.

---

## ✅ Scene 3 – Before/After AR Comparison

**Image Anchors:** `hero_craig`, `caption_ui_mockup`, `sunglasses_standalone`

**Prompt:**  
Split-screen:  
Left — Craig without XR glasses, appearing confused and struggling to hear in the noisy cafe.  
Right — With XR glasses, an AR caption clearly reads:  
> “You dropped this.”  
The caption tracks a person walking by, off-screen.  
**Mood:** Empowered, intuitive.

---

## ✅ Scene 4 – Emotional Reflection

**Image Anchors:** `closeup_indoor`, `caption_ui_mockup`

**Prompt:**  
Indoor close-up of Craig, the soft lighting of the cafe highlighting his expression.  
A caption bubble fades in, capturing a quiet, heartfelt comment from his friend:  
> “I’m proud of you.”  
No voiceover. The gentle hum of the cafe and a soft piano score in the background.  
**Mood:** Quiet intimacy, connection.

---

## ✅ Scene 5 – Product Showcase & Tech Logos

**Image Anchors:** `sunglasses_standalone`, `gemma_logo`, `android_xr_logo`, `caption_ui_mockup`

**Prompt:**  
Rotating sunglasses on a clean, white backdrop.  
Floating tags appear around the frame, highlighting key features:  

- “Gemma 3n On-Device AI”  
- “Privacy Preserved”  
- “Multilingual Real-Time Captions”  
Logos for Gemma and Android XR fade in as subtle watermarks.  
**Mood:** Clean, tech-forward.

---

## ✅ Scene 6 – Hero Scene with Outdoor Closure

**Image Anchors:** `drone_cityshot`, `friend_photo`, `caption_ui_mockup`

**Prompt:**  
Golden hour shot on the patio of the coffee shop. The city ambiance is present but softer.
Craig and his friend are laughing together at their table.  
A final caption appears:  
> “You always find a way.”  
The scene fades out with the tagline:  
> “LiveCaptionsXR. Nothing unheard.”  
**Mood:** Empowerment, resolve, connection.

---

## 📁 Suggested Folder Structure for Google Drive Uploads

```
LiveCaptionsXR_VeoPrompts/
├── hero/
│   ├── craig_hero.jpg
│   ├── craig_ots.jpg
│   ├── craig_emotion.jpg
├── props/
│   ├── sunglasses.png
│   ├── caption_ui.png
├── scenes/
│   ├── city_drone.jpg
│   ├── barista.jpg
│   ├── friend_smile.jpg
├── logos/
│   ├── gemma3n_logo.png
│   ├── androidxr_logo.png
└── veo_prompt_guide_with_images.md
```

Ensure all image files follow the naming convention above. Store this .md file in the root of the folder for easy reference during video generation.

---

## 🧭 Notes

- If replacing a photo, update the filename to match the structure.
- You may optionally embed each prompt directly into Veo along with its referenced images.
