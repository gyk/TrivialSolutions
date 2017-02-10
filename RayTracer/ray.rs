
// Ray tracer based on (a.k.a. line-by-line translated from) Jon Harrop's implementation, 
// the "Minimal" version.
// Just for learning a little bit Rust.
// 
// How to run:
//     rustc ray.rs
//     ./ray > ray.pgm

// TODO: Need refactoring as soon as all C++ projects have been rewritten in Rust.

use std::ops::{Add, Mul, Sub};

const INFINITY: f32 = std::f32::INFINITY;

// TODO: Is implementing Copy trait inefficient if the compiler does not 
// optimize it as passing-by-reference?
#[derive(Copy, Clone, Debug)]
struct Vec3 {
    x: f32,
    y: f32,
    z: f32,
}

impl Vec3 {
    fn new(x: f32, y: f32, z: f32) -> Vec3 {
        Vec3 {
            x: x,
            y: y,
            z: z,
        }
    }

    fn dot(a: &Vec3, b: &Vec3) -> f32 {
        a.x * b.x + a.y * b.y + a.z * b.z
    }

    fn length(&self) -> f32 {
        Vec3::dot(self, self).sqrt()
    }

    fn normalize(&mut self) {
        let len = self.length();
        let one_over_len = 1.0 / len;
        self.x *= one_over_len;
        self.y *= one_over_len;
        self.z *= one_over_len;
    }
}

// Operator overloading ###{

impl Add for Vec3 {
    type Output = Vec3;

    fn add(self, other: Vec3) -> Vec3 {
        Vec3 {
            x: self.x + other.x,
            y: self.y + other.y,
            z: self.z + other.z,
        }
    }
}

impl Sub for Vec3 {
    type Output = Vec3;

    fn sub(self, other: Vec3) -> Vec3 {
        Vec3 {
            x: self.x - other.x,
            y: self.y - other.y,
            z: self.z - other.z,
        }
    }
}

impl Mul<f32> for Vec3 {
    type Output = Vec3;

    fn mul(self, f: f32) -> Vec3 {
        Vec3 {
            x: self.x * f,
            y: self.y * f,
            z: self.z * f,
        }
    }
}

impl Mul<Vec3> for f32 {
    type Output = Vec3;

    fn mul(self, v: Vec3) -> Vec3 {
        Vec3 {
            x: self * v.x,
            y: self * v.y,
            z: self * v.z,
        }
    }
}

// }### Operator overloading

#[derive(Clone, Debug)]
struct Hit {
    dist: f32,
    norm: Vec3,
}

#[derive(Debug)]
struct Ray {
    orig: Vec3,
    dir: Vec3,
}

trait Scene {
    fn intersect(&self, hit: Hit, ray: &Ray) -> Hit;
}

#[derive(Debug)]
struct Sphere {
    center: Vec3,
    radius: f32,
}

impl Sphere {
    fn ray_sphere(&self, ray: &Ray) -> f32 {
        let v = self.center - ray.orig;
        let b = Vec3::dot(&v, &ray.dir);
        let disc = b * b - Vec3::dot(&v, &v) + self.radius * self.radius;
        if disc < 0.0 {
            INFINITY
        } else {
            let d = disc.sqrt();
            let t2 = b + d;
            if t2 < 0.0 {
                INFINITY
            } else {
                let t1 = b - d;
                if t1 > 0.0 { t1 } else { t2 }
            }
        }
    }
}   

impl Scene for Sphere {
    fn intersect(&self, hit: Hit, ray: &Ray) -> Hit {
        let dist = self.ray_sphere(ray);
        if dist > hit.dist {
            hit
        } else {
            let mut dir = ray.orig + (dist * ray.dir - self.center);
            dir.normalize();
            Hit {
                dist: dist,
                norm: dir,
            }
        }
    }
}

struct Group {
    bound: Sphere,
    scenes: Vec<Box<Scene>>,
}

impl Scene for Group {
    fn intersect(&self, hit: Hit, ray: &Ray) -> Hit {
        let dist = self.bound.ray_sphere(ray);
        if dist >= hit.dist {
            hit
        } else {
            self.scenes
                .iter()
                .fold(hit, |h, scene| scene.intersect(h, ray))
        }
    }
}

fn ray_trace(light: &Vec3, ray: &Ray, scene: &Scene) -> f32 {
    let hit0 = Hit {
        dist: INFINITY,
        norm: Vec3::new(0.0, 0.0, 0.0),
    };

    let hit = scene.intersect(hit0.clone(), ray);
    if hit.dist == INFINITY {
        return 0.0;
    }

    let g = Vec3::dot(&hit.norm, &light);
    if g > 0.0 {
        return 0.0;
    }

    let p = ray.orig + hit.dist * ray.dir + std::f32::EPSILON.sqrt() * hit.norm;
    if scene.intersect(hit0,
        &Ray {
            orig: p,
            dir: -1.0 * (*light),
        }).dist < INFINITY {
        0.0
    } else {
        -g
    }
}

fn create_scene(level: i32, c: Vec3, r: f32) -> Box<Scene> {
    let s = Sphere { center: c, radius: r };

    if level == 1 {
        return Box::new(s);
    } else {
        let mut scenes: Vec<Box<Scene>> = Vec::new();
        scenes.push(Box::new(s));
        let rn = r * 3.0 / (12.0f32.sqrt());

        // WTF? No by-value iterator for array?
        for dz in vec![-1, 1] {
            for dx in vec![-1, 1] {
                let v = Vec3::new(dx as f32, 1.0, dz as f32);
                scenes.push(create_scene(level - 1, c + rn * v, r / 2.0));
            }
        }
        return Box::new(
            Group {
                bound: Sphere { center: c, radius: r * 3.0 },
                scenes: scenes,
            });
    }
}

fn main() {
    let level = 6;
    let n: i32 = 512;
    let ss: i32 = 4;

    let ss2 = (ss * ss) as f32;

    let mut light = Vec3 { x: -1.0, y: -3.0, z: 2.0 };
    light.normalize();
    let s = create_scene(level, Vec3 { x: 0.0, y: -1.0, z: 0.0 }, 1.0);
    println!("P2\n{} {}\n255\n", n, n);  // Today it's quite hard to find a proper P5 PGM viewer
    for y in (0 .. n).rev() {
        let y = y as f32;  // So ugly. SAD!
        for x in 0 .. n {
            let x = x as f32;
            let mut g = 0.0;
            for dx in 0 .. ss {
                let dx = dx as f32;
                for dy in 0 .. ss {
                    let dy = dy as f32;
                    let mut dir = Vec3::new(
                        x + dx / ss as f32 - n as f32 / 2.0,
                        y + dy / ss as f32 - n as f32 / 2.0,
                        n as f32);
                    dir.normalize();
                    g += ray_trace(&light,
                        &Ray {
                            orig: Vec3 { x: 0.0, y: 0.0, z: -4.0 },
                            dir: dir,
                        },
                        &*s);  // Even more SAD!
                }
            }
            
            print!("{} ", (0.5 + 255.0 * g / ss2) as u8);
        }
        println!("");
    }
}
