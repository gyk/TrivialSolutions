
binarySearch.exe: binarySearch.cc
	g++ -std=c++0x -o $@ $^

test: binarySearch.exe
	./binarySearch.exe < binarySearch_in.txt > binarySearch_out.txt
	diff binarySearch_out.txt binarySearch_out.sample.txt
