//
//  RxMoya+Extension.swift
//  AwesomeBlogs
//
//  Created by wade.hawk on 2017. 7. 31..
//  Copyright © 2017년 wade.hawk. All rights reserved.
//

import Foundation
import RxSwift
import Moya
import SwiftyJSON

func JSONResponseDataFormatter(_ data: Data) -> Data {
    do {
        let dataAsJSON = try JSONSerialization.jsonObject(with: data)
        let prettyData =  try JSONSerialization.data(withJSONObject: dataAsJSON, options: .prettyPrinted)
        return prettyData
    } catch {
        return data // fallback to original data if it can't be serialized.
    }
}

extension MoyaProviderType {
    func singleRequest(_ token: Target, callbackQueue: DispatchQueue? = nil) -> Single<JSON> {
        return Single<JSON>.create { single in
            let cancellableToken = self.request(token, callbackQueue: callbackQueue, progress: nil) { result in
                switch result {
                case let .success(response):
                    do {
                        let json = try JSON(data: response.data)
                        single(.success(json))
                    }catch {
                        single(.error(RxError.unknown))
                    }
                case let .failure(error):
                    single(.error(error))
                }
            }
            return Disposables.create {
                cancellableToken.cancel()
            }
        }
    }
}
