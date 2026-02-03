## Chinese Version below

---

# English Version: Fast Local Compilation Guide via LLVM-Mingw

This guide provides instructions on how to quickly compile this project using the `llvm-mingw` toolchain.

## 1. Prerequisites
Ensure you have the following ready:
*   **llvm-mingw**: Installed and added to your system PATH.
*   **llama.cpp Binaries**: Download the CPU, CUDA, and Vulkan versions.
*   **Dll2Lib Tool**: Compiled and ready to generate import libraries from DLLs.

## 2. Generating Import Libraries
Since this project uses dynamic linking, you must first generate the linkable libraries for `llama.cpp` components.
> **Note**: I have already generated `.a` or `.def` files, you can skip this step.

Navigate to the `/includes` directory and run:
```bash
# Use llvm-objdump and Dll2Lib to extract symbols and create import libraries
llvm-objdump -x ..\llama-cpp\ggml.dll | Dll2Lib
llvm-objdump -x ..\llama-cpp\ggml-base.dll | Dll2Lib
llvm-objdump -x ..\llama-cpp\ggml-cpu-x64.dll | Dll2Lib
llvm-objdump -x ..\llama-cpp\ggml-cuda.dll | Dll2Lib
llvm-objdump -x ..\llama-cpp\ggml-vulkan.dll | Dll2Lib
```

## 3. Compilation Commands

### Compile `stable-diffusion.dll`
Run this command in the project root (`/`):
```bash
clang -Iggml -Ithirdparty entry.cpp -w --shared \
  -DGGML_MAX_NAME=256 -O2 -flto=thin \
  -ffunction-sections -fdata-sections \
  -Lincludes -lstdc++ -lggml -lggml-base -lggml-cpu-x64 -lggml-cuda \
  -DSD_USE_CUDA -DSD_BUILD_DLL \
  -o stable-diffusion.dll -Wl,-s
```

**Update Import Library**
```bash
cd includes
llvm-objdump -x ..\stable-diffusion.dll | Dll2Lib
cd ..
```

### Compile `sd-cli.exe`
```bash
clang -Iggml -Ithirdparty -I. -Iexamples -w \
  examples\cli\main.cpp \
  -lstdc++ -lstable-diffusion -Lincludes \
  -o sd-cli.exe -Wl,-s
```

## 4. Important Notes
1.  **Backend Selection**:If you are using CPU inference, consider using the DLL optimized for your specific CPU architecture instead of generic `cpu-x64`.
2.  **Macros**: Do not forget to adjust macro definitions (e.g., `-DSD_USE_CUDA`) based on your target hardware.
3.  **Custom Files**: `entry.cpp` is a custom entry point added to this project.
4.  **Deployment**: Ensure all dependency DLLs are placed in the same folder as the executable to avoid "DLL not found" errors.
5. **ABI Compatibility**: C++ ABIs are **incompatible** between **MinGW** and **MSVC**. If you need to use `sd-server`, you must recompile it using this toolchain by changing the source path from `cli\main.cpp` to `server\main.cpp`.

---

_# 中文版本：使用 LLVM-Mingw 快速本地编译指南

本指南介绍如何使用 `llvm-mingw` 工具链在本地环境快速编译项目。

## 1. 环境准备
在开始之前，请确保已准备好以下组件：
*   **llvm-mingw**: 已安装并配置好环境变量。
*   **llama.cpp 二进制文件**: 下载对应的 CPU、CUDA 和 Vulkan 版本。
*   **Dll2Lib 工具**: 编译并准备好该工具，用于从 DLL 生成导入库（`.a` 文件）。

## 2. 生成导入库 (Import Libraries)
由于项目是动态链接的，需要先为 `llama.cpp` 的组件生成链接库。
> **注意**：我已经提供了 `.a` 或 `.def` 文件，可以跳过此步骤。

首先进入 `/includes` 目录，执行以下操作：
```bash
# 使用 llvm-objdump 和 Dll2Lib 提取导出符号并生成链接库
llvm-objdump -x ..\llama-cpp\ggml.dll | Dll2Lib
llvm-objdump -x ..\llama-cpp\ggml-base.dll | Dll2Lib
llvm-objdump -x ..\llama-cpp\ggml-cpu-x64.dll | Dll2Lib
llvm-objdump -x ..\llama-cpp\ggml-cuda.dll | Dll2Lib
llvm-objdump -x ..\llama-cpp\ggml-vulkan.dll | Dll2Lib
```

## 3. 编译步骤

### 编译 `stable-diffusion.dll` (工作目录=`/`)
这是核心动态库。请注意，生成的 `stable-diffusion.dll` 必须与上述所有 `ggml-*.dll` 文件放在同一目录下。

```bash
clang -Iggml -Ithirdparty entry.cpp -w --shared \
  -DGGML_MAX_NAME=256 -O2 -flto=thin \
  -ffunction-sections -fdata-sections \
  -Lincludes -lstdc++ -lggml -lggml-base -lggml-cpu-x64 -lggml-cuda \
  -DSD_USE_CUDA -DSD_BUILD_DLL \
  -o stable-diffusion.dll -Wl,-s
```

**更新导出表**
```bash
cd includes
llvm-objdump -x ..\stable-diffusion.dll | Dll2Lib
```

### 编译 `sd-cli.exe`
```bash
clang -Iggml -Ithirdparty -I. -Iexamples -w \
  examples\cli\main.cpp \
  -lstdc++ -lstable-diffusion -Lincludes \
  -o sd-cli.exe -Wl,-s
```

## 4. 重要提示
1.  **后端选择**：如果您在 CPU 上推理，建议根据您的 CPU 指令集选择对应的 DLL，而不是通用的 `cpu-x64`。
2.  **宏定义**：请务必检查并根据实际后端修改宏定义（如 `-DSD_USE_CUDA`）。
3.  **新增文件**：`entry.cpp` 是项目中额外添加的入口文件。
4.  **运行环境**：编译出的 `.exe` 必须与 `stable-diffusion.dll` 以及对应的 `ggml` DLL 放在同一个文件夹内才能正常执行。
5. **ABI 兼容性警示**： 由于 **MinGW** 和 **MSVC** 的 C++ ABI（应用程序二进制接口）互不兼容，若需使用 `sd-server`，必须使用本工具链重新编译。只需将编译 `sd-cli` 的源代码路径从 `examples\cli\main.cpp` 修改为 `examples\server\main.cpp`。
