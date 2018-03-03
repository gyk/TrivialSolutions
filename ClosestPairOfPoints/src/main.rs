extern crate rand;

mod closest_pair;

use std::io::{BufRead, stdin};

use closest_pair::*;

fn main() {
    let mut points = Vec::new();
    let stdin = stdin();
    for line in stdin.lock().lines() {
        let inputs = line
            .expect("Invalid line")
            .split(' ')
            .map(|x| x.parse::<f32>().unwrap())
            .collect::<Vec<_>>();

        let x = inputs[0];
        let y = inputs[1];

        points.push(Point {
            x,
            y,
        });
    }

    let d_naive = closest_pair_naive(&points[..]);
    let d = closest_pair(&points[..]);

    assert_eq!(d, d_naive);
    println!("The distance between the closest pair of points is {:.3}", d);
}
