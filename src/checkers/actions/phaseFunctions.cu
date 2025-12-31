//
// Created by patryk on 12/31/25.
//

#include <checkers/actions/phaseFunctions.cuh>

template<Players player>
__device__ void GetLegalQueenTakeMoves(
    const unsigned &fieldId,
    LegalTakeMovesSubStateMap& boardSubStateMap,
    SubStatesPerFieldStructure& fieldSubStateReadStructure,
    ResultLegalActionSpace& boardResultActionSpace) {

    auto roundCounter = 0;
    while (true) {
        //round start
        auto wasPushedSomewhereElse = false;
        while (true) {
            CheckersState next{};
            if (!fieldSubStateReadStructure.ReadNextFromStructure(next)) {
                break;
            }
            auto activeWarps = __activemask();
            DirectionGetQueenTakeMoves<GetTopLeftDirection, player>(fieldId, next, boardSubStateMap, wasPushedSomewhereElse);
            __syncwarp(activeWarps);
            DirectionGetQueenTakeMoves<GetTopRightDirection, player>(fieldId, next, boardSubStateMap, wasPushedSomewhereElse);
            __syncwarp(activeWarps);
            DirectionGetQueenTakeMoves<GetBottomLeftDirection, player>(fieldId, next, boardSubStateMap, wasPushedSomewhereElse);
            __syncwarp(activeWarps);
            DirectionGetQueenTakeMoves<GetBottomRightDirection, player>(fieldId, next, boardSubStateMap, wasPushedSomewhereElse);
            __syncwarp(activeWarps);
            if (!wasPushedSomewhereElse && roundCounter > 0) {
                CompleteQueenTakeMove<player>(fieldId, next);
                boardResultActionSpace.AppendToStructure(fieldId, next);
            }
        }
        boardSubStateMap.SwapDataStructures();
        if (!__any_sync(0xffffffff, wasPushedSomewhereElse)) break;
        ++roundCounter;
    }
}

template<Players player>
__device__ void GetLegalPawnTakeMoves(
    const unsigned &fieldId,
    LegalTakeMovesSubStateMap& boardSubStateMap,
    SubStatesPerFieldStructure& fieldSubStateReadStructure,
    ResultLegalActionSpace& boardResultActionSpace) {

    auto roundCounter = 0;
    while (true) {
        //round start
        auto wasPushedSomewhereElse = false;
        while (true) {
            CheckersState next{};
            if (!fieldSubStateReadStructure.ReadNextFromStructure(next)) {
                break;
            }
            auto activeWarps = __activemask();
            DirectionGetPawnTakeMoves<GetTopLeftDirection>, player(fieldId, next, boardSubStateMap, wasPushedSomewhereElse);
            __syncwarp(activeWarps);
            DirectionGetPawnTakeMoves<GetTopRightDirection, player>(fieldId, next, boardSubStateMap, wasPushedSomewhereElse);
            __syncwarp(activeWarps);
            DirectionGetPawnTakeMoves<GetBottomLeftDirection, player>(fieldId, next, boardSubStateMap, wasPushedSomewhereElse);
            __syncwarp(activeWarps);
            DirectionGetPawnTakeMoves<GetBottomRightDirection, player>(fieldId, next, boardSubStateMap, wasPushedSomewhereElse);
            __syncwarp(activeWarps);
            if (!wasPushedSomewhereElse && roundCounter > 0) {
                CompletePawnTakeMove<player>(fieldId, next);
                boardResultActionSpace.AppendToStructure(fieldId, next);
            }
        }
        boardSubStateMap.SwapDataStructures();
        if (!__any_sync(0xffffffff, wasPushedSomewhereElse)) break;
        ++roundCounter;
    }
}

template<Players player>
__device__ void GetLegalQueenNormalMoves(
    const unsigned &fieldId,
    LegalTakeMovesSubStateMap& boardSubStateMap,
    SubStatesPerFieldStructure& fieldSubStateReadStructure,
    ResultLegalActionSpace& boardResultActionSpace) {

    CheckersState next{};
    if (fieldSubStateReadStructure.ReadNextFromStructure(next)) {
        auto activeWarps = __activemask();
        DirectionGetQueenNormalMoves<GetTopLeftDirection, player>(fieldId, next, boardSubStateMap);
        __syncwarp(activeWarps);
        DirectionGetQueenNormalMoves<GetTopRightDirection, player>(fieldId, next, boardSubStateMap);
        __syncwarp(activeWarps);
        DirectionGetQueenNormalMoves<GetBottomLeftDirection, player>(fieldId, next, boardSubStateMap);
        __syncwarp(activeWarps);
        DirectionGetQueenNormalMoves<GetBottomRightDirection, player>(fieldId, next, boardSubStateMap);
        __syncwarp(activeWarps);
    }
    boardSubStateMap.SwapDataStructures();
    __syncwarp(0xffffffff);
    while (true) {
        if (!fieldSubStateReadStructure.ReadNextFromStructure(next)) {
            break;
        }
        CompleteQueenNormalMove<player>(fieldId, next);
        boardResultActionSpace.AppendToStructure(fieldId, next);
    }
}

template<Players player>
__device__ void GetLegalPawnNormalMoves(
    const unsigned &fieldId,
    LegalTakeMovesSubStateMap& boardSubStateMap,
    SubStatesPerFieldStructure& fieldSubStateReadStructure,
    ResultLegalActionSpace& boardResultActionSpace) {

    CheckersState next{};
    if (fieldSubStateReadStructure.ReadNextFromStructure(next)) {
        auto activeWarps = __activemask();
        if constexpr (player == WhitePlayer) {
            DirectionGetPawnNormalMoves<GetTopLeftDirection, player>(fieldId, next, boardSubStateMap);
            __syncwarp(activeWarps);
            DirectionGetPawnNormalMoves<GetTopRightDirection, player>(fieldId, next, boardSubStateMap);
            __syncwarp(activeWarps);
        }
        else {
            DirectionGetPawnNormalMoves<GetBottomLeftDirection, player>(fieldId, next, boardSubStateMap);
            __syncwarp(activeWarps);
            DirectionGetPawnNormalMoves<GetBottomRightDirection, player>(fieldId, next, boardSubStateMap);
            __syncwarp(activeWarps);
        }
    }
    __syncwarp(0xffffffff);
    boardSubStateMap.SwapDataStructures();
    while (true) {
        if (!fieldSubStateReadStructure.ReadNextFromStructure(next)) {
            break;
        }
        CompletePawnNormalMove<player>(fieldId, next);
        boardResultActionSpace.AppendToStructure(fieldId, next);
    }
}