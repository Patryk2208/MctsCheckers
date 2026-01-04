//
// Created by patryk on 12/30/25.
//

#ifndef MCTS_CHECKERS_SHMSTRUCTURE_CUH
#define MCTS_CHECKERS_SHMSTRUCTURE_CUH

#include <cudaUtils/cudaCompatibility.hpp>
#include <checkers/state.hpp>

//todo optimize those defines
#define MAX_TAKE_MOVE_SUB_STATES_PER_FIELD 8
#define MAX_ACTION_COUNT 64

struct SubStatesPerFieldStructure {
    int size_;
    CheckersState buffer_[MAX_TAKE_MOVE_SUB_STATES_PER_FIELD];
};

struct LegalMovesSubStateMap {
    SubStatesPerFieldStructure structures1_[FIELD_COUNT];
    SubStatesPerFieldStructure structures2_[FIELD_COUNT];
    SubStatesPerFieldStructure* readStructures_;
    SubStatesPerFieldStructure* writeStructures_;


    /**
     * One thread reads its buffer pops it
     */
    D bool ReadNextFromStructure(const unsigned &fieldId, CheckersState &state) const;
    /**
     * Has to be warp-safe, as multiple threads in a warp can write to other warp's structure at the same time
     */
    D void WriteToStructure(const unsigned &fieldId, const unsigned &writeFieldId, const CheckersState &state) const;

    D void SwapDataStructures(const unsigned &fieldId);
};

struct ResultLegalActionSpace {
    int size_;
    CheckersState buffer_[MAX_ACTION_COUNT];

    /**
     * Has to be warp-safe, because there is one result space per board(warp)
     */
    D void AppendToStructure(const unsigned &fieldId, const CheckersState &state);
};

constexpr size_t SharedMemorySize = sizeof(LegalMovesSubStateMap) + sizeof(ResultLegalActionSpace);

#endif //MCTS_CHECKERS_SHMSTRUCTURE_CUH