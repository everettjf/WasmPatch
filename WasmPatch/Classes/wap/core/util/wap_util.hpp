//
//  wap_util.hpp
//  WasmPatch
//
//  Created by everettjf on 2020/4/6.
//  Copyright © 2020 everettjf. All rights reserved.
//

#include <string>
#include <cstdlib>
#include <fstream>
#include <iostream>
namespace wap {

inline bool write_buffer_to_file(const std::string & path, const char * buffer, size_t size) {
    std::ofstream outfile(path, std::ios::binary);
    if (!outfile.is_open()) {
        std::cout << "file can not open" << std::endl;
        return false;
    }
    outfile.write((const char*)buffer, size);
    
    if (outfile.bad()) {
        outfile.close();
        return false;
    }
    
    outfile.close();
    return true;
}

inline bool read_buffer_from_file(const std::string & path, std::string & buffer) {
    std::ifstream wapile(path, std::ios::binary | std::ios::ate);
    if (!wapile.is_open()) {
        std::cout << "file can not open" << std::endl;
        return false;
    }
    // file size
    int64_t length = wapile.tellg();

    // read
    wapile.seekg(std::ios::beg);
    buffer.resize(length);
    wapile.read(buffer.data(), length);
    
    // check
    int64_t read_count = wapile.gcount();
    if (read_count != length) {
        std::cout << "read count not equal to file length" << std::endl;
        return false;
    }
    return true;
}
}
