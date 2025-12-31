//
// Created by patryk on 12/30/25.
//

#ifndef MCTS_CHECKERS_SHMSTRUCTURE_CUH
#define MCTS_CHECKERS_SHMSTRUCTURE_CUH

#include <checkers/state.hpp>

//todo optimize those defines
#define MAX_TAKE_MOVE_SUB_STATES_PER_FIELD 128
#define MAX_ACTION_COUNT 256

struct SubStatesPerFieldStructure {
    int size_;
    CheckersState buffer_[MAX_TAKE_MOVE_SUB_STATES_PER_FIELD];

    /**
     * One thread reads its buffer pops it
     */
    __device__ bool ReadNextFromStructure(CheckersState &state);
    /**
     * Has to be warp-safe, as multiple threads in a warp can write to other warp's structure at the same time
     */
    __device__ void WriteToStructure(const unsigned &fieldId, const CheckersState &state);
};

struct LegalTakeMovesSubStateMap {
private:
    SubStatesPerFieldStructure structures1_[FIELD_COUNT];
    SubStatesPerFieldStructure structures2_[FIELD_COUNT];
public:
    SubStatesPerFieldStructure* readStructures_ = structures1_;
    SubStatesPerFieldStructure* writeStructures_ = structures2_;

    __device__ void SwapDataStructures();
};

struct ResultLegalActionSpace {
    int size_;
    CheckersState buffer_[MAX_ACTION_COUNT];

    /**
     * Has to be warp-safe, because there is one result space per board(warp)
     */
    __device__ void AppendToStructure(const unsigned &fieldId, const CheckersState &state);
};

constexpr size_t SharedMemorySize = sizeof(LegalTakeMovesSubStateMap) + sizeof(ResultLegalActionSpace);

#endif //MCTS_CHECKERS_SHMSTRUCTURE_CUH