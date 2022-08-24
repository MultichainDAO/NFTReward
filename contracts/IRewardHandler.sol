// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

interface IRewardHandler {
    function nft() external view returns (address);
    function claimable(uint256 tokenId) external view returns(uint256);
    function claimReward(uint256 tokenId) external;
}