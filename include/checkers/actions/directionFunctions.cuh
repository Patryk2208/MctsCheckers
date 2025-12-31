//
// Created by patryk on 12/30/25.
//

#ifndef MCTS_CHECKERS_DIRECTIONFUNCTIONS_CUH
#define MCTS_CHECKERS_DIRECTIONFUNCTIONS_CUH

#include <checkers/actions/helperFunctions.cuh>
#include <checkers/actions/shmStructure.cuh>

struct GetTopLeftDirection {
    __device__ static unsigned GetId(const unsigned &fieldId);
};

struct GetTopRightDirection {
    __device__ static unsigned GetId(const unsigned &fieldId);
};

struct GetBottomLeftDirection {
    __device__ static unsigned GetId(const unsigned &fieldId);
};

struct GetBottomRightDirection {
    __device__ static unsigned GetId(const unsigned &fieldId);
};

template <typename Dir>
constexpr bool IsValidDirection =
    std::is_same_v<Dir, GetTopLeftDirection> ||
    std::is_same_v<Dir, GetTopRightDirection> ||
    std::is_same_v<Dir, GetBottomLeftDirection> ||
    std::is_same_v<Dir, GetBottomRightDirection>;

template<typename Direction, Players player>
__device__ void DirectionGetQueenTakeMoves(
    unsigned fieldId,
    CheckersState& next,
    LegalTakeMovesSubStateMap& boardSubStateMap,
    bool& wasPushed);

template<typename Direction, Players player>
__device__ void DirectionGetPawnTakeMoves(
    unsigned fieldId,
    CheckersState& next,
    LegalTakeMovesSubStateMap& boardSubStateMap,
    bool& wasPushed);

template<typename Direction, Players player>
__device__ void DirectionGetQueenNormalMoves(
    unsigned fieldId,
    CheckersState& next,
    LegalTakeMovesSubStateMap& boardSubStateMap);

template<typename Direction, Players player>
__device__ void DirectionGetPawnNormalMoves(
    unsigned fieldId,
    CheckersState& next,
    LegalTakeMovesSubStateMap& boardSubStateMap);



#endif //MCTS_CHECKERS_DIRECTIONFUNCTIONS_CUH