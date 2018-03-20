//! Computes all occurrences of a keyword in a given string, with surrounding context. This is known
//! as **keyword-in-context search**.

use std::cmp;

use super::SuffixArray;

pub struct KeywordInContext<'a, T: 'static> {
    suffix_array: SuffixArray<'a, T>,
}

impl<'a, T: Ord> KeywordInContext<'a, T> {
    pub fn new(text: &'a [T]) -> KeywordInContext<'a, T> {
        let suffix_array = SuffixArray::new(text);

        KeywordInContext {
            suffix_array,
        }
    }

    pub fn keyword_in_context(&self, query: &[T], context_len: usize) -> Vec<&'a [T]> {
        let mut found = vec![];
        let arr_len = self.suffix_array.len();
        let qry_len = query.len();

        for i in self.suffix_array.rank(query) .. arr_len {
            let from = match self.suffix_array.original_index(i) {
                Some(from) => from,
                None => return found,
            };
            if SuffixArray::common_prefix_len(query,
                &self.suffix_array.text[from..]) < qry_len {
                return found;
            }
            let to = cmp::min(from + qry_len, arr_len);

            let from_ctx = from.checked_sub(context_len).unwrap_or(0);
            let to_ctx = to.checked_add(context_len).unwrap_or(arr_len);

            found.push(&self.suffix_array.text[from_ctx..to_ctx]);
        }

        found
    }
}
