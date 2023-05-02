# BuckarooBanzai
### A new way to do networking in Swift. That other one is old AF.

BuckarooBanzai is based on service calls to specific API endpoints. These calls are encapsulated into objects that make it easy to reuse, modify and test additional resource paths for the same endpoint.

### Service
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

    /// create your custom initializer to add or update any properties
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
### BuckarooBanzai
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
From here you can access the body data (if any) to perform any parsing required. The `HTTPResponse` also includes a couple of convenience methods for parsing the returned data. These include a method for parsing image data into a `UIImage` object and a method to decode a json payload into a `Codable` object. For example:
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

### Service Properties
#### requestType
The `requestType` is a required property that defines the HTTP method to be used for the request. The following are defined:
```swift
case GET
case POST
case PUT
case DELETE
case HEAD
case CUSTOM(String)
```
`.CUSTOM` can be used to match a type not listed or to match a custom HTTP method that your server will handle.

#### contentType
The `contentType` is an optional property that defines what format the body of the request is using. Mainly used for methods other than `.GET`, `.DELETE`, `.HEAD` or any other HTTP method that does not contain any body data. The following are defined:
```swift
case XML
case JSON
case FORM
case CUSTOM(String)
```
When used, the following is used as the `Content-Type` header entry:
```swift
case .XML: return "application/xml"
case .JSON: return "application/json"
case .FORM: return "application/x-www-form-urlencoded"
case .CUSTOM(let customType): return customType
```
`.CUSTOM` can be used to match a type not listed or to match a custom type your server will return.

When using `.JSON` or `.FORM`, BuckarooBanzai will automatically serialize the body parameters into the correct format and attach it as the body data.

When using any other type, you must provide a `requestSerializer` conforming to the `RequestSerializer` protocol. (see below for details)

#### acceptType
The `acceptType` is a required property that defines the expected body format returned from the server. The following are defined:
```swift
case XML
case JSON
case HTML
case TEXT
case JAVASCRIPT
case ANY
case CUSTOM(String)
```
`.CUSTOM` can be used to match the custom type returned from your server.

BuckarooBanzai will check the `acceptType` against the type `Content-Type` returned in the server response header and throw an error if they do not match. With some exceptions.

For example, if the `Service` object defines the `acceptType` as `.JSON`*(application/json)* but the server responds with `Content-Type: application/json;charset=utf-8`, the return type will split the value by colons (;) and only match against the string before the first colon.

## … *work-in-progress*