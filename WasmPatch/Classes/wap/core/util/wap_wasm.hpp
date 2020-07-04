//
//  wasm_helper.hpp
//  WasmPatch
//
//  Created by everettjf on 2020/4/6.
//  Copyright © 2020 everettjf. All rights reserved.
//


/**
 Usage:
 
 # FunctionWrapper
     
     i32 foo1(i32 a, i32 b) {
         return 0;
     }
     i64 foo2(i64 a, i64 b) {
         return 0;
     }
     int main(int argc, const char * argv[]) {
         cout << FunctionWrapper<foo1>::signature() << endl;
         cout << FunctionWrapper<foo2>::signature() << endl;
         return 0;
     }
 
    output :
 
    i(ii)
    I(II)
 
 # WasmRuntime
 
 todo...
 
 
 */


#ifndef wasm_helper_hpp
#define wasm_helper_hpp

#include "../../depend/wasm3/wasm3.h"
#include "../../depend/wasm3/m3_env.h"
#include "../../depend/wasm3/m3_config.h"
#include "../../depend/wasm3/m3_api_defs.h"

#include <string>
#include <iostream>
#include <cstdlib>
#include <cstdio>
#include <inttypes.h>

#include "wap_util.hpp"

namespace wap {

template<char c>
struct wasm_sig {
    static const char value = c;
};

template<typename T> struct wasm_type_to_sig;
template<> struct wasm_type_to_sig<i32> : wasm_sig<'i'> {};
template<> struct wasm_type_to_sig<i64> : wasm_sig<'I'> {};
template<> struct wasm_type_to_sig<f32> : wasm_sig<'f'> {};
template<> struct wasm_type_to_sig<f64> : wasm_sig<'F'> {};
template<> struct wasm_type_to_sig<void> : wasm_sig<'v'> {};
template<> struct wasm_type_to_sig<void *> : wasm_sig<'*'> {};
template<> struct wasm_type_to_sig<const void *> : wasm_sig<'*'> {};

// helper extension
template<> struct wasm_type_to_sig<char *> : wasm_sig<'i'> {};
template<> struct wasm_type_to_sig<const char *> : wasm_sig<'i'> {};
template<> struct wasm_type_to_sig<u32> : wasm_sig<'i'> {};
template<> struct wasm_type_to_sig<u64> : wasm_sig<'I'> {};


template <typename Ret, typename ... Args>
const char * GetTypeSignature() {
    static const char arr[] = {
        wasm_type_to_sig<Ret>::value,
        '(',
        wasm_type_to_sig<Args>::value...,
        ')',
        0
    };
    return arr;
}

template <auto value>
class FunctionWrapper;

template<typename Ret, typename ... Args, Ret (*Fn)(Args...)>
class FunctionWrapper<Fn> {
public:
    static const char * signature() {
        return GetTypeSignature<Ret, Args...>();
    }
};


#define WAP_LOG_ERROR(msg, ...) { printf("WAP Error: " msg "\n", ##__VA_ARGS__); }

class WasmRuntime {
    
public:
    WasmRuntime() {
        m_env = m3_NewEnvironment();
        if (!m_env) {
            WAP_LOG_ERROR("init environment failed");
        }
        
        m_runtime = m3_NewRuntime(m_env, 8192, NULL);
        if (!m_runtime) {
            WAP_LOG_ERROR("init runtime failed");
        }
    }
    
    ~WasmRuntime() {
        if (m_runtime) {
            m3_FreeRuntime(m_runtime);
            m_runtime = nullptr;
        }
        
        if (m_env) {
            m3_FreeEnvironment(m_env);
            m_env = nullptr;
        }
        
        // m3_FreeRuntime will free internal modules
        // do not free module manually
        m_module = nullptr;
    }
    
    bool loadData(const std::string & buffer) {
        if (buffer.empty()) {
            return false;
        }
        
        m_buffer = buffer;
        
        uint8_t* wasm_code = (uint8_t*)m_buffer.data();
        uint32_t code_fsize = (uint32_t)m_buffer.size();
        
        M3Result result = m3Err_none;
        result = m3_ParseModule(m_env, &m_module, wasm_code, code_fsize);
        if (result) {
            WAP_LOG_ERROR("m3_ParseModule: %s", result);
            return false;
        }

        result = m3_LoadModule(m_runtime, m_module);
        if (result) {
            WAP_LOG_ERROR("m3_LoadModule: %s", result);
            return false;
        }
        
        return true;
    }
    
    bool loadFile(const std::string & path) {
        std::string buffer;
        if (!read_buffer_from_file(path, buffer)) {
            WAP_LOG_ERROR("read file failed");
            return false;
        }
        return loadData(buffer);
    }
    
    template <typename OutRet>
    bool call(const char *function_name, const char **parameters, int parameter_count, OutRet * out_return) {
        M3Result result = m3Err_none;

        IM3Function f;
        result = m3_FindFunction(&f, m_runtime, function_name);
        if (result) {
            WAP_LOG_ERROR("m3_FindFunction: %s", result);
            return false;
        }
        
        result = m3_CallWithArgs(f, parameter_count, parameters);
        if (result) {
            WAP_LOG_ERROR("m3_CallWithArgs: %s", result);
            return false;
        }
        
        if (out_return) {
            *out_return = *(OutRet*)(m_runtime->stack);
        }
        return true;
    }
    
    template <typename OutRet>
    bool call(const char *function_name, OutRet * out_return) {
        const char* parameters[1] = {NULL };
        return call<OutRet>(function_name, parameters, 0, out_return);
    }
    
    bool call(const char *function_name) {
        return call<u32>(function_name, nullptr);
    }
    
    bool link(const char *function_name, const char * signature, M3RawCall raw_call) {
        M3Result result = m3Err_none;
        
        result = m3_LinkRawFunction(m_module, "*", function_name, signature, raw_call);
        if (result) {
            WAP_LOG_ERROR("m3_LinkRawFunction(%s): %s", function_name, result);
            return false;
        }
        
        return true;
    }
    
    template<auto func>
    bool link(const char *function_name, M3RawCall raw_call) {
        return link(function_name, FunctionWrapper<func>::signature(), raw_call);
    }
    
    char * memoryStart() {
        char* vram = (char*)(m3_GetMemory(m_runtime, 0, 0));
        return vram;
    }
    
    char * memoryOffset(int offset) {
        char *vram = memoryStart();
        return (char*)(vram + offset);
    }
private:
    IM3Environment m_env = nullptr;
    IM3Runtime m_runtime = nullptr;
    IM3Module m_module = nullptr;
    std::string m_buffer;
};

}

#endif /* wasm_helper_hpp */
