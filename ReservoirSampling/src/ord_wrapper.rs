use std::cmp::Ordering;

pub struct OrdWrapper<T> {
    pub key: f32,
    pub value: T,
}

impl<T> PartialEq for OrdWrapper<T> {
    fn eq(&self, other:&OrdWrapper<T>) -> bool {
        self.key == other.key
    }
}

impl<T> PartialOrd for OrdWrapper<T> {
    fn partial_cmp(&self, other:&OrdWrapper<T>) -> Option<Ordering> {
        (self.key).partial_cmp(&other.key)
    }
}

impl<T> Eq for OrdWrapper<T> {}

impl<T> Ord for OrdWrapper<T> {
    fn cmp(&self, other:&OrdWrapper<T>) -> Ordering {
        self.key.partial_cmp(&other.key).expect("Unexpected NaN")
    }
}
