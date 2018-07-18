pub mod hyperloglog;

#[cfg(test)]
mod tests {
    #[test]
    fn smoke() {
        use std::collections::hash_map::RandomState;

        use hyperloglog::HyperLogLog;

        let mut hll = HyperLogLog::new(7, RandomState::new());
        const N: usize = 10000;
        for i in 0..N {
            hll.add(&i);
        }
        println!("N = {}, #HyperLogLog = {}", N, hll.count());
    }

    // FIXME: The code is probably buggy. More tests and benchmarks are required.
}
