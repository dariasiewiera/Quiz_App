import Foundation
import SwiftUI
import UniformTypeIdentifiers 


struct Answer: Identifiable, Codable, Equatable, Hashable {
    let id: UUID = UUID()
    var text: String
    var isCorrect: Bool
}

struct Question: Identifiable, Codable, Equatable, Hashable {
    let id: UUID = UUID()
    var text: String
    var answers: [Answer]
    
    var allowsMultipleSelection: Bool {
        answers.filter { $0.isCorrect }.count > 1
    }
}

struct QuizSet: Identifiable, Codable, Equatable, Hashable {
    let id: UUID
    var name: String
    var questions: [Question]
    var progress: [UUID: Set<UUID>] = [:]
    var isCompleted: Bool = false
    
    private enum CodingKeys: String, CodingKey {
        case id, name, questions
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        if let decodedId = try? container.decode(UUID.self, forKey: .id) {
            self.id = decodedId
        } else {
            self.id = UUID()
        }
        name = try container.decode(String.self, forKey: .name)
        questions = try container.decode([Question].self, forKey: .questions)
        progress = [:]
        isCompleted = false
    }
    
    init(name: String, questions: [Question]) {
        self.id = UUID()
        self.name = name
        self.questions = questions
        self.progress = [:]
        self.isCompleted = false
    }
    
    init(id: UUID, name: String, questions: [Question]) {
        self.id = id
        self.name = name
        self.questions = questions
        self.progress = [:]
        self.isCompleted = false
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

extension QuizSet: Transferable {
    static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(exportedContentType: .json) { quizSet in
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            let exportableSet = QuizSet(id: quizSet.id, name: quizSet.name, questions: quizSet.questions)
            return try encoder.encode(exportableSet)
        }
        DataRepresentation(importedContentType: .json) { data in
            let decoder = JSONDecoder()
            return try decoder.decode(QuizSet.self, from: data)
        }
    }
}

struct QuizDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.json] }
    
    var quizSet: QuizSet
    
    init(quizSet: QuizSet) {
        self.quizSet = quizSet
    }
    
    init(configuration: ReadConfiguration) throws {
        let data = try configuration.file.regularFileContents
        ?? Data()
        let decoder = JSONDecoder()
        self.quizSet = try decoder.decode(QuizSet.self, from: data)
    }
    
    
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        let data = try encoder.encode(quizSet)
        return FileWrapper(regularFileWithContents: data)
    }
}
