import Foundation
import SwiftUI
internal import Combine

class QuizSetViewModel: ObservableObject {
    
    @Published private(set) var quizSet: QuizSet
    @Published var currentQuestionIndex: Int = 0
    @Published var userSelections: Set<UUID> = []
    @Published var isAnswerChecked: Bool = false
    
    @Published private(set) var questionsToDisplay: [Question] = []
    @Published var showingSummaryScreen: Bool = false
    @Published var allPerfectInSession: Bool = false
    @Published var completedWithErrors: Bool = false
    
    private let manager: QuizSetManager
    
    // MARK: - INIT
    init(quizSet: QuizSet, manager: QuizSetManager) {
        self.quizSet = quizSet
        self.manager = manager
        restoreState()
    }
    
    // MARK: - Przywracanie stanu
    private func restoreState() {
        if quizSet.isCompleted {
            showSummaryBasedOnProgress()
            return
        }
        
        questionsToDisplay = quizSet.questions
        showingSummaryScreen = false
        loadProgress()
    }
    
    private func showSummaryBasedOnProgress() {
        let allCorrect = quizSet.questions.allSatisfy { q in
            let correct = Set(q.answers.filter { $0.isCorrect }.map { $0.id })
            let user = quizSet.progress[q.id] ?? []
            return user == correct
        }
        
        allPerfectInSession = allCorrect
        completedWithErrors = !allCorrect
        
        showingSummaryScreen = true
        questionsToDisplay = []
        currentQuestionIndex = 0
        userSelections = []
        isAnswerChecked = false
    }
    
    // MARK: - Właściwości pomocnicze
    
    var currentQuestion: Question {
        guard currentQuestionIndex < questionsToDisplay.count else {
            return questionsToDisplay.first ?? quizSet.questions.first!
        }
        return questionsToDisplay[currentQuestionIndex]
    }
    
    var progressText: String {
        "Pytanie \(currentQuestionIndex + 1) z \(questionsToDisplay.count)"
    }
    
    /// ▶️ DODANE — tego potrzebuje widok
    var isLastQuestion: Bool {
        currentQuestionIndex == questionsToDisplay.count - 1
    }
    
    // MARK: - Ładowanie/Zapisywanie
    
    private func loadProgress() {
        if let firstUnanswered = quizSet.questions.firstIndex(where: { quizSet.progress[$0.id] == nil }) {
            currentQuestionIndex = firstUnanswered
        } else {
            currentQuestionIndex = 0
        }
        
        userSelections = []
        isAnswerChecked = false
    }
    
    private func saveProgress() {
        manager.updateSet(quizSet)
    }
    
    // MARK: - Odpowiadanie
    
    func selectAnswer(_ answer: Answer) {
        guard !isAnswerChecked else { return }
        
        if currentQuestion.allowsMultipleSelection {
            if userSelections.contains(answer.id) {
                userSelections.remove(answer.id)
            } else {
                userSelections.insert(answer.id)
            }
        } else {
            userSelections = [answer.id]
        }
    }
    
    func submitAnswer() {
        guard !isAnswerChecked else { return }
        quizSet.progress[currentQuestion.id] = userSelections
        isAnswerChecked = true
    }
    
    func nextQuestion() {
        saveProgress()
        guard currentQuestionIndex < questionsToDisplay.count - 1 else { return }
        
        currentQuestionIndex += 1
        userSelections = []
        isAnswerChecked = false
    }
    
    func previousQuestion() {
        guard currentQuestionIndex > 0 else { return }
        
        currentQuestionIndex -= 1
        userSelections = quizSet.progress[currentQuestion.id] ?? []
        isAnswerChecked = !userSelections.isEmpty
    }
    
    // MARK: - Powtórka
    
    func filterIncorrectlyAnswered() {
        let wrong = quizSet.questions.filter { q in
            let correct = Set(q.answers.filter { $0.isCorrect }.map { $0.id })
            return quizSet.progress[q.id] != correct
        }
        
        if wrong.isEmpty {
            quizSet.isCompleted = true
            saveProgress()
            showSummaryBasedOnProgress()
            return
        }
        
        questionsToDisplay = wrong
        showingSummaryScreen = false
        allPerfectInSession = false
        completedWithErrors = false
        
        wrong.forEach { q in quizSet.progress.removeValue(forKey: q.id) }
        quizSet.isCompleted = false
        saveProgress()
        
        currentQuestionIndex = 0
        userSelections = []
        isAnswerChecked = false
    }
    
    // MARK: - Zakończenie testu
    
    func finishSet() {
        saveProgress()
        
        let allCorrect = questionsToDisplay.allSatisfy { q in
            let correct = Set(q.answers.filter { $0.isCorrect }.map { $0.id })
            let user = quizSet.progress[q.id] ?? []
            return user == correct
        }
        
        allPerfectInSession = allCorrect
        completedWithErrors = !allCorrect
        
        quizSet.isCompleted = true
        saveProgress()
        
        showingSummaryScreen = true
        questionsToDisplay = []
    }
    
    // MARK: - Reset
    
    func resetProgress() {
        quizSet.progress = [:]
        quizSet.isCompleted = false
        saveProgress()
        
        showingSummaryScreen = false
        allPerfectInSession = false
        completedWithErrors = false
        
        questionsToDisplay = quizSet.questions
        loadProgress()
    }
    
    func showAllQuestions() {
        showingSummaryScreen = false
        allPerfectInSession = false
        completedWithErrors = false
        
        questionsToDisplay = quizSet.questions
        loadProgress()
    }
    
    // MARK: - ▶️ BRAKUJĄCE FUNKCJE dla widoku
    
    /// Czy odpowiedź jest zaznaczona
    func isAnswerSelected(_ answer: Answer) -> Bool {
        userSelections.contains(answer.id)
    }
    
    /// Czy odpowiedź jest poprawna (używane po sprawdzeniu)
    func isAnswerCorrect(answer: Answer) -> Bool {
        answer.isCorrect
    }
    
    // MARK: - Inne
    
    var setName: String {
        quizSet.name
    }
}
