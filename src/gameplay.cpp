//
// Created by patryk on 1/23/26.
//
#include <cstdint>
#include <gameplay.hpp>


// Helper functions based on your specifications
bool isWhiteTurn(const CheckersState& s) {
    return (s.metadata_ & 128) == 0;  // Bit 7: 0=white, 1=black
}

// Convert row,col (0-7,0-7) to bit position (0-31, MSB=top-right black square)
int boardPosToBit(int row, int col) {
    // Only dark squares are playable (row+col is odd)
    // MSB (bit 31) = top-right black square (row 0, col 7?)
    // Actually: top-right black square is row 0, col 7? Let me clarify...
    // Standard checkers: dark squares are where (row+col) is odd
    // Row 0 is top, Row 7 is bottom

    // Since MSB is top-right black square, and we have 32 playable squares
    // Let's assume: bit 31 = (0,7) if black square, else (0,6)
    // Actually: top-right corner (0,7) is white square in checkers!

    // Need clarification: Which exact square is MSB (bit 31)?
    // Let's work with algebraic coordinates instead
    return -1; // Placeholder
}

// Convert algebraic (e.g., "d2") to bit position
int algebraicToBit(const std::string& alg) {
    if (alg.length() < 2) return -1;
    char colChar = std::tolower(alg[0]);
    char rowChar = alg[1];

    int col = colChar - 'a';  // a=0, b=1, ..., h=7
    int row = rowChar - '0';  // '1'->row7, '2'->row6, ..., '8'->row0

    // Check if it's a dark square
    if ((row + col) % 2 == 0) {
        return -1;  // Not a playable square
    }

    // Map to bit position (MSB=top-right black square)
    // Since MSB is "top-right black square", let's assume:
    // For black squares (playable), numbering goes right-to-left, top-to-bottom?
    // Let's use a lookup table instead
    static const int lookup[8][8] = {
        // a  b  c  d  e  f  g  h
        {-1, 31,-1, 30,-1, 29,-1, 28}, // row 0 (8)
        {27,-1, 26,-1, 25,-1, 24,-1}, // row 1 (7)
        {-1, 23,-1, 22,-1, 21,-1, 20}, // row 2 (6)
        {19,-1, 18,-1, 17,-1, 16,-1}, // row 3 (5)
        {-1, 15,-1, 14,-1, 13,-1, 12}, // row 4 (4)
        {11,-1, 10,-1,  9,-1,  8,-1}, // row 5 (3)
        {-1,  7,-1,  6,-1,  5,-1,  4}, // row 6 (2)
        { 3,-1,  2,-1,  1,-1,  0,-1}  // row 7 (1)
    };

    return lookup[row][col];
}

int algebraicToBit64(const std::string &alg) {
    if (alg.length() < 2) return -1;
    char colChar = std::tolower(alg[0]);
    char rowChar = alg[1];

    int col = colChar - 'a';  // a=0, b=1, ..., h=7
    int row = rowChar - '0';  // '1'->row7, '2'->row6, ..., '8'->row0
    return (row - 1) * 8 + col;
}

// Convert bit position to algebraic
std::string bitToAlgebraic(int bit) {
    if (bit < 0 || bit > 31) return "??";

    // Reverse lookup
    static const std::string positions[32] = {
        "a1", "c1", "e1", "g1",
        "b2", "d2", "f2", "h2",
        "a3", "c3", "e3", "g3",
        "b4", "d4", "f4", "h4",
        "a5", "c5", "e5", "g5",
        "b6", "d6", "f6", "h6",
        "a7", "c7", "e7", "g7",
        "b8", "d8", "f8", "h8"
    };

    return positions[bit];
}

// Get piece character at a bit position
char getPieceAt(const CheckersState& state, int bit) {
    if (bit < 0 || bit > 31) return '?';

    unsigned mask = 1u << bit;

    if (state.whitePawns_ & mask) return 'w';  // white pawn
    if (state.blackPawns_ & mask) return 'b';  // black pawn
    if (state.whiteQueens_ & mask) return 'W'; // white queen
    if (state.blackQueens_ & mask) return 'B'; // black queen

    return '.';  // empty
}

// Display the board state
void displayState(const CheckersState& state) {
    std::cout << "\n  +-----------------+\n";
    std::cout << "  | A B C D E F G H |\n";
    std::cout << "  +-------------------+";

    for (int row = 7; row >= 0; row--) {
        std::cout << "\n" << row+1 << " | ";

        for (int col = 0; col < 8; col++) {
            if ((row % 2 == 0 && col % 2 == 1) || (row % 2 == 1 && col % 2 == 0)) std::cout << "  ";
            else {
                auto bit = row * 4 + (row % 2 == 0 ? col / 2 : (col-1) / 2);
                char piece = getPieceAt(state, bit);
                // Convert to display symbols
                switch (piece) {
                    case 'w': std::cout << "● "; break;
                    case 'b': std::cout << "○ "; break;
                    case 'W': std::cout << "◉ "; break;
                    case 'B': std::cout << "◎ "; break;
                    default:  std::cout << "· "; break;
                }
            }
        }
        std::cout << "| " << row + 1;
    }

    std::cout << "\n  +-------------------+";
    std::cout << "\n  | A B C D E F G H |\n";
    std::cout << "  +-----------------+\n";

    // Show game info
    std::cout << "\nTurn: " << (isWhiteTurn(state) ? "White ●" : "Black ○");

    // Count pieces
    int whiteCount = __builtin_popcount(state.whitePawns_ | state.whiteQueens_);
    int blackCount = __builtin_popcount(state.blackPawns_ | state.blackQueens_);
    std::cout << "  Pieces: ●" << whiteCount << " vs ○" << blackCount << "\n";
}

// Parse move string (e.g., "d2-e3", "d2:f4", "d2:f4:d6")
std::vector<int> parseMove(const std::string& moveStr) {
    std::vector<int> squares;
    std::string current;

    for (char c : moveStr) {
        if (c == '-' || c == ':' || c == ' ') {
            if (!current.empty()) {
                squares.push_back(algebraicToBit64(current));
                current.clear();
            }
        } else {
            current += c;
        }
    }

    if (!current.empty()) {
        squares.push_back(algebraicToBit64(current));
    }

    return squares;
}

// Get move input from user
std::vector<int> getMoveInput() {
    while (true) {
        std::cout << "\nEnter move (e.g., d2-e3 or d2:f4 or d2:f4:d6): ";
        std::string input;
        std::getline(std::cin, input);

        // Check for commands
        if (input == "quit" || input == "exit") {
            return {};
        }
        if (input == "help") {
            std::cout << "Format: start-end (move) or start:capture:land (jump)\n";
            std::cout << "Examples: d2-e3, e3-d4, d2:f4, d2:f4:d6\n";
            continue;
        }

        auto squares = parseMove(input);
        if (squares.empty() || squares.size() < 2) {
            std::cout << "Invalid format. Use: start-end or start:capture:land\n";
            continue;
        }

        return squares;
    }
}

// Convert 32-bit representation to 64-bit
CheckersState64 convertTo64(const CheckersState& state32) {
    CheckersState64 state64;
    state64.whiteTurn = (state32.metadata_ & 128) == 0;

    state64.whitePawns = 0;
    state64.whiteQueens = 0;
    state64.blackPawns = 0;
    state64.blackQueens = 0;

    // Expand 32 bits to 64 bits (only dark squares)
    for (int bit = 0; bit < 32; bit++) {
        if (state32.whitePawns_ & (1u << bit)) {
            int square64 = bit32To64(bit);
            state64.whitePawns |= (1ULL << square64);
        }
        if (state32.whiteQueens_ & (1u << bit)) {
            int square64 = bit32To64(bit);
            state64.whiteQueens |= (1ULL << square64);
        }
        if (state32.blackPawns_ & (1u << bit)) {
            int square64 = bit32To64(bit);
            state64.blackPawns |= (1ULL << square64);
        }
        if (state32.blackQueens_ & (1u << bit)) {
            int square64 = bit32To64(bit);
            state64.blackQueens |= (1ULL << square64);
        }
    }

    return state64;
}

// Convert 64-bit back to 32-bit
CheckersState convertTo32(const CheckersState64& state64) {
    CheckersState state32;
    state32.metadata_ = state64.whiteTurn ? 0 : 128;

    state32.whitePawns_ = 0;
    state32.whiteQueens_ = 0;
    state32.blackPawns_ = 0;
    state32.blackQueens_ = 0;

    // Convert 64-bit dark squares to 32-bit packed
    for (int square64 = 0; square64 < 64; square64++) {
        if ((square64 / 8 + square64 % 8) % 2 == 0) {  // Dark square
            int bit = square64ToBit32(square64);

            if (state64.whitePawns & (1ULL << square64)) {
                state32.whitePawns_ |= (1u << bit);
            }
            if (state64.whiteQueens & (1ULL << square64)) {
                state32.whiteQueens_ |= (1u << bit);
            }
            if (state64.blackPawns & (1ULL << square64)) {
                state32.blackPawns_ |= (1u << bit);
            }
            if (state64.blackQueens & (1ULL << square64)) {
                state32.blackQueens_ |= (1u << bit);
            }
        }
    }

    return state32;
}

// Convert between representations
int bit32To64(int bit32) {
    // bit32: 0-31, bit64: 0-63 (only dark squares)
    int row = bit32 / 4;  // Row 0-7
    int colInRow = bit32 % 4;

    // Even rows: a,c,e,g (cols 0,2,4,6)
    // Odd rows: b,d,f,h (cols 1,3,5,7)
    int col = (row % 2 == 0) ? colInRow * 2 : colInRow * 2 + 1;

    return row * 8 + col;
}

int square64ToBit32(int square64) {
    int row = square64 / 8;
    int col = square64 % 8;

    int colInRow = (row % 2 == 0) ? col / 2 : (col - 1) / 2;
    int bit32 = row * 4 + colInRow;

    return bit32;
}

// Get piece at 64-bit square
char getPieceAt64(const CheckersState64& state, int square64) {
    if (state.whitePawns & (1ULL << square64)) return 'w';
    if (state.whiteQueens & (1ULL << square64)) return 'W';
    if (state.blackPawns & (1ULL << square64)) return 'b';
    if (state.blackQueens & (1ULL << square64)) return 'B';
    return '.';
}

// Check if square is dark (playable)
bool isDarkSquare(int square64) {
    int row = square64 / 8;
    int col = square64 % 8;
    return (row + col) % 2 == 1;
}

// Get direction between squares
int getDirection(int from, int to) {
    int rowFrom = from / 8, colFrom = from % 8;
    int rowTo = to / 8, colTo = to % 8;

    if (rowTo > rowFrom && colTo > colFrom) return 9;   // SE
    if (rowTo > rowFrom && colTo < colFrom) return 7;   // SW
    if (rowTo < rowFrom && colTo > colFrom) return -7;  // NE
    if (rowTo < rowFrom && colTo < colFrom) return -9;  // NW

    return 0; // Not diagonal
}

// Check if path is clear for queen
bool isPathClear(const CheckersState64& state, int from, int to, int direction) {
    int current = from + direction;

    while (current != to) {
        // Check if any piece occupies this square
        Bitboard occupied = state.whitePawns | state.whiteQueens |
                           state.blackPawns | state.blackQueens;
        if (occupied & (1ULL << current)) {
            return false;
        }
        current += direction;
    }
    return true;
}

// Simple, clean move validation and application
CheckersState applyMove(const CheckersState& state32, const std::vector<int>& squares) {
    if (squares.size() < 2) {
        throw std::invalid_argument("Need at least 2 squares");
    }

    int from = squares[0];
    int to = squares.back();

    auto state = convertTo64(state32);

    // Basic validation
    if (from < 0 || from > 63 || to < 0 || to > 63) {
        throw std::invalid_argument("Invalid square");
    }

    if ((state32.metadata_ & 15) == 15) {
        throw std::invalid_argument("Draw by queen moves");
    }

    // Get piece type
    char piece = getPieceAt64(state, from);
    if (piece == '.') {
        throw std::invalid_argument("No piece at start square");
    }

    bool isWhite = (piece == 'w' || piece == 'W');
    bool isQueen = (piece == 'W' || piece == 'B');

    // Check turn
    if (isWhite != state.whiteTurn) {
        throw std::invalid_argument("Wrong player turn");
    }

    // Check destination is empty
    if (getPieceAt64(state, to) != '.') {
        throw std::invalid_argument("Destination occupied");
    }

    // Apply move
    CheckersState64 newState = state;

    // Remove piece from start
    Bitboard fromMask = 1ULL << from;
    if (isWhite) {
        if (isQueen) {
            newState.whiteQueens &= ~fromMask;
        } else {
            newState.whitePawns &= ~fromMask;
        }
    } else {
        if (isQueen) {
            newState.blackQueens &= ~fromMask;
        } else {
            newState.blackPawns &= ~fromMask;
        }
    }

    // Handle captures for jumps
    for (size_t i = 0; i < squares.size() - 1; i++) {
        int stepFrom = squares[i];
        int stepTo = squares[i + 1];

        if (abs(abs(stepFrom - stepTo) - 8) <= 1) break;

        auto increment = 0;
        if (stepTo < stepFrom) {
            if (stepTo < stepFrom - 16) increment = -9;
            if (stepTo > stepFrom - 16) increment = -7;
        }
        else {
            if (stepTo > stepFrom + 16) increment = 9;
            if (stepTo < stepFrom + 16) increment = 7;
        }
        if (stepTo == stepFrom + increment) break;
        auto takeCounter = 0;
        for (auto j = stepFrom + increment; j < stepTo; j += increment) {
            if ((j == stepFrom + increment || j == stepFrom + 2 * increment) && (j < 0 || j > 63)) throw;
            auto mask = (1ULL << j);
            if (isWhite) {
                if (newState.blackPawns & mask || newState.blackQueens & mask) {
                    newState.blackPawns &= ~mask;
                    newState.blackQueens &= ~mask;
                    takeCounter++;
                }
                if (newState.whitePawns & mask || newState.whiteQueens & mask) {
                    throw;
                }
            } else {
                if (newState.whitePawns & mask || newState.whiteQueens & mask) {
                    newState.whitePawns &= ~mask;
                    newState.whiteQueens &= ~mask;
                    takeCounter++;
                }
                if (newState.blackPawns & mask || newState.blackQueens & mask) {
                    throw;
                }
            }
            if (takeCounter > 1) throw;
        }
    }

    // Place piece at destination
    Bitboard toMask = 1ULL << to;
    if (isWhite) {
        if (isQueen) {
            newState.whiteQueens |= toMask;
        } else {
            newState.whitePawns |= toMask;
        }
    } else {
        if (isQueen) {
            newState.blackQueens |= toMask;
        } else {
            newState.blackPawns |= toMask;
        }
    }

    // Check promotion
    if (!isQueen) {
        int row = to / 8;
        if ((isWhite && row == 7) || (!isWhite && row == 0)) {
            // Promote to queen
            if (isWhite) {
                newState.whitePawns &= ~toMask;
                newState.whiteQueens |= toMask;
            } else {
                newState.blackPawns &= ~toMask;
                newState.blackQueens |= toMask;
            }
        }
    }

    auto outputState = convertTo32(newState);
    outputState.metadata_ ^= 128;
    if (isQueen) {
        outputState.metadata_++;
    }
    return outputState;
}