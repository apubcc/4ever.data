//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.9;

import "../IERC677.sol";
import "./DataDAOModule.sol";
import "./IWithdrawModule.sol";
import "./IJoinListener.sol";
import "./ILeaveListener.sol";

/**
 * @title DataDAO module that limits the amount of tokens that can be withdrawn
 * @dev setup: dataDAO.setWithdrawModule(this); dataDAO.addJoinListener(this); dataDAO.addLeaveListener(this);
 */
contract LimitWithdrawModule is
    DataDAOModule,
    IWithdrawModule,
    IJoinListener,
    ILeaveListener
{
    uint public requiredMemberAgeSeconds;
    uint public withdrawLimitPeriodSeconds;
    uint public withdrawLimitDuringPeriod;
    uint public minimumWithdrawTokenWei;

    mapping(address => uint) public lastWithdrawTimestamp;
    mapping(address => uint) public memberJoinTimestamp;
    mapping(address => uint) public withdrawnDuringPeriod;
    mapping(address => bool) public blacklisted;

    event ModuleReset(
        address newDataDAO,
        uint newRequiredMemberAgeSeconds,
        uint newWithdrawLimitPeriodSeconds,
        uint newWithdrawLimitDuringPeriod,
        uint newMinimumWithdrawTokenWei
    );

    constructor(
        address dataDAOAddress,
        uint newRequiredMemberAgeSeconds,
        uint newWithdrawLimitPeriodSeconds,
        uint newWithdrawLimitDuringPeriod,
        uint newMinimumWithdrawTokenWei
    ) DataDAOModule(dataDAOAddress) {
        requiredMemberAgeSeconds = newRequiredMemberAgeSeconds;
        withdrawLimitPeriodSeconds = newWithdrawLimitPeriodSeconds;
        withdrawLimitDuringPeriod = newWithdrawLimitDuringPeriod;
        minimumWithdrawTokenWei = newMinimumWithdrawTokenWei;
    }

    function setParameters(
        address dataDAOAddress,
        uint newRequiredMemberAgeSeconds,
        uint newWithdrawLimitPeriodSeconds,
        uint newWithdrawLimitDuringPeriod,
        uint newMinimumWithdrawTokenWei
    ) external onlyOwner {
        dataDAO = dataDAOAddress;
        requiredMemberAgeSeconds = newRequiredMemberAgeSeconds;
        withdrawLimitPeriodSeconds = newWithdrawLimitPeriodSeconds;
        withdrawLimitDuringPeriod = newWithdrawLimitDuringPeriod;
        minimumWithdrawTokenWei = newMinimumWithdrawTokenWei;
        emit ModuleReset(
            dataDAO,
            requiredMemberAgeSeconds,
            withdrawLimitPeriodSeconds,
            withdrawLimitDuringPeriod,
            minimumWithdrawTokenWei
        );
    }

    function onJoin(address newMember) external override onlyDataDAO {
        memberJoinTimestamp[newMember] = block.timestamp;

        // reset withdraw limit
        delete blacklisted[newMember];
    }

    function onLeave(
        address leavingMember,
        MemberLeaveCode leaveCode
    ) external override onlyDataDAO {
        if (leaveCode == MemberLeaveCode.BANNED) {
            blacklisted[leavingMember] = true;
        }
    }

    function getWithdrawLimit(
        address member,
        uint maxWithdrawals
    ) external view override returns (uint256) {
        return blacklisted[member] ? 0 : maxWithdrawals;
    }

    function setJoinTimestamp(
        address member,
        uint timestamp
    ) external onlyOwner {
        memberJoinTimestamp[member] = timestamp;
    }

    function onWithdraw(
        address member,
        address to,
        IERC677 token,
        uint amountWei
    ) external override onlyDataDAO {
        require(
            amountWei >= minimumWithdrawTokenWei,
            "error_withdrawAmountBelowMinimum"
        );
        require(
            memberJoinTimestamp[member] > 0,
            "error_mustJoinBeforeWithdraw"
        );
        require(
            block.timestamp >=
                memberJoinTimestamp[member] + requiredMemberAgeSeconds,
            "error_memberTooNew"
        );

        // if the withdraw period is over, we reset the counters
        if (
            block.timestamp >
            lastWithdrawTimestamp[member] + withdrawLimitPeriodSeconds
        ) {
            lastWithdrawTimestamp[member] = block.timestamp;
            withdrawnDuringPeriod[member] = 0;
        }
        withdrawnDuringPeriod[member] += amountWei;
        require(
            withdrawnDuringPeriod[member] <= withdrawLimitDuringPeriod,
            "error_withdrawLimit"
        );

        // transferAndCall also enables transfers over another token bridge
        //   in this case to=another bridge's tokenMediator, and from=recipient on the other chain
        // this follows the tokenMediator API: data will contain the recipient address, which is the same as sender but on the other chain
        // in case transferAndCall recipient is not a tokenMediator, the data can be ignored (it contains the DD member's address)
        require(
            token.transferAndCall(to, amountWei, abi.encodePacked(member)),
            "error_transfer"
        );
    }
}
