// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {EllipticCurve} from "./EllipticCurve.sol";

library StarknetPedersen {
    uint256 internal constant FIELD_PRIME =
        3618502788666131213697322783095070105623107215331596699973092056135872020481;
    uint256 internal constant ALPHA = 1;
    uint256 internal constant LOW_PART_MASK = (1 << 248) - 1;

    uint256 private constant SHIFT_X =
        0x049ee3eba8c1600700ee1b87eb599f16716b0b1022947733551fde4050ca6804;
    uint256 private constant SHIFT_Y =
        0x03ca0cfe4b3bc6ddf346d49d06ea0ed34e621062c0e056c1d0405d266e10268a;
    uint256 private constant P0_X =
        0x0234287dcbaffe7f969c748655fca9e58fa8120b6d56eb0c1080d17957ebe47b;
    uint256 private constant P0_Y =
        0x03b056f100f96fb21e889527d41f4e39940135dd7a6c94cc6ed0268ee89e5615;
    uint256 private constant P1_X =
        0x04fa56f376c83db33f9dab2656558f3399099ec1de5e3018b7a6932dba8aa378;
    uint256 private constant P1_Y =
        0x03fa0984c931c9e38113e0c0e47e4401562761f92a7a23b45168f4e80ff5b54d;
    uint256 private constant P2_X =
        0x04ba4cc166be8dec764910f75b45f74b40c690c74709e90f3aa372f0bd2d6997;
    uint256 private constant P2_Y =
        0x40301cf5c1751f4b971e46c4ede85fcac5c59a5ce5ae7c48151f27b24b219c;
    uint256 private constant P3_X =
        0x054302dcb0e6cc1c6e44cca8f61a63bb2ca65048d53fb325d36ff12c49a58202;
    uint256 private constant P3_Y =
        0x01b77b3e37d13504b348046268d8ae25ce98ad783c25561a879dcc77e99c2426;

    function hashPair(uint256 left, uint256 right) internal pure returns (uint256) {
        _assertFelt(left);
        _assertFelt(right);

        uint256 state = _pedersenRaw(0, left);
        state = _pedersenRaw(state, right);
        return _pedersenRaw(state, 2);
    }

    function _assertFelt(uint256 value) private pure {
        require(value < FIELD_PRIME, "felt overflow");
    }

    function _pedersenRaw(uint256 a, uint256 b) private pure returns (uint256) {
        (uint256 fx, uint256 fy, uint256 fz) = _scalarMulFourBitPoints(a, P0_X, P0_Y, P1_X, P1_Y);
        (uint256 sx, uint256 sy, uint256 sz) = _scalarMulFourBitPoints(b, P2_X, P2_Y, P3_X, P3_Y);

        (uint256 rx, uint256 ry, uint256 rz) = EllipticCurve.jacAdd(
            SHIFT_X,
            SHIFT_Y,
            1,
            fx,
            fy,
            fz,
            FIELD_PRIME
        );
        (rx, ry, rz) = EllipticCurve.jacAdd(rx, ry, rz, sx, sy, sz, FIELD_PRIME);

        (uint256 affineX, ) = EllipticCurve.toAffine(rx, ry, rz, FIELD_PRIME);
        return affineX;
    }

    function _scalarMulFourBitPoints(
        uint256 scalar,
        uint256 lowX,
        uint256 lowY,
        uint256 highX,
        uint256 highY
    ) private pure returns (uint256, uint256, uint256) {
        (uint256 lowMulX, uint256 lowMulY, uint256 lowMulZ) = EllipticCurve.jacMul(
            scalar & LOW_PART_MASK,
            lowX,
            lowY,
            1,
            ALPHA,
            FIELD_PRIME
        );
        (uint256 highMulX, uint256 highMulY, uint256 highMulZ) = EllipticCurve.jacMul(
            scalar >> 248,
            highX,
            highY,
            1,
            ALPHA,
            FIELD_PRIME
        );

        return
            EllipticCurve.jacAdd(
                lowMulX,
                lowMulY,
                lowMulZ,
                highMulX,
                highMulY,
                highMulZ,
                FIELD_PRIME
            );
    }
}
