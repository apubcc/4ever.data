//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.9;

import "./DataDAOModule.sol";
import "./IJoinListener.sol";

/**
 * @title A DataDAO module that allows to ban members
 * @dev setup: dataDAO.setJoinListener(this); dataDAO.addMembershipManager(this);
 */
contract BanModule is DataDAOModule, IJoinListener {
    mapping(address => uint) public bannedUntilTimestamp;

    event MemberBanned(address indexed member);
    event BanWillEnd(address indexed member, uint banEndTimestamp);
    event BanRemoved(address indexed member);

    constructor(address dataDAOAddress) DataDAOModule(dataDAOAddress) {}

    function isBanned(address member) public view returns (bool) {
        return bannedUntilTimestamp[member] > block.timestamp;
    }

    function areBanned(
        address[] memory members
    ) public view returns (uint256 membersBannedBitfield) {
        uint bit = 1;

        for (uint8 i = 0; i < members.length; i++) {
            if (isBanned(members[i])) {
                membersBannedBitfield |= bit;
            }

            bit <<= 1;
        }
    }

    function ban(address member) public onlyMembershipManager {
        bannedUntilTimestamp[member] = type(uint).max;
        if (IDataDAO(dataDAO).isMember(member)) {
            IDataDAO(dataDAO).removeMember(member, MemberLeaveCode.BANNED);
        }
        emit MemberBanned(member);
    }

    function banMembers(address[] memory members) public onlyMembershipManager {
        for (uint8 i = 0; i < members.length; i++) {
            ban(members[i]);
        }
    }

    function banFor(
        address member,
        uint secondsToBan
    ) public onlyMembershipManager {
        ban(member);
        bannedUntilTimestamp[member] = block.timestamp + secondsToBan;
        emit BanWillEnd(member, bannedUntilTimestamp[member]);
    }

    function banMembersFor(
        address[] memory members,
        uint secondsToBan
    ) public onlyMembershipManager {
        for (uint8 i = 0; i < members.length; i++) {
            banFor(members[i], secondsToBan);
        }
    }

    function banMembersSpecific(
        address[] memory members,
        uint[] memory banEndTimestamps
    ) public onlyMembershipManager {
        for (uint8 i = 0; i < members.length; i++) {
            banFor(members[i], banEndTimestamps[i]);
        }
    }

    function restore(address member) public onlyMembershipManager {
        require(isBanned(member), "error_memberNotBanned");
        removeBan(member);
        IDataDAO(dataDAO).addMember(member);
    }

    function restoreMembers(
        address[] memory members
    ) public onlyMembershipManager {
        for (uint8 i = 0; i < members.length; i++) {
            restore(members[i]);
        }
    }

    function removeBan(address member) public onlyMembershipManager {
        delete bannedUntilTimestamp[member];
        emit BanRemoved(member);
    }

    function removeBanMembers(
        address[] memory members
    ) public onlyMembershipManager {
        for (uint8 i = 0; i < members.length; i++) {
            removeBan(members[i]);
        }
    }

    function onJoin(address newMember) external view override onlyDataDAO {
        require(!isBanned(newMember), "error_memberBanned");
    }
}
