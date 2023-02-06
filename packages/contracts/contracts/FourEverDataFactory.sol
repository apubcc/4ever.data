// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

import "./FourEverDataTemplate.sol";
import "./Ownable.sol";

contract FourEverDataFactory is
    Initializable,
    OwnableUpgradeable,
    UUPSUpgradeable
{
    event DataDAOCreated(
        address indexed DataDAO,
        address indexed owner,
        address template
    );

    event NewDataDAOInitialETHUpdated(uint amount);
    event NewDataDAOOwnerInitialEthUpdated(uint amount);
    event DefaultNewMemberInitialEthUpdated(uint amount);
    event DAOFeeOracleUpdated(address newFeeOracleAddress);

    event DataDAOInitialETHSent(uint amountWei);
    event OwnerInitialEthSent(uint amountWei);

    address public FourEverDataTemplateAddress;
    address public defaultToken;

    //variables below are used to initialize new DataDAOs
    uint public newDataDAOInitialEth;
    uint public newDataDAOOwnerInitialEth;
    uint public defaultNewMemberInitialEth;
    address public FourEverDataFeeOracle;
    uint256 public numOfDataDao;
    address public dataDaoFactoryOwner;
    address public pendingOwner;

    struct dataDaoFactoryStruct {
        address dataDaoAddress;
        address dataDaoFactoryOwner;
    }

    mapping(address => dataDaoFactoryStruct) public allDataDaos;

    // owner address will be used check which address own/create a new dataDAO
    mapping(address => address) public searchByAddress;

    function initialize(
        address _dataDAOTemplate,
        address _defaultToken,
        address _DAOFeeOracle
    ) public initializer {
        __Ownable_init();
        __UUPSUpgradeable_init();
        setTemplate(_dataDAOTemplate);
        defaultToken = _defaultToken;
        FourEverDataFeeOracle = _DAOFeeOracle;
        dataDaoFactoryOwner = msg.sender;
    }

    function setTemplate(address _dataDAOTemplate) public onlyOwner {
        FourEverDataTemplateAddress = _dataDAOTemplate;
    }

    receive() external payable {}

    function setNewDataDAOInitialETH(uint amountWei) public onlyOwner {
        newDataDAOInitialEth = amountWei;
        emit NewDataDAOInitialETHUpdated(amountWei);
    }

    function setNewDataDAOOwnerInitialETH(uint amountWei) public onlyOwner {
        newDataDAOOwnerInitialEth = amountWei;
        emit NewDataDAOOwnerInitialEthUpdated(amountWei);
    }

    function setDefaultNewMemberInitialETH(uint amountWei) public onlyOwner {
        defaultNewMemberInitialEth = amountWei;
        emit DefaultNewMemberInitialEthUpdated(amountWei);
    }

    function setDAOFeeOracle(address newFeeOracleAddress) public onlyOwner {
        FourEverDataFeeOracle = newFeeOracleAddress;
        emit DAOFeeOracleUpdated(newFeeOracleAddress);
    }

    function deployNewDataDAO(
        address payable owner,
        uint256 adminFeeFraction,
        address manager,
        string calldata metadataJsonString
    ) public returns (address) {
        return
            deployNewDataDAOWithToken(
                defaultToken,
                owner,
                manager,
                adminFeeFraction,
                metadataJsonString
            );
    }

    function deployNewDataDAOWithToken(
        address token,
        address payable owner,
        address manager,
        uint256 adminFeeFraction,
        string calldata metadataJsonString
    ) public returns (address) {
        address payable DataDAO = payable(
            Clones.clone(FourEverDataTemplateAddress)
        );
        FourEverDataTemplate(DataDAO).initialize(
            owner,
            token,
            manager,
            defaultNewMemberInitialEth,
            adminFeeFraction,
            FourEverDataFeeOracle,
            metadataJsonString
        );

        numOfDataDao++;
        allDataDaos[msg.sender] = (
            dataDaoFactoryStruct(
                msg.sender, // address of dataDAO owner
                address(this)
            )
        );
        searchByAddress[msg.sender] = address(DataDAO);
        emit DataDAOCreated(DataDAO, owner, FourEverDataTemplateAddress);

        if (
            newDataDAOInitialEth != 0 &&
            address(this).balance >= newDataDAOInitialEth
        ) {
            if (DataDAO.send(newDataDAOInitialEth)) {
                emit DataDAOInitialETHSent(newDataDAOInitialEth);
            }
        }
        if (
            newDataDAOOwnerInitialEth != 0 &&
            address(this).balance >= newDataDAOOwnerInitialEth
        ) {
            if (owner.send(newDataDAOOwnerInitialEth)) {
                emit OwnerInitialEthSent(newDataDAOOwnerInitialEth);
            }
        }

        return DataDAO;
    }

    function transferOwnership(address newOwner) public override onlyOwner {
        require(newOwner != address(0), "error_zeroAddress");
        pendingOwner = newOwner;
    }

    function claimOwnership() public {
        require(msg.sender == pendingOwner, "error_onlyPendingOwner");
        _transferOwnership(pendingOwner);
        pendingOwner = address(0);
    }

    function renounceOwnership() public override onlyOwner {}

    function _authorizeUpgrade(address) internal override onlyOwner {}

    function getContractBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function getAddressOfContract() public view returns (address) {
        return address(this);
    }

    function getAddressOfDataDaoFactoryOwner() public view returns (address) {
        return dataDaoFactoryOwner;
    }
}
