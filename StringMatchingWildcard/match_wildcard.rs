
// The reason we don't need backtracking:
//
// Splitting the pattern into units of (wildcard, plain-string) pair, e.g., Pattern: "S*A*B*" ->
// ["S", "*A", "*B", "*"], for string "SXAYAZB", we can see that it doesn't matter whether the 1st
// "*" matches "X" or "XAY", because as soon as the 2nd "*" is reached, it will match either "YAZ"
// or "Z" and neutralize the difference.

// This algorithm is inefficient, especially if the pattern is expected to be used repeatedly, but
// could be suitable when preprocessing doesn't make much sense.

const MANY: u8 = '*' as u8;
const ANY: u8 = '?' as u8;

pub fn match_wildcard(s: &[u8], p: &[u8]) -> bool {
    let s_len = s.len();
    let p_len = p.len();
    let mut s_i: usize = 0;
    let mut p_i: usize = 0;
    let mut s_k: usize = s_len;
    let mut p_k: usize = 0;
    loop {
        if s_i == s_len {
            loop {
                if p_i == p_len {
                    return true;
                } else if p[p_i] == MANY {
                    p_i += 1;
                } else {
                    return false;
                }
            }
        }

        if p_i == p_len {
        } else if p[p_i] == MANY {
            s_k = s_i + 1;
            p_k = p_i;
            s_i = s_i;
            p_i = p_i + 1;
            continue;
        } else if s[s_i] == p[p_i] || p[p_i] == ANY {
            s_i += 1;
            p_i += 1;
            continue;
        }

        // failed
        s_i = s_k;
        p_i = p_k;
    }
}

macro_rules! assert_match {
    ($s:expr, $p:expr) => (assert!(match_wildcard($s.as_bytes(), $p.as_bytes())))
}

macro_rules! assert_not_match {
    ($s:expr, $p:expr) => (assert!(!match_wildcard($s.as_bytes(), $p.as_bytes())))
}

fn main() {
    assert_match!("Make America Great Again!", "Make America Great Again!");
    assert_match!("Grab 'em by the pussy", "Grab 'em by the *");
    assert_match!("Grab 'em by the pussy", "Grab 'em by the p*ssy");
    assert_match!("Grab 'em by the pussy", "Grab * by the p*ssy");
    assert_match!("Fake News", "* News");
    assert_match!("Covfefe", "*");
    assert_match!("Covfefe", "**");
    assert_match!("SAD!", "SAD?");
    assert_match!("SAD!", "S?D?");
    assert_match!("SAD!", "????");
    assert_match!("SAD!", "*?");
    assert_match!("SAD!", "?*");
    assert_match!("SAD!", "?*?");
    assert_match!("SAD!", "*?*");
    assert_match!("", "");
    assert_match!("", "*");

    assert_not_match!("Hello world!", "Hello work!");
    assert_not_match!("Hello world!", "Hello");
    assert_not_match!("Hello world!", "Hello *old");
    assert_not_match!("Hello world!", "Hello world??");
    assert_not_match!("", "?");
}
