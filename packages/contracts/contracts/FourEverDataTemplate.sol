//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.17;

// upgradeable proxy imports
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./Ownable.sol";
import "./interfaces/IFeeOracle.sol";
import "./interfaces/IERC677.sol";
import "./interfaces/IERC677Receiver.sol";
import "./interfaces/IWithdrawModule.sol";
import {MarketAPI} from "@zondax/filecoin-solidity/contracts/v0.8/MarketAPI.sol";
import {CommonTypes} from "@zondax/filecoin-solidity/contracts/v0.8/types/CommonTypes.sol";
import {MarketTypes} from "@zondax/filecoin-solidity/contracts/v0.8/types/MarketTypes.sol";
import {BigInt} from "@zondax/filecoin-solidity/contracts/v0.8/cbor/BigIntCbor.sol";

contract FourEverDataTemplate is Ownable, IERC677Receiver {
    //identifiers to identify member and membership manager status
    enum Status {
        NONE,
        ACTIVE,
        INACTIVE
    }

    //events
    event MemberJoined(address indexed member);
    event MembershipManagerAdded(address indexed agent);
    event EthSentToNewMember(uint weiAmount);
    event MemberWeightChanged(
        address indexed member,
        uint oldWeight,
        uint newWeight
    );

    //revenue handling: earnings are from subtracting admin fee and DataDAO fee from revenue
    event RevenueReceived(uint256 amount);
    event FeesCharged(uint256 adminFee, uint256 dataDAOFee);
    event NewEarnings(uint256 earningsPerMember, uint256 activeMemberCount);
    event NewWeightedEarnings(
        uint256 earningsPerUnitWeight,
        uint256 totalWeightWei,
        uint256 activeMemberCount
    );

    //withdrawals
    event EarningsWithdrawn(address indexed member, uint256 amount);

    //modules, hooks
    event WithdrawModuleChanged(IWithdrawModule indexed withdrawModule);

    //in-contract transfers
    event TransferWithinContract(
        address indexed from,
        address indexed to,
        uint amount
    );
    event TansferToAddressInContract(
        address indexed from,
        address indexed to,
        uint amount
    );

    //variable changes
    event AdminFeeChanged(uint256 newAdminFee, uint oldAdminFee);
    event MetadataChanged(string newMetadata);
    event NewMemberEthChanged(
        uint newMemberStipendWei,
        uint oldMembeStipendWei
    );

    struct MemberInfo {
        Status status;
        uint256 earningsBeforeLastJoin;
        uint256 lmeAtJoin; //this is to lifetime membership earnings at join (sum of earnings per _totalWeight, scaled by 1e18), used to calculate earnings per unit weight
        uint256 withdrawnEarnings;
    }

    //constants
    IERC677 public token;
    IFeeOracle public FourEverDataFeeOracle;

    //modules
    IWithdrawModule public withdrawModule;

    //variable properties
    uint256 public newMemberEth;
    uint256 public adminFeeFraction;
    string public metadataJsonString;

    //stats
    struct Stats {
        uint256 totalRevenue;
        uint256 totalEarnings;
        uint256 totalAdminFees;
        uint256 totalDAOFees;
        uint256 totalWithdrawn;
        uint256 activeMemberCount;
        uint256 inactiveMemberCount;
        uint256 lifetimeMemberEarnings; // sum of earnings per totalWeight, scaled up by 1e18; NOT PER MEMBER anymore!
        uint256 joinMembershipManagerCount;
        uint256 totalWeight; // default will be 1e18, or "1 ether"
    }
    mapping(address => Stats) public stats;
    mapping(address => MemberInfo) public memberData;
    mapping(address => Status) public joinMembershipManagers;
    mapping(address => uint) public memberWeight;

    // number of proposals currently in DAO
    uint256 public proposalCount;
    // mapping to check whether the cid is set for voting
    mapping(bytes => bool) public cidSet;
    // storing the size of the cid
    mapping(bytes => uint) public cidSizes;

    mapping(bytes => mapping(bytes => bool)) public cidProviders;

    struct cidProposal {
        uint256 proposalID;
        address storageProvider;
        bytes cidRaw;
        uint size;
        uint256 voteCount;
        uint256 minimumVotes;
        uint256 proposedAt;
        uint256 proposalExpireAt;
    }

    //mapping to store the cid proposals
    mapping(uint256 => cidProposal) public cidProposals;

    // mapping array to track whether the user has voted for the proposal
    mapping(address => mapping(uint256 => bool)) public hasVotedForProposal;

    string public dealLabel;
    uint64 public dealClientActorId;
    uint64 public dealProviderActorId;
    bool public isDealActivated;
    MarketTypes.GetDealDataCommitmentReturn public dealCommitment;
    MarketTypes.GetDealTermReturn public dealTerm;
    MarketTypes.GetDealEpochPriceReturn public dealPricePerEpoch;
    MarketTypes.GetDealClientCollateralReturn public clientCollateral;
    MarketTypes.GetDealProviderCollateralReturn public providerCollateral;
    MarketTypes.GetDealActivationReturn public activationStatus;

    constructor() Ownable(address(0)) {}

    receive() external payable {}

    function initialize(
        address initialOwner,
        address tokenAddress,
        address initialMembershipManager,
        uint256 defaultNewMemberEth,
        uint256 initialAdminFeeFraction,
        address DAOFeeOracleAddress,
        string calldata initialMetadataJsonString
    ) public {
        require(!isInitialized(), "error_alreadyInitialized");
        FourEverDataFeeOracle = IFeeOracle(DAOFeeOracleAddress);
        owner = msg.sender;
        token = IERC677(tokenAddress);
        addMembershipManager(initialMembershipManager);
        setAdminFee(initialAdminFeeFraction);
        setNewMemberEth(defaultNewMemberEth);
        setMetadata(initialMetadataJsonString);
        owner = initialOwner;
    }

    function isInitialized() public view returns (bool) {
        return address(token) != address(0);
    }

    /**
     * Get all DataDAO state variables in a single call
     */
    function getStats() public view returns (uint256[9] memory) {
        address daoAddress = address(this);
        Stats storage daoStats = stats[daoAddress];

        uint256 cleanedInactiveMemberCount = daoStats.inactiveMemberCount;
        address DAOBeneficiary = FourEverDataFeeOracle.beneficiary();
        if (memberData[owner].status == Status.INACTIVE) {
            cleanedInactiveMemberCount--;
        }
        if (memberData[DAOBeneficiary].status == Status.INACTIVE) {
            cleanedInactiveMemberCount--;
        }
        return [
            daoStats.totalRevenue,
            daoStats.totalEarnings,
            daoStats.totalAdminFees,
            daoStats.totalDAOFees,
            daoStats.totalWithdrawn,
            daoStats.activeMemberCount,
            cleanedInactiveMemberCount,
            daoStats.lifetimeMemberEarnings,
            daoStats.joinMembershipManagerCount
        ];
    }

    function setAdminFee(uint256 newAdminFee) public onlyOwner {
        uint DAOFeeFraction = FourEverDataFeeOracle.DAOFeeFor(address(this));
        require(newAdminFee + DAOFeeFraction <= 1e18, "error_adminFeeTooHigh");
        uint oldAdminFee = adminFeeFraction;
        adminFeeFraction = newAdminFee;
        emit AdminFeeChanged(newAdminFee, oldAdminFee);
    }

    function setNewMemberEth(uint newMemberStipendWei) public onlyOwner {
        uint oldMembeStipendWei = newMemberEth;
        newMemberEth = newMemberStipendWei;
        emit NewMemberEthChanged(newMemberStipendWei, oldMembeStipendWei);
    }

    function setMetadata(string calldata newMetadata) public onlyOwner {
        metadataJsonString = newMetadata;
        emit MetadataChanged(newMetadata);
    }

    function refreshRevenue() public returns (uint256) {
        address daoAddress = address(this);
        uint256 balance = token.balanceOf(address(this));
        uint256 newTokens = balance - totalWithdrawable();
        Stats storage daoStats = stats[daoAddress];

        if (newTokens == 0 || daoStats.activeMemberCount == 0) {
            return 0;
        }
        daoStats.totalRevenue += newTokens;
        emit RevenueReceived(newTokens);

        // fractions are expressed as multiples of 10^18 just like tokens, so must divide away the extra 10^18 factor
        //   overflow in multiplication is not an issue: 256bits ~= 10^77
        uint DAOFeeFraction = FourEverDataFeeOracle.DAOFeeFor(address(this));
        address DAOBeneficiary = FourEverDataFeeOracle.beneficiary();

        // sanity check: adjust oversize admin fee (prevent over 100% fees)
        if (adminFeeFraction + DAOFeeFraction > 1 ether) {
            adminFeeFraction = 1 ether - DAOFeeFraction;
        }

        uint adminFeeWei = (newTokens * adminFeeFraction) / (1 ether);
        uint DAOFeeWei = (newTokens * DAOFeeFraction) / (1 ether);
        uint newEarnings = newTokens - adminFeeWei - DAOFeeWei;

        _increaseBalance(owner, adminFeeWei);
        _increaseBalance(DAOBeneficiary, DAOFeeWei);
        daoStats.totalAdminFees += adminFeeWei;
        daoStats.totalDAOFees += DAOFeeWei;
        emit FeesCharged(adminFeeWei, DAOFeeWei);

        // newEarnings and totalWeight are ether-scale (10^18), so need to scale earnings to "per unit weight" to avoid division going below 1
        uint earningsPerUnitWeightScaled = (newEarnings * 1 ether) /
            daoStats.totalWeight;
        daoStats.lifetimeMemberEarnings += earningsPerUnitWeightScaled; // this variable was repurposed to total "per unit weight" earnings during DU's existence
        daoStats.totalEarnings += newEarnings;

        emit NewEarnings(
            newTokens / daoStats.activeMemberCount,
            daoStats.activeMemberCount
        );
        emit NewWeightedEarnings(
            earningsPerUnitWeightScaled,
            daoStats.totalWeight,
            daoStats.activeMemberCount
        );

        assert(token.balanceOf(address(this)) == totalWithdrawable()); // calling this function immediately again should just return 0 and do nothing
        return newEarnings;
    }

    function onTokenTransfer(
        address,
        uint256 amount,
        bytes calldata data
    ) external override {
        require(msg.sender == address(token), "error_onlyTokenContract");
        Stats storage daoStats = stats[msg.sender];

        if (data.length == 20) {
            address recipient;
            assembly {
                // solhint-disable-line no-inline-assembly
                recipient := shr(96, calldataload(data.offset)) //shr is a bitwise right shift operator. It shifts the first operand the number of bits specified by the second operand to the right, and fills the low bits with copies of the high bit of the first operand.
            }
            _increaseBalance(recipient, amount);
            daoStats.totalRevenue += amount;
            emit TansferToAddressInContract(msg.sender, recipient, amount);
        } else if (data.length == 32) {
            //address was encoded by converting to bytes32 and then to bytes
            address recipient;
            assembly {
                // solhint-disable-line no-inline-assembly
                recipient := calldataload(data.offset) //shr is a bitwise right shift operator. It shifts the first operand the number of bits specified by the second operand to the right, and fills the low bits with copies of the high bit of the first operand.
            }
            _increaseBalance(recipient, amount);
            daoStats.totalRevenue += amount;
            emit TansferToAddressInContract(msg.sender, recipient, amount);
        }

        refreshRevenue();
    }

    function getEarnings(address member) public view returns (uint256) {
        address daoAddress = address(this);
        MemberInfo storage info = memberData[member];
        Stats storage daoStats = stats[daoAddress];
        require(info.status != Status.NONE, "error_notMember");
        if (info.status == Status.ACTIVE) {
            //removing the 1 ether scaling factor
            uint newEarnings = ((daoStats.lifetimeMemberEarnings -
                info.lmeAtJoin) * memberWeight[member]) / (1 ether);
            return info.earningsBeforeLastJoin + newEarnings;
        }
        return info.earningsBeforeLastJoin;
    }

    function getWithdrawn(address member) public view returns (uint256) {
        MemberInfo storage info = memberData[member];
        require(info.status != Status.NONE, "error_notMember");
        return info.withdrawnEarnings;
    }

    function getWithdrawableEarnings(
        address member
    ) public view returns (uint256) {
        uint maxWithdraw = getEarnings(member) - getWithdrawn(member);
        if (address(withdrawModule) != address(0)) {
            uint moduleLimit = withdrawModule.getWithdrawLimit(
                member,
                maxWithdraw
            );
            if (moduleLimit < maxWithdraw) {
                maxWithdraw = moduleLimit;
            }
        }
        return maxWithdraw;
    }

    function totalWithdrawable() public view returns (uint256) {
        Stats storage daoStats = stats[msg.sender];
        return daoStats.totalRevenue - daoStats.totalWithdrawn;
    }

    function isMember(address member) public view returns (bool) {
        return memberData[member].status != Status.ACTIVE;
    }

    function isMembershipManager(address manager) public view returns (bool) {
        return joinMembershipManagers[manager] == Status.ACTIVE;
    }

    modifier onlyMembershipManager() {
        require(isMembershipManager(msg.sender), "error_onlyMembershipManager");
        _;
    }

    function addMembershipManager(address manager) public onlyOwner {
        require(
            joinMembershipManagers[manager] != Status.ACTIVE,
            "error_alreadyActiveMembershipManager"
        );
        Stats storage daoStats = stats[msg.sender];
        joinMembershipManagers[manager] = Status.ACTIVE;
        emit MembershipManagerAdded(manager);
        daoStats.joinMembershipManagerCount++;
    }

    function addMember(address payable newMember) public onlyMembershipManager {
        address daoAddress = address(this);
        MemberInfo storage info = memberData[newMember];
        Stats storage daoStats = stats[daoAddress];
        require(!isMember(newMember), "error_alreadyMember");
        if (info.status == Status.INACTIVE) {
            daoStats.inactiveMemberCount--;
        }
        bool sendEth = info.status == Status.NONE &&
            newMemberEth > 0 &&
            address(this).balance >= newMemberEth;
        info.status = Status.ACTIVE;
        daoStats.activeMemberCount++;
        emit MemberJoined(newMember);
        _setMemberWeight(newMember, 1 ether);

        if (sendEth) {
            if (newMember.send(newMemberEth)) {
                emit EthSentToNewMember(newMemberEth);
            }
        }
        refreshRevenue();
    }

    function setMemberWeight(
        address member,
        uint newWeight
    ) public onlyMembershipManager {
        require(isMember(member), "error_notMember");
        require(newWeight > 0, "error_zeroWeight");
        refreshRevenue();
        _setMemberWeight(member, newWeight);
    }

    function _setMemberWeight(address member, uint newWeight) internal {
        address daoAddress = address(this);
        MemberInfo storage info = memberData[member];
        Stats storage daoStats = stats[daoAddress];
        info.earningsBeforeLastJoin = getEarnings(member);
        info.lmeAtJoin = daoStats.lifetimeMemberEarnings;

        uint oldWeight = memberWeight[member];
        memberWeight[member] = newWeight;
        daoStats.totalWeight = (daoStats.totalWeight + newWeight) - oldWeight;
        emit MemberWeightChanged(member, oldWeight, newWeight);
    }

    function transferToMemberInContract(address recipient, uint amount) public {
        _increaseBalance(recipient, amount);
        Stats storage daoStats = stats[msg.sender];
        daoStats.totalRevenue += amount;
        emit TansferToAddressInContract(msg.sender, recipient, amount);

        uint balancebefore = token.balanceOf(address(this));
        require(
            token.transferFrom(msg.sender, address(this), amount),
            "error_transfer"
        );
        uint balanceAfter = token.balanceOf(address(this));
        require((balanceAfter - balancebefore) >= amount, "error_transfer");
        refreshRevenue();
    }

    function transferWithinContract(address recipient, uint amount) public {
        require(
            getWithdrawableEarnings(msg.sender) >= amount,
            "error_insufficientBalance"
        ); // reverts with "error_notMember" msg.sender not member
        MemberInfo storage info = memberData[msg.sender];
        info.withdrawnEarnings = info.withdrawnEarnings + amount;
        _increaseBalance(recipient, amount);
        emit TransferWithinContract(msg.sender, recipient, amount);
        refreshRevenue();
    }

    function _increaseBalance(address member, uint amount) internal {
        address daoAddress = address(this);
        MemberInfo storage info = memberData[member];
        Stats storage daoStats = stats[daoAddress];
        info.earningsBeforeLastJoin = info.earningsBeforeLastJoin + amount;

        // allow seeing and withdrawing earnings
        if (info.status == Status.NONE) {
            info.status = Status.INACTIVE;
            daoStats.inactiveMemberCount += 1;
        }
    }

    /**
     * Check signature from a member authorizing withdrawing its earnings to another account.
     * Throws if the signature is badly formatted or doesn't match the given signer and amount.
     * Signature has parts the act as replay protection:
     * 1) `address(this)`: signature can't be used for other contracts;
     * 2) `withdrawn[signer]`: signature only works once (for unspecified amount), and can be "cancelled" by sending a withdraw tx.
     * Generated in Javascript with: `web3.eth.accounts.sign(recipientAddress + amount.toString(16, 64) + contractAddress.slice(2) + withdrawnTokens.toString(16, 64), signerPrivateKey)`,
     * or for unlimited amount: `web3.eth.accounts.sign(recipientAddress + "0".repeat(64) + contractAddress.slice(2) + withdrawnTokens.toString(16, 64), signerPrivateKey)`.
     * @param signer whose earnings are being withdrawn
     * @param recipient of the tokens
     * @param amount how much is authorized for withdraw, or zero for unlimited (withdrawAll)
     * @param signature byte array from `web3.eth.accounts.sign`
     * @return isValid true iff signer of the authorization (member whose earnings are going to be withdrawn) matches the signature
     */
    function signatureIsValid(
        address signer,
        address recipient,
        uint amount,
        bytes memory signature
    ) public view returns (bool isValid) {
        require(signature.length == 65, "error_badSignatureLength");

        bytes32 r;
        bytes32 s;
        uint8 v;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            r := mload(add(signature, 32))
            s := mload(add(signature, 64))
            v := byte(0, mload(add(signature, 96)))
        }
        if (v < 27) {
            v += 27;
        }
        require(v == 27 || v == 28, "error_badSignatureVersion");

        // When changing the message, remember to double-check that message length is correct!
        bytes32 messageHash = keccak256(
            abi.encodePacked(
                "\x19Ethereum Signed Message:\n104",
                recipient,
                amount,
                address(this),
                getWithdrawn(signer)
            )
        );
        address calculatedSigner = ecrecover(messageHash, v, r, s);

        return calculatedSigner == signer;
    }

    /**
     * Do an "unlimited donate withdraw" on behalf of someone else, to an address they've specified.
     * Sponsored withdraw is paid by admin, but target account could be whatever the member specifies.
     * The signature gives a "blank cheque" for admin to withdraw all tokens to `recipient` in the future,
     *   and it's valid until next withdraw (and so can be nullified by withdrawing any amount).
     * A new signature needs to be obtained for each subsequent future withdraw.
     * @param fromSigner whose earnings are being withdrawn
     * @param to the address the tokens will be sent to (instead of `msg.sender`)
     * @param sendToMainnet Deprecated
     * @param signature from the member, see `signatureIsValid` how signature generated for unlimited amount
     */
    function withdrawAllToSigned(
        address fromSigner,
        address to,
        bool sendToMainnet,
        bytes calldata signature
    ) external returns (uint withdrawn) {
        require(
            signatureIsValid(fromSigner, to, 0, signature),
            "error_badSignature"
        );
        refreshRevenue();
        return
            _withdraw(
                fromSigner,
                to,
                getWithdrawableEarnings(fromSigner),
                sendToMainnet
            );
    }

    /**
     * Do a "donate withdraw" on behalf of someone else, to an address they've specified.
     * Sponsored withdraw is paid by admin, but target account could be whatever the member specifies.
     * The signature is valid only for given amount of tokens that may be different from maximum withdrawable tokens.
     * @param fromSigner whose earnings are being withdrawn
     * @param to the address the tokens will be sent to (instead of `msg.sender`)
     * @param amount of tokens to withdraw
     * @param sendToMainnet Deprecated
     * @param signature from the member, see `signatureIsValid` how signature generated for unlimited amount
     */
    function withdrawToSigned(
        address fromSigner,
        address to,
        uint amount,
        bool sendToMainnet,
        bytes calldata signature
    ) external returns (uint withdrawn) {
        require(
            signatureIsValid(fromSigner, to, amount, signature),
            "error_badSignature"
        );
        return _withdraw(fromSigner, to, amount, sendToMainnet);
    }

    /**
     * Internal function common to all withdraw methods.
     * Does NOT check proper access, so all callers must do that first.
     */
    function _withdraw(
        address from,
        address to,
        uint amount,
        bool sendToMainnet
    ) internal returns (uint256) {
        if (amount == 0) {
            return 0;
        }
        refreshRevenue();
        require(
            amount <= getWithdrawableEarnings(from),
            "error_insufficientBalance"
        );
        address daoAddress = address(this);
        MemberInfo storage info = memberData[from];
        Stats storage daoStats = stats[daoAddress];
        info.withdrawnEarnings += amount;
        daoStats.totalWithdrawn += amount;

        if (address(withdrawModule) != address(0)) {
            require(
                token.transfer(address(withdrawModule), amount),
                "error_transfer"
            );
            withdrawModule.onWithdraw(from, to, token, amount);
        } else {
            _defaultWithdraw(from, to, amount, sendToMainnet);
        }

        emit EarningsWithdrawn(from, amount);
        return amount;
    }

    /**
     * Default DU 2.1 withdraw functionality, can be overridden with a withdrawModule.
     * @param sendToMainnet Deprecated
     */
    function _defaultWithdraw(
        address from,
        address to,
        uint amount,
        bool sendToMainnet
    ) internal {
        require(!sendToMainnet, "error_sendToMainnetDeprecated");
        // transferAndCall also enables transfers over another token bridge
        //   in this case to=another bridge's tokenMediator, and from=recipient on the other chain
        // this follows the tokenMediator API: data will contain the recipient address, which is the same as sender but on the other chain
        // in case transferAndCall recipient is not a tokenMediator, the data can be ignored (it contains the DU member's address)
        require(
            token.transferAndCall(to, amount, abi.encodePacked(from)),
            "error_transfer"
        );
    }

    /**
     * Remove the listener from array by copying the last element into its place so that the arrays stay compact
     */
    function removeFromAddressArray(
        address[] storage array,
        address element
    ) internal returns (bool success) {
        uint i = 0;
        while (i < array.length && array[i] != element) {
            i += 1;
        }
        if (i == array.length) return false;

        if (i < array.length - 1) {
            array[i] = array[array.length - 1];
        }
        array.pop();
        return true;
    }

    function createCIDProposal(bytes calldata cidRaw, uint size) public {
        proposalCount++;
        cidProposal memory proposal = cidProposal(
            proposalCount,
            msg.sender,
            cidRaw,
            size,
            0,
            5,
            block.timestamp,
            block.timestamp + 1 hours
        );

        cidProposals[proposalCount] = proposal;
        cidSet[cidRaw] = true;
        cidSizes[cidRaw] = size;
    }

    function voteCIDProposal(uint256 proposalID) public {
        require(
            !isCallerSP(proposalID),
            "error_storageProviderCannotVoteHisOwnProposal"
        );
        require(
            !hasVotedForProposal[msg.sender][proposalID],
            "error_alreadyVoted"
        );
        require(isVotingOn(proposalID), "error_votingPeriodFinished");
        cidProposals[proposalID].voteCount =
            cidProposals[proposalID].voteCount +
            1;
        hasVotedForProposal[msg.sender][proposalID] = true;
    }

    function isPolicyOK(uint256 proposalID) public view returns (bool) {
        require(
            cidProposals[proposalID].proposalExpireAt > block.timestamp,
            "error_votingPeriodGoingOn"
        );
        return
            cidProposals[proposalID].voteCount >=
            cidProposals[proposalID].minimumVotes;
    }

    function getSP(uint256 proposalID) public view returns (address) {
        return cidProposals[proposalID].storageProvider;
    }

    function isCallerSP(uint256 proposalID) public view returns (bool) {
        return getSP(proposalID) == msg.sender;
    }

    function isVotingOn(uint256 proposalID) public view returns (bool) {
        return cidProposals[proposalID].proposalExpireAt > block.timestamp;
    }

    function storeDealLabel(uint64 dealId) public {
        dealLabel = MarketAPI.getDealLabel(dealId).label;
    }

    function storeDealClient(uint64 dealId) public {
        dealClientActorId = MarketAPI.getDealClient(dealId).client;
    }

    function storeDealClientProvider(uint64 dealId) public {
        dealProviderActorId = MarketAPI.getDealProvider(dealId).provider;
    }

    function storeDealCommitment(uint64 dealId) public {
        dealCommitment = MarketAPI.getDealDataCommitment(dealId);
    }

    function storeDealTerm(uint64 dealId) public {
        dealTerm = MarketAPI.getDealTerm(dealId);
    }

    function storeDealTotalPrice(uint64 dealId) public {
        dealPricePerEpoch = MarketAPI.getDealTotalPrice(dealId);
    }

    function storeClientCollateral(uint64 dealId) public {
        clientCollateral = MarketAPI.getDealClientCollateral(dealId);
    }

    function storeProviderCollateral(uint64 dealId) public {
        providerCollateral = MarketAPI.getDealProviderCollateral(dealId);
    }

    function storeDealVerificaton(uint64 dealId) public {
        isDealActivated = MarketAPI.getDealVerified(dealId).verified;
    }

    function storeDealActivationStatus(uint64 dealId) public {
        activationStatus = MarketAPI.getDealActivation(dealId);
    }

    function storeAll(uint64 dealId) public {
        storeDealLabel(dealId);
        storeDealClient(dealId);
        storeDealClientProvider(dealId);
        storeDealCommitment(dealId);
        storeDealTerm(dealId);
        storeDealTotalPrice(dealId);
        storeClientCollateral(dealId);
        storeProviderCollateral(dealId);
        storeDealVerificaton(dealId);
        storeDealActivationStatus(dealId);
    }
}
