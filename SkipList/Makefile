CC=g++
CFLAGS=-std=c++0x
CFLAGS_OBJ = -c $(CFLAGS)

SkipList.exe: SkipList_test.cc SkipListUtil.o
	$(CC) $(CFLAGS) -o $@ $^

SkipListUtil.o: SkipListUtil.cc
	$(CC) $(CFLAGS_OBJ) -o $@ $^
