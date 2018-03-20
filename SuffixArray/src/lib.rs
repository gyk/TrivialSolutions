pub mod suffix_array;
pub mod kwic;

pub use suffix_array::SuffixArray;
pub use kwic::KeywordInContext;

pub fn longest_repeated_substring(text: &str) -> Option<String> {
    let text_u16 = text.encode_utf16().collect::<Vec<u16>>();
    let sa = SuffixArray::new(&text_u16[..]);
    (1 .. sa.len())
        .filter_map(|i| {
            sa.longest_common_prefix_len(i).map(|l| (i, l))
        })
        .max_by_key(|&(_, l)| l)
        .and_then(|(i, l)| {
            sa.select(i)
              .map(|s| &s[..l])
        })
        .map(|u16_str| String::from_utf16(u16_str).unwrap())
}


#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn smoke_lrs() {
        // From Wikipedia
        assert_eq!(longest_repeated_substring("ATCGATCGA"), Some("ATCGA".to_owned()));
        // From Shakespeare
        assert_eq!(longest_repeated_substring("to be or not to be"), Some("to be".to_owned()));
        // From..., uh, Ana Banana.
        assert_eq!(longest_repeated_substring("banana"), Some("ana".to_owned()));
    }

    #[test]
    fn smoke_kwic() {
        const TALE: &str = "\
            it was the best of times it was the worst of times \
            it was the age of wisdom it was the age of foolishness \
            it was the epoch of belief it was the epoch of incredulity \
            it was the season of light it was the season of darkness \
            it was the spring of hope it was the winter of despair \
            we had everything before us we had nothing before us \
            we were all going direct to heaven we were all going direct \
            the other wayin short the period was so far like the present \
            period that some of its noisiest authorities insisted on its \
            being received for good or for evil in the superlative degree \
            of comparison only";
        const CONTEXT_LEN: usize = 5;

        let tale_u16 = TALE.encode_utf16().collect::<Vec<u16>>();
        let kwic = KeywordInContext::new(&tale_u16);

        for &(q, expected_hits) in [
            ("was the", 10),
            ("we", 6),
            ("for", 4),
        ].iter() {
            let q_u16 = q.encode_utf16().collect::<Vec<u16>>();
            let q_cxt_print_len = q_u16.len() + CONTEXT_LEN * 2;

            let res = kwic.keyword_in_context(&q_u16, CONTEXT_LEN);
            assert_eq!(res.len(), expected_hits);
            for s in &res {
                println!("{:>width$}", String::from_utf16_lossy(s), width = q_cxt_print_len);
            }
            println!("");
        }
    }
}
