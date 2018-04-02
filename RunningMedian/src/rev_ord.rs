use std::cmp::Ordering;

pub struct RevOrd<T: Ord>(pub T);

impl<T: Ord> PartialEq for RevOrd<T> {
    fn eq(&self, other:&RevOrd<T>) -> bool {
        other.0 == self.0
    }
}

impl<T: Ord> PartialOrd for RevOrd<T> where T: PartialOrd {
    fn partial_cmp(&self, other:&RevOrd<T>) -> Option<Ordering> {
        (other.0).partial_cmp(&self.0)
    }
}

impl<T: Ord> Eq for RevOrd<T> {}

impl<T: Ord> Ord for RevOrd<T> {
    fn cmp(&self, other:&RevOrd<T>) -> Ordering {
        other.0.cmp(&self.0)
    }
}
