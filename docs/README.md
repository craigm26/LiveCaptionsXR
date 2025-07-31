# LiveCaptionsXR Documentation

Welcome to the LiveCaptionsXR documentation! This folder contains comprehensive documentation for developers, contributors, and users of the LiveCaptionsXR project.

## 📚 Documentation Overview

LiveCaptionsXR is an AR-powered accessibility application that provides real-time, spatially-aware closed captioning for the Deaf and Hard of Hearing (D/HH) community. This documentation covers all aspects of the project from technical implementation to user guides.

## 🗂️ Documentation Structure

### Getting Started

- **[SETUP_GUIDE.md](SETUP_GUIDE.md)** - Complete development environment setup guide
- **[README.md](../README.md)** - Main project overview and quick start

### Technical Documentation

- **[ARCHITECTURE.md](ARCHITECTURE.md)** - System architecture and design patterns
- **[TECHNICAL_WRITEUP.md](TECHNICAL_WRITEUP.md)** - Comprehensive technical implementation details
- **[TECHNICAL_DOCUMENTATION.md](TECHNICAL_DOCUMENTATION.md)** - Detailed technical reference
- **[HACKATHON_SUBMISSION.md](HACKATHON_SUBMISSION.md)** - Project description and hackathon submission

### Implementation Guides

- **[WHISPER_SETUP.md](WHISPER_SETUP.md)** - Whisper speech recognition setup and configuration
- **[SPEECH_TO_TEXT_GEMMA_IMPLEMENTATION.md](SPEECH_TO_TEXT_GEMMA_IMPLEMENTATION.md)** - Speech processing implementation details

### Testing and Quality Assurance

- **[TESTING_GUIDE.md](TESTING_GUIDE.md)** - Comprehensive testing strategies and procedures
- **[TESTING_AR_MODE_AND_AUDIO.md](TESTING_AR_MODE_AND_AUDIO.md)** - AR mode and audio testing procedures
- **[ACCESSIBILITY_TESTING.md](ACCESSIBILITY_TESTING.md)** - Accessibility testing guidelines

### Product Requirements

- **[prd/](../prd/)** - Product Requirements Documents folder
  - Contains detailed specifications for each feature
  - Architecture decisions and technical requirements
  - User experience design documents

## 🚀 Quick Start for Developers

1. **Read the [SETUP_GUIDE.md](SETUP_GUIDE.md)** to set up your development environment
2. **Review [ARCHITECTURE.md](ARCHITECTURE.md)** to understand the system design
3. **Check [TECHNICAL_WRITEUP.md](TECHNICAL_WRITEUP.md)** for implementation details
4. **Follow [TESTING_GUIDE.md](TESTING_GUIDE.md)** for quality assurance

## 🎯 Key Technologies

### Core Technologies

- **Flutter/Dart** - Cross-platform mobile development
- **whisper_ggml** - On-device speech recognition
- **flutter_gemma** - Gemma 3n integration for text enhancement
- **ARKit/ARCore** - Augmented reality functionality
- **flutter_sound** - Audio capture and processing

### Architecture Components

- **Hybrid Localization Engine** - Spatial positioning system
- **Audio Processing Pipeline** - Real-time audio analysis
- **AR Caption Rendering** - 3D spatial caption display
- **State Management** - Flutter Bloc pattern implementation

## 📋 Documentation Categories

### For New Contributors

1. **[SETUP_GUIDE.md](SETUP_GUIDE.md)** - Start here to set up your environment
2. **[ARCHITECTURE.md](ARCHITECTURE.md)** - Understand the system design
3. **[TESTING_GUIDE.md](TESTING_GUIDE.md)** - Learn how to test your changes

### For Technical Deep Dives

1. **[TECHNICAL_WRITEUP.md](TECHNICAL_WRITEUP.md)** - Comprehensive technical overview
2. **[TECHNICAL_DOCUMENTATION.md](TECHNICAL_DOCUMENTATION.md)** - Detailed technical reference
3. **[SPEECH_TO_TEXT_GEMMA_IMPLEMENTATION.md](SPEECH_TO_TEXT_GEMMA_IMPLEMENTATION.md)** - Speech processing details

### For Testing and Quality

1. **[TESTING_GUIDE.md](TESTING_GUIDE.md)** - Complete testing strategy
2. **[TESTING_AR_MODE_AND_AUDIO.md](TESTING_AR_MODE_AND_AUDIO.md)** - AR and audio testing
3. **[ACCESSIBILITY_TESTING.md](ACCESSIBILITY_TESTING.md)** - Accessibility guidelines

### For Project Understanding

1. **[HACKATHON_SUBMISSION.md](HACKATHON_SUBMISSION.md)** - Project vision and goals
2. **[prd/](../prd/)** - Product requirements and specifications
3. **[README.md](../README.md)** - Main project overview

## 🔧 Development Workflow

### 1. Environment Setup
```bash
# Follow SETUP_GUIDE.md for complete setup
git clone https://github.com/craigm26/livecaptionsxr.git
cd livecaptionsxr
flutter pub get
```

### 2. Understanding the Codebase
- Read [ARCHITECTURE.md](ARCHITECTURE.md) for system design
- Review [TECHNICAL_WRITEUP.md](TECHNICAL_WRITEUP.md) for implementation details
- Explore the `lib/` folder structure

### 3. Making Changes
- Create a feature branch
- Follow the coding standards
- Write tests for new functionality
- Update documentation as needed

### 4. Testing Your Changes
- Run unit tests: `flutter test`
- Follow [TESTING_GUIDE.md](TESTING_GUIDE.md) for comprehensive testing
- Test on both iOS and Android devices

### 5. Contributing
- Create a pull request with detailed description
- Reference related issues
- Ensure all tests pass
- Update documentation if needed

## 🐛 Troubleshooting

### Common Issues

1. **Setup Problems** - Check [SETUP_GUIDE.md](SETUP_GUIDE.md) troubleshooting section
2. **Whisper Issues** - See [WHISPER_SETUP.md](WHISPER_SETUP.md) for configuration
3. **AR Problems** - Review [TESTING_AR_MODE_AND_AUDIO.md](TESTING_AR_MODE_AND_AUDIO.md)
4. **Performance Issues** - Check [TESTING_GUIDE.md](TESTING_GUIDE.md) performance section

### Getting Help

1. **Search existing issues** on GitHub
2. **Check the documentation** in this folder
3. **Create a new issue** with detailed information
4. **Join community discussions** on GitHub

## 📖 Documentation Standards

### Writing Guidelines

- Use clear, concise language
- Include code examples where appropriate
- Provide step-by-step instructions
- Include troubleshooting sections
- Keep documentation up to date

### File Naming

- Use descriptive, kebab-case filenames
- Include the topic in the filename
- Use consistent naming patterns

### Structure

- Start with an overview
- Include prerequisites
- Provide step-by-step instructions
- Include examples and code snippets
- Add troubleshooting section
- Link to related documentation

## 🔄 Keeping Documentation Updated

### When to Update

- New features are added
- APIs change
- Dependencies are updated
- Issues are discovered and resolved
- User feedback indicates gaps

### Update Process

1. **Identify the need** for documentation updates
2. **Update the relevant files**
3. **Test the documentation** by following the instructions
4. **Review for clarity** and completeness
5. **Commit changes** with descriptive messages

## 📞 Support and Community

### Resources

- **[GitHub Repository](https://github.com/craigm26/livecaptionsxr)** - Main project repository
- **[Issues](https://github.com/craigm26/livecaptionsxr/issues)** - Bug reports and feature requests
- **[Discussions](https://github.com/craigm26/livecaptionsxr/discussions)** - Community discussions

### Contributing to Documentation

1. **Identify gaps** in existing documentation
2. **Create or update** documentation files
3. **Follow the writing guidelines** above
4. **Submit a pull request** with your changes
5. **Include rationale** for your changes

## 🎉 Welcome!

Thank you for your interest in LiveCaptionsXR! This documentation is designed to help you understand, contribute to, and use the project effectively. If you find any gaps or have suggestions for improvement, please don't hesitate to contribute.

Happy coding! 🚀 