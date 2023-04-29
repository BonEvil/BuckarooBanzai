# BuckarooBanzai
### A new way to do networking in Swift. That other one is old AF.

## Usage
BuckarooBanzai is based on service calls to API endpoints. As such, BuckarooBanzai has a concept of a `Service` protocol.

The `Service` protocol contains a number of required and optional parameters. Use this protocol to create a concrete struct or class. Here we are creating a base service to use for a specific resource endpoint.

```swift
import BuckarooBanzai

struct BaseService: Service {
    var requestType: HTTPRequestType = .GET
    var contentType: HTTPContentType?
    var acceptType: HTTPAcceptType = .JSON
    var timeout: TimeInterval = 10
    var requestURL: String = "https://httpbin.org"
    var requestBody: Data?
    var parameters: [String : Any]?
    var additionalHeaders: [String : String]?
    var requestSerializer: RequestSerializer?
    var sessionDelegate: URLSessionTaskDelegate?
    var testResponse: HTTPResponse?

    init(withPath path: String, serviceParams: [AnyHashable: Any]? = nil) {
        requestURL = requestURL + path
        if let serviceParams = serviceParams {
            self.parameters = serviceParams
        }
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
## … *work-in-progress*