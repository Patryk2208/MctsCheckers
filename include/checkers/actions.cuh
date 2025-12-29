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

/**
 * Calculates all legal actions into a structure???
 * Uses a thread per a field on a board, checks all possible take-moves first, if none available,
 * checks all possible moves, if none moves then it's a draw, such situation must be caught by CheckTerminal
 * One thread has its own data structure??? in shared memory, the algorithm runs in rounds with __syncthreads(),
 * in each round a thread(pos) reads all possible states and creates all possible one-moves, wrties those to the
 * structure of a destination thread(pos) and ends its round. todo
 * @param states
 */
__global__ void GetLegalActions(BatchSoACheckersState states); //todo output format for this function

__device__ Mask GetTopLeftMask(unsigned int fieldId);
__device__ Mask GetTopRightMask(unsigned int fieldId);
__device__ Mask GetBottomLeftMask(unsigned int fieldId);
__device__ Mask GetBottomRightMask(unsigned int fieldId);

#endif //MCTS_CHECKERS_ACTIONS_CUH