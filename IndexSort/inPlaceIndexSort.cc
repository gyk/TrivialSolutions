#include <cstdlib>
#include <ctime>

#include <algorithm>
#include <numeric>  // for iota
#include <vector>
#include <string>
#include <iostream>
#include <sstream>

using std::vector;
using std::string;
using std::cout;

struct Datum
{
    Datum(int key, string payload) : key(key), payload(payload) {};
    Datum(const Datum& rhs) = default;
    Datum(Datum&& rhs) = default;
    int key;
    string payload;
};

template <typename T>
void rearrange_in_place(vector<T>& data, vector<int>& indices)
{
    int n = data.size();
    for (int i=0; i<n; i++) {
        T d = data[i];
        int j;
        for (j=i; indices[j]!=i; ) {
            data[j] = data[indices[j]];
            int t = j;
            j = indices[j];
            indices[t] = t;
        }
        data[j] = d;
        indices[j] = j;
    }
}

vector<int> index_sort(const vector<Datum>& data)
{
    vector<int> indices(data.size());
    std::iota(indices.begin(), indices.end(), 0);

    std::sort(indices.begin(), indices.end(),
        [&data](int a, int b)
        {
            return data[a].key < data[b].key;
        });
    return indices;
}

vector<Datum> random_data(int size)
{
    std::srand((size_t)std::time(nullptr));
    vector<Datum> data;
    data.reserve(size);
    for (int i=0; i<size; i++) {
        int x = rand();

        // https://gcc.gnu.org/bugzilla/show_bug.cgi?id=52015
        // string s = std::to_string(x);

        std::ostringstream oss;
        oss << x;
        string s = oss.str();

        Datum d(x % 100, std::move(s));
        data.push_back(std::move(d));
    }

    return data;
}

void print_data(vector<Datum> data)
{
    cout << '[';
    for (auto& d : data) {
        cout << '(';
        cout << d.key << ", \"" << d.payload << '\"';
        cout << "), ";
    }
    cout << "\b\b";
    cout << "]\n";
}

int main()
{
    vector<Datum> data = random_data(20);
    print_data(data);
    vector<int> indices = index_sort(data);

    for (auto v : indices) {
        cout << v << ' ';
    }
    cout << "\n\n";

    rearrange_in_place(data, indices);
    print_data(data);

    for (auto v : indices) {
        cout << v << ' ';
    }

    return 0;
}
