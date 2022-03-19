//
//  AllAnswersView.swift
//  WordScramble
//
//  Created by Michael M. Mayer on 3/14/22.
//
// Inspired by Paul Hudson at [HackingWithSwift.com](https://www.hackingwithswift.com), this started as an exercise that was part of his [100 Days of SwiftUI](https://www.hackingwithswift.com/100/swiftui).

import SwiftUI

// All real words created from the root word grouped by length 3 - 8
var wordGroups = [[String]]()
// The number of rows needed to display each group
var groupNumRows = [Int]()

// Displays all the possible legal words that can be generated from the root word of length 3 - 8
// displays the words in 3 columns
struct AllAnswersView: View {
    @State private var usedWords: [String]
    var body: some View {
        Form {
            ForEach(3..<9) { count in
                Section("\(count) Letter Words scoring \(count.wordScore())") {
                    GridStack(rows: groupNumRows[count - 3], columns: 3) { row, col in
                            Text( wordGroups[count - 3][row * 3 + col])
                                .foregroundColor(usedWords.contains(wordGroups[count - 3][row * 3 + col]) ? .red : .primary)
                                .frame(width: 90.0, height: 30.0,  alignment: .leading)
                    }
                    .padding(.horizontal, 25)
                }
            }
        }
    }
    
    init(usedWords: [String]) {
        self.usedWords = usedWords
        wordGroups = [[String]]()
        groupNumRows = [Int]()
        for i in 3...8 {
            // creates a array of words of all the same length for the list of all possible valid words
            var group = possibleWords.filter { $0.count == i }.map {String($0)}
            // pads the list so that it is a multiple of 3
            while group.count % 3 != 0 {
                group.append("")
            }
            wordGroups.append(group)
            // determines the number of rows needed to display all the words in that group
            var theRow: Int = wordGroups[i - 3].count / 3
            theRow += (wordGroups[i - 3].count % 3 == 0) ? 0 : 1
            groupNumRows.append(theRow)
        }
        
    }
}

struct AllAnswersView_Previews: PreviewProvider {
    static var previews: some View {
        AllAnswersView(usedWords: ["park", "drive", "reverse"])
    }
}
