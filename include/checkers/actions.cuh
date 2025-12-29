//
// Created by patryk on 12/28/25.

#ifndef MCTS_CHECKERS_ACTIONS_CUH
#define MCTS_CHECKERS_ACTIONS_CUH
#include <tocpuwb/batchExecutor.cuh>

using Mask = unsigned int;

/**
 * Checks if a state of the board is terminal, also if the state is not terminal, checks if it's a knows winning,
 * drawing or losing state, if not continues.
 * Uses a thread per state, as end conditions are trivial???
 * @param batchSize
 * @param states
 * @param results
 * @param terminal
 */
__global__ void CheckTerminal(int batchSize, BatchSoACheckersState states, float* results, bool* terminal);

//todo optimize those defines
#define MAX_TAKE_MOVE_SUB_STATES_PER_FIELD 144
#define MAX_ACTION_COUNT (144 * 4)

struct SubStatesPerFieldStructure {
    int size_;
    CheckersState buffer_[MAX_TAKE_MOVE_SUB_STATES_PER_FIELD];

    __device__ bool ReadNextFromStructure(CheckersState &state);
    __device__ void WriteToStructure(CheckersState state);
};

struct LegalTakeMovesSubStateMap {
    SubStatesPerFieldStructure readStructures_[FIELD_COUNT];
    SubStatesPerFieldStructure writeStructures_[FIELD_COUNT];

    __device__ void UpdateStructuresAfterRound();
};

struct ResultLegalActionSpace {
    int size_;
    CheckersState buffer_[MAX_ACTION_COUNT];

    __device__ void AppendToStructure(CheckersState state);
};

/**
 * Calculates all legal actions into a structure???
 * Uses a thread per a field on a board, checks all possible take-moves first, if none available,
 * checks all possible moves, if none moves then it's a draw, such situation must be caught by CheckTerminal
 * One thread has its own data structure??? in shared memory, the algorithm runs in rounds with __syncthreads(),
 * in each round a thread(pos) reads all possible states and creates all possible one-moves, writes those to the
 * structure of a destination thread(pos) and ends its round. todo
 * @param states
 * @param batchSize
 * @param batchSize
 */
__global__ void GetLegalActions(BatchSoACheckersState& states, int batchSize); //todo output format for this function

__device__ void GetLegalQueenTakeMoves(
    const unsigned &fieldId,
    LegalTakeMovesSubStateMap& boardSubStateMap,
    SubStatesPerFieldStructure& fieldSubStateReadStructure,
    ResultLegalActionSpace& boardResultActionSpace,
    Players player);

__device__ void GetLegalPawnTakeMoves(
    const unsigned &fieldId,
    LegalTakeMovesSubStateMap& boardSubStateMap,
    SubStatesPerFieldStructure& fieldSubStateReadStructure,
    ResultLegalActionSpace& boardResultActionSpace,
    Players player);

__device__ void GetLegalQueenNormalMoves(
    const unsigned &fieldId,
    LegalTakeMovesSubStateMap& boardSubStateMap,
    SubStatesPerFieldStructure& fieldSubStateReadStructure,
    ResultLegalActionSpace& boardResultActionSpace,
    Players player);

__device__ void GetLegalPawnNormalMoves(
    const unsigned &fieldId,
    LegalTakeMovesSubStateMap& boardSubStateMap,
    SubStatesPerFieldStructure& fieldSubStateReadStructure,
    ResultLegalActionSpace& boardResultActionSpace,
    Players player);

//helper functions

__device__ unsigned GetTopLeftId(unsigned fieldId);
__device__ unsigned GetTopRightId(unsigned fieldId);
__device__ unsigned GetBottomLeftId(unsigned fieldId);
__device__ unsigned GetBottomRightId(unsigned fieldId);

__device__ Mask GetTopLeftMask(unsigned fieldId);
__device__ Mask GetTopRightMask(unsigned fieldId);
__device__ Mask GetBottomLeftMask(unsigned fieldId);
__device__ Mask GetBottomRightMask(unsigned fieldId);

/*
__device__ Mask GetTopLeftTakeMask(unsigned int fieldId);
__device__ Mask GetTopRightTakeMask(unsigned int fieldId);
__device__ Mask GetBottomLeftTakeMask(unsigned int fieldId);
__device__ Mask GetBottomRightTakeMask(unsigned int fieldId);
*/

__device__ bool CheckQueenTakeMoveForMask(
    const Mask &originMask,
    const Mask &takenMask,
    const Mask &destinationMask,
    BoardMap &pawns,
    BoardMap &queens,
    BoardMap &opponentPawns,
    BoardMap &opponentQueens);

__device__ bool CheckPawnTakeMoveForMask(
    const Mask &originMask,
    const Mask &takenMask,
    const Mask &destinationMask,
    BoardMap &pawns,
    BoardMap &queens,
    BoardMap &opponentPawns,
    BoardMap &opponentQueens);

__device__ bool CheckQueenNormalMoveForMask(
    const Mask &originMask,
    const Mask& destinationMask,
    BoardMap &pawns,
    BoardMap &queens,
    BoardMap& opponentPawns,
    BoardMap& opponentQueens);

__device__ bool CheckPawnNormalMoveForMask(
    const Mask &originMask,
    const Mask& destinationMask,
    BoardMap &pawns,
    BoardMap &queens,
    BoardMap& opponentPawns,
    BoardMap& opponentQueens);



__device__ void CompleteQueenMoveFromSubTakeMoveState(CheckersState &state);
__device__ void CompletePawnMoveFromSubTakeMoveState(CheckersState &state);
__device__ void CompleteQueenNormalMove(CheckersState &state);
__device__ void CompletePawnNormalMove(CheckersState &state);

__device__ void AssignSides(
    const CheckersState &state,
    BoardMap &pawns,
    BoardMap &queens,
    BoardMap &opponentPawns,
    BoardMap &opponentQueens,
    const Players& player);

#endif //MCTS_CHECKERS_ACTIONS_CUH