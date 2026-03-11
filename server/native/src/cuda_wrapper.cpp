// Simple wrapper providing add_vectors_c. By default this uses a CPU implementation.
// To enable CUDA accelerated implementation:
// 1) Implement add_vectors_cuda in a .cu file and link it.
// 2) Add build steps to compile CUDA sources and define USE_CUDA.

#include "cuda_wrapper.h"

#ifdef USE_CUDA
// If compiled with -DUSE_CUDA, link to CUDA implementation (not included here).
extern "C" void add_vectors_cuda(const float* a, const float* b, float* out, int n);

extern "C" void add_vectors_c(const float* a, const float* b, float* out, int n) {
  add_vectors_cuda(a,b,out,n);
}
#else
// CPU fallback implementation
extern "C" void add_vectors_c(const float* a, const float* b, float* out, int n) {
  for (int i = 0; i < n; ++i) {
    out[i] = a[i] + b[i];
  }
}
#endif
