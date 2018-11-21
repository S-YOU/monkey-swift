//
//  AstTests.swift
//  AstTests
//
//  Created by Yusuke Kita on 11/15/18.
//

import XCTest
import Token
import Ast

final class AstTests: XCTestCase {
    func test_nextDescription() {
        
        let programs: [Program] = [
            .init(
                statements: [
                    LetStatement(
                        token: .init(type: .let),
                        name: .init(token: .makeIdentifier(identifier: "x")),
                        value: .init(token: .makeNumber(number: "5"))
                    )
                ]
            ),
            .init(
                statements: [
                    LetStatement(
                        token: .init(type: .let),
                        name: .init(token: .makeIdentifier(identifier: "myVar")),
                        value: .init(token: .makeIdentifier(identifier: "anotherVar"))
                    )
                ]
            )
        ]
        
        let expectedDescriptions = [
            "let x = 5;",
            "let myVar = anotherVar;"
        ]
        
        for (index, program) in programs.enumerated() {
            XCTAssertTrue(program.description == expectedDescriptions[index], "program.description not \(expectedDescriptions[index])")
        }
    }
}