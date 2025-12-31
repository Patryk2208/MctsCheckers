//
// Created by patryk on 12/31/25.
//
#include <cudaUtils/intrinsicsWrappers.cuh>

D unsigned Template_activemask() {
    return __activemask();
}

D void Template_syncwarp(unsigned mask) {
    __syncwarp(mask);
}

D int Template_any_sync(unsigned mask, int pred) {
    return __any_sync(mask, pred);
}