
# README: Survey Center

## 📌 Project Overview
Survey Center is a university-focused survey management application designed to streamline the creation, distribution, and analysis of surveys within academic faculties. It supports admin-controlled survey creation, student-specific access based on departments, and comprehensive data analytics to inform decision-making.

The system features:
- Department-based survey targeting
- Admin and super admin roles
- Real-time analytics with visualizations
- Firebase-based authentication and database
- Flutter-powered cross-platform mobile experience

---

## ⚙️ Setup Instructions

### 🔗 Prerequisites
Ensure the following are installed before setup:
- **Flutter SDK** (Latest stable version): https://flutter.dev/docs/get-started/install
- **Dart SDK** (comes with Flutter)
- **Firebase CLI**: `npm install -g firebase-tools`
- **Git**
- **VS Code / Android Studio** (with Flutter/Dart plugins)
- **Google Chrome or Android Emulator** (for testing)

---

## 💻 Installation Steps

### 🪟 For Windows
1. **Clone the Repository**
   ```bash
   git clone https://github.com/your-username/survey-center.git
   cd survey-center
   ```

2. **Install Flutter Dependencies**
   ```bash
   flutter pub get
   ```

3. **Set up Firebase**
   - Create a Firebase project.
   - Add an Android app in Firebase Console.
   - Replace `google-services.json` in `android/app`.
   - Run:
     ```bash
     firebase login
     firebase init
     ```

4. **Run the App**
   ```bash
   flutter run
   ```

### 🍏 For macOS
1. **Clone the Repository**
   ```bash
   git clone https://github.com/your-username/survey-center.git
   cd survey-center
   ```

2. **Install Dependencies**
   ```bash
   flutter pub get
   ```

3. **Set up Firebase**
   - Add iOS app to Firebase project.
   - Replace `GoogleService-Info.plist` in `ios/Runner`.
   - Ensure Xcode is configured correctly.

4. **Run the App**
   ```bash
   flutter run
   ```

---

## 🔧 Configuration
- Check `lib/firebase_options.dart` for environment configs.
- Ensure Firestore rules match app logic.
- Enable Email/Password sign-in from Firebase Authentication settings.

---

## 🛠️ Troubleshooting Tips
- **Flutter Doctor**: Always start with `flutter doctor` to diagnose setup issues.
- **Gradle build failed**: Delete `.gradle` and `.idea`, then run `flutter clean && flutter pub get`.
- **Firebase errors**: Ensure Firebase JSON/plist is correctly placed and valid.
- **Permission issues**: On macOS, grant emulator or app folder full disk access if needed.

For more assistance, refer to [Flutter Docs](https://flutter.dev/docs) and [Firebase Docs](https://firebase.google.com/docs).
