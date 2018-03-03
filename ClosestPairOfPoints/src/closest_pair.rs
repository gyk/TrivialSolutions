//! Closest Pair of 2D Points
//!
//! Based on _Algorithms, 4th Edition_ by Robert Sedgewick and Kevin Wayne. This implementation is
//! more elegant than some others, say, [the one from GeeksforGeeks][1].
//!
//! [1]: http://geeksforgeeks.org/closest-pair-of-points-onlogn-implementation/

#[derive(PartialEq, PartialOrd, Clone, Copy, Debug)]
pub struct Point {
    pub x: f32,
    pub y: f32,
}

fn distance(p1: &Point, p2: &Point) -> f32 {
    ((p1.x - p2.x).powi(2) + (p1.y - p2.y).powi(2)).sqrt()
}

// Naive quadratic algorithm
pub fn closest_pair_naive(points: &[Point]) -> f32 {
    let mut closest = ::std::f32::MAX;
    for i in 0 .. points.len() {
        for j in (i + 1) .. points.len() {
            let d = distance(&points[i], &points[j]);
            if d < closest {
                closest = d;
            }
        }
    }
    closest
}

// Divide-and-conquer algorithm
pub fn closest_pair(points: &[Point]) -> f32 {
    assert!(points.len() > 1, "Too few points");

    let mut points_x = points.to_vec();
    points_x.sort_by(|p1, p2| {
        p1.x.partial_cmp(&p2.x).expect("Cannot compare NaN")
    });

    // checks for coincident points
    for i in 0 .. (points.len() - 1) {
        if points_x[i] == points_x[i + 1] {
            return 0.0_f32;
        }
    }

    let mut points_y = points_x.clone();
    let mut aux = points_x.clone();
    // By now `points_y` has not been sorted according to Y
    closest_pair_r(&mut points_x, &mut points_y, &mut aux)
}

fn closest_pair_r(points_x: &mut [Point], points_y: &mut [Point], aux: &mut [Point]) -> f32 {
    debug_assert_eq!(points_x.len(), points_y.len());
    debug_assert_eq!(points_x.len(), aux.len());

    let mid = match points_x.len() {
        1 => return ::std::f32::MAX,
        2 => return distance(&points_x[0], &points_x[1]),
        l => l / 2,
    };

    let d_min_l = closest_pair_r(&mut points_x[..mid], &mut points_y[..mid], &mut aux[..mid]);
    let d_min_r = closest_pair_r(&mut points_x[mid..], &mut points_y[mid..], &mut aux[mid..]);
    let mut d_min = d_min_l.min(d_min_r);

    // Now `points_y[..mid]` and `points_y[mid..]` are sorted subarrays, so merges them up.
    merge(points_y, mid, aux);

    let x_mid = points_x[mid].x;
    let mut m = 0;
    for p in points_y.iter() {
        if (p.x - x_mid).abs() <= d_min {
            aux[m] = *p;
            m += 1;
        }
    }

    // The inner loop runs at most 6 times so it's O(n log n) rather than O(n^2).
    // See https://en.wikipedia.org/wiki/Closest_pair_of_points_problem.
    for i in 0 .. (m - 1) {
        for j in (i + 1) .. m {
            if aux[i].x - aux[j].x > d_min {
                break;
            }

            let d = distance(&aux[i], &aux[j]);
            if d < d_min {
                d_min = d;
            }
        }
    }

    d_min
}

// Merges two sorted subarrays into one.
//
// Precondition: `points[..mid]` and `points[mid..]` are sorted in ascending order.
fn merge(points: &mut [Point], mid: usize, aux: &mut [Point]) {
    let len = points.len();
    aux.copy_from_slice(points);
    let mut l = 0;
    let mut r = mid;
    for i in 0..len {
        if l == mid {
            points[i] = aux[r];
            r += 1;
        } else if r == len {
            points[i] = aux[l];
            l += 1;
        } else if aux[l] < aux[r] {
            points[i] = aux[l];
            l += 1;
        } else {
            points[i] = aux[r];
            r += 1;
        }
    }
}

mod tests {
    use super::*;

    use rand::thread_rng;
    use rand::distributions::{IndependentSample, Range};

    #[allow(dead_code)]
    fn random_points(n: usize) -> Vec<Point> {
        const X_MIN: f32 = 0.0_f32;
        const X_MAX: f32 = 50.0_f32;
        const Y_MIN: f32 = 1.0_f32;
        const Y_MAX: f32 = 100.0_f32;

        let mut rng = thread_rng();
        let mut points = Vec::with_capacity(n);
        let x_between = Range::new(X_MIN, X_MAX);
        let y_between = Range::new(Y_MIN, Y_MAX);
        for _ in 0..n {
            let x = x_between.ind_sample(&mut rng);
            let y = y_between.ind_sample(&mut rng);
            points.push(Point {
                x,
                y,
            });
        }

        points
    }

    #[test]
    fn smoke() {
        let points = random_points(100);

        let d_naive = closest_pair_naive(&points[..]);
        let d = closest_pair(&points[..]);

        assert_eq!(d, d_naive);
    }
}
