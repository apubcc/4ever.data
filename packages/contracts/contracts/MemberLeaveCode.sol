// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.9;

/**
 * Describes how the DataDAO member left
 */
enum MemberLeaveCode {
    SELF,   // self remove using partMember()
    AGENT,  // removed by joinPartAgent using partMember()
    BANNED  // removed by BanModule
}