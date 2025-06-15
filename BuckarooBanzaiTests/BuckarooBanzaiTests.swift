import XCTest
@testable import BuckarooBanzai
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

final class BuckarooBanzaiTests: XCTestCase {

    struct Person: Codable, Equatable {
        let name: String
        let age: Int
    }

    struct DummyService: Service {
        var requestMethod: HTTPRequestMethod = .GET
        var acceptType: HTTPAcceptType = .JSON
        var timeout: TimeInterval = 1
        var requestURL: String = "https://example.com"
        var contentType: HTTPContentType?
        var requestBody: Data?
        var parameters: [AnyHashable: Any]?
        var additionalHeaders: [AnyHashable: Any]?
        var requestSerializer: RequestSerializer?
        var sessionDelegate: URLSessionTaskDelegate?
        var testResponse: HTTPResponse?
    }

    func testJSONRequestSerializerSuccess() throws {
        let params: [String: Any] = ["name": "Dan", "age": 40]
        let data = try JSONRequestSerializer().serialize(params)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        XCTAssertEqual(json?["name"] as? String, "Dan")
        XCTAssertEqual(json?["age"] as? Int, 40)
    }

    func testJSONRequestSerializerFailure() {
        let invalidObject = Date()
        XCTAssertThrowsError(try JSONRequestSerializer().serialize(invalidObject))
    }

    func testFormRequestSerializer() throws {
        let params: [String: Any] = ["name": "John Doe", "age": 22]
        let data = try FormRequestSerializer().serialize(params)
        let body = String(data: data, encoding: .utf8)
        XCTAssertTrue(body?.contains("name=John%20Doe") == true)
        XCTAssertTrue(body?.contains("age=22") == true)
    }

    func testDecodeBodyData() throws {
        let person = Person(name: "Jane", age: 30)
        let data = try JSONEncoder().encode(person)
        let response = HTTPResponse(statusCode: 200, headers: ["Content-Type": "application/json"], body: data)
        let decoded: Person = try response.decodeBodyData()
        XCTAssertEqual(decoded, person)
    }

#if canImport(UIKit)
    func testDecodeBodyDataAsImage() throws {
        let base64 = "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/wwAAgMBAf8CwaoAAAAASUVORK5CYII="
        let data = Data(base64Encoded: base64)!
        let response = HTTPResponse(statusCode: 200, headers: ["Content-Type": "image/png"], body: data)
        let image = try response.decodeBodyDataAsImage()
        XCTAssertNotNil(image.cgImage)
    }
#endif

    func testStartServiceWithTestResponse() async throws {
        let expected = HTTPResponse(statusCode: 200, headers: ["Content-Type": "application/json"], body: nil)
        var service = DummyService()
        service.testResponse = expected
        let response = try await BuckarooBanzai.shared.start(service: service)
        XCTAssertEqual(response.statusCode, 200)
    }
}
