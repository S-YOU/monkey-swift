//
//  ParserTests.swift
//  SemaTests
//
//  Created by Yusuke Kita on 11/15/18.
//

import XCTest
import Syntax
import Lexer
import Sema

final class ParserTests: XCTestCase {
    func test_letStatement() {
        let input = """
            let x = 5;
            let y = 10;
            let foobar = 838383;
        """
        
        let program = makeProgram(from: input)
        
        let statementsCount = program.statements.count
        let expectedCount = 3
        guard statementsCount == expectedCount else {
            XCTFail("program.statements does not contain \(expectedCount) statements. got=\(statementsCount)")
            return
        }
        
        let expectedIdentifiers = [
            "x",
            "y",
            "foobar"
        ]
        
        for (index, expectedIdentifier) in expectedIdentifiers.enumerated() {
            let statement = program.statements[index]
            testLetStatement(statement, name: expectedIdentifier)
        }
    }
    
    func test_returnStatement() {
        let input = """
            return 5;
            return 10;
            return 993322;
        """
        
        let program = makeProgram(from: input)
        
        let statementsCount = program.statements.count
        let expectedCount = 3
        guard statementsCount == expectedCount else {
            XCTFail("program.statements does not contain \(expectedCount) statements. got=\(statementsCount)")
            return
        }
        
        program.statements.forEach { statement in
            guard let returnStatement = statement as? ReturnStatement else {
                XCTFail("statement not \(ReturnStatement.self). got=\(type(of: statement))")
                return
            }
            
            XCTAssertTrue(returnStatement.token.type == .return, "tokenType not \(TokenType.return). got=\(returnStatement.token.type)")
        }
    }
    
    func test_identifierExpression() {
        let input = "foobar;"
        
        let program = makeProgram(from: input)
        let statement = makeExpressionStatement(from: program)
        
        testIdentifier(expression: statement.expression, expected: "foobar")
    }
    
    func test_parsingPrefixExpressions() {
        let prefixTests: [(input: String, `operator`: String, value: Int64)] = [
            (input: "!5", operator: "!", value: 5),
            (input: "-15", operator: "-", value: 15)
        ]
        
        prefixTests.forEach {
            let program = makeProgram(from: $0.input)
            let statement = makeExpressionStatement(from: program)
            
            guard let expression = statement.expression as? PrefixExpression else {
                XCTFail("statement.expression not \(PrefixExpression.self). got=\(type(of: statement.expression))")
                return
            }
            
            XCTAssertTrue(expression.operator == $0.operator, "expression.operator not \($0.operator). got=\(expression.operator)")
            testIntegerLiteral($0.value, with: expression.right)
        }
    }
    
    func test_parsingInfixExpressions() {
        let infixTests: [(input: String, leftValue: Any, `operator`: String, rightValue: Any)] = [
            (input: "5 + 5;", leftValue: 5, operator: "+", rightValue: 5),
            (input: "5 - 5;", leftValue: 5, operator: "-", rightValue: 5),
            (input: "5 * 5;", leftValue: 5, operator: "*", rightValue: 5),
            (input: "5 / 5;", leftValue: 5, operator: "/", rightValue: 5),
            (input: "5 > 5;", leftValue: 5, operator: ">", rightValue: 5),
            (input: "5 < 5;", leftValue: 5, operator: "<", rightValue: 5),
            (input: "5 == 5;", leftValue: 5, operator: "==", rightValue: 5),
            (input: "5 != 5;", leftValue: 5, operator: "!=", rightValue: 5),
            (input: "true == true", leftValue: true, operator: "==", rightValue: true),
            (input: "true != false", leftValue: true, operator: "!=", rightValue: false),
            (input: "false == false", leftValue: false, operator: "==", rightValue: false),
        ]
        
        infixTests.forEach {
            let program = makeProgram(from: $0.input)
            let statement = makeExpressionStatement(from: program)
            
            testInfixExpression(statement.expression, leftValue: $0.leftValue, operator: $0.operator, rightValue: $0.rightValue)
        }
    }
    
    func test_operatorPrecedenceParsing() {
        let precedenceTests: [(input: String, expected: String)] = [
            (input: "-a * b", expected: "((-a) * b)"),
            (input: "!-a", expected: "(!(-a))"),
            (input: "a + b + c", expected: "((a + b) + c)"),
            (input: "a + b - c", expected: "((a + b) - c)"),
            (input: "a * b * c", expected: "((a * b) * c)"),
            (input: "a * b / c", expected: "((a * b) / c)"),
            (input: "a + b * c", expected: "(a + (b * c))"),
            (input: "a + b * c + d / e - f", expected: "(((a + (b * c)) + (d / e)) - f)"),
            (input: "3 + 4; -5 * 5", expected: "(3 + 4)((-5) * 5)"),
            (input: "5 > 4 == 3 < 4", expected: "((5 > 4) == (3 < 4))"),
            (input: "5 > 4 != 3 < 4", expected: "((5 > 4) != (3 < 4))"),
            (input: "3 + 4 * 5 == 3 * 1 + 4 * 5", expected: "((3 + (4 * 5)) == ((3 * 1) + (4 * 5)))"),
            (input: "true", expected: "true"),
            (input: "false", expected: "false"),
            (input: "3 > 5 == false", expected: "((3 > 5) == false)"),
            (input: "3 < 5 == true", expected: "((3 < 5) == true)"),
            (input: "1 + (2 + 3) + 4", expected: "((1 + (2 + 3)) + 4)"),
            (input: "(5 + 5) * 2", expected: "((5 + 5) * 2)"),
            (input: "2 / (5 + 5)", expected: "(2 / (5 + 5))"),
            (input: "-(5 + 5)", expected: "(-(5 + 5))"),
            (input: "!(true == true)", expected: "(!(true == true))"),
        ]
        
        precedenceTests.forEach {
            let program = makeProgram(from: $0.input)
            
            XCTAssertTrue(program.description == $0.expected, "program.description not \($0.expected). got=\(program.description)")
        }
    }
    
    func test_callExpressionParsing() {
        let input = "add(1, 2 * 3, 4 + 5)"

        let program = makeProgram(from: input)
        let statement = makeExpressionStatement(from: program)

        guard let callExpression = statement.expression as? CallExpression else {
            XCTFail("statement.expression not \(CallExpression.self). got=\(statement.expression)")
            return
        }

        testIdentifier(expression: callExpression.function, expected: "add")

        XCTAssertTrue(callExpression.arguments.count == 3, "callExpression.arguments wrong. want 3, got \(callExpression.arguments.count)")

        testLiteralExpression(callExpression.arguments[0], expected: 1)
        testInfixExpression(callExpression.arguments[1], leftValue: 2, operator: "*", rightValue: 3)
        testInfixExpression(callExpression.arguments[2], leftValue: 4, operator: "+", rightValue: 5)
    }
    
    func test_boolExpression() {
        let boolTests: [(input: String, expected: Bool)] = [
            (input: "true", expected: true),
            (input: "false", expected: false)
        ]
        
        boolTests.forEach {
            let program = makeProgram(from: $0.input)
            let statement = makeExpressionStatement(from: program)
            
            testBoolean(expression: statement.expression, expected: $0.expected)
        }
    }
    
    func test_ifExpression() {
        let input = "if (x < y) { x }"
        
        let program = makeProgram(from: input)
        let statement = makeExpressionStatement(from: program)
        
        guard let ifExpression = statement.expression as? IfExpression else {
            XCTFail("statement.expression not \(IfExpression.self). got=\(type(of: statement.expression))")
            return
        }
        
        testInfixExpression(ifExpression.condition, leftValue: "x", operator: "<", rightValue: "y")
        
        guard !ifExpression.consequence.statements.isEmpty else {
            XCTFail("consequence.statements is empty")
            return
        }
        
        guard let consequence = ifExpression.consequence.statements[0] as? ExpressionStatement else {
            XCTFail("consequence.statements[0] not \(ExpressionStatement.self). got=\(ifExpression.consequence.statements[0])")
            return
        }
        
        testIdentifier(expression: consequence.expression, expected: "x")
        
        XCTAssertNil(ifExpression.alternative, "alternative should be nil")
    }
    
    func test_functionLiteralParsing() {
        let input = "fn(x, y) { x + y; }"
        
        let program = makeProgram(from: input)
        let statement = makeExpressionStatement(from: program)
        
        guard let functionLiteral = statement.expression as? FunctionLiteral else {
            XCTFail("statement.expression not \(FunctionLiteral.self). got=\(statement.expression)")
            return
        }
        
        guard functionLiteral.parameters.count == 2 else {
            XCTFail("function.parameters.count wrong. want 2, got=\(functionLiteral.parameters.count)")
            return
        }
        
        guard let bodyStatement = functionLiteral.body.statements[0] as? ExpressionStatement else {
            XCTFail("function.body.statements[0] not \(ExpressionStatement.self). got=\(functionLiteral.body.statements[0])")
            return
        }
        
        testInfixExpression(bodyStatement.expression, leftValue: "x", operator: "+", rightValue: "y")
    }
    
    func test_functionParametersParsing() {
        let tests: [(input: String, expectedParams: [String])] = [
            (input: "fn() {};", expectedParams: []),
            (input: "fn(x) {};", expectedParams: ["x"]),
            (input: "fn(x, y, z) {};", expectedParams: ["x", "y", "z"]),
        ]
        
        tests.forEach {
            let program = makeProgram(from: $0.input)
            let statement = makeExpressionStatement(from: program)
            
            guard let functionLiteral = statement.expression as? FunctionLiteral else {
                XCTFail("statement.expression not \(FunctionLiteral.self). got=\(statement.expression)")
                return
            }
            
            XCTAssertTrue(functionLiteral.parameters.count == $0.expectedParams.count, "functionLiteral.parameters.count wrong. want=\($0.expectedParams.count), got=\(functionLiteral.parameters.count)")
            
            for (index, param) in $0.expectedParams.enumerated() {
                testLiteralExpression(functionLiteral.parameters[index], expected: param)
            }
        }
    }
    
    private func testLetStatement(_ statement: Statement, name: String) {
        guard statement.tokenLiteral == Token(type: .let).literal else {
            XCTFail("tokenLiteral not \(Token(type: .let).literal). got=\(statement.tokenLiteral)")
            return
        }
        
        guard let letStatement = statement as? LetStatement else {
            XCTFail("statement not \(LetStatement.self). got=\(type(of: statement))")
            return
        }
        
        XCTAssertTrue(letStatement.name.value == name, "letStatement.name not \(name). got=\(letStatement.name)")
        XCTAssertTrue(letStatement.name.tokenLiteral == name, "letStatement.name.tokenLiteral not \(name). got=\(letStatement.name.tokenLiteral)")
    }
    
    private func testLiteralExpression(_ expression: Expression, expected: Any) {
        switch expected {
        case let value as Int:
            testIntegerLiteral(Int64(value), with: expression)
        case let value as Int64:
            testIntegerLiteral(value, with: expression)
        case let value as String:
            testIdentifier(expression: expression, expected: value)
        case let value as Bool:
            testBoolean(expression: expression, expected: value)
        default:
            XCTFail("unsupported type")
        }
    }
    
    private func testIntegerLiteral(_ value: Int64, with expression: Expression) {
        guard let integerLiteral = expression as? IntegerLiteral else {
            XCTFail("expression not \(IntegerLiteral.self). got=\(type(of: expression))")
            return
        }
        
        XCTAssertTrue(integerLiteral.value == value, "integerLiteral.value not \(value). got=\(integerLiteral.value)")
        XCTAssertTrue(integerLiteral.tokenLiteral == "\(value)", "integerLiteral.tokenLiteral not \(value). got=\(integerLiteral.tokenLiteral)")
    }
    
    private func testBoolean(expression: Expression, expected: Bool) {
        guard let boolean = expression as? Boolean else {
            XCTFail("statement.expression not \(Boolean.self). got=\(expression)")
            return
        }
        
        XCTAssertTrue(boolean.value == expected, "boolean.value not \(expected). got=\(boolean.value)")
    }
    
    private func testIdentifier(expression: Expression, expected: String) {
        guard let identifier = expression as? Identifier else {
            XCTFail("statement.expression not \(Identifier.self). got=\(expression)")
            return
        }
        
        XCTAssertTrue(identifier.value == expected, "identifier.value not \(expected). got=\(identifier.value)")
        XCTAssertTrue(identifier.tokenLiteral == expected, "identifier.tokenLiteral not \(expected). got=\(identifier.tokenLiteral)")
    }
    
    private func testInfixExpression(_ expression: Expression, leftValue: Any, operator: String, rightValue: Any) {
        guard let infixExpression = expression as? InfixExpression else {
            XCTFail("expression not \(InfixExpression.self). got=\(type(of: expression))")
            return
        }
        
        testLiteralExpression(infixExpression.left, expected: leftValue)
        XCTAssertTrue(infixExpression.operator == `operator`, "infixExpression.operator not \(`operator`). got=\(infixExpression.operator)")
    }
    
    private func makeProgram(from input: String) -> Program {
        let lexer = Lexer(input: input)
        var parser = Parser(lexer: lexer)
        
        let program: Program
        do {
            program = try parser.parse()
        } catch let error as Error & CustomStringConvertible {
            XCTFail(error.description); fatalError()
        } catch {
            XCTFail("unexpected error"); fatalError()
        }
        return program
    }
    
    private func makeExpressionStatement(from program: Program) -> ExpressionStatement {
        guard !program.statements.isEmpty else {
            XCTFail("program.statements is empty")
            fatalError()
        }
        
        guard let statement = program.statements[0] as? ExpressionStatement else {
            XCTFail("program.statements[0] not \(ExpressionStatement.self). got=\(type(of: program.statements[0]))")
            fatalError()
        }
        
        return statement
    }
}