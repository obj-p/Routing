import Foundation

let components = NSURLComponents(URL: NSURL(string:"http://google/api/:id/:foo?bar=1&baz=2")!, resolvingAgainstBaseURL: false)

let string = components
    .map { "/" + ($0.host ?? "") + ($0.path ?? "") }
    ?? ""

let queryItems = components
    .map { $0.queryItems }?
    .flatMap { $0 }?
    .reduce([String : String?]()) { (var dict, query) in
        dict.updateValue(query.value, forKey: query.name)
        return dict
}

print(queryItems)

let route = "/route/one/:id/:foo"
var regex: String! = "^\(route)/?$"

func matchResults(string: String, regex: String) -> [NSTextCheckingResult]? {
    return (try? NSRegularExpression(pattern: regex, options: .CaseInsensitive))
        .map { $0.matchesInString(string, options: [], range: NSMakeRange(0, string.characters.count)) }
}

let parameters = matchResults(regex, regex: ":[a-zA-Z0-9-_]+")?
    .map { $0.range }
    .map { (regex as NSString).substringWithRange($0) }

let keys = parameters?
    .map { $0.stringByReplacingOccurrencesOfString(":", withString: "") }

regex = parameters?
    .reduce(regex) { $0.stringByReplacingOccurrencesOfString($1, withString: "([^/]+)") }

let patterns: (String?, [String]?)? = (regex, keys)

let aRoute = "/route/one/1234/5678"
let match = patterns?.0
    .map { matchResults(aRoute, regex: $0)?.first }?
    .flatMap { $0 }

var p: [String : String] = [:]
if let m = match, let k = patterns?.1  {
    for i in 1 ..< m.numberOfRanges where k.count == m.numberOfRanges - 1 {
        p.updateValue((aRoute as NSString).substringWithRange(match!.rangeAtIndex(i)), forKey: k[i-1])
    }
}

print(p)
