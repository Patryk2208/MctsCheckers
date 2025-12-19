#ifndef MCTS_CHECKERS_KERNELS_CUH
#define MCTS_CHECKERS_KERNELS_CUH

#include "cuda_runtime.h"

struct DeviceMctsTree;

/**
 * Inserts the nodes into the tree's free buffer by shifting all its elements by appropriate amount using a prefix sum
 * over node positions in a shift array, created by inserting "1" on positions of new nodes
 * @param tree
 * @param k amount of nodes to add
 * @param nodes input/output buffer of new node numbers
 * @param nodesPositions input positions at which the new nodes should be inserted
 */
__global__ void AddNodes(DeviceMctsTree* tree, unsigned int k, unsigned int* nodes, unsigned int* nodesPositions);

__global__ void SetupNewNodes(DeviceMctsTree* tree, unsigned int k, unsigned int* nodesPositions);


#endif //MCTS_CHECKERS_KERNELS_CUH