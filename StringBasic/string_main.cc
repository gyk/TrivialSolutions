#include <iostream>

#include <cassert>

#include "string.h"

int main(int argc, char const *argv[])
{
    String s1("Whatever");
    String s2(s1);
    auto s3 = s1;

    {
        String s;
        s = s1;
        s1 = std::move(s);
    }

    String s4, s5;
    std::cout << s4;
    s4 = s5 = s3;

    std::cout
        << s1 << ' ' << s2 << ' ' << s3 << ' '
        << s4 << ' ' << s5 << std::endl;

    assert(s2.c_str()[s2.length()] == '\0');
    return 0;
}
