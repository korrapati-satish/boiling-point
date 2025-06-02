# Flutter & Backend Setup Guide with Android Studio and Emulator

This guide provides step-by-step instructions for setting up a Flutter development environment using Android Studio, creating and running a Flutter app on an Android emulator, and setting up the backend server.

---

## 🛠️ Prerequisites

Before you begin, ensure you have the following installed:

- ✅ [Flutter SDK](https://docs.flutter.dev/get-started/install)
- ✅ [Android Studio](https://developer.android.com/studio)
- ✅ System requirements (RAM, disk space, virtualization support)

---

## 🚀 Step-by-Step Setup Instructions

### 1. Install Flutter SDK

#### Mac / Linux / Windows:

1. Download Flutter SDK from the official site:  
   👉 [https://flutter.dev/docs/get-started/install](https://flutter.dev/docs/get-started/install)
2. Extract the zip file and add Flutter to your system `PATH`.

   ```bash
   export PATH="$PATH:/path/to/flutter/bin"
   ```

3. Run the following command to verify installation:

   ```bash
   flutter doctor
   ```

---

### 2. Install Android Studio

1. Download and install Android Studio:  
   👉 [https://developer.android.com/studio](https://developer.android.com/studio)
2. Open Android Studio and install the following plugins:
   - **Flutter**
   - **Dart**

   **Steps:**
   - Go to `Preferences > Plugins`
   - Search for **Flutter**, click **Install**
   - It will auto-install Dart

---

### 3. Set Up Android Emulator

1. Open Android Studio
2. Navigate to:
   - `Tools > Device Manager`
3. Click on `Create Device`:
   - Select a phone model (e.g., Pixel 5)
   - Click **Next**
4. Choose a system image (preferably **API 31+**) and download it
5. Click **Finish** to create the emulator
6. Start the emulator using the **▶** button next to the device

---

### 4. Create a New Flutter Project

1. Open Android Studio
2. Click `New Flutter Project`
3. Choose:
   - **Flutter Application**
   - Provide Project Name, SDK path, and project location
4. Click **Finish** – Android Studio will create your app

---

### 5. Run Flutter App in Emulator

1. Launch the emulator (if not already running)
2. In Android Studio, select the emulator from the device dropdown
3. Click the green **Run** button (▶) or use terminal:

   ```bash
   flutter run
   ```

4. Your app should compile and launch in the emulator

---

## ✅ Verify Setup

Run the following command:

```bash
flutter doctor
```

Ensure there are **no red crosses (✗)**. Fix any issues reported, especially with Android licenses:

```bash
flutter doctor --android-licenses
```

---

## 🧪 Useful Flutter CLI Commands

```bash
flutter create my_app         # Create new Flutter app
flutter run                   # Run the app
flutter build apk             # Build release APK
flutter clean                 # Clear build cache
```

---

# 🔥 Running the Backend (`boiling_point_server`)

# Boiling Point Server - FastAPI
This README provides instructions to set up and run the FastAPI application on the Boiling Point server.

## Prerequisites
Ensure you have the following installed:
- Python 3.8 or higher
- `pip` (Python package manager)
- `virtualenv` (optional but recommended)

## Setup Instructions

1. **Clone the Repository**:
    ```bash
    git clone <repository-url>
    cd boiling_point_server
    ```

2. **Create and Activate a Virtual Environment** (optional):
    ```bash
    python3 -m venv venv
    source venv/bin/activate  # On Windows: venv\Scripts\activate
    ```

3. **Install Dependencies**:
    ```bash
    pip install -r requirements.txt
    ```
    
4. **Run the FastAPI Application**:
    ```bash
    uvicorn boiling_point:app --host 0.0.0.0 --port 8000 --reload
    ```
    Replace `boiling_point:app` with the correct module and app instance if different.

5. **Access the Application**:
    Open your browser and navigate to:
    ```
    http://127.0.0.1:8000
    ```

6. **API Documentation**:
    - Swagger UI: [http://127.0.0.1:8000/docs](http://127.0.0.1:8000/docs)
    - ReDoc: [http://127.0.0.1:8000/redoc](http://127.0.0.1:8000/redoc)


## Additional Notes
- Ensure the required ports are open if deploying on a remote server.
- Use a process manager like `gunicorn` or `supervisor` for production deployments.


## 📦 Resources

- Flutter Docs: [flutter.dev/docs](https://flutter.dev/docs)
- Flutter Setup Video: [YouTube Flutter Setup](https://www.youtube.com/results?search_query=flutter+setup+android+studio)
- Dart Language: [dart.dev](https://dart.dev)
- Python Docs: [python.org](https://www.python.org/doc/)