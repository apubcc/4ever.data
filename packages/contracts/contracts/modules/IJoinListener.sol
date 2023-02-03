// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.9;

interface IJoinListener {
    function onJoin(address newMember) external;
}