#include <napi.h>
#include "cuda_wrapper.h"

Napi::Value AddVectors(const Napi::CallbackInfo& info) {
  Napi::Env env = info.Env();
  if (info.Length() < 2) {
    Napi::TypeError::New(env, "Expected two Float32Array arguments").ThrowAsJavaScriptException();
    return env.Null();
  }
  Napi::Float32Array a = info[0].As<Napi::Float32Array>();
  Napi::Float32Array b = info[1].As<Napi::Float32Array>();
  size_t n = std::min(a.ElementLength(), b.ElementLength());
  Napi::Float32Array out = Napi::Float32Array::New(env, n);

  add_vectors_c((float*)a.Data(), (float*)b.Data(), (float*)out.Data(), (int)n);

  return out;
}

Napi::Object Init(Napi::Env env, Napi::Object exports) {
  exports.Set("addVectors", Napi::Function::New(env, AddVectors));
  return exports;
}

NODE_API_MODULE(addon, Init)
