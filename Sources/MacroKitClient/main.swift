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
        logger.debug("Msg")
    }
}

LogModel().log()
