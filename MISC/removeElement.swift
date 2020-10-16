// Remove Element (https://leetcode.com/problems/remove-element/)
class Solution {
    func removeElement(_ nums: inout [Int], _ val: Int) -> Int {
        var i = 0
        for j in 0 ..< nums.count {
            if nums[j] == val {
                continue
            }
            nums[i] = nums[j]
            i += 1
        }
        return i
    }
}
