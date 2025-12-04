import Foundation
import SwiftUI
internal import Combine

/// ViewModel do zarządzania stanem widoku tworzenia nowego zestawu pytań.
class CreateQuizViewModel: ObservableObject {
    @Published var quizSetName: String = ""
    @Published var questions: [Question] = []
    
    // Stan tymczasowy dla tworzenia/edycji pojedynczego pytania
    @Published var currentQuestionText: String = ""
    @Published var currentAnswers: [Answer] = [
        Answer(text: "", isCorrect: false),
        Answer(text: "", isCorrect: false)
    ]
    
    // Flaga do przełączania się między tworzeniem pytań a zarządzaniem zestawem
    @Published var isEditingQuestion: Bool = false
    
    // Tryb edycji istniejącego zestawu
    private var editingSetID: UUID? = nil
    
    private let manager: QuizSetManager

    init(manager: QuizSetManager) {
        self.manager = manager
    }
    
    /// Inicjalizator do edycji istniejącego zestawu
    convenience init(manager: QuizSetManager, editing set: QuizSet) {
        self.init(manager: manager)
        self.quizSetName = set.name
        self.questions = set.questions
        self.editingSetID = set.id
    }
    
    // MARK: - Zarządzanie Pytaniami/Odpowiedziami
    
    /// Dodaje nową, pustą odpowiedź do bieżącego edytowanego pytania.
    func addAnswer() {
        // Dodawanie nowej odpowiedzi
        currentAnswers.append(Answer(text: "", isCorrect: false))
    }
    
    /// Usuwa odpowiedź używając standardowego mechanizmu .onDelete z List.
    func removeAnswers(at offsets: IndexSet) {
        // Zabezpieczenie: usuwaj tylko jeśli pozostaną co najmniej 2 odpowiedzi
        if currentAnswers.count - offsets.count >= 2 {
            currentAnswers.remove(atOffsets: offsets)
        }
    }
    
    /// Dodaje lub aktualizuje pytanie do głównej listy zestawu.
    func saveQuestion() {
        // Filtruj puste odpowiedzi
        let validAnswers = currentAnswers.filter { !$0.text.isEmpty }
        
        guard !currentQuestionText.isEmpty && !validAnswers.isEmpty else {
            print("Błąd: Pytanie i odpowiedzi nie mogą być puste.")
            return
        }
        
        // Upewnij się, że co najmniej jedna odpowiedź jest poprawna
        guard validAnswers.contains(where: { $0.isCorrect }) else {
            print("Błąd: Musisz zaznaczyć co najmniej jedną poprawną odpowiedź.")
            return
        }
        
        let newQuestion = Question(text: currentQuestionText, answers: validAnswers)
        questions.append(newQuestion)
        
        // Resetuj stan edycji pytania
        resetQuestionState()
        isEditingQuestion = false
    }
    
    /// Usuwa pytanie z zestawu po indeksie. Używane w mainQuizSetEditor.
    func removeQuestion(at offsets: IndexSet) {
        questions.remove(atOffsets: offsets)
    }
    
    /// Resetuje stan tymczasowy do tworzenia nowego pytania.
    func resetQuestionState() {
        currentQuestionText = ""
        currentAnswers = [
            Answer(text: "", isCorrect: false),
            Answer(text: "", isCorrect: false)
        ]
    }
    
    // MARK: - Zarządzanie Zestawem
    
    /// Zapisuje cały zestaw do Menedżera.
    func saveQuizSet() -> Bool {
        guard !quizSetName.isEmpty else {
            print("Nazwa zestawu nie może być pusta.")
            return false
        }
        guard !questions.isEmpty else {
            print("Zestaw musi zawierać co najmniej jedno pytanie.")
            return false
        }
        
        if let id = editingSetID {
            // Edycja istniejącego zestawu: zachowaj ID (i tym samym progres w managerze)
            var edited = QuizSet(id: id, name: quizSetName, questions: questions)
            // Progres zostanie zastąpiony pustym w powyższym inicjalizatorze, ale chcemy zachować istniejący progres.
            // Pobierz aktualny zestaw z managera i przenieś jego progress.
            if let existing = manager.availableSets.first(where: { $0.id == id }) {
                edited.progress = existing.progress
            }
            manager.updateSet(edited)
        } else {
            // Nowy zestaw
            let newQuizSet = QuizSet(name: quizSetName, questions: questions)
            manager.updateSet(newQuizSet)
        }
        return true
    }
}

