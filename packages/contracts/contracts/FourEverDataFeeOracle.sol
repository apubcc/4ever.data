// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.9;

// upgradeable proxy imports
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

import "./interfaces/IFeeOracle.sol";

contract FourEverDataFeeOracle is
    Initializable,
    OwnableUpgradeable,
    UUPSUpgradeable,
    IFeeOracle
{
    uint public fee; //unsigned integer that stores the fee in wei
    address public override beneficiary; //address of the beneficiary

    // TODO: fee is a percentage, not absolute wei, rename it to feePercentageWei or similar
    event FeeChanged(uint newFeeWei); //event that is emitted when the fee is changed
    event BeneficiaryChanged(address newDAOFeeBeneficiaryAddress); //event that is emitted when the beneficiary is changed

    function initialize(
        uint feeWei,
        address DAOFeeBeneficiaryAddress
    ) public initializer {
        __Ownable_init();
        __UUPSUpgradeable_init();
        setFee(feeWei);
        setBeneficiary(DAOFeeBeneficiaryAddress);
    }

    function setFee(uint feeWei) public onlyOwner {
        fee = feeWei;
        emit FeeChanged(feeWei);
    }

    function setBeneficiary(address DAOFeeBeneficiaryAddress) public onlyOwner {
        beneficiary = DAOFeeBeneficiaryAddress;
        emit BeneficiaryChanged(DAOFeeBeneficiaryAddress);
    }

    function DAOFeeFor(address) public view override returns (uint feeWei) {
        return fee;
    }

    function _authorizeUpgrade(address) internal override onlyOwner {}
}
