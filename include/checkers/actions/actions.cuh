//
// Created by patryk on 12/28/25.

#ifndef MCTS_CHECKERS_ACTIONS_CUH
#define MCTS_CHECKERS_ACTIONS_CUH

#include <checkers/actions/phaseFunctions.cuh>
#include <checkers/actions/directionFunctions.cuh>
#include <checkers/actions/helperFunctions.cuh>
#include <checkers/actions/shmStructure.cuh>

/**
 * Checks if a state of the board is terminal, also if the state is not terminal, checks if it's a knows winning,
 * drawing or losing state, if not continues.
 * Uses a thread per state, as end conditions are trivial???
 * @param batchSize
 * @param states
 * @param results
 * @param terminal
 */
GLOBAL void CheckTerminal(int batchSize, BatchSoACheckersState *states, float* results, bool* terminal);

/**
 * Calculates all legal actions into a result array
 * Uses a thread per a field on a board, checks all possible take-moves first, if none available,
 * checks all possible moves, if none moves then it's a draw, such situation must be caught by CheckTerminal
 * One thread has its own data structure in shared memory, the algorithm runs in rounds,
 * in each round a thread(pos) reads all possible states and creates all possible one-moves, writes those to the
 * structure of a destination thread(pos) and ends its round.
 * @param batchSize
 * @param batchSize
 * @param states
 * @param actions
 */
GLOBAL void GetLegalActions(size_t batchSize, const BatchSoACheckersState *states, BatchLegalActions *actions);


template<Players player>
D void InitializeDataStructure(
    const unsigned &fieldId,
    const CheckersState& state,
    LegalTakeMovesSubStateMap& boardSubStateMap) {
    const auto fieldMask = 1 << fieldId;
    if constexpr (player == WhitePlayer) {
        if (state.whitePawns_ & fieldMask || state.whiteQueens_ & fieldMask) {
            boardSubStateMap.writeStructures_[fieldId].WriteToStructure(fieldId, state);
        }
    }
    else {
        if (state.blackPawns_ & fieldMask || state.blackQueens_ & fieldMask) {
            boardSubStateMap.writeStructures_[fieldId].WriteToStructure(fieldId, state);
        }
    }
    boardSubStateMap.SwapDataStructures();
}

template<Players player>
D void DiscoverActions(
    const unsigned &fieldId,
    const CheckersState& originalState,
    LegalTakeMovesSubStateMap& boardSubStateMap,
    SubStatesPerFieldStructure& fieldSubStateReadStructure,
    ResultLegalActionSpace& boardResultActionSpace) {

    //take-moves section
    InitializeDataStructure<player>(fieldId, originalState, boardSubStateMap);
    GetLegalQueenTakeMoves<player>(fieldId, boardSubStateMap, fieldSubStateReadStructure, boardResultActionSpace);

    InitializeDataStructure<player>(fieldId, originalState, boardSubStateMap);
    GetLegalPawnTakeMoves<player>(fieldId, boardSubStateMap, fieldSubStateReadStructure, boardResultActionSpace);
    if (boardResultActionSpace.size_ == 0) {
        //normal moves section
        InitializeDataStructure<player>(fieldId, originalState, boardSubStateMap);
        GetLegalQueenNormalMoves<player>(fieldId, boardSubStateMap, fieldSubStateReadStructure, boardResultActionSpace);

        InitializeDataStructure<player>(fieldId, originalState, boardSubStateMap);
        GetLegalPawnNormalMoves<player>(fieldId, boardSubStateMap, fieldSubStateReadStructure, boardResultActionSpace);
    }
}

#endif //MCTS_CHECKERS_ACTIONS_CUH