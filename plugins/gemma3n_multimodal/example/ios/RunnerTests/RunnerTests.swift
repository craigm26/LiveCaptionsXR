import Flutter
import UIKit
import XCTest

@testable import gemma3n_multimodal

// This demonstrates a simple unit test of the Swift portion of this plugin's implementation.
//
// See https://developer.apple.com/documentation/xctest for more information about using XCTest.

class RunnerTests: XCTestCase {

  func testGetPlatformVersion() {
    let plugin = Gemma3nMultimodalPlugin()

    let call = FlutterMethodCall(methodName: "getPlatformVersion", arguments: [])

    let resultExpectation = expectation(description: "result block must be called.")
    plugin.handle(call) { result in
      XCTAssertEqual(result as! String, "iOS " + UIDevice.current.systemVersion)
      resultExpectation.fulfill()
    }
    waitForExpectations(timeout: 1)
  }

  func testIsModelLoadedInitialState() {
    let plugin = Gemma3nMultimodalPlugin()
    
    let call = FlutterMethodCall(methodName: "isModelLoaded", arguments: nil)
    
    let resultExpectation = expectation(description: "result block must be called.")
    plugin.handle(call) { result in
      XCTAssertEqual(result as! Bool, false)
      resultExpectation.fulfill()
    }
    waitForExpectations(timeout: 1)
  }

  func testGetBundleModelPaths() {
    let plugin = Gemma3nMultimodalPlugin()
    
    let call = FlutterMethodCall(methodName: "getBundleModelPaths", arguments: nil)
    
    let resultExpectation = expectation(description: "result block must be called.")
    plugin.handle(call) { result in
      let resultDict = result as! [String: Any]
      XCTAssertNotNil(resultDict["bundleModels"])
      XCTAssertNotNil(resultDict["bundlePath"])
      XCTAssertTrue(resultDict["bundleModels"] is [String])
      resultExpectation.fulfill()
    }
    waitForExpectations(timeout: 1)
  }

  func testGetModelInfoWhenNotLoaded() {
    let plugin = Gemma3nMultimodalPlugin()
    
    let call = FlutterMethodCall(methodName: "getModelInfo", arguments: nil)
    
    let resultExpectation = expectation(description: "result block must be called.")
    plugin.handle(call) { result in
      let resultDict = result as! [String: Any]
      XCTAssertEqual(resultDict["isLoaded"] as! Bool, false)
      resultExpectation.fulfill()
    }
    waitForExpectations(timeout: 1)
  }

  func testLoadModelWithInvalidPath() {
    let plugin = Gemma3nMultimodalPlugin()
    
    let call = FlutterMethodCall(methodName: "loadModel", arguments: [
      "path": "nonexistent_model.task"
    ])
    
    let resultExpectation = expectation(description: "result block must be called.")
    plugin.handle(call) { result in
      XCTAssertTrue(result is FlutterError)
      let error = result as! FlutterError
      XCTAssertEqual(error.code, "MODEL_NOT_FOUND")
      resultExpectation.fulfill()
    }
    waitForExpectations(timeout: 1)
  }

  func testLoadModelWithMissingArguments() {
    let plugin = Gemma3nMultimodalPlugin()
    
    let call = FlutterMethodCall(methodName: "loadModel", arguments: [:])
    
    let resultExpectation = expectation(description: "result block must be called.")
    plugin.handle(call) { result in
      XCTAssertTrue(result is FlutterError)
      let error = result as! FlutterError
      XCTAssertEqual(error.code, "INVALID_ARGUMENT")
      resultExpectation.fulfill()
    }
    waitForExpectations(timeout: 1) 
  }

  func testUnloadModel() {
    let plugin = Gemma3nMultimodalPlugin()
    
    let call = FlutterMethodCall(methodName: "unloadModel", arguments: nil)
    
    let resultExpectation = expectation(description: "result block must be called.")
    plugin.handle(call) { result in
      XCTAssertNil(result)  // Should return nil on success
      resultExpectation.fulfill()
    }
    waitForExpectations(timeout: 1)
  }

}
