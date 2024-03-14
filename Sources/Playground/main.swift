import MacroKit

// MARK: ExpressionMacros

let a = 17
let b = 25

let (result, code) = #stringify(a + b)

print("The value \(result) was produced by the code \"\(code)\"")

// MARK: MemberMacros

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

LogModel().log()

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

