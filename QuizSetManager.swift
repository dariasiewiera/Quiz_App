import Foundation
import SwiftUI
internal import Combine

// MARK: - Menedżer Zestawów (QuizSetManager)
// Odpowiedzialny za persystencję, ładowanie, zapisywanie zestawów i zarządzanie JSON I/O.

class QuizSetManager: ObservableObject {
    // Użycie @Published, aby ContentView automatycznie reagował na zmiany listy zestawów.
    @Published var availableSets: [QuizSet] = []
    
    private let storageKey = "QuizSetsData"

    init() {
        loadSets()
        // W przypadku pustej listy (pierwsze uruchomienie), załaduj zestaw demonstracyjny.
        if availableSets.isEmpty {
            createDemoSet()
        }
    }

    // MARK: - Persystencja
    
    /// Zapisuje wszystkie zestawy (w tym ich postępy) do UserDefaults.
    func saveSets() {
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            let data = try encoder.encode(availableSets)
            UserDefaults.standard.set(data, forKey: storageKey)
        } catch {
            print("Błąd zapisu zestawów (Persistence Error): \(error)")
        }
    }

    /// Ładuje zestawy z UserDefaults.
    func loadSets() {
        if let data = UserDefaults.standard.data(forKey: storageKey) {
            do {
                let decoder = JSONDecoder()
                availableSets = try decoder.decode([QuizSet].self, from: data)
            } catch {
                print("Błąd ładowania zestawów (Persistence Error): \(error)")
                availableSets = []
            }
        }
    }
    
    /// Aktualizuje istniejący zestaw lub dodaje nowy (wywoływane przez ViewModel po zmianie postępu).
    func updateSet(_ quizSet: QuizSet) {
        if let index = availableSets.firstIndex(where: { $0.id == quizSet.id }) {
            // Zastąp istniejący zestaw, zachowując referencję do aktualizacji.
            availableSets[index] = quizSet
        } else {
            availableSets.append(quizSet)
        }
        saveSets()
    }
    
    /// Usuwa zestaw po obiekcie.
    func removeSet(_ set: QuizSet) {
        removeSet(id: set.id)
    }
    
    /// Usuwa zestaw po ID.
    func removeSet(id: UUID) {
        if let index = availableSets.firstIndex(where: { $0.id == id }) {
            availableSets.remove(at: index)
            saveSets()
        }
    }
    
    // MARK: JSON Import/Export
    
    /// Eksportuje zestaw do JSON. Zwraca String z samą definicją pytań (bez postępu).
    func exportSetToJSON(_ quizSet: QuizSet) -> String? {
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            
            // Używamy NOWEGO konstruktora do stworzenia kopii zestawu bez progresu.
            let exportableSet = QuizSet(id: quizSet.id, name: quizSet.name, questions: quizSet.questions)
            let data = try encoder.encode(exportableSet)
            return String(data: data, encoding: .utf8)
        } catch {
            print("Błąd eksportu JSON: \(error)")
            return nil
        }
    }

    /// Importuje zestaw z JSON.
    func importSetFromJSON(jsonString: String) -> Bool {
        guard let data = jsonString.data(using: .utf8) else { return false }
        do {
            let decoder = JSONDecoder()
            let newSet = try decoder.decode(QuizSet.self, from: data) // Progress jest ignorowany przez custom init
            
            // Sprawdzenie, czy zestaw o tym ID już istnieje
            if let index = availableSets.firstIndex(where: { $0.id == newSet.id }) {
                // Jeśli istnieje, aktualizuj treść, ale zachowaj stary progres
                var existingSet = availableSets[index]
                existingSet.name = newSet.name
                existingSet.questions = newSet.questions
                // Jeśli importowany zestaw ma to samo ID, nowy progres jest ignorowany
                availableSets[index] = existingSet
            } else {
                availableSets.append(newSet)
            }
            saveSets()
            return true
        } catch {
            print("Błąd importu JSON (Invalid JSON format): \(error)")
            return false
        }
    }

    // MARK: Zestaw Demonstracyjny

    private func createDemoSet() {
        let question1 = Question(
            text: "Czym jest Architektura MVVM w kontekście SwiftUI?",
            answers: [
                Answer(text: "Model-View-ViewModel", isCorrect: true),
                Answer(text: "Model-View-Manager", isCorrect: false),
                Answer(text: "Multi-View-Modular", isCorrect: false)
            ]
        )
        
        let question2 = Question(
            text: "Które z poniższych są Property Wrappers w Swift/SwiftUI?",
            answers: [
                Answer(text: "@State", isCorrect: true),
                Answer(text: "@Published", isCorrect: true),
                Answer(text: "@View", isCorrect: false),
                Answer(text: "@Environment", isCorrect: true)
            ]
        )
        
        let question3 = Question(
            text: "Jaki jest podstawowy cel @ObservableObject w MVVM?",
            answers: [
                Answer(text: "Umożliwienie aktualizacji widoku (View) po zmianie danych w ViewModelu.", isCorrect: true),
                Answer(text: "Wykonywanie asynchronicznych operacji sieciowych.", isCorrect: false),
                Answer(text: "Bezpośrednie zarządzanie stanem UI (jak @State).", isCorrect: false)
            ]
        )
        
        let demoSet = QuizSet(name: "Zaawansowane Swift/SwiftUI (Demo)", questions: [question1, question2, question3])
        availableSets.append(demoSet)
        saveSets()
    }
}

