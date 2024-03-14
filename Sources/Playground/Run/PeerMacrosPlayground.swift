//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2023 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//

import Foundation
import MacroKit

func runPeerMacrosPlayground() {}

// MARK: - Add Async

struct MyStruct {
    @AddAsync
    func c(a: Int, for b: String, _ value: Double, completionBlock: @escaping (Result<String, Error>) -> Void) -> Void {
        completionBlock(.success("a: \(a), b: \(b), value: \(value)"))
    }

    @AddAsync
    func d(a: Int, for b: String, _ value: Double, completionBlock: @escaping (Bool) -> Void) -> Void {
        completionBlock(true)
    }
}
