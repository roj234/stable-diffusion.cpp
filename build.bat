@echo off
pushd %~dp0
echo Compiling wait patiently
clang -Iggml -Ithirdparty entry.cpp -w --shared -DGGML_MAX_NAME=256 -O2 -flto=thin -ffunction-sections -fdata-sections -Lincludes -lstdc++ -lggml -lggml-base -lggml-cpu-x64 -lggml-cuda -DSD_USE_CUDA -DSD_BUILD_DLL -o stable-diffusion.dll -Wl,-s
clang -Iggml -Ithirdparty -I. -Iexamples -w examples\cli\main.cpp -lstdc++ -lstable-diffusion -Lincludes -o sd-cli.exe -Wl,-s
