// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IMerkleTreePathValidator.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract MerkleTreePathValidator is IMerkleTreePathValidator {

    using MerkleProof for bytes32[];

    function containsNode(
        bytes32 merkleTreeRoot,
        uint256 treeDepth,
        address wallet,
        uint256 balance,
        bytes32[] memory proof
    ) override external pure returns (bool) {
        if (proof.length != treeDepth) return false;
        bytes32 leaf = keccak256(abi.encode(wallet, balance));
        return proof.verify(merkleTreeRoot, leaf);
    }
}
