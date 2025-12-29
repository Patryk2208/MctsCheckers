//
// Created by patryk on 12/28/25.
//

#ifndef MCTS_CHECKERS_SMARTPOINTER_CUH
#define MCTS_CHECKERS_SMARTPOINTER_CUH

#include "cudaUtils/errors.cuh"

/**
 * Elegant RAII wrapper for cuda memory allocation
 * @tparam T type of the resource
 */
template<typename T>
class CudaResource {
    T* resource_;
    size_t objectSize;
    size_t typeSize;
    size_t rawSize;
public:
    explicit CudaResource(size_t size) {
        objectSize = size;
        typeSize = sizeof(T);
        rawSize = objectSize * sizeof(T);
        CUDA_CHECK(cudaMalloc((void**)&resource_, size * sizeof(T)));
    }

    explicit CudaResource(size_t objectSize, size_t typeSize) {
        this->objectSize = objectSize;
        this->typeSize = typeSize;
        this->rawSize = objectSize * typeSize;
        CUDA_CHECK(cudaMalloc((void**)&resource_, objectSize * typeSize));
    }

    ~CudaResource() {
        if (resource_) {
            cudaFree(resource_);
        }
    }

    CudaResource(CudaResource&& other) noexcept
        : resource_(other.resource_)
    {
        other.resource_ = nullptr;
    }

    CudaResource& operator=(CudaResource&&) = delete;
    CudaResource(const CudaResource&) = delete;
    CudaResource& operator=(const CudaResource&) = delete;

    // Accessors
    T* get() {
        return resource_;
    }

    size_t getObjectSize() const {
        return objectSize;
    }
    size_t getTypeSize() const {
        return typeSize;
    }
    size_t getRawSize() const {
        return rawSize;
    }
    /*T* operator->() const { return resource_; }
    T& operator*() const { return *resource_; }*/
};


#endif //MCTS_CHECKERS_SMARTPOINTER_CUH