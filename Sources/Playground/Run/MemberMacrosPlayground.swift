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

func runMemberMacrosPlayground() {
    runCaseDetection()

    runLogging()

    runAssociatedValues()
}

// MARK: MemberMacros

private func runCaseDetection() {
    @CaseDetection(.fileprivate)
    enum Animal1 {
        case dog
        case cat(curious: Bool)
    }

    @CaseDetection(.public)
    enum Animal2 {
        case dog
        case cat(curious: Bool)
    }

    let dog = Animal1.dog
    print("dog is \(dog.isDog)")

    let cat = Animal2.cat(curious: true)
    print("cat is \(cat.isCat)")
}

private func runLogging() {
    @Logging
    class LogModel {
        func log() {
            Logger(logger).trace("log messsage")
            os_log(.info, log: logger, "log messsage")
            #log(level: .info, "log messsage")
            #log(level: .debug, "log messsage")
            #log(level: .error, "log messsage")
        }
    }
    @Logging(category: "UI")
    class LogUIModel {
        func log() {
            Logger(logger).trace("log messsage")
            os_log(.info, log: logger, "log messsage")
            #log(level: .info, "log messsage")
            #log(level: .debug, "log messsage")
            #log(level: .error, "log messsage")
        }
    }

    LogModel().log()
    LogUIModel().log()
}

private func runAssociatedValues() {
    @AssociatedValues(.fileprivate)
    enum SomeEnum {
        case none
        case labeledValue(a: String, b: String)
        case optional(String?)
        case value(Int)
        case closure(() -> Void)
    }

    print(SomeEnum.labeledValue(a: "a", b: "b").labeledValue!)
    print(SomeEnum.value(10).value!)
    print(SomeEnum.optional("Hello").optional!!)
    SomeEnum.closure({ print("Hello MacroKit World") }).closure!()
}
