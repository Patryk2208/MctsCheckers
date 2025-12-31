//
// Created by patryk on 12/31/25.
//

#include <checkers/actions/shmStructure.cuh>

D bool SubStatesPerFieldStructure::ReadNextFromStructure(CheckersState &state) {
    if (size_ == 0) return false;
    state = buffer_[--size_];
    return true;
}

D void SubStatesPerFieldStructure::WriteToStructure(const unsigned &fieldId, const CheckersState &state) {
    const auto activeMask = __activemask();
    const auto writeCount = __popc(activeMask);
    //here we count how many threads are with index smaller that the current, for active 0, 1, 4, 5 and for thread 4
    //we have __popc(0b00110011 & (0b00010000 - 1)) = __popc(0b00110011 & 0b00001111) = __popc(0b00000011) = 2
    const auto writeIndex = size_ + __popc(activeMask & ((1u << fieldId) - 1));
    buffer_[writeIndex] = state;
    if (fieldId == __ffs(activeMask) - 1) {
        size_ += writeCount;
    }
    __syncwarp(activeMask);
}


D void LegalTakeMovesSubStateMap::SwapDataStructures() {
    const auto temp = readStructures_;
    readStructures_ = writeStructures_;
    writeStructures_ = temp;
}


D void ResultLegalActionSpace::AppendToStructure(const unsigned &fieldId, const CheckersState &state) {
    const auto activeMask = __activemask();
    const auto writeCount = __popc(activeMask);
    //here we count how many threads are with index smaller that the current, for active 0, 1, 4, 5 and for thread 4
    //we have __popc(0b00110011 & (0b00010000 - 1)) = __popc(0b00110011 & 0b00001111) = __popc(0b00000011) = 2
    const auto writeIndex = size_ + __popc(activeMask & ((1u << fieldId) - 1));
    buffer_[writeIndex] = state;
    if (fieldId == __ffs(activeMask) - 1) {
        size_ += writeCount;
    }
    __syncwarp(activeMask);
}
