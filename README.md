# README: Survey Center

## 📌 Project Overview
Survey Center is a university-focused survey management application designed to streamline the creation, distribution, and analysis of surveys within academic faculties. It supports admin-controlled survey creation, student-specific access based on departments, and comprehensive data analytics to inform decision-making.

The system features:
- Department-based survey targeting
- Admin and super admin roles
- Real-time analytics with visualizations
- Firebase-based authentication and database
- Flutter-powered cross-platform mobile experience

## 📥 Download App
[![Download APK](https://img.shields.io/badge/Download%20APK-007AFF?style=for-the-badge&logo=android&logoColor=white)](exe/survey-center.apk)

---

## ⚙️ Setup Instructions

### 🔗 Prerequisites
Ensure the following are installed before setup:
- *Flutter SDK* (Latest stable version): https://flutter.dev/docs/get-started/install
- *Dart SDK* (comes with Flutter)
- *Git*
- *VS Code* with Flutter and Dart extensions installed
- *Android Studio* (for Android emulator)
- *Android Emulator* or physical Android device

---

## 💻 Installation Steps

### 🪟 For Windows
1. *Required Software*
   - Install [Flutter SDK](https://flutter.dev/docs/get-started/install)
   - Install [VS Code](https://code.visualstudio.com/)
   - Install [Android Studio](https://developer.android.com/studio)
   - Install [Git](https://git-scm.com/downloads)
   - Install Flutter and Dart extensions in VS Code

2. *Setup Android Emulator*
   - Open Android Studio
   - Go to Tools > Device Manager
   - Create a new virtual device
   - Start the emulator

3. *Get the Code*
   bash
   git clone https://github.com/Amgooodd/Survey_Center_App.git
   cd Survey_Center_App
   code .  # Opens VS Code
   

4. *Install Dependencies*
   bash
   cd src
   flutter pub get
   

5. *Run the App*
   bash
   flutter run
   
   - Make sure your emulator is running or physical device is connected
   - If using a physical device, enable USB debugging in Developer Options

---

## 🔧 Development Tips
- Use flutter run to start the app
- Press r for hot reload during development
- Press R for hot restart
- Press q to quit the app

---

## 🔧 Configuration
- Check lib/firebase_options.dart for environment configs.
- Ensure Firestore rules match app logic.
- Enable Email/Password sign-in from Firebase Authentication settings.

---

## 🛠️ Troubleshooting Tips
- *Flutter Doctor*: Always start with flutter doctor to diagnose setup issues.
- *Gradle build failed*: Delete .gradle and .idea, then run flutter clean && flutter pub get.
- *Firebase errors*: Ensure Firebase JSON/plist is correctly placed and valid.
- *Permission issues*: On macOS, grant emulator or app folder full disk access if needed.

For more assistance, refer to [Flutter Docs](https://flutter.dev/docs) and [Firebase Docs](https://firebase.google.com/docs).