#include "string.h"

#include <algorithm>
#include <iostream>

#include <cstring>


String::String() : len(0), data(make_unique<char[]>(1)) {}

String::String(const char* s) : len(strlen(s)), data(make_unique<char[]>(len + 1)) {
    std::strncpy(data.get(), s, len);
}

String::String(const String& s) : len(s.length()), data(make_unique<char[]>(len + 1)) {
    std::copy(s.data.get(), s.data.get() + len, data.get());
}

String::String(String&& s) = default;

String& String::operator=(String&& rhs) = default;

String& String::operator=(const String& rhs) {
    auto& self = *this;
    if (&self == &rhs) {
        return self;
    }

    String temp(rhs);
    std::swap(self, temp);
    return self;
}

String::~String() = default;

std::ostream& operator<<(std::ostream& os, const String& s) {
    return os << s.c_str();
}
