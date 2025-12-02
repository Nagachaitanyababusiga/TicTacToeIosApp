//
//  ContentView.swift
//  TicTakToe
//
//  Created by Sarfaraz on 02/12/25.
//
import SwiftUI
internal import Combine

enum Player: String {
    case x = "X"
    case o = "O"
    
    var next: Player { self == .x ? .o : .x }
}

struct Move {
    let player: Player
    let index: Int
}

final class GameViewModel: ObservableObject {
    
    @Published var board: [String] = Array(repeating: "", count: 9)
    @Published var currentPlayer: Player = .x
    @Published var isGameOver: Bool = false
    @Published var message: String = ""
    @Published var scoreX: Int = 0
    @Published var scoreO: Int = 0
    
    private let winningSets: Set<Set<Int>> = [
        [0,1,2], [3,4,5], [6,7,8], // rows
        [0,3,6], [1,4,7], [2,5,8], // cols
        [0,4,8], [2,4,6]           // diagonals
    ]
    
    func makeMove(at index: Int) {
        guard !isGameOver else { return }
        guard index >= 0 && index < board.count else { return }
        guard board[index].isEmpty else { return } // already taken
        
        board[index] = currentPlayer.rawValue
        if checkWin(for: currentPlayer) {
            isGameOver = true
            message = "\(currentPlayer.rawValue) wins!"
            if currentPlayer == .x { scoreX += 1 } else { scoreO += 1 }
        } else if board.filter({ $0.isEmpty }).isEmpty {
            // draw
            isGameOver = true
            message = "It's a draw!"
        } else {
            currentPlayer = currentPlayer.next
            message = "\(currentPlayer.rawValue)'s turn"
        }
    }
    
    private func checkWin(for player: Player) -> Bool {
        let playerPositions = Set(board.enumerated().compactMap { $0.element == player.rawValue ? $0.offset : nil })
        for winSet in winningSets {
            if winSet.isSubset(of: playerPositions) {
                return true
            }
        }
        return false
    }
    
    func resetBoard(nextStartsWith winnerStartsNext: Bool = false) {
        board = Array(repeating: "", count: 9)
        isGameOver = false
        if winnerStartsNext {
            // keep currentPlayer as it is (winner will be currentPlayer if they won).
        } else {
            currentPlayer = .x
        }
        message = "\(currentPlayer.rawValue)'s turn"
    }
    
    func newGame() {
        // reset everything except scores
        resetBoard()
        scoreX = 0
        scoreO = 0
    }
}

struct ContentView: View {
    @StateObject private var vm = GameViewModel()
    
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 3)
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Tic-Tac-Toe")
                .font(.largeTitle)
                .bold()
            
            HStack(spacing: 20) {
                VStack {
                    Text("Player X")
                        .font(.subheadline)
                    Text("\(vm.scoreX)")
                        .font(.title)
                        .bold()
                }
                .frame(maxWidth: .infinity)
                
                VStack {
                    Text("Player O")
                        .font(.subheadline)
                    Text("\(vm.scoreO)")
                        .font(.title)
                        .bold()
                }
                .frame(maxWidth: .infinity)
            }
            .padding(.horizontal)
            
            Text(vm.message)
                .font(.headline)
                .padding(.vertical, 4)
            
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(0..<9) { i in
                    ZStack {
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(lineWidth: 2)
                            .frame(height: 90)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color(white: 0.98))
                            )
                        
                        Text(vm.board[i])
                            .font(.system(size: 48, weight: .bold, design: .rounded))
                    }
                    .onTapGesture {
                        withAnimation {
                            vm.makeMove(at: i)
                        }
                    }
                    .disabled(!vm.board[i].isEmpty || vm.isGameOver)
                    .opacity(vm.board[i].isEmpty ? 1.0 : 1.0)
                }
            }
            .padding()
            
            if vm.isGameOver {
                HStack(spacing: 12) {
                    Button(action: {
                        // restart board; winner starts next if someone won (keeps currentPlayer)
                        let lastWinnerIsX = vm.message.contains("X wins")
                        let lastWinnerIsO = vm.message.contains("O wins")
                        if lastWinnerIsX || lastWinnerIsO {
                            // if there was a winner keep currentPlayer (the winner) to start next
                            vm.resetBoard(nextStartsWith: true)
                        } else {
                            vm.resetBoard()
                        }
                    }) {
                        Text("Play Again")
                            .bold()
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(RoundedRectangle(cornerRadius: 10).stroke())
                    }
                    
                    Button(action: {
                        vm.newGame()
                    }) {
                        Text("New Game")
                            .bold()
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(RoundedRectangle(cornerRadius: 10).stroke())
                    }
                }
                .padding(.horizontal)
            } else {
                HStack(spacing: 12) {
                    Button(action: {
                        // undo not implemented for simplicity — you can add it later
                        vm.resetBoard()
                    }) {
                        Text("Restart")
                            .bold()
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(RoundedRectangle(cornerRadius: 10).stroke())
                    }
                    
                    Button(action: {
                        vm.newGame()
                    }) {
                        Text("Reset Scores")
                            .bold()
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(RoundedRectangle(cornerRadius: 10).stroke())
                    }
                }
                .padding(.horizontal)
            }
            
            Spacer()
            
            Text("Tap a cell to play. \(vm.currentPlayer.rawValue) starts.")
                .font(.footnote)
                .foregroundColor(.secondary)
                .padding(.bottom, 10)
        }
        .padding(.top, 20)
        .onAppear {
            vm.resetBoard()
        }
    }
}
