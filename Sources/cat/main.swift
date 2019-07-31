#if os(Linux)
import Glibc
#else
import DarwinC
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
