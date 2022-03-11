//
//  ContentView.swift
//  WordScramble
//
//  Created by Michael Mayer on 8/29/21.
//
// Inspired by Paul Hudson at [HackingWithSwift.com](https://www.hackingwithswift.com), this started as an exercise that was part of his [100 Days of SwiftUI](https://www.hackingwithswift.com/100/swiftui).

import SwiftUI

// Contains the elements to be displayed in each row of the list
struct ListItem : Identifiable {
    var id = UUID()
    var word: String
    var imageName: String
}

// Contains the list of all eight letter words to be drawn from for root words
var allWords = [String]()


struct ContentView: View {
    
    // Accepted word items
    @State private var usedItems = [ListItem]()
    // The word the user derives other words from.  Randomly chosen from allWords
    @State private var rootWord = ""
    // The word answer the user is in the process of generating
    @State private var newWord = ""
    // Causes focus to be on the input textfield
    @FocusState private var isFocused: Bool

    // These contain error messages or determine when an error message should be shown
    @State private var errorTitle = ""
    @State private var errorMessage = ""
    @State private var showError = false
    @State private var isFatalError = false
    
    // tracks and displays the time remaining
    @State private var timeRemaining = 90
    // A user default that maintains a record of the highest score achieved
    @AppStorage("highScore") private var highScore = 0
    // the current game score
    @State private var gameScore = 0
    // tracks whether a game is being played or is over
    @State private var gameOver = false
    
    // a timer on the main event loop which triggers every second so the time remaining can be updated
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        NavigationView {
            ZStack {
                // the background
                LinearGradient(colors: [Color(red: 81.0/255.0, green: 0.75, blue: 1), Color.teal, .yellow, .yellow], startPoint: .top, endPoint: .bottom)
                    .rotationEffect(.degrees(10))
                    .ignoresSafeArea(.all)

                VStack {
                    TextField("Enter your word", text: $newWord, onCommit: addNewWord)
                        .focused($isFocused)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                        // changes the color of the text to red if the word (so far) won't be accepted
                        .foregroundColor(isValid(newWord) ? .black : .red)
                        .padding()
                    List(usedItems) { item in
                            HStack {
                                Image(systemName: item.imageName)
                                Text(item.word)
                            }
                    }
                    .padding(.horizontal)
                    // toggles the text to be displayed depending on whether the game is in session
                    Text(gameOver ? "Score: \(gameScore)" : "Time: \(timeRemaining)")
                        .font(.largeTitle)
                        .foregroundColor(timeRemaining > 9 || gameOver ? .white : .red)
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
                
                // performs all the start-up functions
                .onAppear(perform: startGame)
                
                // displays an alert if an error is detected, then quits the game if the error is fatal.
                .alert(errorTitle, isPresented: $showError) {
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
            
            // When the timer fires, the time remaining is updated.  The game ends when the time reaches zero.
            // The high score is updated if needed when the game ends.
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
    
    // performs all the start-up functions like loading the list of root words and setting the root word
    // All errors here are fatal
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
    
    // Creates a new game, reseting variables to their starting values.  Gets a new root word.
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
    
    // Called when a new word is submitted.  Checks it for validity and if valid, adds it to the list of accepted words.
    func addNewWord() {
        // resets focus to the textfield after a word is submitted
        isFocused = true
        
        // No action is taken if the game is over
        if gameOver {
            return
        }
        
        // An easter egg that allows the high score to be reset.
        if newWord == "XXX" {
            highScore = 0
            newWord = ""
            return
        }
        
        // lowercase and trim the word, to make sure we don't add duplicate words with case differences
        let answer = newWord.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        
        // The following four guard statements are all checks on the validity of the answer submitted.
        // An error is flagged if any of these checks fail
        guard isOriginal(word: answer) else {
            wordError(title: "Repeated word", message: "\(answer) was used already.")
            return
        }
        
        guard isPossible(word: answer) else {
            wordError(title: "Unmakeable", message: "Word cannot be created from \"\(rootWord)\".")
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
        
        // If the word is valid, it is placed in the array of accepted answers along with its score value.
        // The list of updated accepted words is then displayed with animation.
        // The score is updated with the value of the accepted word.
        withAnimation {
            usedItems.insert(ListItem(word: answer, imageName: "\(wordScore(answer)).circle"), at: 0)
            newWord = ""
        }
        gameScore += wordScore(answer)
    }
    
    // Combines all the different validy checks without setting the error flag
    func isValid(_ word: String) -> Bool {
        isOriginal(word: word) && isPossible(word: word) && isLongEnough(word: word) && isReal(word: word)
    }
    
    // Word Count Score - computes the word's game score
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
    
    // makes sure that the word submitted hasn't already been accepted or is the same as the root word
    func isOriginal(word: String) -> Bool {
        !usedItems.map(\.word).contains(word) && word != rootWord
    }
    
    // the submitted word must be of at least length 3
    func isLongEnough(word: String) -> Bool {
        return word.count >= 3
    }
    
    // the submitted word must be createable from the root word
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
    
    // the submitted word must be an actual word found in the game's dictionary.
    func isReal(word: String) -> Bool {
        let checker = UITextChecker()
        let range = NSRange(location: 0, length: word.utf16.count)
        let misspelledRange = checker.rangeOfMisspelledWord(in: word, range: range, startingAt: 0, wrap: false, language: "en")
        
        return misspelledRange.location == NSNotFound
    }
    
    // called when a submitted word is not valid - sets up the error to be shown
    func wordError(title: String, message: String) {
        errorTitle = title
        errorMessage = message
        showError = true
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
