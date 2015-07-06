//
//  NetworkFetcher.swift
//  CarlosSample
//
//  Created by Monaco, Vittorio on 03/07/15.
//  Copyright (c) 2015 WeltN24. All rights reserved.
//

import Foundation

/// This class is a network cache level, mostly acting as a fetcher (meaning that calls to the set method won't have any effect). It internally uses NSURLSession to retrieve values from the internet
public class NetworkFetcher: CacheLevel {
  //TODO: Improve implementation
  private class Request {
    let URL : NSURL
    
    var session : NSURLSession {
      return NSURLSession.sharedSession()
    }
    
    var task : NSURLSessionDataTask? = nil
    
    init(URL: NSURL, success succeed : (NSData) -> (), failure fail : ((NSError?) -> ())) {
      self.URL = URL
      self.task = session.dataTaskWithURL(URL) {[weak self] (data, response, error) in
        if let strongSelf = self {
          strongSelf.onReceiveData(data, response: response, error: error, failure: fail, success: succeed)
        }
      }
      task?.resume()
    }
    
    private func validate(response: NSHTTPURLResponse, withData data: NSData) -> Bool {
      let expectedContentLength = response.expectedContentLength
      if (expectedContentLength > -1) {
        let dataLength = data.length
        return Int64(dataLength) >= expectedContentLength
      }
      return true
    }
    
    private func onReceiveData(data : NSData!, response : NSURLResponse!, error : NSError!, failure fail : ((NSError?) -> ()), success succeed : (NSData) -> ()) {
      let URL = self.URL
      
      if let error = error {
        if error.domain == NSURLErrorDomain && error.code == NSURLErrorCancelled {
          return
        }
        
        dispatch_async(dispatch_get_main_queue(), { fail(error) })
        return
      }
      
      // Intentionally avoiding `if let` to continue in golden path style.
      let httpResponse = response as! NSHTTPURLResponse
      if httpResponse.statusCode != 200 {
        failWithCode(10, failure: fail)
        return
      }
      
      if !validate(httpResponse, withData: data) {
        failWithCode(9, failure: fail)
        return
      }
      
      let value = data
      if value == nil {
        failWithCode(11, failure: fail)
        return
      }
      
      dispatch_async(dispatch_get_main_queue()) { succeed(value) }
    }
    
    private func failWithCode(code: Int, failure fail : ((NSError?) -> ())) {
      let error = NSError(domain: "Carlos", code: code, userInfo: nil)
      dispatch_async(dispatch_get_main_queue()) { fail(error) }
    }
  }
  
  private var pendingRequests: [String: Request] = [:]
  
  public init() {}
  
  public func onMemoryWarning() {}
  
  public func get(fetchable: FetchableType, onSuccess success: (NSData) -> Void, onFailure failure: (NSError?) -> Void) {
    let request = Request(URL: NSURL(string: fetchable.fetchableKey)!, success: { data in
      Logger.log("Fetched \(fetchable.fetchableKey) from the network fetcher")
      success(data)
      self.pendingRequests[fetchable.fetchableKey] = nil
    }, failure: { error in
      Logger.log("Failed fetching \(fetchable.fetchableKey) from the network fetcher")
      failure(error)
      self.pendingRequests[fetchable.fetchableKey] = nil
    })
    
    pendingRequests[fetchable.fetchableKey] = request
  }
  
  public func set(value: NSData, forKey fetchable: FetchableType) {}
  
  public func clear() {}
}