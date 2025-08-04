# AI Diagram Generator Pro 🚀

A professional Flutter mobile application for generating AI-powered diagrams and documents. Create beautiful, professional visualizations and documentation with the power of artificial intelligence.

## ✨ Features

### 📊 Diagram Generation
- **12 Professional Diagram Types:**
  - Flowcharts & Process Flow
  - Sequence Diagrams
  - State Diagrams
  - Mind Maps
  - SWOT Analysis
  - Timeline Diagrams
  - Gantt Charts
  - User Journey Maps
  - Entity Relationship Diagrams (ERD)
  - Class Diagrams
  - Network Architecture
  - System Architecture

### 📄 Document Generation
- Professional document templates
- AI-powered content generation
- Export capabilities
- Rich formatting options

### 🎨 Premium Design
- Modern Material Design UI
- Smooth animations and transitions
- Responsive layout
- Dark mode support
- Professional color schemes

## 🛠️ Setup Instructions

### Prerequisites
- Flutter SDK (3.0 or higher)
- Python 3.8+
- Android Studio or VS Code
- Git

### Installation

1. **Clone the repository:**
   ```bash
   git clone https://github.com/your-username/my_flutter_app.git
   cd my_flutter_app
   ```

2. **Install Flutter dependencies:**
   ```bash
   flutter pub get
   ```

3. **Install Python backend dependencies:**
   ```bash
   cd backend
   pip install -r requirements.txt
   ```

4. **Start the backend server:**
   
   **Windows:**
   ```bash
   # Run the provided script
   start_backend.bat
   
   # Or manually:
   cd backend
   python app.py
   ```
   
   **Linux/macOS:**
   ```bash
   # Run the provided script
   ./start_backend.sh
   
   # Or manually:
   cd backend
   python3 app.py
   ```

5. **Run the Flutter app:**
   ```bash
   flutter run
   ```

## 🚀 Quick Start

1. **Launch the app** - The app will automatically check backend connectivity
2. **Enter your description** - Describe what you want to visualize
3. **Select a diagram type** - Choose from 12 professional templates
4. **Generate** - Click generate and watch AI create your diagram
5. **Export & Share** - Copy, save, or share your creations

## 📱 App Structure

```
lib/
├── constants/          # App-wide constants and themes
├── models/            # Data models
├── screens/           # Main app screens
├── services/          # API and backend services
├── utils/             # Utility functions and error handling
└── widgets/           # Reusable UI components

backend/
├── app.py            # Main Flask server
├── requirements.txt  # Python dependencies
└── ...              # Additional backend files
```

## 🔧 Configuration

### Backend Configuration
The app connects to a local Python Flask server running on `http://127.0.0.1:5000`.

### API Key Setup
For enhanced AI capabilities, configure your Groq API key in the backend:
```python
# In backend/app.py
GROQ_API_KEY = "your_groq_api_key_here"
```

## 🐛 Troubleshooting

### Common Issues

**1. Backend Connection Failed**
- Ensure the Python server is running (`python backend/app.py`)
- Check that port 5000 is available
- Verify firewall settings

**2. App Won't Start**
- Run `flutter clean && flutter pub get`
- Check Flutter SDK version compatibility
- Ensure all dependencies are installed

**3. Diagram Generation Fails**
- Verify backend server is healthy
- Check internet connection for AI features
- Ensure input description is clear and detailed

**4. Performance Issues**
- Close unused apps to free memory
- Restart the app if animations lag
- Check device storage space

### Error Messages

The app provides user-friendly error messages with suggested solutions:
- ❌ Connection errors → Check backend server
- ⚠️ Warning messages → Review input or settings
- ✅ Success confirmations → Actions completed

## 🔒 Privacy & Security

- All processing happens locally or on your specified server
- No data is stored permanently without your consent
- API keys are handled securely
- Network requests use HTTPS when possible

## 🆘 Support

If you encounter issues:

1. **Check the logs** - Look for error messages in the console
2. **Restart components** - Try restarting the app and backend
3. **Update dependencies** - Ensure you have the latest versions
4. **Report bugs** - Create an issue with detailed information

## 🎯 Performance Optimizations

The app includes several performance improvements:
- ✅ Lazy loading of components
- ✅ Optimized animations and transitions
- ✅ Efficient memory management
- ✅ Background task processing
- ✅ Smart caching strategies

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

---

**Made with ❤️ using Flutter and AI technology**

For more information or support, please visit our documentation or create an issue in the repository.