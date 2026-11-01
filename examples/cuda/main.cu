#include <cstdio>
#include <cuda_runtime.h>

__global__ void double_values(int *values, int count)
{
    int i = blockIdx.x * blockDim.x + threadIdx.x;
    if (i < count) values[i] *= 2;
}

int main()
{
    const int count = 4;
    int values[count] = {1, 2, 3, 4};
    int *device = nullptr;
    cudaError_t status = cudaMalloc(&device, sizeof(values));
    if (status == cudaSuccess)
        status = cudaMemcpy(device, values, sizeof(values), cudaMemcpyHostToDevice);
    if (status == cudaSuccess) {
        double_values<<<1, 32>>>(device, count);
        status = cudaGetLastError();
    }
    if (status == cudaSuccess)
        status = cudaMemcpy(values, device, sizeof(values), cudaMemcpyDeviceToHost);
    if (device) cudaFree(device);
    if (status != cudaSuccess) {
        std::fprintf(stderr, "CUDA error: %s\n", cudaGetErrorString(status));
        return 1;
    }
    for (int value : values) std::printf("%d ", value);
    std::printf("\n");
    return 0;
}
