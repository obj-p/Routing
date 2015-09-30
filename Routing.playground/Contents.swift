import UIKit

NSURLComponents(URL: NSURL(string:"http://google/api/v1")!, resolvingAgainstBaseURL: false)
    .map { "/" + ($0.host ?? "") + ($0.path ?? "") }
