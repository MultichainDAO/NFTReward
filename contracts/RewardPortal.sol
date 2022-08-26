// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./IRewardHandler.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

interface IRewardHandler_Factory_SlowRelease {
    function create(
        address nft,
        address rewardToken,
        uint256 salt
    ) external payable returns (address);
}

interface IRewardHandler_Factory_VEShare {
    function create(
        address multi,
        address ve,
        address vereward,
        string memory name,
        address nft,
        uint256 salt
    ) external payable returns (address);
}

/**
 * Portal contract to initiate an nft reward and claim reward
 */
contract RewardPortal is Initializable,OwnableUpgradeable {
    mapping(address => address) public rewardHandler; // nft -> RewardHandler
    address factory_slowRelease;
    address factory_veShare;

    function initialize() public initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function setFactory_SlowRelease(address factory_) public onlyOwner {
        factory_slowRelease = factory_;
    }

    function setFactory_VE(address factory_) public onlyOwner {
        factory_veShare = factory_;
    }

    function deployRewardHandler_SlowRelease(address nft, address rewardToken, uint256 salt)
        public
        payable
        onlyOwner
        returns (address)
    {
        address handler = IRewardHandler_Factory_SlowRelease(
            factory_slowRelease
        ).create{value:msg.value}(nft, rewardToken, salt);
        rewardHandler[nft] = handler;
        return handler;
    }

    function deployRewardHandler_VEShare(
        address nft,
        address multi,
        address ve,
        address vereward,
        string memory name,
        uint256 salt
    ) public payable onlyOwner returns (address) {
        address nft;
        address handler = IRewardHandler_Factory_VEShare(factory_veShare)
            .create{value:msg.value}(multi, ve, vereward, name, nft, salt);
        rewardHandler[nft] = handler;
        return handler;
    }

    function claimable(address nft, uint256 tokenId)
        external
        view
        returns (uint256)
    {
        return IRewardHandler(rewardHandler[nft]).claimable(tokenId);
    }

    function claimReward(address nft, uint256 tokenId) external {
        IRewardHandler(rewardHandler[nft]).claimReward(tokenId);
    }
}
