import SwiftUI

@MainActor

struct QuizSetView: View {

    @ObservedObject var viewModel: QuizSetViewModel

    @State private var showingResetAlert = false



    var body: some View {

        Group {

            // 1) Zestaw pusty

            if viewModel.quizSet.questions.isEmpty {

                Text("Ten zestaw nie zawiera pytań. Dodaj pytania, aby rozpocząć test.")

                    .padding()

                    .multilineTextAlignment(.center)



            // 2) Podsumowanie

            } else if viewModel.showingSummaryScreen {

                QuizSummaryView(

                    viewModel: viewModel,

                    restartAction: {

                        viewModel.resetProgress()

                    },

                    reviewIncorrectAction: {

                        viewModel.filterIncorrectlyAnswered()

                    }

                )



            // 3) Normalny tryb quizu

            } else {

                quizContent

            }

        }

        .navigationTitle(self.viewModel.setName)

        .navigationBarTitleDisplayMode(.inline)

    }



    var quizContent: some View {

        VStack(spacing: 20) {

            // NAGŁÓWEK

            VStack(alignment: .leading, spacing: 8) {

                let isIncorrectReview = viewModel.questionsToDisplay.count < viewModel.quizSet.questions.count



                Text(isIncorrectReview ?

                     "Powtórka Błędów (\(viewModel.questionsToDisplay.count) pytań)" :

                        viewModel.progressText)

                    .font(.headline)

                    .foregroundColor(isIncorrectReview ? .red : .blue)



                if viewModel.currentQuestion.allowsMultipleSelection {

                    Text("Wielokrotny wybór")

                        .font(.caption)

                        .foregroundColor(.orange)

                }

            }

            .padding(.horizontal)



            Divider()



            // PYTANIE + ODPOWIEDZI

            ScrollView {

                VStack(alignment: .leading, spacing: 20) {

                    Text(viewModel.currentQuestion.text)

                        .font(.title2)

                        .padding(.bottom, 10)



                    ForEach(self.viewModel.currentQuestion.answers) { answer in

                        AnswerButton(

                            answer: answer,

                            isSelected: viewModel.isAnswerSelected(answer),

                            isChecked: viewModel.isAnswerChecked,

                            isCorrect: viewModel.isAnswerChecked ? viewModel.isAnswerCorrect(answer: answer) : nil,

                            action: { viewModel.selectAnswer(answer) }

                        )

                    }

                }

                .padding(.horizontal)

            }



            Divider()



            // PRZYCISKI DÓŁ

            HStack {

                Button("Poprzednie") {

                    viewModel.previousQuestion()

                }

                .buttonStyle(.bordered)

                .disabled(viewModel.currentQuestionIndex == 0)



                Spacer()



                if !viewModel.isAnswerChecked {

                    Button("Sprawdź Odpowiedź") {

                        viewModel.submitAnswer()

                    }

                    .buttonStyle(.borderedProminent)

                    .tint(.green)

                    .disabled(viewModel.userSelections.isEmpty)

                } else {

                    Button(viewModel.isLastQuestion ? "Zakończ" : "Dalej") {

                        if viewModel.isLastQuestion {

                            viewModel.finishSet()

                        } else {

                            viewModel.nextQuestion()

                        }

                    }

                    .buttonStyle(.borderedProminent)

                    .tint(.blue)

                }

            }

            .padding([.horizontal, .bottom])

        }

    }

}



struct QuizSummaryView: View {

    @ObservedObject var viewModel: QuizSetViewModel

    let restartAction: () -> Void

    let reviewIncorrectAction: () -> Void

    

    // Statystyki

    var stats: (correctCount: Int, totalCount: Int, percentage: Int, incorrectCount: Int) {

        let total = viewModel.quizSet.questions.count

        var correct = 0

        

        for question in viewModel.quizSet.questions {

            guard let selections = viewModel.quizSet.progress[question.id] else { continue }

            let allCorrect = Set(question.answers.filter { $0.isCorrect }.map { $0.id })

            if selections == allCorrect {

                correct += 1

            }

        }

        

        let incorrect = total - correct

        let percentage = total > 0 ? Int(Double(correct) / Double(total) * 100) : 0

        return (correct, total, percentage, incorrect)

    }

    

    var body: some View {

        VStack(spacing: 30) {

            Text("Podsumowanie Zestawu")

                .font(.largeTitle).bold()

                .padding(.bottom, 20)

            

            Image(systemName: stats.percentage >= 70 ? "star.fill" : "chart.bar.fill")

                .font(.system(size: 80))

                .foregroundColor(stats.percentage >= 70 ? .yellow : .orange)

            

            Text("\(stats.correctCount) / \(stats.totalCount) Poprawnych Odpowiedzi")

                .font(.title2)

            

            Text("\(stats.percentage)% Skuteczności")

                .font(.headline)

                .foregroundColor(stats.percentage >= 70 ? .green : .red)

            

            ProgressView(value: Double(stats.percentage) / 100.0)

                .progressViewStyle(LinearProgressViewStyle(tint: stats.percentage >= 70 ? .green : .red))

                .scaleEffect(x: 1, y: 3, anchor: .center)

                .frame(width: 200)

            

            VStack(spacing: 15) {

                if stats.incorrectCount > 0 {

                    Button("Powtórz tylko BŁĘDNE Pytania (\(stats.incorrectCount))") {

                        reviewIncorrectAction()

                    }

                    .buttonStyle(ModernButtonStyle(backgroundColor: .red))

                }

                

                Button("Zacznij od Początku (Reset Postępu)") {

                    restartAction()

                }

                .buttonStyle(ModernButtonStyle(backgroundColor: .blue))

            }

        }

        .padding()

    }

}



/// Pojedyncza odpowiedź (przycisk z kolorowaniem)

struct AnswerButton: View {

    let answer: Answer

    let isSelected: Bool

    let isChecked: Bool

    let isCorrect: Bool? // nil, jeśli jeszcze nie sprawdzono

    let action: () -> Void



    var backgroundColor: Color {

        guard isChecked else {

            return isSelected ? Color.accentColor.opacity(0.15) : Color(.systemBackground)

        }

        if isCorrect == true {

            return .green.opacity(0.85)

        } else if isSelected && isCorrect == false {

            return .red.opacity(0.85)

        } else {

            return Color(.systemBackground)

        }

    }

    

    var foregroundColor: Color {

        isChecked && (isCorrect == true || (isSelected && isCorrect == false)) ? .white : .primary

    }



    var body: some View {

        HStack {

            Text(answer.text)

                .foregroundColor(foregroundColor)

                .padding(.vertical, 10)

            Spacer()