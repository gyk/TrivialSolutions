// First Missing Positive (https://leetcode.com/problems/first-missing-positive/)

class Solution {
    func firstMissingPositive(_ nums: [Int]) -> Int {
        let n = nums.count
        var a = (0 ... (n + 1)).map { _ in false }
        nums.filter { $0 > 0 && $0 <= n }.forEach { a[$0] = true }
        return a.dropFirst().firstIndex(of: false)!
    }
}
