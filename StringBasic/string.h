#pragma once

#include <memory>
#include <iosfwd>

using std::unique_ptr, std::make_unique;


class String
{
public:
    String();
    ~String();
    explicit String(const char* s);
    String(String&& s);
    String(const String& s);

    String& operator=(String&& rhs);
    String& operator=(const String& rhs);

    int length() const {
        return this->len;
    }

    char* c_str() {
        return this->data.get();
    }

    const char* c_str() const {
        return this->data.get();
    }

private:
    long len;
    unique_ptr<char[]> data;
};

std::ostream& operator<<(std::ostream& os, const String& s);
