cmake_minimum_required(VERSION 3.31)
set(CMAKE_CUDA_ARCHITECTURES native)
set(CMAKE_CUDA_COMPILER nvcc)
project(mcts_checkers LANGUAGES CXX CUDA)

####set(CMAKE_VERBOSE_MAKEFILE ON CACHE BOOL "Always build verbosely") ###testing

####set(CUDAToolkit_FIND_REQUIRED_CUDA TRUE)
####set(CUDAToolkit_ROOT "/usr/local/cuda-13.0")

include(CTest)
enable_testing()

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CUDA_STANDARD 20)
set(CMAKE_CUDA_STANDARD_REQUIRED ON)
find_package(CUDAToolkit REQUIRED)

#get_filename_component(CUDA_INCLUDE_DIR "${CUDAToolkit_INCLUDE_DIRS}" ABSOLUTE)
####set(CUDA_cuda_driver_LIBRARY "/usr/lib64/libcuda.so" CACHE FILEPATH "Override stub library" FORCE)

include(FetchContent)

set(SOURCES
        src/main.cpp
        src/tocpuwb/mcts.cpp
        src/tocpuwb/batchQueue.cpp
        src/tocpuwb/batchExecutor.cu
        src/checkers/state.cpp
        src/checkers/actions.cu
)

add_executable(MCTS ${SOURCES})

target_include_directories(MCTS PUBLIC include)

target_link_libraries(MCTS PRIVATE
        CUDA::cudart
)

#if(EXISTS "${CUDA_INCLUDE_DIR}/cccl")
#    message(STATUS "Found CCCL at: ${CUDA_INCLUDE_DIR}")
#    target_include_directories(KMeans SYSTEM PUBLIC "${CUDA_INCLUDE_DIR}/cccl" ${CUDA_INCLUDE_DIR})
#else()
#    target_include_directories(KMeans SYSTEM PUBLIC ${CUDA_INCLUDE_DIR})
#endif()


set_target_properties(MCTS PROPERTIES CUDA_SEPARABLE_COMPILATION ON CUDA_STANDARD 20)