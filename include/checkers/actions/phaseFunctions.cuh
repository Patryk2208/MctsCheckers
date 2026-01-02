//
// Created by patryk on 12/30/25.
//

#ifndef MCTS_CHECKERS_PHASEFUNCTIONS_CUH
#define MCTS_CHECKERS_PHASEFUNCTIONS_CUH

#include <checkers/actions/directionFunctions.cuh>
#include <checkers/actions/helperFunctions.cuh>
#include <checkers/actions/shmStructure.cuh>

#include "cudaUtils/intrinsicsWrappers.cuh"

template<Players player>
D void GetLegalQueenTakeMoves(
    const unsigned &fieldId,
    LegalMovesSubStateMap *const boardSubStateMap,
    ResultLegalActionSpace *const boardResultActionSpace) {

    auto roundCounter = 0;
    while (true) {
        //round start
        auto wasPushedSomewhereElse = false;
        while (true) {
            CheckersState next{};
            if (!boardSubStateMap->ReadNextFromStructure(fieldId, next)) {
                break;
            }
            const auto activeWarps = Template_activemask();
            DirectionGetQueenTakeMoves<GetTopLeftDirection, player>(fieldId, next, boardSubStateMap, wasPushedSomewhereElse);
            Template_syncwarp(activeWarps);
            DirectionGetQueenTakeMoves<GetTopRightDirection, player>(fieldId, next, boardSubStateMap, wasPushedSomewhereElse);
            Template_syncwarp(activeWarps);
            DirectionGetQueenTakeMoves<GetBottomLeftDirection, player>(fieldId, next, boardSubStateMap, wasPushedSomewhereElse);
            Template_syncwarp(activeWarps);
            DirectionGetQueenTakeMoves<GetBottomRightDirection, player>(fieldId, next, boardSubStateMap, wasPushedSomewhereElse);
            Template_syncwarp(activeWarps);
            if (!wasPushedSomewhereElse && roundCounter > 0) {
                CompleteQueenTakeMove<player>(fieldId, next);
                boardResultActionSpace->AppendToStructure(fieldId, next);
            }
        }
        Template_syncwarp();
        boardSubStateMap->SwapDataStructures(fieldId);
        if (!Template_any_sync(0xffffffff, wasPushedSomewhereElse)) break;
        ++roundCounter;
    }
}

template<Players player>
D void GetLegalPawnTakeMoves(
    const unsigned &fieldId,
    LegalMovesSubStateMap *const boardSubStateMap,
    ResultLegalActionSpace *const boardResultActionSpace) {

    auto roundCounter = 0;
    while (true) {
        //round start
        auto wasPushedSomewhereElse = false;
        while (true) {
            CheckersState next{};
            if (!boardSubStateMap->ReadNextFromStructure(fieldId, next)) {
                break;
            }
            const auto activeWarps = Template_activemask();
            DirectionGetPawnTakeMoves<GetTopLeftDirection, player>(fieldId, next, boardSubStateMap, wasPushedSomewhereElse);
            Template_syncwarp(activeWarps);
            DirectionGetPawnTakeMoves<GetTopRightDirection, player>(fieldId, next, boardSubStateMap, wasPushedSomewhereElse);
            Template_syncwarp(activeWarps);
            DirectionGetPawnTakeMoves<GetBottomLeftDirection, player>(fieldId, next, boardSubStateMap, wasPushedSomewhereElse);
            Template_syncwarp(activeWarps);
            DirectionGetPawnTakeMoves<GetBottomRightDirection, player>(fieldId, next, boardSubStateMap, wasPushedSomewhereElse);
            Template_syncwarp(activeWarps);
            if (!wasPushedSomewhereElse && roundCounter > 0) {
                CompletePawnTakeMove<player>(fieldId, next);
                boardResultActionSpace->AppendToStructure(fieldId, next);
            }
        }
        Template_syncwarp();
        boardSubStateMap->SwapDataStructures(fieldId);
        if (!Template_any_sync(0xffffffff, wasPushedSomewhereElse)) break;
        ++roundCounter;
    }
}

template<Players player>
D void GetLegalQueenNormalMoves(
    const unsigned &fieldId,
    LegalMovesSubStateMap *const boardSubStateMap,
    ResultLegalActionSpace *const boardResultActionSpace) {

    CheckersState next{};
    if (boardSubStateMap->ReadNextFromStructure(fieldId, next)) {
        const auto activeWarps = Template_activemask();
        DirectionGetQueenNormalMoves<GetTopLeftDirection, player>(fieldId, next, boardSubStateMap);
        Template_syncwarp(activeWarps);
        DirectionGetQueenNormalMoves<GetTopRightDirection, player>(fieldId, next, boardSubStateMap);
        Template_syncwarp(activeWarps);
        DirectionGetQueenNormalMoves<GetBottomLeftDirection, player>(fieldId, next, boardSubStateMap);
        Template_syncwarp(activeWarps);
        DirectionGetQueenNormalMoves<GetBottomRightDirection, player>(fieldId, next, boardSubStateMap);
        Template_syncwarp(activeWarps);
    }
    Template_syncwarp();
    boardSubStateMap->SwapDataStructures(fieldId);
    while (true) {
        if (!boardSubStateMap->ReadNextFromStructure(fieldId, next)) {
            break;
        }
        CompleteQueenNormalMove<player>(fieldId, next);
        boardResultActionSpace->AppendToStructure(fieldId, next);
    }
}

template<Players player>
D void GetLegalPawnNormalMoves(
    const unsigned &fieldId,
    LegalMovesSubStateMap *const boardSubStateMap,
    ResultLegalActionSpace *const boardResultActionSpace) {

    CheckersState next{};
    if (boardSubStateMap->ReadNextFromStructure(fieldId, next)) {
        const auto activeWarps = Template_activemask();
        if constexpr (player == WhitePlayer) {
            DirectionGetPawnNormalMoves<GetTopLeftDirection, player>(fieldId, next, boardSubStateMap);
            Template_syncwarp(activeWarps);
            DirectionGetPawnNormalMoves<GetTopRightDirection, player>(fieldId, next, boardSubStateMap);
            Template_syncwarp(activeWarps);
        }
        else {
            DirectionGetPawnNormalMoves<GetBottomLeftDirection, player>(fieldId, next, boardSubStateMap);
            Template_syncwarp(activeWarps);
            DirectionGetPawnNormalMoves<GetBottomRightDirection, player>(fieldId, next, boardSubStateMap);
            Template_syncwarp(activeWarps);
        }
    }
    Template_syncwarp();
    boardSubStateMap->SwapDataStructures(fieldId);

    while (true) {
        if (!boardSubStateMap->ReadNextFromStructure(fieldId, next)) {
            break;
        }
        CompletePawnNormalMove<player>(fieldId, next);
        boardResultActionSpace->AppendToStructure(fieldId, next);
    }
}

#endif //MCTS_CHECKERS_PHASEFUNCTIONS_CUH