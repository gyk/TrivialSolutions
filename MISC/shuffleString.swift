// Shuffle String (https://leetcode.com/problems/shuffle-string/)
class Solution {
    func restoreString(_ s: String, _ indices: [Int]) -> String {
        var chars = Array(s)
        for (ch, i) in zip(s, indices) {
            chars[i] = ch
        }
        return String(chars)
    }
}
