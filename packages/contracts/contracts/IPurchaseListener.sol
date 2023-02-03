// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.9;

/**
 * The purpose of the Purchase Listener interface is to listen for purchases of datasets on the marketplace, Purchase Listener
 * is set to the data product beneficiary
 */
interface IPurchaseListener {
	/**
	 * Similarly to ETH transfer, returning false will decline the transaction
	 *   (declining should probably cause revert, but that's up to the caller)
	 * IMPORTANT: include onlyMarketplace modifier to your implementations if your logic depends on the arguments!
	 */
	function onPurchase(
		bytes32 productId, 
		address subscriber, 
		uint256 endTimestamp, 
		uint256 priceDatacoin,
		uint256 feeDatacoin
	) external returns (bool accepted);
}