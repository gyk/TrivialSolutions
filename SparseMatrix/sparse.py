from collections import defaultdict
from random import random
import json

class Sparse(object):
    def __init__(self, nr, nc, mat={}, row_major=True):
        self.nr = nr
        self.nc = nc
        self.mat = mat
        self.row_major = row_major

    def __iter__(self):
        for i, r in self.mat.iteritems():
            for j, e in r.iteritems():
                yield (i, j), e

    def random(self, p):
        """Generates random sparse matrix where the probability of an element 
        being nonzero is p
        """
        m = {r: {c: random() for c in range(self.nc) if random() < p}
                for r in range(self.nr)}
        for k in m.keys():
            if not m[k]:
                del m[k]
        self.mat = m

    def __str__(self):
        return "nr = {0}, nc = {1}\n".format(self.nr, self.nc) + \
            json.dumps(self.mat, indent=4)

    def to_full(self):
        full = [[0.0] * self.nc for i in range(self.nr)]
        for (i, j), e in self:
            full[i][j] = e
        return full

    def _t(self):
        mat_new = defaultdict(lambda:defaultdict(float))
        for (i, j), e in self:
            mat_new[j][i] = e
        mat_new.default_factory = None
        self.mat = mat_new

    def transpose(self):
        self._t()
        self.nr, self.nc = self.nc, self.nr

    def change_major(self):
        self._t()
        self.row_major = not self.row_major

    # Complexity: O(nr*nm*nc*p)
    def mul_naive(self, other):
        nr = self.nr
        nm = self.nc
        nc = other.nc

        from copy import deepcopy
        other = deepcopy(other)
        other.transpose();
        res = defaultdict(lambda:defaultdict(float))

        this = self.mat
        that = other.mat
        for i, r in this.iteritems():
            for k in range(nc):
                for j, e in r.iteritems():
                    if that.has_key(k) and that[k].has_key(j):
                        res[i][k] += this[i][j] * that[k][j]

        res.default_factory = None
        return Sparse(nr, nc, res)

    # Complexity: O(nr*nm*nc*p^2)
    def mul(self, other):
        nr = self.nr
        nm = self.nc
        nc = other.nc

        res = defaultdict(lambda:defaultdict(float))

        this = self.mat
        that = other.mat
        for i, r in this.iteritems():
            for j, e in r.iteritems():
                if not that.has_key(j):
                    continue
                for k, e2 in that[j].iteritems():
                    res[i][k] += e * e2

        res.default_factory = None
        return Sparse(nr, nc, res)

    def __mul__(self, other):
        return self.mul(other)

if __name__ == '__main__':
    sp1 = Sparse(3, 4)
    sp1.random(0.4)
    print sp1
    sp2 = Sparse(3, 4)
    sp2.random(0.4)
    print sp2

    print "\nResults:"
    print sp1.mul_naive(sp2)
    print sp1.mul(sp2)

    # timing
    from time import clock
    sp1 = Sparse(300, 500)
    sp1.random(0.1)
    sp2 = Sparse(300, 500)
    sp2.random(0.1)

    n_tests = 3
    start = clock()
    for i in range(n_tests):
        sp1.mul_naive(sp2)
    print "t_naive = %.3fs" % ((clock() - start) / n_tests)

    start = clock()
    for i in range(n_tests):
        sp1.mul(sp2)
    print "t = %.3fs" % ((clock() - start) / n_tests)
