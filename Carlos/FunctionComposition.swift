import Foundation

// Expose later on when the library is more async-computation oriented
/**
Composes two sync closures

- parameter f: A closure taking an A parameter and returning an Optional<B>
- parameter g: A closure taking a B parameter and returning an Optional<C>

- returns: A closure taking an A parameter and returning an Optional<C> obtained by combining f and g in a way similar to g(f(x))
*/
internal func >>> <A, B, C>(f: A -> B?, g: B -> C?) -> A -> C? {
  return { x in
    if let fx = f(x) {
      return g(fx)
    } else {
      return nil
    }
  }
}

// Expose later when transformers will to be async and caches will be chainable in a similar way
/**
Composes two async (Future) closures

- parameter f: A closure taking an A parameter and returning a Future<B> (basically a future for a B return type)
- parameter g: A closure taking a B parameter and returning a Future<C> (basically a future for a C return type)

- returns: A closure taking an A parameter and returning a Future<C> (basically a future for a C return type) obtained by combining f and g in a way similar to g(f(x)) (if the closures were sync)
*/
internal func >>> <A, B, C>(f: A -> Future<B>, g: B -> Future<C>) -> A -> Future<C> {
  return { param in
    let resultingRequest = Promise<C>()
    
    f(param)
      .onSuccess { result in
        g(result)
          .onSuccess(resultingRequest.succeed)
          .onFailure(resultingRequest.fail)
          .onCancel(resultingRequest.cancel)
      }
      .onCancel(resultingRequest.cancel)
      .onFailure(resultingRequest.fail)
    
    return resultingRequest.future
  }
}

// Expose later if needed with async transformers
/**
Composes two async closures

- parameter f: A closure taking an A parameter and a completion callback taking an Optional<B> and returning Void
- parameter g: A closure taking a B parameter and a completion callback taking an Optional<C> and returning Void

- returns: A closure taking an A parameter and a completion callback taking an Optional<C> and returning Void obtained by combining f and g in a way similar to g(f(x)) (if the closures were sync)
*/
internal func >>> <A, B, C>(f: (A, B? -> Void) -> Void, g: (B, C? -> Void) -> Void) -> (A, C? -> Void) -> Void {
  return { x, completion in
    f(x) { fx in
      if let fx = fx {
        g(fx) { result in
          completion(result)
        }
      } else {
        completion(nil)
      }
    }
  }
}
