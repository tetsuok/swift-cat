// Copyright 2019 Tetsuo Kiso. All Rights Reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

#if os(Linux)
import Glibc
#else
import Darwin.C
#endif

enum CatError : Error {
    case openError
    case closeError
    case readError
    case writeError
    case outOfMemory
}

func main() {
    guard CommandLine.arguments.count >= 2 else {
        print("usage: cat FILE...")
        exit(0)
    }
    for file in CommandLine.arguments[1...] {
        let result = cat(at: file)
        switch result {
        case let .failure(error):
            print("failed reading \(file): \(error)")
            exit(1)
        default:
          continue
        }
    }
}

func cat(at path: String) -> Result<Int, CatError> {
    let fd = open(path, O_RDONLY, 0)
    defer { close(fd) }
    if fd < 0 {
        return .failure(.openError)
    }
    return cat(fd: fd)
}

func cat(fd: Int32, bufSize: Int = 4096) -> Result<Int, CatError> {
    let wfd = fileno(stdout)
    var buf = UnsafeMutableBufferPointer<UInt8>.allocate(capacity: bufSize)
    defer { buf.deallocate() }

    var totalWrite = 0
    while true {
        var nread = read(fd, buf.baseAddress!, bufSize)
        if nread <= 0 {
            break
        }
        var offset = 0
        while nread > 0 {
            let nwrite = write(wfd, buf.baseAddress! + offset, nread)
            if nwrite <= 0 {
                return .failure(.writeError)
            }
            nread -= nwrite
            offset += nwrite
            totalWrite += nwrite
        }
    }
    return .success(totalWrite)
}

main()
