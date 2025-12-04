import SwiftUI

/// Widok do ręcznego tworzenia nowego zestawu testów.
struct CreateQuizView: View {
    @ObservedObject var viewModel: CreateQuizViewModel
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            VStack {
                if viewModel.isEditingQuestion {
                    editQuestionView
                } else {
                    mainQuizSetEditor
                }
            }
            .navigationTitle(viewModel.isEditingQuestion ? "Dodaj Pytanie" : "Utwórz Zestaw")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Anuluj") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    if !viewModel.isEditingQuestion {
                        Button("Zapisz Zestaw") {
                            if viewModel.saveQuizSet() {
                                dismiss()
                            }
                        }
                        .disabled(viewModel.quizSetName.isEmpty || viewModel.questions.isEmpty)
                    } else {
                        // W trybie edycji pytania (editQuestionView), przycisk Zapisz
                        Button("Zapisz Pytanie") {
                            viewModel.saveQuestion()
                        }
                        // Dodanie disabled, jeśli brakuje treści lub poprawnych odpowiedzi
                        .disabled(viewModel.currentQuestionText.isEmpty || viewModel.currentAnswers.filter { !$0.text.isEmpty && $0.isCorrect }.isEmpty)
                    }
                }
            }
        }
    }
    
    // MARK: - Edytor Głównego Zestawu
    var mainQuizSetEditor: some View {
        VStack {
            TextField("Nazwa Zestawu (np. Wzorce Projektowe)", text: $viewModel.quizSetName)
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(10)
                .padding(.horizontal)
                .overlay(
                    RoundedRectangle(cornerRadius: 10).stroke(Color.gray.opacity(0.5), lineWidth: 1)
                        .padding(.horizontal)
                )
            
            List {
                Section("Pytania w Zestawie (\(viewModel.questions.count))") {
                    ForEach(viewModel.questions) { question in
                        Text(question.text)
                            .lineLimit(1)
                            .font(.subheadline)
                    }
                    .onDelete(perform: viewModel.removeQuestion)
                    
                    Button {
                        viewModel.resetQuestionState()
                        viewModel.isEditingQuestion = true
                    } label: {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                            Text("Dodaj Nowe Pytanie")
                        }
                    }
                    .foregroundColor(.blue)
                }
            }
            .listStyle(.insetGrouped)
        }
    }
    
    // MARK: - Edytor Pojedynczego Pytania
    var editQuestionView: some View {
        List {
            Section("Treść Pytania") {
                TextEditor(text: $viewModel.currentQuestionText)
                    .frame(height: 100)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8).stroke(Color.gray.opacity(0.5), lineWidth: 1)
                    )
            }
            
            Section("Odpowiedzi i Poprawność") {
                // *** OBEJŚCIE CRASHA: Iterujemy po indeksach (stabilne) i używamy Bindingu na elementach ***
                
                // Używamy bezpiecznej, stałej kopii tablicy, aby uniknąć problemów z Bindingiem ForEach
                let currentAnswersCopy = viewModel.currentAnswers // Używamy kopii do iteracji

                ForEach(currentAnswersCopy.indices, id: \.self) { index in
                    
                    // Tworzymy jawny, bezpieczny Binding do elementu tablicy za pomocą indeksu
                    let answerBinding = Binding(
                        get: {
                            // Zabezpieczenie przed Index out of range
                            return viewModel.currentAnswers.indices.contains(index) ? viewModel.currentAnswers[index] : Answer(text: "", isCorrect: false)
                        },
                        set: { newValue in
                            if viewModel.currentAnswers.indices.contains(index) {
                                viewModel.currentAnswers[index] = newValue
                            }
                        }
                    )
                    
                    HStack {
                        // Bindowanie do elementu
                        TextField("Treść Odpowiedzi", text: answerBinding.text)
                            .submitLabel(.done)
                        
                        // Toggle dla poprawności
                        Toggle("", isOn: answerBinding.isCorrect)
                            .labelsHidden()
                            .tint(.green)
                        
                        // Przycisk usuwania
                        if viewModel.currentAnswers.count > 2 {
                            Button {
                                // Używamy metody z ViewModelu do bezpiecznego usunięcia
                                viewModel.removeAnswers(at: IndexSet(integer: index))
                            } label: {
                                Image(systemName: "minus.circle.fill")
                                    .foregroundColor(.red)
                            }
                        }
                    }
                    // Jawne ID jest potrzebne, gdy iterujemy po indices
                    .id(currentAnswersCopy[index].id)
                }
                
                // Przycisk dodawania odpowiedzi (działa zawsze)
                Button {
                    viewModel.addAnswer()
                } label: {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("Dodaj Odpowiedź")
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        // Usuwamy EditButton, ponieważ przywróciliśmy przycisk usuwania (-) w HSTACK.
        .toolbar {
            // EditButton usunięty, aby nie mieszać mechanizmów usuwania
        }
    }
}
