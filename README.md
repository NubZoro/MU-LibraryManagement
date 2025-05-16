# Library Management App

A Flutter-based library management app that allows users to manage books, borrowing, and reading lists.

# Video Demo Link (Showcasing Functionality and Features)

https://youtu.be/4aztZd3oges

## 📄 Project Documentation

- 👉 [Statement Of Work (SOW)](./SOW_LMS.pdf)
- 👉 [Software Requirements Specification (SRS)](./SRS.final.pdf)
- 👉 [Software Design Document (SDD)](./Project_SDD_Team-1.pdf)


## Features

- **User Authentication**: Sign up, login, and manage user profiles.
- **Book Management**: Add, edit, and delete books. View book details.
- **Borrowing System**: Borrow and return books. Track borrowed books.
- **Reading Lists**: Create, edit, and delete reading lists. Share public reading lists.
- **QR Scanner**: Scan QR codes to quickly access book details.
- **Admin Panel**: Manage users, books, and borrowing history (admin only).
- **Dark/Light Theme**: Toggle between dark and light themes.

## Dependencies

- **Flutter**: The UI framework used to build the app.
- **Firebase**: Used for authentication, database, and storage.
  - **Firebase Auth**: For user authentication.
  - **Firebase Firestore**: For the database.
  - **Firebase Storage**: For storing images (if applicable).

## Installation

1. **Clone the repository**:
   ```bash
   git clone <repository-url>
   cd libmu
   ```

2. **Install dependencies**:
   ```bash
   flutter pub get
   ```

3. **Configure Firebase**:
   - Create a Firebase project at [Firebase Console](https://console.firebase.google.com/).
   - Add your Android and iOS apps to the Firebase project.
   - Download the `google-services.json` file for Android and place it in `android/app/`.

4. **Run the app**:
   ```bash
   flutter run
   ```

## Building a Release Version

To build a release version of the app (without debug banners or warnings), run:

```bash
flutter build apk --release
```

The release APK will be located at `build/app/outputs/flutter-apk/app-release.apk`.

## Project Structure

- **lib/**: Contains the Dart code for the app.
  - **screens/**: UI screens (e.g., home, login, book details).
  - **models/**: Data models (e.g., Book, User, ReadingList).
  - **services/**: Services for Firebase, authentication, etc.
  - **providers/**: State management using Provider.
  - **widgets/**: Reusable UI components.
  - **theme/**: App theme configuration.

## Contributing

1. Fork the repository.
2. Create a new branch for your feature.
3. Commit your changes.
4. Push to the branch.
5. Create a Pull Request.
