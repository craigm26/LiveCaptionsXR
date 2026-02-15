# Speaker Diarization & 3D/4D Spatial Intelligence

LiveCaptionsXR implements advanced speaker diarization that maps translations to speakers in 3D/4D space.

## Voice Embedding Features

- **MFCC Coefficients:** Mel-Frequency Cepstral Coefficients for voice characterization
- **Delta MFCCs:** First-order derivatives capturing speech dynamics
- **Spectral Features:** Centroid, bandwidth, rolloff, and flatness
- **Pitch Estimation:** Autocorrelation-based fundamental frequency detection
- **Energy Statistics:** RMS energy for voice activity detection

## Spatial Tracking (4D)

- **3D Position:** GCC-PHAT time-delay-of-arrival + hybrid localization
- **Temporal History:** Exponential decay weighted position averaging
- **Velocity Estimation:** Position prediction for smooth caption animation
- **Confidence Weighting:** High-confidence observations weighted more heavily

## Speaker Profile Management

- **Similarity Threshold:** Cosine similarity matching (default: 0.75)
- **Spatial Coherence:** Position-based matching boost for nearby speakers
- **Profile Persistence:** Export/import for cross-session recognition
- **Max Speakers:** Configurable limit with LRU pruning

## UI Components

- **SpeakerIndicator:** Individual speaker badge with color and position
- **SpeakerTracker:** Horizontal list of all tracked speakers
- **SpeakerRadar:** Radar-style 2D visualization of 3D speaker positions
