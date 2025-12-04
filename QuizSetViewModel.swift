import Foundation
import SwiftUI
internal import Combine

class QuizSetViewModel: ObservableObject {
    
    @Published private(set) var quizSet: QuizSet
    @Published var currentQuestionIndex: Int = 0
    @Published var userSelections: Set<UUID> = []
    @Published var isAnswerChecked: Bool = false
    @Published var sessionQuestionCount: Int = 0
    @Published private(set) var questionsToDisplay: [Question] = []
    @Published var showingSummaryScreen: Bool = false
    @Published var allPerfectInSession: Bool = false
    @Published var completedWithErrors: Bool = false
    
    private let manager: QuizSetManager
    
    
    init(quizSet: QuizSet, manager: QuizSetManager) {
        self.quizSet = quizSet
        self.manager = manager
        restoreState()
    }
    
   
    private func restoreState() {
    
        if quizSet.isCompleted {
            showSummaryBasedOnProgress()
            return
        }
        
        
        let allQuestionsAnswered = quizSet.questions.allSatisfy { question in
            quizSet.progress[question.id] != nil
        }
        
        if allQuestionsAnswered && !quizSet.questions.isEmpty {
            showSummaryBasedOnProgress()
            return
        }
        
        questionsToDisplay = quizSet.questions
        sessionQuestionCount = questionsToDisplay.count 
        
        showingSummaryScreen = false
        loadProgress()
    }
   /* private func restoreState() {
        if quizSet.isCompleted {
            showSummaryBasedOnProgress()
            return
        }
        
        questionsToDisplay = quizSet.questions
        sessionQuestionCount = questionsToDisplay.count
        showingSummaryScreen = false
        loadProgress()
    }*/
    
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
    
    
    
    var currentQuestion: Question {
        guard currentQuestionIndex < questionsToDisplay.count else {
            return questionsToDisplay.first ?? quizSet.questions.first!
        }
        return questionsToDisplay[currentQuestionIndex]
    }
    
    var progressText: String {
        "Pytanie \(currentQuestionIndex + 1) z \(sessionQuestionCount)"
    }
    
  
    var isLastQuestion: Bool {
        currentQuestionIndex == (sessionQuestionCount - 1)
    }
    
   
    
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
        guard currentQuestionIndex < sessionQuestionCount - 1 else { return }
        
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
        sessionQuestionCount = wrong.count
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
        
        let allCorrect = questionsToDisplay.allSatisfy { q in
            let correct = Set(q.answers.filter { $0.isCorrect }.map { $0.id })
            let user = quizSet.progress[q.id] ?? []
            return user == correct
        }
        
        allPerfectInSession = allCorrect
        completedWithErrors = !allCorrect
        
        quizSet.isCompleted = true
        
        
        questionsToDisplay = []
        
        saveProgress()
        //currentQuestionIndex = 0
        userSelections = []
        isAnswerChecked = false
        showingSummaryScreen = true
        
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
        sessionQuestionCount = questionsToDisplay.count
        loadProgress()
    }
    
    func showAllQuestions() {
        showingSummaryScreen = false
        allPerfectInSession = false
        completedWithErrors = false
        
        questionsToDisplay = quizSet.questions
        sessionQuestionCount = questionsToDisplay.count
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