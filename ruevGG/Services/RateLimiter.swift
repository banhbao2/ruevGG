import Foundation

actor RateLimiter {
    private var shortTermTokens: Int
    private var longTermTokens: Int
    private var lastShortRefill: Date
    private var lastLongRefill: Date
    
    private let shortTermLimit = 20
    private let shortTermWindow: TimeInterval = 1.0
    private let longTermLimit = 100
    private let longTermWindow: TimeInterval = 120.0
    
    init() {
        self.shortTermTokens = shortTermLimit
        self.longTermTokens = longTermLimit
        self.lastShortRefill = Date()
        self.lastLongRefill = Date()
    }
    
    func waitForToken() async {
        while true {
            refillTokens()
            
            if shortTermTokens > 0 && longTermTokens > 0 {
                shortTermTokens -= 1
                longTermTokens -= 1
                return
            }
            
            let shortWait = shortTermTokens <= 0 ? shortTermWindow - Date().timeIntervalSince(lastShortRefill) : 0
            let longWait = longTermTokens <= 0 ? longTermWindow - Date().timeIntervalSince(lastLongRefill) : 0
            let waitTime = max(shortWait, longWait, 0.05)
            
            try? await Task.sleep(nanoseconds: UInt64(waitTime * 1_000_000_000))
        }
    }
    
    private func refillTokens() {
        let now = Date()
        
        if now.timeIntervalSince(lastShortRefill) >= shortTermWindow {
            shortTermTokens = shortTermLimit
            lastShortRefill = now
        }
        
        if now.timeIntervalSince(lastLongRefill) >= longTermWindow {
            longTermTokens = longTermLimit
            lastLongRefill = now
        }
    }
}
