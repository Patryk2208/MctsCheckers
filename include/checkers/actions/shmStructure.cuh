//
// Created by patryk on 12/30/25.
//

#ifndef MCTS_CHECKERS_SHMSTRUCTURE_CUH
#define MCTS_CHECKERS_SHMSTRUCTURE_CUH

#include <checkers/state.hpp>

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

    __device__ void SwapDataStructures();
};

struct ResultLegalActionSpace {
    int size_;
    CheckersState buffer_[MAX_ACTION_COUNT];

    __device__ void AppendToStructure(CheckersState state);
};


#endif //MCTS_CHECKERS_SHMSTRUCTURE_CUH