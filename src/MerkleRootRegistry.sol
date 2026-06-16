// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {BuildInfo} from "./generated/BuildInfo.sol";
import {StarknetPedersen} from "./hash/StarknetPedersen.sol";
import {StrkMerkleProof} from "./StrkMerkleProof.sol";

contract MerkleRootRegistry {
    uint256 private constant FIELD_PRIME =
        3618502788666131213697322783095070105623107215331596699973092056135872020481;

    error ZeroRoot();
    error Unauthorized();
    error InvalidOwner();
    error InvalidRootUpdater();

    event ActiveRootUpdated(bytes32 indexed previousRoot, bytes32 indexed newRoot, address indexed updater);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event RootUpdaterAdded(address indexed updater);
    event RootUpdaterRemoved(address indexed updater);

    bytes32 public activeRoot;
    address public owner;
    mapping(address => bool) public isRootUpdater;
    address[] private rootUpdaterList;
    mapping(address => uint256) private rootUpdaterIndex;

    modifier onlyOwner() {
        if (msg.sender != owner) {
            revert Unauthorized();
        }
        _;
    }

    modifier onlyRootUpdater() {
        if (!isRootUpdater[msg.sender]) {
            revert Unauthorized();
        }
        _;
    }

    constructor() {
        owner = msg.sender;
        emit OwnershipTransferred(address(0), msg.sender);
        _addRootUpdater(msg.sender);
    }

    function transferOwnership(address newOwner) external onlyOwner {
        if (newOwner == address(0)) {
            revert InvalidOwner();
        }
        address oldOwner = owner;
        owner = newOwner;
        _removeRootUpdater(oldOwner);
        _addRootUpdater(newOwner);
        emit OwnershipTransferred(oldOwner, newOwner);
    }

    function addRootUpdater(address updater) external onlyOwner {
        _addRootUpdater(updater);
    }

    function removeRootUpdater(address updater) external onlyOwner {
        _removeRootUpdater(updater);
    }

    function getRootUpdaters() external view returns (address[] memory) {
        return rootUpdaterList;
    }

    /// @notice Returns the semantic version embedded into this build.
    function version() external pure returns (string memory) {
        return BuildInfo.VERSION;
    }

    /// @notice Replaces the current Merkle root with the latest off-chain state snapshot.
    function setActiveRoot(bytes32 newRoot) external onlyRootUpdater {
        if (newRoot == bytes32(0)) {
            revert ZeroRoot();
        }

        bytes32 previousRoot = activeRoot;
        activeRoot = newRoot;
        emit ActiveRootUpdated(previousRoot, newRoot, msg.sender);
    }

    /// @notice Checks whether a single canonical leaf hash is included in the latest active root.
    function containsLeafHash(bytes32 leafHash, bytes32[] calldata proof) external view returns (bool) {
        return _containsLeafHash(leafHash, proof);
    }

    /// @notice Checks whether a raw felt252 hash is included in the latest active root.
    function contains(bytes32 hashValue, bytes32[] calldata proof) external view returns (bool) {
        if (!_isValidFelt(uint256(hashValue))) {
            return false;
        }

        uint256 leafHash = StarknetPedersen.hashFelt252Leaf(uint256(hashValue));
        return _containsLeafHash(bytes32(leafHash), proof);
    }

    function _containsLeafHash(bytes32 leafHash, bytes32[] calldata proof) private view returns (bool) {
        bytes32 root = activeRoot;
        if (root == bytes32(0)) {
            return false;
        }

        if (!_isValidFelt(uint256(root)) || !_isValidFelt(uint256(leafHash))) {
            return false;
        }

        uint256[] memory feltProof = new uint256[](proof.length);
        for (uint256 index = 0; index < proof.length; index++) {
            uint256 proofValue = uint256(proof[index]);
            if (!_isValidFelt(proofValue)) {
                return false;
            }
            feltProof[index] = proofValue;
        }

        return StrkMerkleProof.verify(uint256(root), uint256(leafHash), feltProof);
    }

    /// @notice Checks whether a set of leaf hashes is included in the latest active root.
    function containsMany(
        bytes32[] calldata leafHashes,
        bytes32[] calldata proof,
        bool[] calldata proofFlags
    ) external view returns (bool) {
        bytes32 root = activeRoot;
        if (root == bytes32(0)) {
            return false;
        }

        if (!_isValidFelt(uint256(root))) {
            return false;
        }

        uint256[] memory feltLeaves = new uint256[](leafHashes.length);
        for (uint256 index = 0; index < leafHashes.length; index++) {
            uint256 leafValue = uint256(leafHashes[index]);
            if (!_isValidFelt(leafValue)) {
                return false;
            }
            feltLeaves[index] = leafValue;
        }

        uint256[] memory feltProof = new uint256[](proof.length);
        for (uint256 index = 0; index < proof.length; index++) {
            uint256 proofValue = uint256(proof[index]);
            if (!_isValidFelt(proofValue)) {
                return false;
            }
            feltProof[index] = proofValue;
        }

        bool[] memory proofFlagsCopy = new bool[](proofFlags.length);
        for (uint256 index = 0; index < proofFlags.length; index++) {
            proofFlagsCopy[index] = proofFlags[index];
        }

        return StrkMerkleProof.verifyMultiProof(uint256(root), feltLeaves, feltProof, proofFlagsCopy);
    }

    function _isValidFelt(uint256 value) private pure returns (bool) {
        return value < FIELD_PRIME;
    }

    function _addRootUpdater(address updater) private {
        if (updater == address(0)) {
            revert InvalidRootUpdater();
        }
        if (isRootUpdater[updater]) {
            return;
        }

        isRootUpdater[updater] = true;
        rootUpdaterList.push(updater);
        rootUpdaterIndex[updater] = rootUpdaterList.length;
        emit RootUpdaterAdded(updater);
    }

    function _removeRootUpdater(address updater) private {
        uint256 index = rootUpdaterIndex[updater];
        if (index == 0) {
            return;
        }

        uint256 lastIndex = rootUpdaterList.length;
        if (index != lastIndex) {
            address lastUpdater = rootUpdaterList[lastIndex - 1];
            rootUpdaterList[index - 1] = lastUpdater;
            rootUpdaterIndex[lastUpdater] = index;
        }

        rootUpdaterList.pop();
        delete rootUpdaterIndex[updater];
        delete isRootUpdater[updater];
        emit RootUpdaterRemoved(updater);
    }
}
