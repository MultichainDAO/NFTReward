// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./Administrable.sol";
import "./IRewardHandler.sol";

interface IERC721 {
  function ownerOf(uint256 tokenId) external view returns (address owner);
}

interface IERC20 {
    function transfer(address recipient, uint256 amount) external returns (bool);
}

contract RewardHandler_SlowRelease is Administrable, IRewardHandler {
    address override public nft;
    address rewardToken; // trusted erc20 token
    event LogWithdrawReward(uint256 amount);

    struct Info {
        uint256 amount;
        uint64 startTime;
        uint64 endTime;
    }

    mapping(uint256 => Info) public rewardInfo;
    mapping(uint256 => uint256) public lastClaimTime;

    constructor (address nft_, address rewardToken_, address admin) {
        rewardToken = rewardToken_;
        nft = nft_;
        setAdmin(admin);
    }

    function setReward(uint256[] calldata tokenIds, uint256 amount, uint256 startTime, uint256 endTime) onlyAdmin external {
        for (uint i = 0; i < tokenIds.length; i++) {
            rewardInfo[tokenIds[i]] = Info(amount, uint64(startTime), uint64(endTime));
        }
    }

    function withdrawReward(uint256 amount) onlyAdmin external {
        IERC20(rewardToken).transfer(msg.sender, amount);
        emit LogWithdrawReward(amount);
    }

    function claimable(uint256 tokenId) override public view returns(uint256) {
        Info memory info = rewardInfo[tokenId];
        uint256 start = uint256(info.startTime);
        uint256 end = uint256(info.endTime);
        uint256 length = end - start;
        if (start < lastClaimTime[tokenId]) {
            start = lastClaimTime[tokenId];
        }
        if (end > block.timestamp) {
            end = block.timestamp;
        }
        return info.amount * (end - start) / length;
    }

    function claimReward(uint256 tokenId) override external {
        uint256 amount = claimable(tokenId);
        lastClaimTime[tokenId] = block.timestamp;
        IERC20(rewardToken).transfer(IERC721(nft).ownerOf(tokenId), amount);
    }
}

contract RewardHandler_Factory_SlowRelease {
    function getBytecode(address nft, address rewardToken, address admin) public pure returns (bytes memory) {
        bytes memory bytecode = type(RewardHandler_SlowRelease).creationCode;
        return abi.encodePacked(bytecode, abi.encode(nft), abi.encode(rewardToken), abi.encode(admin));
    }

    function create(address nft, address rewardToken, uint salt, address admin) payable public returns (address) {
        address addr;
        bytes memory bytecode = getBytecode(nft, rewardToken, admin);
        assembly {
            addr := create2(
                callvalue(),
                add(bytecode, 0x20),
                mload(bytecode),
                salt
            )

            if iszero(extcodesize(addr)) {
                revert(0, 0)
            }
        }
        return addr;
    }
}