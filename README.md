# 📱 Testownik (Quiz App)

**Testownik** is a native iOS application built with **SwiftUI**, designed for creating, managing, and taking knowledge quizzes. The app supports the **MVVM** architecture, data persistence, and JSON import/export capabilities.

Perfect for studying, exam revision, or creating custom quizzes for others.

## ✨ Key Features

### 🎓 Taking Quizzes
- **Interactive Interface:** Smooth transitions between questions with immediate feedback (answer highlighting).
- **Multiple Question Types:** Supports both single-choice and multiple-choice questions.
- **Smart Review:** After completing a test, if mistakes were made, the app suggests an **"Error Review"** mode, filtering only the incorrectly answered questions.
- **Progress Tracking:** Progress bar and percentage statistics for each quiz set.

### 🛠 Creator & Editor
- **Create Sets:** Manually add questions and answers directly within the app.
- **Edit:** Modify existing questions, add new answers, or rename quiz sets.
- **Manage:** Delete sets and reset progress with a single click.

### 📂 Import & Export (JSON)
- **Export:** Share quiz sets as `.json` files (with automatic filename sanitization).
- **Import:** Load sets from external files or by pasting JSON text from the clipboard.
- **Security:** Implements `Security Scoped Resources` for safe and compliant file access on iOS/macOS.

## 🏗 Architecture & Technologies

The project is built using modern Apple standards:

- **Language:** Swift 5
- **UI Framework:** SwiftUI
- **Design Pattern:** MVVM (Model-View-ViewModel)
- **Data Persistence:** `UserDefaults` (for local storage of sets and progress).
- **File Handling:** `FileDocument`, `UniformTypeIdentifiers` (integration with the native iOS "Files" app).

### Project Structure

- **Models:** `Question`, `Answer`, `QuizSet`, `QuizDocument` - `Codable` compliant data structures.
- **ViewModels:**
  - `QuizSetManager`: The main data manager, handles global I/O logic and persistence.
  - `QuizSetViewModel`: Logic for a single quiz session (navigation, answer validation).
  - `CreateQuizViewModel`: Logic for creation and editing forms.
- **Views:**
  - `ContentView`: Main view with the list of quiz sets.
  - `QuizSetView`: The quiz taking screen.
  - `CreateQuizView`: The editor screen.
  - `SetCardView`: Visual component for a quiz set card.

## 🚀 How to Run

1. **Requirements:** Mac with **Xcode 14+** installed.
2. Clone the repository or download the source files.
3. Open the `.xcodeproj` file in Xcode.
4. Select a simulator (e.g., iPhone 15) or a connected physical device.
5. Press `Cmd + R` to build and run the app.

## 📄 JSON File Format

The application uses a simple JSON format for exchanging quiz sets. Below is an example structure that the app accepts during import:

```json
{
  "id" : "E621E1F8-C36C-495A-93FC-0C247A3E6E5F",
  "name" : "Sample Quiz Set",
  "questions" : [
    {
      "id" : "A1B2C3D4-...",
      "text" : "What is the result of 2+2?",
      "answers" : [
        {
          "id" : "...",
          "text" : "4",
          "isCorrect" : true
        },
        {
          "id" : "...",
          "text" : "5",
          "isCorrect" : false
        }
      ]
    }
  ]
}

