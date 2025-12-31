//
// Created by patryk on 12/31/25.
//

#ifndef MCTS_CHECKERS_CUDACOMPATIBILITY_HPP
#define MCTS_CHECKERS_CUDACOMPATIBILITY_HPP

#pragma once

#ifdef __CUDACC__
    #define HD __host__ __device__
    #define D  __device__
    #define H  __host__
#else
    #define HD
    #define D
    #define H
#endif

#ifdef __CUDACC__
    #define GLOBAL __global__
#else
    #define GLOBAL
#endif


#endif //MCTS_CHECKERS_CUDACOMPATIBILITY_HPP