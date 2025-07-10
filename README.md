# 🏛️ Parishoners App

A comprehensive parish management application built with Flutter, designed to connect and serve parish community members through digital platforms.

![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![Firebase](https://img.shields.io/badge/Firebase-039BE5?style=for-the-badge&logo=Firebase&logoColor=white)
![Dart](https://img.shields.io/badge/dart-%230175C2.svg?style=for-the-badge&logo=dart&logoColor=white)

## 📱 About

Parishoners App is a modern, cross-platform mobile application that facilitates seamless communication and engagement within parish communities. Built with Flutter and powered by Firebase, it provides a centralized hub for parish members to stay connected, informed, and engaged with their community.

## ✨ Features

### 🏠 Dashboard
- **Modern Glass Morphism UI** - Beautiful, contemporary interface with glassmorphism design
- **Interactive Carousel** - Auto-scrolling welcome cards with smooth animations
- **Quick Navigation** - Easy access to all app modules from a centralized dashboard
- **Real-time Updates** - Live data synchronization with Firebase

### 📢 Announcements
- **Real-time Notifications** - Instant parish announcements and updates
- **Rich Media Support** - Attachments including images, PDFs, and documents
- **Formatted Content** - Well-structured announcements with timestamps
- **File Downloads** - Direct access to announcement attachments

### 📅 Events Management
- **Event Calendar** - View upcoming parish events and activities
- **Event Details** - Comprehensive information about each event
- **RSVP System** - Event participation tracking
- **Category Filtering** - Organize events by type and importance

### 🖼️ Gallery
- **Photo Sharing** - Community photo gallery for parish events
- **Album Organization** - Categorized photo collections
- **High-quality Images** - Optimized image viewing experience
- **Download & Share** - Easy photo sharing capabilities

### 👥 Members Directory
- **Community Directory** - Connect with fellow parishioners
- **Contact Information** - Access to member contact details
- **Search & Filter** - Find members easily with search functionality
- **Privacy Controls** - Secure member information management

### 💰 Dues Management
- **Payment Tracking** - Monitor dues and contributions
- **Payment History** - Complete transaction records
- **Due Reminders** - Automated payment notifications
- **Receipt Generation** - Digital receipts for all transactions

### 👤 Profile Management
- **Personal Profiles** - Manage individual member profiles
- **Privacy Settings** - Control information visibility
- **Account Management** - Update personal information and preferences
- **Authentication** - Secure login and registration system

## 🚀 Getting Started

### Prerequisites

- **Flutter SDK** (3.8.1 or higher)
- **Dart SDK** (included with Flutter)
- **Android Studio** / **VS Code** with Flutter extensions
- **Firebase Account** for backend services

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/ashiquegeorge15/Parishoners_app.git
   cd Parishoners_app
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Firebase Setup**
   - Create a new Firebase project at [Firebase Console](https://console.firebase.google.com/)
   - Enable Authentication, Firestore, Storage, and Realtime Database
   - Download `google-services.json` (Android) and `GoogleService-Info.plist` (iOS)
   - Place configuration files in respective platform folders

4. **Run the application**
   ```bash
   flutter run
   ```

## 🏗️ Project Structure

```
lib/
├── main.dart                 # App entry point and dashboard
├── firebase_options.dart     # Firebase configuration
├── models/                   # Data models
│   ├── announcement.dart
│   ├── dues.dart
│   ├── event.dart
│   ├── gallery.dart
│   └── user_profile.dart
├── screens/                  # UI screens
│   ├── auth_screen.dart
│   ├── dues_screen.dart
│   ├── events_screen.dart
│   ├── gallery_screen.dart
│   ├── members_screen.dart
│   └── profile_screen.dart
└── services/                 # Backend services
    └── firebase_service.dart
```

## 📦 Dependencies

### Core Dependencies
- **flutter**: SDK framework
- **firebase_core**: Firebase initialization
- **firebase_auth**: Authentication services
- **cloud_firestore**: NoSQL database
- **firebase_storage**: File storage
- **firebase_messaging**: Push notifications
- **firebase_analytics**: App analytics
- **firebase_database**: Realtime database

### UI & Utilities
- **google_fonts**: Custom typography
- **url_launcher**: External link handling
- **cupertino_icons**: iOS-style icons

## 🔧 Configuration

### Firebase Setup
1. **Authentication**: Configure sign-in methods in Firebase Console
2. **Firestore Rules**: Set up security rules for data access
3. **Storage Rules**: Configure file upload permissions
4. **Realtime Database**: Structure data for announcements and real-time features

### Environment Configuration
- Update `firebase_options.dart` with your Firebase project configuration
- Ensure platform-specific configuration files are properly placed
- Configure app permissions in platform manifest files

## 🎨 Design Features

- **Material Design 3** - Modern Material You design system
- **Glass Morphism** - Contemporary frosted glass effects
- **Responsive Layout** - Adaptive design for all screen sizes
- **Custom Animations** - Smooth transitions and micro-interactions
- **Dark/Light Theme** - Automatic theme adaptation
- **Accessibility** - Screen reader and accessibility support

## 🚀 Deployment

### Android
```bash
flutter build apk --release
# or for app bundle
flutter build appbundle --release
```

### iOS
```bash
flutter build ios --release
```

### Web
```bash
flutter build web --release
```

## 🤝 Contributing

We welcome contributions to the Parishoners App! Please follow these steps:

1. **Fork** the repository
2. **Create** a feature branch (`git checkout -b feature/AmazingFeature`)
3. **Commit** your changes (`git commit -m 'Add some AmazingFeature'`)
4. **Push** to the branch (`git push origin feature/AmazingFeature`)
5. **Open** a Pull Request

### Code Style
- Follow [Dart style guide](https://dart.dev/guides/language/effective-dart/style)
- Use meaningful variable and function names
- Add comments for complex logic
- Ensure code is properly formatted (`flutter format .`)

## 📱 Platform Support

- ✅ **Android** (API 21+)
- ✅ **iOS** (iOS 12.0+)
- ✅ **Web** (Chrome, Firefox, Safari, Edge)
- ✅ **Windows** (Windows 10+)
- ✅ **macOS** (macOS 10.14+)
- ✅ **Linux** (Ubuntu 20.04+)

## 🐛 Known Issues

- Some Firebase services may require additional configuration for web deployment
- Ensure proper permissions are set for file uploads and downloads
- Real-time features require stable internet connection

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- **Flutter Team** - For the amazing cross-platform framework
- **Firebase Team** - For comprehensive backend services
- **Google Fonts** - For beautiful typography options
- **Parish Community** - For inspiration and feedback

## 📞 Support

For support, email ashiquegeorge15@gmail.com or create an issue in this repository.

---

**Built with ❤️ for parish community**
