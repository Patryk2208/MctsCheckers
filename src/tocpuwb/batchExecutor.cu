//
// Created by patryk on 12/27/25.
//

#include "tocpuwb/batchExecutor.cuh"

/*void BatchExecutor::Run(size_t size, BatchSoACheckersState batch, BatchResults results) {
    auto d_batch = CudaResource<BatchSoACheckersState>(size , sizeof(CheckersState));
    batch.CopyToGpu(d_batch, size);
    auto d_actions = CudaResource<BatchLegalActions>(size, sizeof(ResultLegalActionSpace));
    while (true) {
        //todo check if terminal or known, if so return result as float
        //todo perform a random action from GetLegalActions
    }
    results.CopyFromGpu(d_results);
}*/

__global__ void testDirectionFunctions(unsigned fieldId, unsigned* result) {
    auto id = threadIdx.x;
    if (id == 0) {
        result[id] = GetTopLeftDirection::GetId(fieldId);
    }
    else if (id == 1) {
        result[id] = GetTopRightDirection::GetId(fieldId);
    }
    else if (id == 2) {
        result[id] = GetBottomLeftDirection::GetId(fieldId);
    }
    else if (id == 3) {
        result[id] = GetBottomRightDirection::GetId(fieldId);
    }
}

void BatchExecutor::Test(size_t size, const BatchSoACheckersStateHost& batch, BatchLegalActionsHost& actions) {
    /*unsigned *a, *res = new unsigned[4];
    int input = 31;
    CUDA_CHECK(cudaMalloc(&a, 4 * sizeof(unsigned)));
    testDirectionFunctions<<<1, 4>>>(input, a);
    CUDA_CHECK(cudaMemcpy(res, a, 4 * sizeof(unsigned), cudaMemcpyDeviceToHost));
    printf("%u -> [%u, %u, %u, %u]\n", input, res[0], res[1], res[2], res[3]);
    delete[] res;
    return;*/

    BatchSoACheckersStateResource d_batch(batch, size);
    BatchLegalActionsResource d_actions(size);

    const auto gridSize = 1;
    const auto blockSize = 32;
    const auto shmSize = size * SharedMemorySize;
    GetLegalActions<<<gridSize, blockSize, shmSize>>>(size, d_batch.self_.get(), d_actions.self_.get());
    KERNEL_CHECK();
    CUDA_CHECK(cudaDeviceSynchronize());
}