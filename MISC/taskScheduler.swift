// Task Scheduler (https://leetcode.com/problems/task-scheduler/)

// If the number of task types is larger than `n + 1` (after merging task types with `maxCount`
// tasks), there are two cases to consider:
//
// 1. The vacancies in slots `[0 ..< ((n + 1) * (maxCount - 1))]` exceeds the number of remaining
//    tasks. Then we can arrange the tasks to make sure they fulfill the cooldown constriait. This
//    is because the tasks are sorted descendingly, the counts of tasks for each remaining task
//    types are smaller than `maxCount - 1`, so there will be no conflict.
//
// 2. Otherwise, the total number of units of time is bounded by task count instead of `(n + 1) *
//    (maxCount - 1)`. Inserting new tasks into the existing queue will not violates the cooldown
//    constrait.

class Solution {
    func leastInterval(_ tasks: [Character], _ n: Int) -> Int {
        guard n > 0 else { return tasks.count }

        var freq = [Character : Int]()
        for t in tasks {
            freq[t, default: 0] += 1
        }
        let freqSorted = freq.sorted { $0.1 > $1.1 }
        let maxCount = freqSorted.first!.1
        let c = freqSorted.filter { $0.1 == maxCount }.count
        return max(tasks.count, (n + 1) * (maxCount - 1) + c)
    }
}
