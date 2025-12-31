//
// Created by patryk on 12/30/25.
//

#ifndef MCTS_CHECKERS_PHASEFUNCTIONS_CUH
#define MCTS_CHECKERS_PHASEFUNCTIONS_CUH

#include <checkers/actions/directionFunctions.cuh>
#include <checkers/actions/helperFunctions.cuh>
#include <checkers/actions/shmStructure.cuh>

template<Players player>
__device__ void GetLegalQueenTakeMoves(
    const unsigned &fieldId,
    LegalTakeMovesSubStateMap& boardSubStateMap,
    SubStatesPerFieldStructure& fieldSubStateReadStructure,
    ResultLegalActionSpace& boardResultActionSpace);

template<Players player>
__device__ void GetLegalPawnTakeMoves(
    const unsigned &fieldId,
    LegalTakeMovesSubStateMap& boardSubStateMap,
    SubStatesPerFieldStructure& fieldSubStateReadStructure,
    ResultLegalActionSpace& boardResultActionSpace);

template<Players player>
__device__ void GetLegalQueenNormalMoves(
    const unsigned &fieldId,
    LegalTakeMovesSubStateMap& boardSubStateMap,
    SubStatesPerFieldStructure& fieldSubStateReadStructure,
    ResultLegalActionSpace& boardResultActionSpace);

template<Players player>
__device__ void GetLegalPawnNormalMoves(
    const unsigned &fieldId,
    LegalTakeMovesSubStateMap& boardSubStateMap,
    SubStatesPerFieldStructure& fieldSubStateReadStructure,
    ResultLegalActionSpace& boardResultActionSpace);


#endif //MCTS_CHECKERS_PHASEFUNCTIONS_CUH