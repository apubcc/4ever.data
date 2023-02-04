//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.9;

uint8 constant unsignedInt = 0;
uint8 constant negativeInt = 1;
uint8 constant byteString = 2;
uint8 constant textString = 3;
uint8 constant array = 4;
uint8 constant map = 5;
uint8 constant tag = 6;
uint8 constant others = 7;

function parseAuthenticateMessageParams(
    bytes calldata cborParams
) pure returns (bytes calldata slice) {
    uint byteIdx = 0;

    assert(cborParams[0] == hex"82"); // array of 2 elements
    byteIdx++;

    uint8 major;
    uint len;

    (major, len, byteIdx) = parseHeader(cborParams, byteIdx);
    assert(major == byteString); // byte string
    byteIdx += len;

    (major, len, byteIdx) = parseHeader(cborParams, byteIdx);
    assert(major == byteString); // byte string
    return cborParams[byteIdx:cborParams.length];
}

function parseDealProposal(
    bytes calldata cborDealProposal
) pure returns (bytes calldata rawcid, bytes calldata provider, uint size) {
    uint byteIdx = 0;
    assert(cborDealProposal[byteIdx] == hex"8b"); // array of 11 elements
    byteIdx++;
    assert(cborDealProposal[byteIdx] == hex"D8"); // array of 2 elements
    byteIdx++;
    assert(cborDealProposal[byteIdx] == hex"2A"); // tag 42
    byteIdx++;

    uint8 major;
    uint len;
    (major, len, byteIdx) = parseHeader(cborDealProposal, byteIdx);

    assert(major == byteString); // byte string
    rawcid = cborDealProposal[byteIdx:byteIdx + len];
    byteIdx += len;
}
