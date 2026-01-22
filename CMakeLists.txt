cmake_minimum_required(VERSION 3.31)
set(CMAKE_CUDA_ARCHITECTURES native)
set(CMAKE_CUDA_COMPILER nvcc)
project(mcts_checkers LANGUAGES CXX CUDA)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CUDA_STANDARD 20)
set(CMAKE_CUDA_STANDARD_REQUIRED ON)
find_package(CUDAToolkit REQUIRED)

#set(CMAKE_CUDA_FLAGS_DEBUG "-g -G --source-in-ptx -lineinfo -O0")

#[[option(BUILD_WITH_DEBUG "Build with device debug (-G) for stepping" ON)
option(BUILD_WITH_LINEINFO "Build with line info for profiling" ON)

if(BUILD_WITH_DEBUG)
    message(STATUS "Building with device debug (-G) - WILL BE SLOW!")
    set(CMAKE_CUDA_FLAGS_DEBUG "-g -G --source-in-ptx -lineinfo -O0")
elseif(BUILD_WITH_LINEINFO)
    set(CMAKE_CUDA_FLAGS_RELWITHDEBINFO "-g -lineinfo")
else()
    set(CMAKE_CUDA_FLAGS_DEBUG "-g -O0")
endif()]]


if(CMAKE_CUDA_COMPILER_ID STREQUAL "NVIDIA")
    set(CMAKE_CUDA_HOST_COMPILER /usr/bin/g++)
endif()

message(STATUS "CUDAToolkit_VERSION: ${CUDAToolkit_VERSION}")
message(STATUS "CUDAToolkit_INCLUDE_DIRS: ${CUDAToolkit_INCLUDE_DIRS}")
message(STATUS "CUDAToolkit_LIBRARY_DIR: ${CUDAToolkit_LIBRARY_DIR}")

#get_filename_component(CUDA_INCLUDE_DIR "${CUDAToolkit_INCLUDE_DIRS}" ABSOLUTE)
####set(CUDA_cuda_driver_LIBRARY "/usr/lib64/libcuda.so" CACHE FILEPATH "Override stub library" FORCE)

include(FetchContent)

set(SOURCES
        src/main.cpp
        src/tocpuwb/mcts.cpp
        src/tocpuwb/batchExecutor.cu
        src/checkers/state.cpp
        src/checkers/actions/actions.cu
        src/checkers/actions/directionFunctions.cu
        src/checkers/actions/helperFunctions.cu
        src/checkers/actions/shmStructure.cu
        src/cudaUtils/intrinsicsWrappers.cu
        src/checkers/deviceResources/batchActionSpace.cu
        src/checkers/deviceResources/batchCheckerState.cu
        src/checkers/deviceResources/batchSimulationResults.cu
        src/tocpuwb/serialization.cpp
)

add_executable(MCTS ${SOURCES})

target_include_directories(MCTS PUBLIC include)

target_link_libraries(MCTS PRIVATE
        CUDA::cudart
        CUDA::curand
)

set_target_properties(MCTS PROPERTIES CUDA_SEPARABLE_COMPILATION ON CUDA_STANDARD 20)