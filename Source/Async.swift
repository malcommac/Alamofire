//
//  Async.swift
//
//  Copyright (c) 2021 Alamofire Software Foundation (http://alamofire.org/)
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

import Foundation

@available(macOS 12, iOS 15.0, tvOS 15.0, watchOS 8.0, *)
public struct AsyncDataResponse<Value> {
    public let request: DataRequest
    public var response: DataResponse<Value, AFError> {
        get async { await handle.get() }
    }
    public var value: Value {
         get async throws {
             let response = await response
             switch response.result {
             case let .success(value):
                 return value
             case let .failure(error):
                 throw error
             }
         }
    }
    public let handle: Task.Handle<AFDataResponse<Value>, Never>
    
    fileprivate init(request: DataRequest, handle: Task.Handle<AFDataResponse<Value>, Never>) {
        self.request = request
        self.handle = handle
    }
}

extension DispatchQueue {
    fileprivate static let asyncCompletionQueue = DispatchQueue(label: "org.alamofire.asyncCompletionQueue")
}

@available(macOS 12, iOS 15.0, tvOS 15.0, watchOS 8.0, *)
extension DataRequest {
    public func asyncResponse<Value: Decodable>(decoding: Value.Type = Value.self) -> AsyncDataResponse<Value> {
        let handle = `async` {
            await withCheckedContinuation { continuation in
                self.responseDecodable(of: Value.self, queue: .asyncCompletionQueue) {
                    continuation.resume(returning: $0)
                }
            }
        }

        return AsyncDataResponse<Value>(request: self, handle: handle)
    }
}
