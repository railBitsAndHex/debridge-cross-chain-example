// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "@debridge-finance/debridge-protocol-evm-interfaces/contracts/interfaces/IDeBridgeGate.sol";
import "@debridge-finance/debridge-protocol-evm-interfaces/contracts/interfaces/IDeBridgeGateExtended.sol";
import "@debridge-finance/debridge-protocol-evm-interfaces/contracts/interfaces/ICallProxy.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "./interfaces/IMessageReceiver.sol";

error InvalidChainId(uint256 submissionChainId, uint256 supportedChain);
error InvalidCaller(string errMessage);

contract MessageReceiver is Ownable, IMessageReceiver{
    IDeBridgeGateExtended public deBridgeGate;
    uint256 public supportedChain;
    int256 public price = 0;
    bytes trustedChainCaller;

    constructor(address _deBridgeGate, uint256 _supportedChain) {
        deBridgeGate = IDeBridgeGateExtended(_deBridgeGate);
        supportedChain = _supportedChain;
    }

    modifier onlyCrossChainCaller {
        ICallProxy callProxy = ICallProxy(deBridgeGate.callProxy());

        uint256 chainIdFrom = callProxy.submissionChainIdFrom();
        bytes memory nativeSender = callProxy.submissionNativeSender();

        if (chainIdFrom != supportedChain) {
            revert InvalidChainId(chainIdFrom, supportedChain);
        }
        if(keccak256(nativeSender) != keccak256(trustedChainCaller)) {
            revert InvalidCaller("Invalid caller!");
        }
        _;
    }

    function setTrustedChainCaller(address _trustee) external onlyOwner {
        trustedChainCaller = abi.encodePacked(_trustee);
    }
    function receivePriceFeed(int _price) external override onlyCrossChainCaller {
        price = _price;
    }

    function viewCrossChainPrice() external view returns(int) {
        return price;
    }
    function viewSupportedChain() external view returns(uint256) {
        return supportedChain;
    }
}