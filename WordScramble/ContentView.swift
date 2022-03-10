//
//  ContentView.swift
//  WordScramble
//
//  Created by Michael Mayer on 8/29/21.
//

import SwiftUI

struct ListItem : Identifiable {
    var id = UUID()
    var word: String
    var imageName: String
}

var allWords = [String]()


struct ContentView: View {
    @State private var usedItems = [ListItem]()
    @State private var rootWord = ""
    @State private var newWord = ""
    @FocusState private var isFocused: Bool

    @State private var errorTitle = ""
    @State private var errorMessage = ""
    @State private var showingError = false
    @State private var isFatalError = false
    
    @State private var timeRemaining = 90
    @AppStorage("highScore") private var highScore = 0
    @State private var gameScore = 0
    @State private var gameOver = false
    
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(colors: [Color(red: 81.0/255.0, green: 0.75, blue: 1), Color.teal, .yellow, .yellow], startPoint: .top, endPoint: .bottom)
                    .rotationEffect(.degrees(10))
                    .ignoresSafeArea(.all)
                VStack {
                    TextField("Enter your word", text: $newWord, onCommit: addNewWord)
                        .focused($isFocused)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .foregroundColor(isValid(newWord) ? .black : .red)
                        .padding()
                    List(usedItems) { item in
                            HStack {
                                Image(systemName: item.imageName)
                                Text(item.word)
                            }
                    }
                    
                    .padding(.horizontal)
                    Text(gameOver ? "Score: \(gameScore)" : "Time: \(timeRemaining)")
                        .font(.largeTitle)
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 5)
                        .background(
                            Capsule()
                                .fill(Color.black)
                                .opacity(0.75)
                        )
                        .padding()
                    Spacer()
                    Text("High Score: \(highScore)")
                }
                .navigationBarTitle(rootWord)
                .onAppear(perform: startGame)
                .alert(errorTitle, isPresented: $showingError) {
                    Button("OK", role: .cancel) {
                        if isFatalError {
                            fatalError(errorMessage)
                        }
                    }
                } message: {
                    Text(errorMessage)
                }
            }
            .navigationBarItems(trailing: Button(action: newGame) {
                Text("New Game")
                    .bold()
                    .foregroundColor(.black)
            })
            .onReceive(timer) { time in
                if self.timeRemaining > 0 {
                    self.timeRemaining -= 1
                }
                else {
                    gameOver = true
                    if gameScore > highScore {
                        highScore = gameScore
                    }
                    isFocused = false
                }
            }
            
        }
    }
    
    func startGame() {
        isFocused = true
        if let startWordsURL = Bundle.main.url(forResource: "start", withExtension: "txt") {
            if let startWords = try? String(contentsOf: startWordsURL) {
                allWords = startWords.components(separatedBy: "\n")
                if let randomWord = allWords.randomElement() {
                    rootWord = randomWord
                    return
                }
                else {
                    wordError(title: "Fatal Error", message: "List of words from start.txt appears to be empty.")
                }
            }
            else {
                wordError(title: "Fatal Error", message: "Could not load start.txt from bundle.")
            }
        }
        else {
            wordError(title: "Fatal Error", message: "Could not find start.txt from bundle.")
        }
        isFatalError = true
    }
    
    func newGame() {
        isFocused = true
        timeRemaining = 90
        newWord = ""
        gameScore = 0
        gameOver = false
        usedItems.removeAll()
        if let randomWord = allWords.randomElement() {
            rootWord = randomWord
        }
        else {
            wordError(title: "Fatal Error", message: "List of words from start.txt appears to be empty.")
            isFatalError = true
        }
    }
    
    func addNewWord() {
        isFocused = true
        if gameOver {
            return
        }
        // lowercase and trim the word, to make sure we don't add duplicate words with case differences
        let answer = newWord.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard isOriginal(word: answer) else {
            wordError(title: "Repeated word", message: "\(answer) was used already.")
            return
        }
        
        guard isPossible(word: answer) else {
            wordError(title: "Unmakeable", message: "Word cannot be made from \"\(rootWord)\".")
            return
        }
        
        guard isLongEnough(word: answer) else {
            wordError(title: "Word too short", message: "Word must be at least three letters long.")
            return
        }
        
        guard isReal(word: answer) else {
            wordError(title: "Invalid word", message: "\(answer) does not occur in Word Scramble's dictionary")
            return
        }
        withAnimation {
            usedItems.insert(ListItem(word: answer, imageName: "\(wordScore(answer)).circle"), at: 0)
            newWord = ""
        }
        gameScore += wordScore(answer)
    }
    
    func isValid(_ word: String) -> Bool {
        isLongEnough(word: word) && isPossible(word: word) && isOriginal(word: word) && isReal(word: word)
    }
    
    // Word Count Score
    //        3    3
    //        4    4
    //        5    6
    //        6    8
    //        7    13
    //        8    18
    func wordScore(_ word: String) -> Int {
        let count = word.count
        return count + max(0, count - 4) + max(0, count - 5) + max(0, count - 6) + max(0, count - 7)
    }
    
    func isOriginal(word: String) -> Bool {
        !usedItems.map(\.word).contains(word) && word != rootWord
    }
    
    func isLongEnough(word: String) -> Bool {
        return word.count >= 3
    }
    
    func isPossible(word: String) -> Bool {
        var tempWord = rootWord
        
        for letter in word {
            if let pos = tempWord.firstIndex(of: letter) {
                tempWord.remove(at: pos)
            } else {
                return false
            }
        }
        
        return true
    }
    
    func isReal(word: String) -> Bool {
        let checker = UITextChecker()
        let range = NSRange(location: 0, length: word.utf16.count)
        let misspelledRange = checker.rangeOfMisspelledWord(in: word, range: range, startingAt: 0, wrap: false, language: "en")
        
        return misspelledRange.location == NSNotFound
    }
    
    func wordError(title: String, message: String) {
        errorTitle = title
        errorMessage = message
        showingError = true
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
