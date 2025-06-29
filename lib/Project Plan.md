
# live_captions_xr - Project Planning & Development Status

**This document tracks the current development status, milestones, and detailed requirements for live_captions_xr.**

---

## Current Development Status

### ✅ Completed (June 2025)
- [x] On-device sound detection (TFLite)
- [x] Real-time sound localization (TDOA, TFLite)
- [x] Visual object detection (TFLite)
- [x] AR overlay UI (Flutter)
- [x] Basic project architecture and dependency injection setup

### 🔄 In Progress
- [ ] Demo mode for simulated events
- [ ] Pre-trained Gemma 3n LiteRT model integration (see [LITERT_INTEGRATION.md](../LITERT_INTEGRATION.md))
- [ ] Multimodal fusion (text+image, text+image+audio)
- [ ] Flutter web demo refinements

### ✅ Recently Unblocked  
- [x] Gemma 3n integration path (Google released pre-trained LiteRT models)

---

## Development Milestones

### 🎯 Hackathon MVP (June 2025)
**Target**: Demonstrate core functionality with TFLite models

**Required Features:**
- [x] TFLite-based sound and vision pipeline
- [x] Real-time AR overlay for sound localization and object identification
- [ ] Demo mode for simulated events
- [ ] Basic integration plan for Gemma 3n (pending ONNX/TFLite export)

**Stretch Goals:**
- [ ] Partial Gemma 3n integration (if ONNX export succeeds)
- [ ] Multimodal queries (text+image)
- [ ] Real device tests (Android/iOS)

### 🚀 Full Application (Q3-Q4 2025)
**Target**: Production-ready application for D/HH community

**Core Features:**
- [ ] Robust onboarding and comprehensive accessibility features
- [ ] iOS/Android feature parity and optimization
- [ ] Cloud sync, user settings, and analytics integration
- [ ] Full Gemma 3n integration (text+image+audio)
- [ ] Advanced AR overlays and feedback systems (haptics, light, etc.)
- [ ] XR/AR extension support (see [XR Extension PRD](../docs/XR_EXTENSION_PRD.md))

**Quality & Deployment:**
- [ ] Comprehensive accessibility testing (see [Accessibility Testing Plan](../docs/ACCESSIBILITY_TESTING.md))
- [ ] Production deployment and app store submission
- [ ] User feedback collection and iteration pipeline
- [ ] Community partnerships and user testing programs

---

## Technical Requirements

### Platform Support
- **Primary**: Android 8.0+ (API level 26)
- **Secondary**: iOS 13.0+
- **Future**: Web (limited functionality)

### Hardware Requirements
- **Minimum**: 4GB RAM, dual microphones, rear camera
- **Recommended**: 6GB+ RAM, microphone array, main + depth cameras
- **Optimal**: 8GB+ RAM, advanced camera systems, haptic feedback

### Performance Targets
- **Audio Processing**: <100ms latency for sound detection
- **Visual Processing**: <200ms latency for object detection  
- **AR Overlay**: 30+ FPS rendering
- **Battery Life**: <15% additional drain during active use

---

## Feature Prioritization

### P0 (Critical - Must Have)
1. Sound detection and classification
2. Sound localization and direction finding
3. Visual object identification
4. Basic AR overlay system
5. Multi-modal feedback (visual, haptic, light)

### P1 (Important - Should Have)  
1. Demo mode for testing and demonstration
2. Settings and user customization
3. Accessibility features and WCAG compliance
4. Performance optimization and battery management
5. Basic onboarding and user education

### P2 (Nice to Have - Could Have)
1. Gemma 3n multimodal integration
2. Advanced AR features and 3D anchoring
3. Cloud sync and cross-device support  
4. Analytics and usage insights
5. XR/headset extension support

### P3 (Future - Won't Have This Release)
1. Full AR glasses integration
2. AI-powered learning and adaptation
3. Social features and community integration
4. Advanced spatial audio processing
5. Multi-language natural language processing

---

## Risk Assessment & Mitigation

### High Risk Items
| Risk | Impact | Probability | Mitigation Strategy |
|------|--------|-------------|-------------------|
| Gemma 3n integration failure | High | Medium | Continue with TFLite models, explore smaller model variants |
| AR performance on low-end devices | Medium | High | Implement progressive enhancement and fallback modes |
| Accessibility compliance gaps | High | Low | Early and continuous accessibility testing throughout development |

### Medium Risk Items  
| Risk | Impact | Probability | Mitigation Strategy |
|------|--------|-------------|-------------------|
| Sound localization accuracy | Medium | Medium | Extensive testing across device types, fallback algorithms |
| Battery life impact | Medium | Medium | Optimization passes, power management features |
| App store approval delays | Low | Medium | Early submission, compliance review processes |

---

## Testing Strategy

### Unit Testing
- All core services (AudioService, LocalizationService, VisualService)
- Cubit state management logic
- Model inference pipelines
- Utility functions and data processing

### Integration Testing  
- Sensor data pipeline end-to-end
- AR overlay rendering and performance
- Multi-modal feedback coordination
- Settings persistence and app lifecycle

### User Acceptance Testing
- D/HH community feedback sessions
- Accessibility compliance verification
- Real-world scenario testing
- Performance validation across devices

For detailed accessibility testing procedures, see [Accessibility Testing Plan](../docs/ACCESSIBILITY_TESTING.md).

---

## Dependencies & External Factors

### Critical Dependencies
- **TensorFlow Lite**: Core AI inference engine
- **Flutter**: Primary development framework
- **ARCore/ARKit**: Augmented reality functionality
- **Device Hardware**: Microphone arrays, cameras, haptic feedback

### External Factors
- **Gemma 3n Model Availability**: Affects advanced AI features
- **Hardware Ecosystem**: AR glasses and XR device adoption
- **Platform Updates**: Android/iOS AR capability evolution
- **Community Feedback**: D/HH user needs and preferences

---

## Resource Allocation

### Development Focus Areas
1. **Core Functionality** (60%): Sound/vision processing, AR overlays
2. **Accessibility & UX** (25%): D/HH-specific features, testing
3. **Performance & Optimization** (10%): Battery, memory, speed
4. **Advanced Features** (5%): Gemma 3n, XR extensions

### Key Deliverables by Sprint
- **Sprint 1-2**: Hackathon MVP completion
- **Sprint 3-4**: Accessibility and user testing
- **Sprint 5-6**: Performance optimization and polish  
- **Sprint 7-8**: Production deployment preparation

---

*This document is updated regularly to reflect current development status and priorities. For technical implementation details, see [INTEGRATION_PLAN.md](../INTEGRATION_PLAN.md).*
