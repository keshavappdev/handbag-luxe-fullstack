
<div align="center">

<img src="https://capsule-render.vercel.app/api?type=waving&color=0:1a1a1a,50:8a6d3b,100:d4af37&height=230&section=header&text=POTLI&fontSize=84&fontColor=ffffff&animation=fadeIn&fontAlignY=38&desc=Carry%20Luxury%2C%20Beautifully&descSize=20&descAlignY=60" width="100%" alt="Potli banner"/>

<a href="https://git.io/typing-svg">
<img src="https://readme-typing-svg.demolab.com?font=Fira+Code&weight=500&size=20&duration=3200&pause=900&color=D4AF37&center=true&vCenter=true&width=640&lines=Luxury+handbag+e-commerce+platform;Flutter+%C2%B7+Java+%C2%B7+Node.js+%C2%B7+MongoDB+%C2%B7+React;Mobile+App+%2B+Backend+API+%2B+Admin+Dashboard" alt="Typing animation"/>
</a>

<br/>

<img src="https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white"/>
<img src="https://img.shields.io/badge/Java-ED8B00?style=for-the-badge&logo=openjdk&logoColor=white"/>
<img src="https://img.shields.io/badge/Node.js-339933?style=for-the-badge&logo=node.js&logoColor=white"/>
<img src="https://img.shields.io/badge/MongoDB-47A248?style=for-the-badge&logo=mongodb&logoColor=white"/>
<img src="https://img.shields.io/badge/React-20232A?style=for-the-badge&logo=react&logoColor=61DAFB"/>
<img src="https://img.shields.io/badge/Firebase-FFCA28?style=for-the-badge&logo=firebase&logoColor=000"/>

<br/><br/>

**[Overview](#-overview) · [Screenshots](#-screenshots) · [Features](#-features) · [Native Integration](#-android-native-integration) · [Architecture](#-architecture) · [Getting Started](#-getting-started) · [Roadmap](#-roadmap) · [Author](#-author)**

</div>

---

## 💎 Overview

> *A potli is a traditional drawstring bag, a small treasure carried with pride. Potli reimagines that idea as a premium digital boutique for luxury handbags.*

**Potli** is a full-stack e-commerce ecosystem consisting of three connected components.

| | Component | Description |
|:-:|---|---|
| 📱 | **Flutter Mobile App** | Android and iOS shopping experience |
| ⚙️ | **Backend API** | Node.js and Express REST APIs backed by MongoDB |
| 🖥️ | **Admin Panel** | React and Vite dashboard for store management |

The Android application also includes native Java integration through Flutter MethodChannel.

---

## 🖼️ Screenshots

### 📱 Mobile Application

<div align="center">

<img src="Potli-Flutter-App-Updated/Potli-Flutter-App-Updated/assets/images/screenshots/1.png" width="30%" alt="Potli Mobile Screen 1"/>
<img src="Potli-Flutter-App-Updated/Potli-Flutter-App-Updated/assets/images/screenshots/2.png" width="30%" alt="Potli Mobile Screen 2"/>
<img src="Potli-Flutter-App-Updated/Potli-Flutter-App-Updated/assets/images/screenshots/3.png" width="30%" alt="Potli Mobile Screen 3"/>

<p><em>Potli Mobile Shopping Experience</em></p>

</div>

### 🖥️ Admin Panel

<div align="center">

<img src="Potli-Flutter-App-Updated/Potli-Flutter-App-Updated/assets/images/admin/1.png" width="90%" alt="Admin Dashboard Overview"/>

<p><em>Dashboard Overview</em></p>

<img src="Potli-Flutter-App-Updated/Potli-Flutter-App-Updated/assets/images/admin/2.png" width="90%" alt="Admin Management Interface"/>

<p><em>Management Interface</em></p>

<img src="Potli-Flutter-App-Updated/Potli-Flutter-App-Updated/assets/images/admin/3.png" width="90%" alt="Admin Additional Interface"/>

<p><em>Additional Admin Interface</em></p>

</div>

---

## ✨ Features

<details open>
<summary><b>📱 Mobile Application</b></summary>

<br/>

| | Feature | Description |
|:-:|---|---|
| 🔐 | Authentication | User registration, login and account management |
| 👜 | Product Catalogue | Browse handbags and view detailed product information |
| 🔎 | Search | Search for available products |
| ❤️ | Wishlist | Save favourite products |
| 🛒 | Shopping Cart | Add, remove and manage cart items |
| 💳 | Checkout | Checkout and payment workflow |
| 📍 | Addresses | Manage delivery addresses |
| 📦 | Orders | View order history and details |
| 🚚 | Order Tracking | Track order status |
| 🔔 | Notifications | Firebase push notifications |
| ↩️ | Returns | Return-related workflows |
| 🎧 | Support | Customer support features |
| 📤 | Native Product Sharing | Share product information through Android's native Share Sheet using Java |

</details>

<details open>
<summary><b>🖥️ Admin Panel</b></summary>

<br/>

- Dashboard and store overview
- Product management
- Category management
- Order management
- Customer management
- Payment and order status management
- Product image management
- Protected administrative access

</details>

<details open>
<summary><b>⚙️ Backend Capabilities</b></summary>

<br/>

- JWT-based authentication
- Product and category REST APIs
- Cart and wishlist APIs
- Address management APIs
- Order management APIs
- Payment service integration
- Cloudinary media services
- Firebase notification integration
- MongoDB data persistence
- Authorization for protected endpoints

</details>

---

## ☕ Android Native Integration

### Product Sharing with Java and Flutter MethodChannel

Potli includes an Android-native product sharing feature implemented using **Java, Kotlin, and Flutter MethodChannel**.

This integration allows customers to share product details using the Android system Share Sheet without requiring an additional Flutter sharing package.

**How it works:**

1. The user opens a product details screen in Flutter.
2. The user taps the Share icon.
3. Flutter sends the product details through a MethodChannel.
4. The Android native layer receives the request.
5. Java uses `Intent.ACTION_SEND` to open the Android Share Sheet.
6. The user selects WhatsApp, Gmail, Bluetooth or another compatible application.

**Technical Implementation**

| Component | Technology |
|---|---|
| Mobile UI | Flutter / Dart |
| Native Android Logic | Java |
| Channel Registration | Kotlin |
| Flutter–Android Communication | MethodChannel |
| Android API | Intent.ACTION_SEND |
| Data Shared | Product name, price and store URL |
| Platform | Android |

### Native Communication Flow

```mermaid
flowchart TD
    A["Flutter Product Detail Screen"] --> B["Share Button"]
    B --> C["Dart MethodChannel"]
    C --> D["Kotlin MainActivity"]
    D --> E["Java ProductShareHandler"]
    E --> F["Android Intent.ACTION_SEND"]
    F --> G["Android Share Sheet"]
```

### Implementation Files

```text
android/app/src/main/
├── java/com/potli/app/
│   └── ProductShareHandler.java
└── kotlin/com/potli/app/
    └── MainActivity.kt

lib/
├── services/
│   └── native_product_share_service.dart
└── views/shop/
    └── shop_views.dart
```

**Note:** This integration requires no backend API, database schema or admin panel modifications. Android support is implemented; equivalent native iOS sharing requires a separate Swift implementation.

---

## 🧰 Tech Stack

<div align="center">

| Layer | Technologies |
|:-:|:--|
| **📱 Mobile** | Flutter, Dart, Android, iOS |
| **☕ Native Android** | Java, Kotlin, MethodChannel, Android Intent |
| **⚙️ Backend** | Node.js, Express.js, MongoDB, JWT |
| **🖥️ Admin Panel** | React, Vite, JavaScript |
| **☁️ Services** | Firebase, Cloudinary, Docker, GitHub |

</div>

---

## 🏗️ Architecture

```mermaid
flowchart LR
    A["Flutter Mobile App"] -->|REST + JWT| C["Node.js + Express API"]
    B["React Admin Panel"] -->|REST + JWT| C
    C --> D[("MongoDB")]
    C --> E["Cloudinary"]
    C --> F["Firebase"]
    C --> G["Payment Service"]
    A -->|MethodChannel| H["Native Android Java"]
    H --> I["Android Share Sheet"]
```

### 🛍️ Customer Journey

```mermaid
flowchart LR
    S["Sign In"] --> B["Browse & Search"]
    B --> W["Wishlist / Cart"]
    W --> CH["Checkout & Pay"]
    CH --> T["Track Order"]
    T --> R["Return / Support"]
```

---

## 📂 Project Structure

```text
handbag-luxe-fullstack/
│
├── README.md
│
├── Potli-Flutter-App-Updated/
│   └── Potli-Flutter-App-Updated/
│       ├── android/
│       │   └── app/src/main/
│       │       ├── java/com/potli/app/
│       │       │   └── ProductShareHandler.java
│       │       └── kotlin/com/potli/app/
│       │           └── MainActivity.kt
│       ├── ios/
│       ├── assets/
│       │   └── images/
│       ├── lib/
│       │   ├── services/
│       │   │   └── native_product_share_service.dart
│       │   └── views/shop/
│       │       └── shop_views.dart
│       └── pubspec.yaml
│
└── Potli-Backend-Updated/
    └── my-ecommerce/
        ├── backend/
        ├── admin-panel/
        ├── docs/
        └── docker-compose.yml
```

---

## 🚀 Getting Started

### Prerequisites

- Flutter SDK and Dart
- Android SDK and JDK
- Node.js (LTS) and npm
- MongoDB (local or Atlas), or Docker
- Cloudinary and Firebase configuration

### 1️⃣ Clone the Repository

```bash
git clone https://github.com/keshavappdev/handbag-luxe-fullstack.git
cd handbag-luxe-fullstack
```

### 2️⃣ Run the Backend

```bash
cd Potli-Backend-Updated/my-ecommerce/backend
npm install
cp .env.example .env
npm run dev
```

Configure your backend environment variables before starting the API.

### 3️⃣ Run the Admin Panel

From the repository root:

```bash
cd Potli-Backend-Updated/my-ecommerce/admin-panel
npm install
npm run dev
```

### 4️⃣ Run the Flutter Mobile App

From the repository root:

```bash
cd Potli-Flutter-App-Updated/Potli-Flutter-App-Updated
flutter pub get
flutter run
```

### 5️⃣ Test the Java Native Sharing Feature

1. Run the Flutter application on an Android device or emulator.
2. Open the product details screen.
3. Tap the Share icon.
4. Android will display the native sharing interface.
5. Select a compatible application to share the product information.

No additional Flutter package is required for this native integration.

### 🐳 Docker Setup

From the repository root:

```bash
cd Potli-Backend-Updated/my-ecommerce
docker-compose up --build
```

### 🔧 Environment Variables

Create a `.env` file in the backend directory using the actual environment variable names required by the project.

Example:

```env
PORT=5000
MONGO_URI=your_mongodb_connection_string
JWT_SECRET=your_long_random_secret
CLOUDINARY_CLOUD_NAME=your_cloud_name
CLOUDINARY_API_KEY=your_api_key
CLOUDINARY_API_SECRET=your_api_secret
```

---

## 🔐 Security

- Keep database credentials, API keys and JWT secrets out of version control.
- Use environment variables for sensitive backend configuration.
- Protect administrative endpoints using server-side authorization.
- Never publish real production credentials or private keys.
- Review configuration files before pushing the project to GitHub.

---

## 🗺️ Roadmap

- [x] Authentication and protected routes
- [x] Product catalogue, cart and wishlist
- [x] Orders, tracking and notifications
- [x] Admin dashboard
- [x] Android native product sharing using Java and MethodChannel
- [ ] Native iOS product sharing integration
- [ ] Reviews and ratings
- [ ] Coupons and promotional offers
- [ ] Advanced filters and recommendations
- [ ] Analytics and sales reports
- [ ] Automated tests and CI/CD pipeline

---

## 🤝 Contributing

Ideas and improvements are welcome.

1. Fork the repository.
2. Create a feature branch: `git checkout -b feature/amazing-idea`
3. Commit your changes: `git commit -m "Add amazing idea"`
4. Push your branch: `git push origin feature/amazing-idea`
5. Open a Pull Request.

---

## 👨‍💻 Author

<div align="center">

### Keshav Upadhyay

**Flutter / Mobile Application Developer**

<a href="https://github.com/keshavappdev">
<img src="https://img.shields.io/badge/GitHub-keshavappdev-181717?style=for-the-badge&logo=github&logoColor=white"/>
</a>

<br/><br/>

⭐ **If you like this project, give it a star!** ⭐

</div>

<img src="https://capsule-render.vercel.app/api?type=waving&color=0:d4af37,50:8a6d3b,100:1a1a1a&height=120&section=footer&text=Mobile%20%C2%B7%20Backend%20%C2%B7%20Admin&fontSize=22&fontColor=ffffff&fontAlignY=65" width="100%" alt="footer"/>
