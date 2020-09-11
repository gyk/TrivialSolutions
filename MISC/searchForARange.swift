// Search for a Range (a.k.a. Find First and Last Position of Element in Sorted Array)
//
// https://leetcode.com/problems/find-first-and-last-position-of-element-in-sorted-array/

class Solution {
    func searchRange(_ a: [Int], _ x: Int) -> [Int] {
        func go(_ lt: (Int, Int) -> Bool) -> Int {
            var l = 0, r = a.count
            while (l < r) {
                let m = l + (r - l) / 2
                if lt(x, a[m]) {
                    r = m
                } else {
                    l = m + 1
                }
            }
            return l
        }

        let lower = go((<=)), upper = go((<)) - 1
        return lower <= upper ? [lower, upper] : [-1, -1]
    }
}
