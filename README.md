# Checkers engine
Implementation of Monte-Carlo Tree Search algorithm, it contains 4 phases:
1. Selection - where we select the best possible node, with a UCB metric, to balance exploitation and exploration
2. Expansion - where we add new nodes to a node with no children(so a move we did not see yet)
3. Simulation - where we simulate the best possible move in the node we expand, this process is highly parallelizable, hence the place where a parallel CUDA approach was implemented, in some paper it's referred to as Leaf Parallelization
4. Backpropagation - where we adjust the weights of all the nodes up the tree, so that in the next steps, we can choose a better path.
