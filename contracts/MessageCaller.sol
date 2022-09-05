// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "./interfaces/IMessageReceiver.sol";

import "@debridge-finance/debridge-protocol-evm-interfaces/contracts/libraries/Flags.sol";
import "@debridge-finance/debridge-protocol-evm-interfaces/contracts/interfaces/IDeBridgeGateExtended.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";


error InsufficientFees(uint256 _msgValue, uint256 _executionFee, uint256 _protocolFee);
contract MessageCaller is Ownable{

    /// @dev DeBridgeGate's address on the current chain
    IDeBridgeGateExtended public deBridgeGate;
    AggregatorV3Interface public priceFeed;
    uint256 public crossChainReceiverChainId;
    address public crossChainReceiverAddress;

    constructor(address _deBridgeGate, address _priceFeed, uint256 _crossChainReceiverChainId, address _crossChainReceiverAddress) {
        deBridgeGate = IDeBridgeGateExtended(_deBridgeGate);
        priceFeed = AggregatorV3Interface(_priceFeed);
        crossChainReceiverChainId = _crossChainReceiverChainId;
        crossChainReceiverAddress = _crossChainReceiverAddress;

    }

    // Mutable Functions

    function setCrossChainReceiverChainId(uint256 _crossChainReceiverChainId) external onlyOwner {
        crossChainReceiverChainId = _crossChainReceiverChainId;
    }

    function setCrossChainReceiverAddress(address _crossChainReceiverAddress) external onlyOwner {
        crossChainReceiverAddress = _crossChainReceiverAddress;
    }

    function sendPriceFeed(int _price, uint256 _executionFee) external payable {
        bytes memory messageReceiverEncoded = _getEncodedMessageReceiver(_price);
        _send(messageReceiverEncoded, _executionFee);
    }


    // Internal Methods

    function _getEncodedMessageReceiver(int256 _price) internal pure returns(bytes memory) {
        return abi.encodeWithSelector(
            IMessageReceiver.receivePriceFeed.selector,
            _price
        );
    }

    function _send(bytes memory _dstMethodCall, uint256 _executionFee) internal {

        uint256 protocolFee = deBridgeGate.globalFixedNativeFee();
        require(
            msg.value >= (protocolFee + _executionFee),
            "fees not covered by the msg.value"
        );

        uint256 assetFeeBps = deBridgeGate.globalTransferFeeBps();
        /// @dev this is when only bridging the execution fee
        uint256 amountToBridge = _executionFee;
        /// @dev amount after the gate cuts off the 10 bps fee from bridged asset
        uint256 amountAfterFees = amountToBridge * (10000 - assetFeeBps) / 10000;

        IDeBridgeGateExtended.SubmissionAutoParamsTo memory autoParams;

        autoParams.executionFee = amountAfterFees;


        autoParams.flags = Flags.setFlag(
            autoParams.flags,
            Flags.PROXY_WITH_SENDER,
            true
        );

        autoParams.flags = Flags.setFlag(
            autoParams.flags,
            Flags.REVERT_IF_EXTERNAL_FAIL,
            true
        );
        autoParams.data = _dstMethodCall;
        autoParams.fallbackAddress = abi.encodePacked(msg.sender);

        deBridgeGate.send{value: msg.value}(
            address(0), // tokenAddress to bridge, in this case bridging native asset
            amountToBridge, 
            crossChainReceiverChainId,
            abi.encodePacked(crossChainReceiverAddress),
            "",
            true, // useAssetFee: should be set to false (reserved for future use),
            0,
            abi.encode(autoParams)
        );

    }


    function getPriceFeed() external view returns(int) {
        (   uint80 roundId,
            int price,
            uint startedAt,
            uint timeStamp,
            uint80 answeredInRound) = priceFeed.latestRoundData();
     
        return price;                
    }


}