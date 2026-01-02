//
// Created by patryk on 12/28/25.

#ifndef MCTS_CHECKERS_ACTIONS_CUH
#define MCTS_CHECKERS_ACTIONS_CUH

#include <checkers/actions/phaseFunctions.cuh>
#include <checkers/actions/directionFunctions.cuh>
#include <checkers/actions/helperFunctions.cuh>
#include <checkers/actions/shmStructure.cuh>

#include "checkers/deviceResources/batchActionSpace.cuh"
#include "checkers/deviceResources/batchCheckerState.cuh"
#include "checkers/deviceResources/batchSimulationResults.cuh"

/**
 * Checks if a state of the board is terminal, also if the state is not terminal, checks if it's a knows winning,
 * drawing or losing state, if not continues.
 * Uses a thread per state, as end conditions are trivial???
 * @param batchSize
 * @param states
 * @param results
 * @param terminal
 */
GLOBAL void CheckTerminal(int batchSize, BatchSoACheckersStateDevice *states, BatchSimulationResultsDevice* results, bool* terminal);

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
GLOBAL void GetLegalActions(size_t batchSize, const BatchSoACheckersStateDevice *states, BatchLegalActionsDevice *actions);


template<Players player>
D void InitializeDataStructureForQueens(
    const unsigned &fieldId,
    const CheckersState& state,
    LegalMovesSubStateMap *const boardSubStateMap) {
    const auto fieldMask = 1 << fieldId;
    if constexpr (player == WhitePlayer) {
        if (state.whiteQueens_ & fieldMask) {
            boardSubStateMap->WriteToStructure(fieldId, fieldId, state);
        }
    }
    else {
        if (state.blackQueens_ & fieldMask) {
            boardSubStateMap->WriteToStructure(fieldId, fieldId, state);
        }
    }
    Template_syncwarp();
    boardSubStateMap->SwapDataStructures(fieldId);
}

template<Players player>
D void InitializeDataStructureForPawns(
    const unsigned &fieldId,
    const CheckersState& state,
    LegalMovesSubStateMap *const boardSubStateMap) {
    const auto fieldMask = 1 << fieldId;
    if constexpr (player == WhitePlayer) {
        if (state.whitePawns_ & fieldMask) {
            boardSubStateMap->WriteToStructure(fieldId, fieldId, state);
        }
    }
    else {
        if (state.blackPawns_ & fieldMask) {
            boardSubStateMap->WriteToStructure(fieldId, fieldId, state);
        }
    }
    Template_syncwarp();
    boardSubStateMap->SwapDataStructures(fieldId);
}

template<Players player>
D void DiscoverActions(
    const unsigned &fieldId,
    const CheckersState& originalState,
    LegalMovesSubStateMap *const boardSubStateMap,
    ResultLegalActionSpace *const boardResultActionSpace) {

    //take-moves section
    InitializeDataStructureForQueens<player>(fieldId, originalState, boardSubStateMap);
    Template_syncwarp();
    GetLegalQueenTakeMoves<player>(fieldId, boardSubStateMap, boardResultActionSpace);
    Template_syncwarp();

    InitializeDataStructureForPawns<player>(fieldId, originalState, boardSubStateMap);
    Template_syncwarp();
    GetLegalPawnTakeMoves<player>(fieldId, boardSubStateMap, boardResultActionSpace);
    Template_syncwarp();
    if (boardResultActionSpace->size_ == 0) {
        //normal moves section
        InitializeDataStructureForQueens<player>(fieldId, originalState, boardSubStateMap);
        Template_syncwarp();
        GetLegalQueenNormalMoves<player>(fieldId, boardSubStateMap, boardResultActionSpace);
        Template_syncwarp();

        InitializeDataStructureForPawns<player>(fieldId, originalState, boardSubStateMap);
        Template_syncwarp();
        GetLegalPawnNormalMoves<player>(fieldId, boardSubStateMap, boardResultActionSpace);
        Template_syncwarp();
    }
}

#endif //MCTS_CHECKERS_ACTIONS_CUH