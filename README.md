# 🎨 AI Diagram & Document Generator

<div align="center">

![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![Python](https://img.shields.io/badge/Python-3776AB?style=for-the-badge&logo=python&logoColor=white)
![Flask](https://img.shields.io/badge/Flask-000000?style=for-the-badge&logo=flask&logoColor=white)
![Android](https://img.shields.io/badge/Android-3DDC84?style=for-the-badge&logo=android&logoColor=white)

**🚀 Professional AI-powered diagram and document generation with beautiful Flutter UI**

[📱 Download APK](#-installation) • [🔧 Setup](#-setup) • [🎯 Features](#-features) • [🌐 Live Demo](#-live-backend)

</div>

---

## ✨ Features

### 📊 **12 Diagram Types**
- 🔄 **Flowcharts** - Process visualization
- 🧠 **Mind Maps** - Idea organization  
- 📈 **SWOT Analysis** - Strategic planning
- ⏱️ **Timeline** - Project scheduling
- 📅 **Gantt Charts** - Task management
- 🔀 **Sequence Diagrams** - System interactions
- 🔄 **State Diagrams** - Process states
- 🛣️ **User Journey** - Experience mapping
- 🗄️ **ERD** - Database design
- 📦 **Class Diagrams** - Software architecture
- 🌐 **Network Diagrams** - Infrastructure
- 🏗️ **Architecture** - System design

### 📄 **Professional Documents**
- 💼 **Business Plans** - Complete strategic documents
- 🔧 **Technical Specifications** - Detailed system docs
- 📋 **Project Proposals** - Professional presentations
- 📈 **Marketing Strategies** - Campaign planning
- 📖 **User Manuals** - Step-by-step guides

### 🎨 **Modern Features**
- 🤖 **AI-Powered Generation** - Smart content creation
- 📱 **Cross-Platform** - Android, iOS, Web, Desktop
- 🎨 **Beautiful UI** - Modern Material Design
- 📤 **Export Options** - SVG, PDF, Text formats
- 🔄 **Real-time Editing** - Live diagram updates
- 💾 **Offline Support** - Works without internet
- 🌙 **Dark Mode** - Eye-friendly interface

---

## 🚀 Quick Start

### 📱 Installation

#### Option 1: Download APK (Recommended)
```bash
# Download the latest release APK
# Install on your Android device
# No additional setup required!
```

#### Option 2: Build from Source
```bash
# Clone the repository
git clone https://github.com/hanyaaqeel/DiagramGenerator.git
cd DiagramGenerator

# Install Flutter dependencies
flutter pub get

# Run the app
flutter run

# Build APK
flutter build apk --release
```

### 🔧 Setup

#### For Development
```bash
# 1. Clone and setup Flutter
git clone https://github.com/hanyaaqeel/DiagramGenerator.git
cd DiagramGenerator
flutter pub get

# 2. Backend setup (optional - app works with hosted backend)
cd backend
pip install -r requirements.txt
python app.py
```

#### Environment Variables (Backend)
```bash
# Create backend/.env file
GROQ_API_KEY=your_groq_api_key_here
RAILWAY_ENVIRONMENT=development
```

---

## 🌐 Live Backend

The app uses a **free hosted backend** at:
```
https://diagramgenerator-hj9d.onrender.com
```

✅ **Always available** - No setup required  
✅ **Free forever** - Render.com free tier  
✅ **Auto-scaling** - Handles traffic automatically  
✅ **Secure** - Environment variables protected  

---

## 🛠️ Tech Stack

### Frontend
- **Flutter** - Cross-platform UI framework
- **Dart** - Programming language
- **Material Design** - Modern UI components
- **HTTP** - API communication
- **SVG** - Vector graphics rendering

### Backend
- **Python Flask** - Web framework
- **Groq AI** - Language model integration
- **Gunicorn** - WSGI HTTP Server
- **CORS** - Cross-origin support
- **Render.com** - Cloud hosting

### Architecture
```
┌─────────────┐    HTTP/HTTPS    ┌──────────────┐
│   Flutter   │ ───────────────► │    Flask     │
│     App     │                  │   Backend    │
│             │ ◄─────────────── │              │
└─────────────┘    JSON/SVG      └──────────────┘
       │                                │
       │                                │
   ┌───▼────┐                      ┌────▼────┐
   │ Mobile │                      │  Groq   │
   │  APK   │                      │   AI    │
   └────────┘                      └─────────┘
```

---

## 📸 Screenshots

<div align="center">

### 🏠 Home Screen
*Beautiful dashboard with feature overview*

### 📊 Diagram Generator  
*12 professional diagram types with AI generation*

### 📄 Document Creator
*Professional document templates with smart content*

### 🎨 Modern UI
*Material Design with smooth animations*

</div>

---

## 🎯 Use Cases

### 👨‍💼 **Business Professionals**
- Create business plans and strategies
- Generate SWOT analysis and timelines
- Design organizational flowcharts

### 👨‍💻 **Developers & Architects**
- System architecture diagrams
- Database ERD design
- Class and sequence diagrams

### 📚 **Students & Educators**
- Mind maps for learning
- Project timelines
- Technical documentation

### 🎨 **Content Creators**
- User journey mapping
- Process documentation
- Visual presentations

---

## 🔧 Development

### Project Structure
```
DiagramGenerator/
├── lib/                    # Flutter source code
│   ├── screens/           # App screens
│   ├── widgets/           # Reusable components
│   ├── services/          # API communication
│   ├── models/            # Data models
│   └── constants/         # App constants
├── backend/               # Python Flask backend
│   ├── app.py            # Main server file
│   ├── requirements.txt  # Python dependencies
│   └── Procfile         # Deployment config
└── android/              # Android-specific files
```

### Key Components
- **API Service** - Handles backend communication
- **Diagram Viewers** - SVG rendering and editing
- **Document Generator** - Professional document creation
- **Template System** - Reusable content templates

---

## 🌟 Contributing

We welcome contributions! Here's how to get started:

1. **Fork the repository**
2. **Create feature branch** (`git checkout -b feature/amazing-feature`)
3. **Commit changes** (`git commit -m 'Add amazing feature'`)
4. **Push to branch** (`git push origin feature/amazing-feature`)
5. **Open Pull Request**

### Development Guidelines
- Follow Flutter/Dart style guidelines
- Add tests for new features
- Update documentation
- Ensure cross-platform compatibility

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---




### Found a Bug?
Please create an issue with:
- Device information
- Steps to reproduce
- Expected vs actual behavior
- Screenshots (if applicable)

---

## 🎉 Acknowledgments

- **Flutter Team** - Amazing cross-platform framework
- **Groq** - Powerful AI language models
- **Render.com** - Free hosting platform
- **Material Design** - Beautiful UI components
- **Open Source Community** - Inspiration and support

---

<div align="center">

**⭐ Star this repository if you found it helpful!**

</div>