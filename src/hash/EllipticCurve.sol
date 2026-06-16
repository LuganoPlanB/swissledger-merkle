// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

library EllipticCurve {
    uint256 private constant U255_MAX_PLUS_1 =
        57896044618658097711785492504343953926634992332820282019728792003956564819968;

    function invMod(uint256 x, uint256 p) internal pure returns (uint256) {
        require(x != 0 && x != p && p != 0, "invalid number");

        uint256 q = 0;
        uint256 newT = 1;
        uint256 r = p;
        uint256 t;

        while (x != 0) {
            t = r / x;
            (q, newT) = (newT, addmod(q, (p - mulmod(t, newT, p)), p));
            (r, x) = (x, r - t * x);
        }

        return q;
    }

    function toAffine(
        uint256 x,
        uint256 y,
        uint256 z,
        uint256 p
    ) internal pure returns (uint256, uint256) {
        uint256 zInv = invMod(z, p);
        uint256 zInv2 = mulmod(zInv, zInv, p);
        uint256 affineX = mulmod(x, zInv2, p);
        uint256 affineY = mulmod(y, mulmod(zInv, zInv2, p), p);
        return (affineX, affineY);
    }

    function jacAdd(
        uint256 x1,
        uint256 y1,
        uint256 z1,
        uint256 x2,
        uint256 y2,
        uint256 z2,
        uint256 p
    ) internal pure returns (uint256, uint256, uint256) {
        if (x1 == 0 && y1 == 0) return (x2, y2, z2);
        if (x2 == 0 && y2 == 0) return (x1, y1, z1);

        uint256[4] memory zs;
        zs[0] = mulmod(z1, z1, p);
        zs[1] = mulmod(z1, zs[0], p);
        zs[2] = mulmod(z2, z2, p);
        zs[3] = mulmod(z2, zs[2], p);

        zs = [
            mulmod(x1, zs[2], p),
            mulmod(y1, zs[3], p),
            mulmod(x2, zs[0], p),
            mulmod(y2, zs[1], p)
        ];

        require(zs[0] != zs[2] || zs[1] != zs[3], "use jacDouble");

        uint256[4] memory hr;
        hr[0] = addmod(zs[2], p - zs[0], p);
        hr[1] = addmod(zs[3], p - zs[1], p);
        hr[2] = mulmod(hr[0], hr[0], p);
        hr[3] = mulmod(hr[2], hr[0], p);

        uint256 qx = addmod(mulmod(hr[1], hr[1], p), p - hr[3], p);
        qx = addmod(qx, p - mulmod(2, mulmod(zs[0], hr[2], p), p), p);

        uint256 qy = mulmod(hr[1], addmod(mulmod(zs[0], hr[2], p), p - qx, p), p);
        qy = addmod(qy, p - mulmod(zs[1], hr[3], p), p);

        uint256 qz = mulmod(hr[0], mulmod(z1, z2, p), p);
        return (qx, qy, qz);
    }

    function jacDouble(
        uint256 x,
        uint256 y,
        uint256 z,
        uint256 aa,
        uint256 p
    ) internal pure returns (uint256, uint256, uint256) {
        if (z == 0) return (x, y, z);

        uint256 xx = mulmod(x, x, p);
        uint256 yy = mulmod(y, y, p);
        uint256 zz = mulmod(z, z, p);

        uint256 s = mulmod(4, mulmod(x, yy, p), p);
        uint256 m = addmod(mulmod(3, xx, p), mulmod(aa, mulmod(zz, zz, p), p), p);

        uint256 qx = addmod(mulmod(m, m, p), p - addmod(s, s, p), p);
        uint256 qy = addmod(
            mulmod(m, addmod(s, p - qx, p), p),
            p - mulmod(8, mulmod(yy, yy, p), p),
            p
        );
        uint256 qz = mulmod(2, mulmod(y, z, p), p);

        return (qx, qy, qz);
    }

    function jacMul(
        uint256 d,
        uint256 x,
        uint256 y,
        uint256 z,
        uint256 aa,
        uint256 p
    ) internal pure returns (uint256, uint256, uint256) {
        if (d == 0) {
            return (0, 0, 1);
        }

        uint256 remaining = d;
        uint256 qx = 0;
        uint256 qy = 0;
        uint256 qz = 1;

        while (remaining != 0) {
            if ((remaining & 1) != 0) {
                (qx, qy, qz) = jacAdd(qx, qy, qz, x, y, z, p);
            }

            remaining /= 2;
            (x, y, z) = jacDouble(x, y, z, aa, p);
        }

        return (qx, qy, qz);
    }
}
