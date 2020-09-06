// Jump Game (https://leetcode.com/problems/jump-game/submissions/)

class Solution {
    func canJump(_ nums: [Int]) -> Bool {
        let n = nums.count
        var m = 0
        for i in 0 ..< n where i <= m {
            m = max(m, i + nums[i])
        }
        return m >= n - 1
    }
}
