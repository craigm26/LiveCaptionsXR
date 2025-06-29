# live_captions_xr: Flutter Web Demo

**Interactive Flutter web demonstration of live_captions_xr's multimodal AI captioning capabilities for Google Gemma 3n Hackathon judges**

---

## 📁 Web Demo Structure

This web platform is organized as a standalone sub-platform demonstration:

- **`demo/`** - Flutter web demo implementation ([see demo README](demo/README.md))
- **`icons/`** - Progressive Web App icons and assets
- **`index.html`** - Flutter web application entry point
- **`manifest.json`** - PWA configuration
- **`favicon.png`** - Web application favicon

## 🎯 Purpose

- **🏆 Hackathon Demonstration**: Interactive Flutter web showcase for Google Gemma 3n Hackathon judges and reviewers
- **📱 Product Visualization**: Comprehensive demonstration of live_captions_xr's XR captioning features and accessibility experience  
- **🧠 Technical Proof**: Live representation of Gemma 3n's multimodal AI integration and real-world impact
- **♿ Accessibility Showcase**: Interactive demonstration of how multimodal AI transforms accessibility technology

## 🚀 How to Experience the Demo

### 🌐 **Online Access (Recommended)**
- **Live URL**: *Deploying to Github Pages*
- **📱 No installation required**: Instantly accessible from any modern web browser
- **🔄 Auto-updates**: Always shows the latest version

### 🏗️ **Local Development**
```bash
# Build for production
./build_web.sh

# Or run in development mode
flutter run -d web-server --web-port 8080
```

### 📋 **System Requirements**
- **Browsers**: Chrome, Edge, Safari, Firefox (latest versions)
- **Performance**: Works on desktop, tablet, and mobile browsers
- **Accessibility**: Full screen reader support and keyboard navigation

## 🎬 Demo Highlights for Judges

### 1. **Interactive Web Interface**
- Responsive Flutter web application optimized for desktop viewing
- Seamless navigation between project sections and live demo scenarios
- Real-time animation and interaction showcasing mobile app capabilities

### 2. **Multimodal AI Workflow Simulator**
- Interactive scenarios demonstrating practical applications
- Examples: "Microwave finished", "Doorbell ringing", "Emergency vehicle approaching"  
- Shows complete AI pipeline from sensor input to accessible output

### 3. **Technology Deep Dive**
- Visual explanation of Gemma 3n's multimodal capabilities
- Architecture diagrams showing integration approach
- Performance metrics and technical specifications

### 4. **Accessibility-First Design**
- Live demonstration of WCAG 2.2 AA compliance
- Screen reader compatible interface
- Keyboard navigation and high contrast support

## 🔧 Technical Implementation

- **🎨 Framework**: Flutter Web with responsive design and web-optimized widgets
- **📈 Interactive Elements**: Real-time animations and scenario simulations
- **♿ Accessibility**: Full screen reader support and keyboard navigation
- **📱 Responsive**: Optimized for desktop, tablet, and mobile viewing
- **🚀 Performance**: Efficient Flutter web renderer with fast loading times

## 🌐 Deployment & Hosting

### Firebase Hosting Configuration
```bash
# Build the web app
flutter build web --release

# Deploy to Firebase (requires Firebase CLI)
firebase deploy
```

### Development Server
```bash
# Run local development server
flutter run -d web-server --web-port 8080

# Build for testing
flutter build web
```  
- Shows natural language output from Gemma 3n multimodal understanding

### 3. **Technical Innovation Showcase**
- Architecture diagrams showing mobile AI deployment strategy
- Performance metrics and optimization techniques
- Accessibility compliance and user experience design

### 4. **Global Impact Visualization**
- 140+ language support capability (leveraging Gemma 3n's multilingual features)
- Statistics on hearing loss community served (466 million people worldwide)
- Accessibility standards compliance (WCAG 2.2 AA)

## 🔧 Technical Implementation

- **🎨 Framework**: Hand-crafted HTML/CSS/JS with Tailwind CSS for responsive design
- **📈 Visualizations**: Chart.js for interactive data presentation  
- **♿ Accessibility**: Full screen reader support and keyboard navigation
- **📱 Responsive**: Optimized for desktop, tablet, and mobile viewing

## 🎯 Key Messages for Hackathon Judges

1. **🧠 Multimodal Innovation**: First accessibility application leveraging Gemma 3n's unified audio+visual+text processing
2. **📱 Mobile-First Privacy**: Complete on-device processing ensuring sensitive data never leaves user's device  
3. **♿ Real-world Impact**: Addresses genuine accessibility challenges for 466 million people with hearing loss
4. **🏗️ Technical Excellence**: Production-ready architecture with comprehensive error handling and fallback strategies

## 🔗 Connection to Mobile App

This demo complements the full Flutter mobile application by:
- **📋 Visualizing Features**: Shows intended user experience and technical capabilities
- **🎯 Demonstrating Value**: Communicates product vision and real-world impact
- **🧪 Proving Concept**: Validates technical approach and accessibility design decisions
- **📱 Bridging Understanding**: Helps judges understand mobile app functionality without device testing

---

**For judges**: This demo represents the product vision that the mobile Flutter application implements. It shows how Gemma 3n's multimodal capabilities can transform accessibility technology when deployed thoughtfully and with deep understanding of user needs.
