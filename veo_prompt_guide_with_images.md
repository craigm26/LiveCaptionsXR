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
| `rooftop_scene`        | Rooftop photo with golden hour light     | `rooftop_goldenhour.jpg`          |
| `friend_photo`         | Companion or family member image         | `friend_smile.jpg`                |

---

## ✅ Scene 1 – Establishing Identity

**Image Anchors:** `hero_craig`, `sunglasses_standalone`, `drone_cityshot`

**Prompt:**  
Wide drone shot of an urban café or outdoor working area during golden hour.  
Craig is seated, glancing around, wearing modern sunglasses (stand-in XR).  
Slow push-in. City bustle in background.  
**Mood:** Hopeful, modern, observational.

---

## ✅ Scene 2 – First Use of AR Captions

**Image Anchors:** `craig_ots`, `barista_scene`, `caption_ui_mockup`

**Prompt:**  
Over-the-shoulder of Craig facing a barista.  
Floating AR text appears:  
> “Your iced coffee is ready.”  
Text aligns to barista head position.  
**Mood:** Delight, revelation.

---

## ✅ Scene 3 – Before/After AR Comparison

**Image Anchors:** `hero_craig`, `caption_ui_mockup`, `sunglasses_standalone`

**Prompt:**  
Split-screen:  
Left — Craig without XR glasses, appearing confused.  
Right — With XR glasses, AR caption reads:  
> “You dropped this.”  
Tracking speaker off-screen.  
**Mood:** Empowered, intuitive.

---

## ✅ Scene 4 – Emotional Reflection

**Image Anchors:** `closeup_indoor`, `caption_ui_mockup`

**Prompt:**  
Indoor close-up of Craig.  
Caption bubble fades in:  
> “I’m proud of you.”  
No voiceover. Ambient piano.  
**Mood:** Quiet intimacy, connection.

---

## ✅ Scene 5 – Product Showcase & Tech Logos

**Image Anchors:** `sunglasses_standalone`, `gemma_logo`, `android_xr_logo`, `caption_ui_mockup`

**Prompt:**  
Rotating sunglasses on white backdrop.  
Floating tags appear around frame:  
- “Gemma 3n On-Device AI”  
- “Privacy Preserved”  
- “Multilingual Real-Time Captions”  
Fade in logos as subtle watermarks.  
**Mood:** Clean, tech-forward.

---

## ✅ Scene 6 – Hero Scene with Rooftop Closure

**Image Anchors:** `rooftop_scene`, `friend_photo`, `caption_ui_mockup`

**Prompt:**  
Golden hour rooftop arc shot.  
Craig and friend laughing.  
Caption appears:  
> “You always find a way.”  
Final fade out:  
> “LiveCaptionsXR. Nothing unheard.”  
**Mood:** Empowerment, resolve.

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
│   ├── rooftop_goldenhour.jpg
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

