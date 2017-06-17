//! Find the nth [Regular Number](https://en.wikipedia.org/wiki/Regular_number).
use std::collections::VecDeque;

// Poor man's HashMap
fn at(i: u64) -> usize {
    ((i - 1) / 2) as usize
}

fn reg_num(mut n: u64) -> u64 {
    let u235 = vec![2, 3, 5];
    let mut q = u235.iter()
        .map(|&p| VecDeque::from(vec![p]))
        .collect::<Vec<_>>();

    n -= 1; // The first one is 1
    loop {
        let (min_i, m) = u235.iter()
            .fold((100, u64::max_value()), |(min_i, m), &i| {
                match q[at(i)].front() {
                    None => (min_i, m),
                    Some(&p) => if p < m { (i, p) } else { (min_i, m) },
                }
            });

        q[at(min_i)].pop_front();
        n -= 1;
        if n == 0 {
            return m;
        }
        
        for &i in u235.iter() {
            // The number only needs to be pushed to the queues with greater indices, e.g., for $s =
            // 2^x * 3^y$ popped from q[3], we do not push $s * 2$ to q[2] because we have $t =
            // 2^(x+1) * 3^(y-1)$ which is less than $s$ and has already been pushed to q[3] as $t *
            // 3 = 2^(x+1) * 3^y$.
            if i >= min_i {
                q[at(i)].push_back(m * i);
            }
        }
    }
}

fn main() {
    let n = 1500;
    println!("reg_num #{} = {}", n, reg_num(1500));
}
