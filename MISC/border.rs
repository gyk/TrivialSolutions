// SGU 133 - Border

fn solve(mut ab: Vec<(usize, usize)>) -> usize {
    ab.sort();
    let mut count = 0;
    let mut r = ab[0].1;
    for i in 0..ab.len() {
        if ab[i].1 < r {
            count += 1;
        } else {
            r = ab[i].1;
        }
    }
    count
}

// IO code removed for brevity.
