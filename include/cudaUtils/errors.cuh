//
// Created by patryk on 12/28/25.
//

#ifndef MCTS_CHECKERS_ERRORS_CUH
#define MCTS_CHECKERS_ERRORS_CUH

#include <string>
#include <stdexcept>
#include <cuda_runtime.h>

/*
 * Macros for elegant cuda error handling
 */
class CudaException : public std::runtime_error {
public:
    CudaException(const std::string& message, const char* file, int line)
        : std::runtime_error(format_message(message, file, line)) {}

private:
    static std::string format_message(const std::string& message, const char* file, int line) {
        return "CUDA Error at " + std::string(file) + ":" + std::to_string(line) + " - " + message;
    }
};

#define CUDA_CHECK(call) \
do { \
    cudaError_t error = call; \
    if (error != cudaSuccess) { \
        throw CudaException( \
            std::string("CUDA error: ") + cudaGetErrorString(error) + \
            " (" + std::to_string(error) + ") in " + #call, \
            __FILE__, __LINE__ \
        ); \
    } \
} while(0)

#define CUDA_CHECK_LAST_ERROR() \
do { \
    cudaError_t error = cudaGetLastError(); \
    if (error != cudaSuccess) { \
        throw CudaException( \
            std::string("CUDA error: ") + cudaGetErrorString(error) + \
            " (" + std::to_string(error) + ") in ", \
            __FILE__, __LINE__ \
        ); \
    } \
} while(0)

#define KERNEL_CHECK() CUDA_CHECK_LAST_ERROR()


#endif //MCTS_CHECKERS_ERRORS_CUH