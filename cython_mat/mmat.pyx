import numpy as np
cimport numpy as np


cdef extern from "mmat_impl.h":
    void mmat_impl_cpp(int n_row, int n_col, int k, int v, int l,
                       const float* p1, const float* p2, float* res, const float* p3, float* res2,
                       int block_size)
    void mmat_impl_cpp(int n_row, int n_col, int k, int v, int l,
                       const double* p1, const double* p2, double* res, const double* p3, double* res2,
                       int block_size)


cdef mmat_c_float(const float[:, ::1] a, const float [:, ::1] b, float [:, ::1] res, const float [:, ::1] c, float [:, ::1] res2,
                  int block_size):
    mmat_impl_cpp(a.shape[0], b.shape[1], a.shape[0], c.shape[1], a.shape[0], &a[0, 0], &b[0, 0], &res[0, 0], &c[0, 0], &res2[0, 0],
                  block_size)


cdef mmat_c_double(const double[:, ::1] a, const double[:, ::1] b, double[:, ::1] res, const double[:, ::1] c, double[:, ::1] res2,
                   int block_size):
    mmat_impl_cpp(a.shape[0], b.shape[1], a.shape[0], c.shape[1], a.shape[0], &a[0, 0], &b[0, 0], &res[0, 0], &c[0, 0], &res2[0, 0],
                  block_size)


def _mmat(np.ndarray a, np.ndarray b, np.ndarray c, block_size=16):
    res = np.zeros((a.shape[0], b.shape[1]), dtype=a.dtype)
    res2 = np.zeros((a.shape[0], c.shape[1]), dtype=a.dtype)

    if a.dtype == np.float32:
        mmat_c_float(a, b, res, c, res2, block_size)
    elif a.dtype == np.float64:
        mmat_c_double(a, b, res, c, res2, block_size)
    else:
        raise NotImplementedError(f"Not implemented for dtype={a.dtype}")
    return res2


def cython_attention(a, b, c, block_size=16):
    """Matrix multiplication."""
    assert len(a.shape) == 2 == len(b.shape), (
        f"Only applies on matrices but a.shape={a.shape}, b.shape={b.shape}"
    )
    assert a.shape[1] == b.shape[0], (
        f"Shape mismatch: a.shape={a.shape}, b.shape={b.shape}"
    )

    assert a.dtype == b.dtype, f"Type mismatch a.dtype={a.dtype}, b.dtype={b.dtype}"
    assert a.flags["C_CONTIGUOUS"], "Matrix a must be contiguous"
    assert b.flags["C_CONTIGUOUS"], "Matrix b must be contiguous"
    assert c.flags["C_CONTIGUOUS"], "Matrix b must be contiguous"

    return _mmat(a, b, c, block_size)
