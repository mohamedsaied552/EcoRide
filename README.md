# Smart Scooter App

## 🛴 Move Faster, Move Smarter

Welcome to the Smart Scooter app! We're thrilled to introduce you to a seamless and intuitive way to navigate your city. This application is designed to make your urban commutes more efficient, enjoyable, and eco-friendly. Whether you're zipping to a meeting or exploring new neighborhoods, Smart Scooter is your trusted companion.

## ✨ What Makes Smart Scooter Special?

We've poured our hearts into creating an experience that's not just functional, but genuinely delightful. Here are some of the core features that make Smart Scooter stand out:

- **Effortless Onboarding & Secure Access:** Getting started is a breeze! We guide you through a simple registration process, securing your account with phone number verification (OTP via SMS) and ensuring a safe community through quick ID and selfie verification.

- **Intuitive Map & Scooter Discovery:** Our interactive map is your gateway to freedom. Easily spot available scooters nearby, understand operational zones at a glance (no-ride, slow-speed, no-parking), and get all the details you need about a scooter before you even walk to it.

- **Seamless Ride Management:** Ready to roll? Just scan a QR code, confirm your ride details, and you're off! Our app provides real-time tracking during your ride, showing your route, duration, and cost. Ending your ride is just as simple, with guided parking verification to ensure responsible usage.

- **Smart Wallet & Payments:** Manage your funds with ease. Top up your wallet, view your transaction history, and make secure payments directly within the app. We've made sure your financial interactions are smooth and transparent.

- **Personalized Profile & Support:** Your profile is your hub for managing personal information, updating your avatar, and reviewing past rides. And if you ever need a hand, our comprehensive Help Center is just a tap away, offering FAQs and direct contact with our friendly support team.

## 🚀 Getting Started

To get this amazing app up and running, you'll need a few things. Our app is built with Flutter, leveraging the power of Firebase for authentication and real-time services.

### Prerequisites

Before you begin, ensure you have:

- **Flutter SDK:** Installed and configured on your development machine.

- **Firebase Project:** A Firebase project set up with Phone Authentication enabled.

- **Google Maps API Key:** Configured for both Android and iOS if you intend to use Google Maps for live ride tracking.

### Installation

1. **Clone the repository:**

   ```bash
   git clone https://github.com/mohamedsaied552/Zakzouka.git
   cd Zakzouka
   ```

1. **Install dependencies:**

   ```bash
   flutter pub get
   ```

1. **Configure Firebase:**
  - Follow the official FlutterFire documentation to connect your Flutter project to your Firebase project. This typically involves adding `google-services.json` for Android and `GoogleService-Info.plist` for iOS.
  - Ensure your `firebase_options.dart` file is correctly generated and reflects your project's configuration.

1. **Set up Google Maps API Key (if applicable):**
  - Add your Google Maps API key to your Android and iOS project configurations as per Google Maps Platform documentation.

### Running the App

Once everything is set up, you can run the app on your preferred device or emulator:

```bash
flutter run
```

## 🛠️ Built With

- **Flutter:** Our chosen framework for building beautiful, natively compiled applications for mobile, web, and desktop from a single codebase.

- **Firebase:** Powering our backend with robust authentication, messaging, and more.

- **Flutter Bloc:** For predictable and manageable state management throughout the application.

- **Google Maps / Flutter Map:** Providing interactive and dynamic mapping experiences.

- **Geolocator:** Handling precise location services for scooter tracking and user positioning.

## 🤝 Contributing

We believe in collaboration and continuous improvement. If you're interested in contributing to the Smart Scooter app, please reach out to our team. We'd love to hear your ideas and welcome your contributions!

## 📄 License

This project is licensed under the [ License ] - see the `LICENSE` file for details.

---

We hope you enjoy using and developing with the Smart Scooter app! If you have any questions or feedback, don't hesitate to connect with us. Happy riding!