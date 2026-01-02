//
// Created by patryk on 12/31/25.
//

#include <checkers/actions/shmStructure.cuh>

D bool LegalMovesSubStateMap::ReadNextFromStructure(const unsigned &fieldId, CheckersState &state) const {
    auto& [size_, buffer_] = readStructures_[fieldId];
    if (size_ == 0) return false;
    state = buffer_[--size_];
    return true;
}

D void LegalMovesSubStateMap::WriteToStructure(const unsigned &fieldId, const unsigned &writeFieldId, const CheckersState &state) const {
    auto& [size_, buffer_] = writeStructures_[writeFieldId];
    //printf("%u, my size is %d, im writing to %u\n", fieldId, size_, writeFieldId);
    const auto activeMask = __activemask();
    const auto sameTargetMask = __match_any_sync(activeMask, writeFieldId);
    //here we count how many threads are with index smaller that the current, for active 0, 1, 4, 5 and for thread 4
    //we have __popc(0b00110011 & (0b00010000 - 1)) = __popc(0b00110011 & 0b00001111) = __popc(0b00000011) = 2
    const auto writeIndex = size_ + __popc(sameTargetMask & ((1u << fieldId) - 1));
    buffer_[writeIndex] = state;
    if (fieldId == __ffs(sameTargetMask) - 1) {
        size_ += __popc(sameTargetMask);
    }
    //auto writtenIndex = writeIndex;
    //printf("%u wrote to %u at %d with mask %u, the state is %u, %u, %u, %u, %u\n", fieldId, writeFieldId, writtenIndex, sameTargetMask, buffer_[writtenIndex].whiteQueens_, buffer_[writtenIndex].whitePawns_, buffer_[writtenIndex].blackQueens_, buffer_[writtenIndex].blackPawns_, buffer_[writtenIndex].metadata_);
    __syncwarp(activeMask);
}


D void LegalMovesSubStateMap::SwapDataStructures(const unsigned &fieldId) {
    const auto activeMask = __activemask();
    if (fieldId == __ffs(activeMask) - 1) {
        const auto temp = readStructures_;
        readStructures_ = writeStructures_;
        writeStructures_ = temp;
    }
    __syncwarp(activeMask);
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
