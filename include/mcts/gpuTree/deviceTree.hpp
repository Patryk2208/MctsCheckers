//
// Created by patryk on 12/19/25.

#ifndef MCTS_CHECKERS_DEVICETREE_HPP
#define MCTS_CHECKERS_DEVICETREE_HPP

#include "deviceTree.cuh"

/**
 * A struct representing a tree in a concise buffer on a gpu that supports parallel insertion of nodes
 */
struct DeviceMctsTree {
    unsigned int* nodes_;
    unsigned int nodesSize_;


    unsigned int* nodeBuffer1_;
    unsigned int buffer1Size_;

    unsigned int* nodeBuffer2_;
    unsigned int buffer2Size_;

    unsigned int* shiftBuffer_;
	unsigned int shiftBufferSize_;
};


#endif //MCTS_CHECKERS_DEVICETREE_HPP