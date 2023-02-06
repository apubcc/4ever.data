//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.9;

import "../interfaces/IERC677.sol";

interface IDataDAO {
    function owner() external returns (address);

    function addMember(address newMember) external;

    function isMember(address member) external view returns (bool);

    function isMembershipManager(address manager) external view returns (bool);
}

contract DataDAOModule {
    address public dataDAO;

    modifier onlyOwner() {
        require(msg.sender == IDataDAO(dataDAO).owner(), "error_onlyOwner");
        _;
    }

    modifier onlyMembershipManager() {
        require(
            IDataDAO(dataDAO).isMembershipManager(msg.sender),
            "error_onlyMembershipManager"
        );
        _;
    }

    modifier onlyDataDAO() {
        require(msg.sender == dataDAO, "error_onlyDataDAOContract");
        _;
    }

    constructor(address dataDAOAddress) {
        dataDAO = dataDAOAddress;
    }
}
