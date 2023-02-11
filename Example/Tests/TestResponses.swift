//
//  TestResponses.swift
//  Tests
//
//  Created by Ihor Yarovyi on 10.02.2023.
//  Copyright © 2023 CocoaPods. All rights reserved.
//

import Foundation

final class SuccessTestResponse: HTTPURLResponse {
    override var statusCode: Int { 200 }

    convenience init?(statusCode: Int = 200) {
        self.init(url: URL(string: "https://example.con")!, statusCode: statusCode, httpVersion: nil, headerFields: nil)
    }

    override init?(url: URL, statusCode: Int, httpVersion HTTPVersion: String?, headerFields: [String : String]?) {
        super.init(url: url, statusCode: statusCode, httpVersion: HTTPVersion, headerFields: headerFields)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

final class FailTestResponse: HTTPURLResponse {
    override var statusCode: Int { 400 }

    convenience init?(statusCode: Int = 400) {
        self.init(url: URL(string: "https://example.con")!, statusCode: statusCode, httpVersion: nil, headerFields: nil)
    }

    override init?(url: URL, statusCode: Int, httpVersion HTTPVersion: String?, headerFields: [String : String]?) {
        super.init(url: url, statusCode: statusCode, httpVersion: HTTPVersion, headerFields: headerFields)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

final class ServerErrorTestResponse: HTTPURLResponse {
    override var statusCode: Int { _statusCode }
    private var _statusCode: Int

    convenience init?(statusCode: Int = 502) {
        self.init(url: URL(string: "https://example.con")!, statusCode: statusCode, httpVersion: nil, headerFields: nil)
    }

    override init?(url: URL, statusCode: Int, httpVersion HTTPVersion: String?, headerFields: [String : String]?) {
        self._statusCode = statusCode
        super.init(url: url, statusCode: statusCode, httpVersion: HTTPVersion, headerFields: headerFields)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

final class TimeoutErrorTestResponse: HTTPURLResponse {
    override var statusCode: Int { -1001 }

    convenience init?(statusCode: Int = -1001) {
        self.init(url: URL(string: "https://example.con")!, statusCode: statusCode, httpVersion: nil, headerFields: nil)
    }

    override init?(url: URL, statusCode: Int, httpVersion HTTPVersion: String?, headerFields: [String : String]?) {
        super.init(url: url, statusCode: statusCode, httpVersion: HTTPVersion, headerFields: headerFields)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

final class UnauthorizeErrorTestResponse: HTTPURLResponse {
    override var statusCode: Int { 401 }

    convenience init?(statusCode: Int = 401) {
        self.init(url: URL(string: "https://example.con")!, statusCode: statusCode, httpVersion: nil, headerFields: nil)
    }

    override init?(url: URL, statusCode: Int, httpVersion HTTPVersion: String?, headerFields: [String : String]?) {
        super.init(url: url, statusCode: statusCode, httpVersion: HTTPVersion, headerFields: headerFields)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
