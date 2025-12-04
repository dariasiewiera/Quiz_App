import SwiftUI
import UniformTypeIdentifiers

/// Główny widok do zarządzania zestawami, nawigacji i operacji I/O.
struct ContentView: View {
    @StateObject var manager = QuizSetManager()
    
    // Stany dla modali
    @State private var showingCreateSheet = false
    @State private var showingExportSheet = false
    
    // Stany dla systemowego importu/eksportu
    @State private var isImporting = false
    @State private var isExporting = false
    @State private var selectedSetForExport: QuizSet? = nil
    
    // Stany dla wklejania tekstu (import z tekstu)
    @State private var showingPasteImportSheet = false
    @State private var importJsonText: String = ""
    
    // Stan edycji zestawu
    @State private var editingSet: QuizSet? = nil
    
    // MARK: - WŁAŚCIWOŚCI POMOCNICZE

    /// Pomocnicza etykieta dla przycisku "Dodaj Zestaw" (Immersyjna Karta)
    var addButtonLabel: some View {
        VStack(spacing: 10) {
            Image(systemName: "plus.app.fill")
                .resizable()
                .frame(width: 50, height: 50)
                .foregroundColor(.white)
            Text("Dodaj Zestaw")
                .font(.headline)
                .foregroundColor(.white)
        }
        .frame(maxWidth: .infinity)
        .padding(30)
        .background(
            LinearGradient(gradient: Gradient(colors: [Color.blue.opacity(0.8), Color.blue]), startPoint: .topLeading, endPoint: .bottomTrailing)
        )
        .cornerRadius(20)
        .shadow(color: .blue.opacity(0.5), radius: 10, x: 0, y: 5)
    }

    /// Pasek narzędzi: Import i Eksport rozdzielone i czytelne
    var toolbarButtons: some View {
        HStack(spacing: 15) {
            // Import menu
            Menu {
                Button {
                    isImporting = true
                } label: {
                    Label("Importuj z pliku JSON…", systemImage: "tray.and.arrow.down")
                }
                Button {
                    showingPasteImportSheet = true
                } label: {
                    Label("Importuj przez wklejenie JSON", systemImage: "doc.on.clipboard")
                }
            } label: {
                Image(systemName: "square.and.arrow.down.on.square")
                    .imageScale(.large)
            }
            .accessibilityLabel("Importuj zestaw")

            // Eksport (otwórz wybór zestawu)
            Button {
                selectedSetForExport = nil
                showingExportSheet = true
            } label: {
                Image(systemName: "square.and.arrow.up")
                    .imageScale(.large)
            }
            .accessibilityLabel("Eksportuj zestaw do pliku JSON")
        }
    }
    
    // MARK: - GŁÓWNA TREŚĆ WIDOKU
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 15) {
                    // Dodaj Zestaw
                    Button(action: { showingCreateSheet = true }) {
                        addButtonLabel
                    }
                    .buttonStyle(PlainButtonStyle())
                    .frame(maxWidth: .infinity)
                    
                    // Lista kart zestawów
                    ForEach(manager.availableSets) { quizSet in
                        SetCardView(
                            manager: manager,
                            quizSet: quizSet,
                            onEdit: { set in editingSet = set },
                            onDelete: { set in manager.removeSet(set) }
                        )
                        .frame(maxWidth: .infinity)
                    }
                }
                .padding()
            }
            .navigationTitle("Twoje Zestawy Testów")
            .background(Color(.systemGray6))
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    toolbarButtons
                }
            }
            // MARK: - Modale
            .sheet(isPresented: $showingCreateSheet) {
                CreateQuizView(viewModel: CreateQuizViewModel(manager: manager))
            }
            .sheet(item: $editingSet, onDismiss: { editingSet = nil }) { set in
                CreateQuizView(viewModel: CreateQuizViewModel(manager: manager, editing: set))
            }
            .sheet(isPresented: $showingPasteImportSheet) {
                pasteImportView
            }
            .sheet(isPresented: $showingExportSheet) {
                ExportSelectionView(
                    manager: manager,
                    selectedSet: $selectedSetForExport,
                    isExporting: $isExporting,
                    dismissSheet: { showingExportSheet = false }
                )
            }
            
            // MARK: - Systemowe Importery/Eksportery
            .fileImporter(
                isPresented: $isImporting,
                allowedContentTypes: [.json],
                allowsMultipleSelection: false
            ) { result in
                do {
                    guard let fileURL = try result.get().first else { return }
                    let data = try Data(contentsOf: fileURL)
                    if let jsonString = String(data: data, encoding: .utf8) {
                        if manager.importSetFromJSON(jsonString: jsonString) {
                            print("Pomyślnie zaimportowano plik JSON.")
                        }
                    }
                } catch {
                    print("Błąd importu pliku: \(error.localizedDescription)")
                }
            }
            .fileExporter(
                isPresented: $isExporting,
                items: [selectedSetForExport].compactMap { $0 },
                contentTypes: [.json],
                onCompletion: { result in
                    switch result {
                    case .success:
                        print("Pomyślnie wyeksportowano plik.")
                    case .failure(let error):
                        print("Błąd eksportu pliku: \(error.localizedDescription)")
                    }
                    selectedSetForExport = nil
                }
            )
        }
    }
    
    // MARK: - Import przez wklejenie JSON
    var pasteImportView: some View {
        VStack {
            Text("Wklej Treść JSON")
                .font(.title).bold()
                .padding()
            
            TextEditor(text: $importJsonText)
                .frame(height: 300)
                .background(Color(.secondarySystemBackground))
                .cornerRadius(10)
                .padding()
                .overlay(
                    RoundedRectangle(cornerRadius: 10).stroke(Color.gray.opacity(0.5), lineWidth: 1)
                )
            
            Button("Załaduj Zestaw z Tekstu") {
                if manager.importSetFromJSON(jsonString: importJsonText) {
                    importJsonText = ""
                    showingPasteImportSheet = false
                } else {
                    print("Błąd importu z tekstu. Sprawdź format JSON.")
                }
            }
            .buttonStyle(ModernButtonStyle(backgroundColor: .green))
            .padding(.bottom)
            
            Button("Importuj z pliku") {
                showingPasteImportSheet = false
                isImporting = true
            }
            .buttonStyle(.bordered)
            .padding(.top)
        }
        .padding()
    }
}

/// Karta zestawu
struct SetCardView: View {
    @ObservedObject var manager: QuizSetManager
    var quizSet: QuizSet
    var onEdit: (QuizSet) -> Void
    var onDelete: (QuizSet) -> Void
    
    var progress: Double {
        guard quizSet.questions.count > 0 else { return 0 }
        return Double(quizSet.progress.count) / Double(quizSet.questions.count)
    }
    
    var progressColor: Color {
        if progress == 1.0 { return .purple }
        if progress >= 0.5 { return .orange }
        return .blue
    }
    
    var body: some View {
        NavigationLink {
            QuizSetView(viewModel: QuizSetViewModel(quizSet: quizSet, manager: manager))
        } label: {
            VStack(alignment: .leading, spacing: 15) {
                HStack(alignment: .top) {
                    Image(systemName: "doc.text.magnifyingglass")
                        .resizable()
                        .frame(width: 35, height: 35)
                        .foregroundColor(progressColor)
                        .padding(.trailing, 10)
                    
                    VStack(alignment: .leading, spacing: 5) {
                        Text(quizSet.name)
                            .font(.title2)
                            .fontWeight(.bold)
                            .lineLimit(2)
                            .foregroundColor(.primary)
                        Text("\(quizSet.questions.count) pytań")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    Spacer()
                    Menu {
                        Button {
                            onEdit(quizSet)
                        } label: {
                            Label("Edytuj zestaw", systemImage: "pencil")
                        }
                        Button(role: .destructive) {
                            onDelete(quizSet)
                        } label: {
                            Label("Usuń zestaw", systemImage: "trash")
                        }
                        Divider()
                        Button {
                            // Szybki eksport tego konkretnego zestawu
                            // Notyfikacja do ContentView przez NotificationCenter lub inny mechanizm mogłaby być użyta.
                            // Tu zostawiamy tylko placeholder – eksport globalnie robimy z toolbaru i arkusza wyboru.
                        } label: {
                            Label("Eksportuj ten zestaw", systemImage: "square.and.arrow.up")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle.fill")
                            .font(.title2)
                            .foregroundColor(.secondary)
                    }
                }
                
                ProgressView(value: progress)
                    .progressViewStyle(LinearProgressViewStyle(tint: progressColor))
                    .scaleEffect(x: 1, y: 3, anchor: .center)
                    .padding(.vertical, 5)
                
                HStack {
                    Text("Ukończono: \(Int(progress * 100))%")
                    Spacer()
                    Text("Pozostało: \(quizSet.questions.count - quizSet.progress.count)")
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(20)
            .background(Color(.systemBackground))
            .cornerRadius(20)
            .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

/// Widok do wyboru zestawu przed eksportem pliku (sheet)
struct ExportSelectionView: View {
    @ObservedObject var manager: QuizSetManager
    @Binding var selectedSet: QuizSet?
    @Binding var isExporting: Bool
    var dismissSheet: () -> Void
    
    var body: some View {
        NavigationView {
            VStack {
                Text("Wybierz zestaw do eksportu jako plik JSON")
                    .font(.headline)
                    .padding(.top, 20)
                
                Picker("Zestaw", selection: $selectedSet) {
                    Text("Wybierz zestaw").tag(nil as QuizSet?)
                    ForEach(manager.availableSets) { set in
                        Text(set.name).tag(set as QuizSet?)
                    }
                }
                .pickerStyle(.wheel)
                .frame(height: 150)
                .clipped()
                .padding(.horizontal)
                
                Button("Eksportuj Plik JSON") {
                    if selectedSet != nil {
                        // Zamknij arkusz i uruchom systemowy fileExporter
                        dismissSheet()
                        // Za chwilę ContentView uruchomi fileExporter, bo isExporting zostanie ustawione na true
                        // i selectedSetForExport będzie już ustawiony (w ContentView).
                        // W tym widoku ustawiamy tylko flagę isExporting, ContentView ma już binding.
                        isExporting = true
                    }
                }
                .buttonStyle(ModernButtonStyle(backgroundColor: .blue))
                .disabled(selectedSet == nil)
                .padding(.vertical, 20)
                
                Spacer()
            }
            .background(Color(.systemGray6).edgesIgnoringSafeArea(.all))
            .navigationTitle("Eksport Zestawu")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Anuluj", action: dismissSheet)
                }
            }
        }
    }
}

// MARK: - STYLES AND UTILITIES

/// Niestandardowy styl przycisku dla nowoczesnego wyglądu (zaokrąglone i cieniowane)
struct ModernButtonStyle: ButtonStyle {
    var backgroundColor: Color

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundColor(.white)
            .padding()
            .frame(maxWidth: .infinity)
            .background(backgroundColor.opacity(configuration.isPressed ? 0.8 : 1.0))
            .cornerRadius(12)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .shadow(color: backgroundColor.opacity(0.5), radius: 5, x: 0, y: configuration.isPressed ? 1 : 4)
            .padding(.horizontal)
            .animation(.easeOut(duration: 0.1), value: configuration.isPressed)
    }
}

#Preview {
    ContentView()
}
