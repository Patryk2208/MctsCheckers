//
// Created by patryk on 12/27/25.
//

#include "tocpuwb/batchExecutor.cuh"

#include <bitset>
#include <iostream>

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


// Simple test structure similar to yours

struct TestStructure {
    int size_;
    int metadata_;
};

struct SharedMap {
    TestStructure structures1_[32];
    TestStructure structures2_[32];
    TestStructure* readStructures_;
    TestStructure* writeStructures_;

    __device__ SharedMap() : structures1_{}, structures2_{} {readStructures_ = structures1_; writeStructures_ = structures2_;}
};

__global__ void TestSharedMemoryVisibility() {
    // Single warp: 32 threads, 1 block
    __shared__ SharedMap shm_map;

    int lane_id = threadIdx.x % 32;  // Should be 0-31

    // Initialize all sizes to 0
    if (lane_id == 0) {
        shm_map.readStructures_ = shm_map.structures1_;
        shm_map.writeStructures_ = shm_map.structures2_;
    }
    shm_map.writeStructures_[lane_id].size_ = 0;
    shm_map.writeStructures_[lane_id].metadata_ = 0;
    __syncwarp();  // Sync after initialization


    // Each lane writes its own data
    shm_map.writeStructures_[lane_id].size_ = lane_id + 100;  // 100-131
    shm_map.writeStructures_[lane_id].metadata_ = lane_id * 10;  // 0,10,20,...,310
    __syncwarp();

    if (lane_id == 0) {
        for (auto i = 0; i < 32; i++) {
            printf("%u reads %u, read: %d, %d\n", lane_id, i, shm_map.readStructures_[i].size_, shm_map.readStructures_[i].metadata_);
            printf("%u reads %u, read: %d, %d\n\n", lane_id, i, shm_map.writeStructures_[i].size_, shm_map.writeStructures_[i].metadata_);
        }
    }
    __syncwarp();

    // Each lane writes other lane's data
    shm_map.writeStructures_[lane_id].size_ = 0;
    shm_map.writeStructures_[lane_id].metadata_ = 0;
    if (lane_id % 6 == 0 || lane_id % 8 == 3) {
        shm_map.writeStructures_[(lane_id + 5) % 32].size_ = lane_id + 100;  // 100-131
        shm_map.writeStructures_[(lane_id + 5) % 32].metadata_ = lane_id * 10;  // 0,10,20,...,310
    }
    __syncwarp();

    if (lane_id == 0) {
        for (auto i = 0; i < 32; i++) {
            printf("%u reads %u, read: %d, %d\n", lane_id, i, shm_map.readStructures_[i].size_, shm_map.readStructures_[i].metadata_);
            printf("%u reads %u, read: %d, %d\n\n", lane_id, i, shm_map.writeStructures_[i].size_, shm_map.writeStructures_[i].metadata_);
        }
    }
    __syncwarp();

    /*// ============ TEST 1: Basic write/read ============
    // Each lane writes its own data
    shm_map.writeStructures_[lane_id].size_ = lane_id + 100;  // 100-131
    shm_map.writeStructures_[lane_id].metadata_ = lane_id * 10;  // 0,10,20,...,310

    printf("Test 1 - After write, lane %d: my size=%d\n",
           lane_id, shm_map.writeStructures_[lane_id].size_);
    __syncwarp();

    // Lane 0 tries to read all buckets WITHOUT proper fence
    if (lane_id == 0) {
        printf("\n=== Test 1: Lane 0 reading WITHOUT memory fence ===\n");
        for (int i = 0; i < 32; i++) {
            printf("Bucket[%2d]: size=%2d metadata=%3d\n",
                   i,
                   shm_map.writeStructures_[i].size_,
                   shm_map.writeStructures_[i].metadata_);
        }
    }
    __syncwarp();

    // ============ TEST 2: With memory fence ============
    // Reset
    shm_map.writeStructures_[lane_id].size_ = 0;
    shm_map.writeStructures_[lane_id].metadata_ = 0;
    __syncwarp();

    // Write again
    shm_map.writeStructures_[lane_id].size_ = lane_id + 200;  // 200-231
    shm_map.writeStructures_[lane_id].metadata_ = lane_id * 20;  // 0,20,40,...,620

    // ADD MEMORY FENCE
    __threadfence_block();  // Make writes visible
    __syncwarp();           // Sync execution

    // Lane 0 reads WITH fence
    if (lane_id == 0) {
        printf("\n=== Test 2: Lane 0 reading WITH memory fence ===\n");
        for (int i = 0; i < 32; i++) {
            printf("Bucket[%2d]: size=%2d metadata=%3d\n",
                   i,
                   shm_map.writeStructures_[i].size_,
                   shm_map.writeStructures_[i].metadata_);
        }
    }
    __syncwarp();

    // ============ TEST 3: With volatile pointer ============
    // Reset again
    shm_map.writeStructures_[lane_id].size_ = 0;
    shm_map.writeStructures_[lane_id].metadata_ = 0;
    __syncwarp();

    // Write
    shm_map.writeStructures_[lane_id].size_ = lane_id + 300;  // 300-331
    shm_map.writeStructures_[lane_id].metadata_ = lane_id * 30;  // 0,30,60,...,930

    __threadfence_block();
    __syncwarp();

    // Lane 0 reads using volatile pointer
    if (lane_id == 0) {
        printf("\n=== Test 3: Lane 0 reading with volatile pointer ===\n");
        volatile TestStructure* ws = shm_map.writeStructures_;

        for (int i = 0; i < 32; i++) {
            // Force fresh read each iteration
            asm volatile("" ::: "memory");

            printf("Bucket[%2d]: size=%2d metadata=%3d\n",
                   i,
                   ws[i].size_,
                   ws[i].metadata_);
        }
    }
    __syncwarp();

    // ============ TEST 4: Simulate your exact problem ============
    // Only write to first 12 buckets (like your case)
    if (lane_id < 12) {
        shm_map.writeStructures_[lane_id].size_ = 1;
        shm_map.writeStructures_[lane_id].metadata_ = lane_id * 100;
    } else {
        shm_map.writeStructures_[lane_id].size_ = 0;
        shm_map.writeStructures_[lane_id].metadata_ = 999;
    }

    // Test different sync methods
    if (lane_id == 0) {
        printf("\n=== Test 4: First 12 buckets only ===\n");
        printf("Method A - No fence:\n");
        for (int i = 0; i < 32; i++) {
            printf("[%d]:%d ", i, shm_map.writeStructures_[i].size_);
        }
        printf("\n");
    }
    __syncwarp();

    __threadfence_block();
    __syncwarp();

    if (lane_id == 0) {
        printf("Method B - With fence:\n");
        for (int i = 0; i < 32; i++) {
            printf("[%d]:%d ", i, shm_map.writeStructures_[i].size_);
        }
        printf("\n");
    }

    // ============ TEST 5: Race condition test ============
    // Simulate a race: lane 0 reads while others write
    __syncwarp();

    // All lanes except 0 write
    if (lane_id != 0) {
        shm_map.writeStructures_[lane_id].size_ = 555;
    }
    // NO FENCE HERE

    // Lane 0 reads IMMEDIATELY (racing!)
    if (lane_id == 0) {
        printf("\n=== Test 5: Race condition test ===\n");
        printf("Lane 0 reading during writes (should see mix):\n");
        for (int i = 0; i < 32; i++) {
            printf("[%d]:%d ", i, shm_map.writeStructures_[i].size_);
        }
        printf("\n");
    }
    __syncwarp();

    // Now with proper ordering
    if (lane_id != 0) {
        shm_map.writeStructures_[lane_id].size_ = 777;
    }
    __threadfence_block();
    __syncwarp();

    if (lane_id == 0) {
        printf("Lane 0 reading after fence (should see all 777):\n");
        for (int i = 0; i < 32; i++) {
            if (i == 0) continue;  // Skip lane 0's own bucket
            printf("[%d]:%d ", i, shm_map.writeStructures_[i].size_);
        }
        printf("\n");
    }*/
}

int TestTest() {
    printf("Launching single warp test kernel...\n");

    // Launch exactly 32 threads (1 warp)
    TestSharedMemoryVisibility<<<1, 32>>>();

    cudaDeviceSynchronize();

    printf("\nTest complete!\n");
    printf("\n=== ANALYSIS ===\n");
    printf("If Test 1 shows 0s but Test 2 shows correct values:\n");
    printf("  -> You're missing memory fences (__threadfence_block())\n");
    printf("\nIf all tests show correct values:\n");
    printf("  -> Your hardware/compiler is more forgiving\n");
    printf("  -> But still use fences for correctness!\n");

    return 0;
}

void BatchExecutor::Test(const size_t size, const BatchSoACheckersStateHost& batch, BatchLegalActionsHost& actions) {
    /*unsigned *a, *res = new unsigned[4];
    int input = 31;
    CUDA_CHECK(cudaMalloc(&a, 4 * sizeof(unsigned)));
    testDirectionFunctions<<<1, 4>>>(input, a);
    CUDA_CHECK(cudaMemcpy(res, a, 4 * sizeof(unsigned), cudaMemcpyDeviceToHost));
    printf("%u -> [%u, %u, %u, %u]\n", input, res[0], res[1], res[2], res[3]);
    delete[] res;
    return;*/
    //TestTest();
    //return;

    BatchSoACheckersStateResource d_batch(batch, size);
    BatchLegalActionsResource d_actions(size);

    const auto gridSize = 1;
    const auto blockSize = 32;
    const auto shmSize = size * SharedMemorySize;
    GetLegalActions<<<gridSize, blockSize, shmSize>>>(size, d_batch.self_.get(), d_actions.self_.get());
    KERNEL_CHECK();
    actions.CopyFromGpu(d_actions);
    for (auto i = 0; i < size; i++) {
        std::cout << "Result for board " << i << ":: " << std::endl;
        for (auto j = 0; j < actions.actions_[i].size_; j++) {
            std::cout << std::bitset<32>(actions.actions_[i].buffer_[j].whitePawns_) << " " <<
                std::bitset<32>(actions.actions_[i].buffer_[j].whiteQueens_) << " " <<
                std::bitset<32>(actions.actions_[i].buffer_[j].blackPawns_) << " " <<
                std::bitset<32>(actions.actions_[i].buffer_[j].blackQueens_) << " " <<
                std::bitset<32>(actions.actions_[i].buffer_[j].metadata_) << std::endl;
        }
        std::cout << std::endl;
    }
}