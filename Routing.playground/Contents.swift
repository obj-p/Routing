import UIKit

let string = NSURLComponents(URL: NSURL(string:"http://google/api/:id/:foo")!, resolvingAgainstBaseURL: false)
    .map { "/" + ($0.host ?? "") + ($0.path ?? "") }
    ?? ""

let route = "/route/one/:id/:foo"
var regex = "^\(route)/?$"

let parameters = (try? NSRegularExpression(pattern: ":[a-zA-Z0-9-_]+", options: .CaseInsensitive))
    .map { $0.matchesInString(regex, options: [], range: NSMakeRange(0, regex.characters.count)) }?
    .map { $0.range }
    .map { (regex as NSString).substringWithRange($0) }


