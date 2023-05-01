# BuckarooBanzai
### A new way to do networking in Swift. That other one is old AF.

## Usage
BuckarooBanzai is based on service calls to API endpoints. As such, BuckarooBanzai has a concept of a `Service` protocol.

The `Service` protocol contains a number of required and optional parameters. Use this protocol to create a concrete struct or class. Here we are creating a base service to use for a specific resource domain.

```swift
import BuckarooBanzai

struct BaseService: Service {
    var requestType: HTTPRequestType = .GET
    var contentType: HTTPContentType?
    var acceptType: HTTPAcceptType = .JSON
    var timeout: TimeInterval = 10
    var requestURL: String = "https://httpbin.org"
    var requestBody: Data?
    var parameters: [AnyHashable: Any]?
    var additionalHeaders: [AnyHashable: Any]?
    var requestSerializer: RequestSerializer?
    var sessionDelegate: URLSessionTaskDelegate?
    var testResponse: HTTPResponse?

    init(withPath path: String, serviceParams: [AnyHashable: Any]? = nil) {
        requestURL = requestURL + path
        self.parameters = serviceParams
    }
}
```
Then you can create a service like the following:
```swift
let service = BaseService(withPath: "/get")
```
BuckarooBanzai is a singleton and uses concurrency. You can then use the `service` like this:
```swift
Task {
    do {
        let response = try await BuckarooBanzai.sharedInstance().start(service: service)
        /// do something with response
    } catch let error as BBError {
        print("ERROR: \(error)")
    }
}
```

### HTTPResponse
A successful `start(service:)` call will return an `HTTPResponse` object. This object contains properties of the service response.
```swift
public var statusCode: Int
public var headers: [AnyHashable: Any]
public var body: Data?
```
From here you can access the body data (if any) to perform any parsing required. The `HTTPResponse` also includes a couple convenience methods for parsing the returned data. These include a method for parsing image data into a `UIImage` object and a method to decode a json payload into a generic object. For example:
```swift
/// Decode body data into image
let webImage = try response.decodeBodyDataAsImage()

/// Decode into a custom object
let myObject: MyObject = try response.decodeBodyData()
```
Both of these methods throw so you can keep them inline with the `response` object.
```swift
do {
    let response = try await BuckarooBanzai.sharedInstance().start(service: service)
    let webImage = try response.decodeBodyDataAsImage()
    /// do something with image
} catch {
    print("ERROR: \(error)")
}
```

## … *work-in-progress*