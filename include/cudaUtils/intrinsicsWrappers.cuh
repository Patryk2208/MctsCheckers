//
// Created by patryk on 12/31/25.
//

#ifndef MCTS_CHECKERS_INTRINSICSWRAPPERS_CUH
#define MCTS_CHECKERS_INTRINSICSWRAPPERS_CUH

#include <cudaUtils/cudaCompatibility.hpp>

D unsigned Template_activemask();

D void Template_syncwarp(unsigned mask);

D int Template_any_sync(unsigned mask, int pred);

#endif //MCTS_CHECKERS_INTRINSICSWRAPPERS_CUH