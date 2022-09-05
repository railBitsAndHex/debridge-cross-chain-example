// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

interface IMessageReceiver {
    function receivePriceFeed(int _price) external;
}