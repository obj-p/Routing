import Routing

let router = Routing()

router.add("/route/one/:id") { (parameters: [String : String]) in }

router.open(NSURL(string: "/route/one/1")!)
router.open(NSURL(string: "/unsupported/route")!)
