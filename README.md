# EventEase

A comprehensive Flutter-based event management and social networking platform designed to streamline event organization, discovery, and participation.

## 🚀 Features

### 🌐 Social Networking & Discovery
- **User Profiles**: Showcase bio, profile picture, and social links.
- **Feed System**: Discover and interact with posts, photos, and videos.
- **Friend Requests**: Connect with other users through a robust friend management system.
- **Advanced Search**: Find events, users, or groups with powerful filtering capabilities.

### 🎭 Event Management
- **Event Creation**: Create public or private events with detailed descriptions.
- **Ticket Management**: Sell tickets with Stripe integration for seamless payments.
- **RSVP System**: Simple "Going" or "Not Going" responses for quick planning.
- **Polls & Discussions**: Create polls and host discussions to engage attendees.

### 🏢 Organizations & Groups
- **Organization Pages**: Create and manage organizational profiles for brands or clubs.
- **Group Chat**: Dedicated chat rooms for organizers and specific event groups.
- **Event Recommendations**: AI-powered recommendations tailored to user interests.
- **Event Chat**: Real-time communication for event attendees.

### 💳 Ticketing & Payments
- **Stripe Integration**: Secure payment processing for ticket purchases.
- **Ticket Delivery**: Instant ticket generation and delivery via email (Stream/GMAIL).
- **Access Control**: QR code validation for quick and secure event entry.

### 🎨 Design & Customization
- **Theme Engine**: Dynamic theme system with support for multiple color schemes.
- **Custom Banners**: Upload custom header banners for profiles and events.
- **Language Support**: Built-in support for English, Arabic, and French.
- **Dynamic Fonts**: Adjust text size (Small, Medium, Large) for accessibility.

### 📡 Real-time & Communication
- **Real-Time Chat**: Instant messaging for friends and group discussions.
- **Live Updates**: Real-time notifications for event changes, likes, comments, and messages.

### 🔒 Security & Privacy
- **Two-Factor Authentication (2FA)**: Enhanced security with Google Authenticator integration.
- **Password Strength Meter**: Guides users in creating strong, secure passwords.
- **Content Moderation**: Tools for reporting and managing inappropriate content.

### 📦 Additional Features
- **Sitemap**: Automatic sitemap generation for improved SEO.
- **File Upload**: Comprehensive file management for organizers.
- **Settings**: Advanced settings for privacy, notifications, and appearance.
- **Calendar Sync**: Seamless integration with local device calendars.
- **QR Scanner**: Built-in scanner for ticket validation and social QR codes.
- **Map Integration**: Google Maps integration for event location discovery.

## 🛠️ Tech Stack

- **Framework**: Flutter
- **Backend**: Firebase (Auth, Firestore, Storage)
- **Payments**: Stripe
- **Email**: Stream / Gmail for ticket delivery
- **QR Codes**: flutter_barcode_scanner, flutter_qr_reader
- **Maps**: google_maps_flutter
- **Localization**: flutter_localizations
- **AI/ML**: TensorFlow Lite for recommendations

## 📂 Project Structure

The project follows a clean architecture with separation of concerns:
```
lib/
├── models/           # Data models and DTOs
├── services/         # Business logic and API integrations
├── utils/            # Utility functions and helpers
├── widgets/          # Reusable UI components
├── screens/          # Main screen widgets
├── themes/           # Theme configurations
└── controllers/      # State management controllers
```

## 🔌 Setup & Configuration

### Firebase Setup
1.  Ensure you have a Firebase project set up.
2.  Run `flutterfire configure` to link the project with your local setup.

### Stripe API Keys
Update `lib/services/payment_service.dart` with your Stripe publishable key:
```dart
final String stripePublishableKey = 'pk_test_your_publishable_key';
```

### Email Configuration
Configure Gmail SMTP credentials in `lib/services/email_service.dart` for ticket delivery.

## 🔄 Build & Run

### Running the App
```bash
flutter run
```

### Build APK
```bash
flutter build apk --release
```

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
