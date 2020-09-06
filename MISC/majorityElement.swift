// Majority Element (https://leetcode.com/problems/majority-element/)

class SolutionI {
    func majorityElement(_ nums: [Int]) -> Int {
        var (m, c) = (0, 0)
        for x in nums {
            if c == 0 {
                (m, c) = (x, 1)
            } else {
                c += x == m ? 1 : -1
            }
        }
        return m
    }
}

// Majority Element II (https://leetcode.com/problems/majority-element-ii/)

class SolutionII {
    func majorityElement(_ nums: [Int]) -> [Int] {
        var (m1, c1) = (0, 0)
        var (m2, c2) = (0, 0)
        for x in nums {
            if c1 != 0 && x == m1 {
                c1 += 1
                continue
            } else if c2 != 0 && x == m2 {
                c2 += 1
                continue
            }

            if c1 == 0 {
                (m1, c1) = (x, 1)
            } else if c2 == 0 {
                (m2, c2) = (x, 1)
            } else {
                c1 -= 1
                c2 -= 1
            }
        }

        let n1 = c1 > 0 ? m1 : nil
        let n2 = c2 > 0 ? m2 : nil
        c1 = 0
        c2 = 0

        for x in nums {
            if let n = n1, x == n {
                c1 += 1
            } else if let n = n2, x == n {
                c2 += 1
            }
        }

        var ret = [Int]()
        let threshold = nums.count / 3
        if c1 > threshold {
            ret.append(n1!)
        }
        if c2 > threshold {
            ret.append(n2!)
        }
        return ret
    }
}

// Uses Dictionary
class SolutionII_Dict {
    func majorityElement(_ nums: [Int]) -> [Int] {
        var m = [Int:Int]()
        for x in nums {
            if let c = m[x] {
                m[x] = c + 1
            } else if m.count == 2 {
                for (k, v) in m {
                    let vNew = v - 1
                    if vNew == 0 {
                        m[k] = nil
                    } else {
                        m[k] = vNew
                    }
                }
            } else {
                m[x] = 1
            }
        }

        var candidates = m.mapValues { _ in 0 }
        for x in nums {
            if let c = candidates[x] {
                candidates[x] = c + 1
            }
        }

        return candidates
            .filter { $0.1 > nums.count / 3 }
            .map { $0.0 }
    }
}
