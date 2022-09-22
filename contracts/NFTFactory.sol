// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Base64.sol";

contract NFT is ERC721Enumerable {
    constructor(
        string memory name_,
        string memory symbol_,
        string memory eventID_,
        address owner_
    ) ERC721(name_, symbol_) {
        eventID = eventID_;
        owner = owner_;
    }

    string public eventID;
    address public owner;
    address public pendingOwner;
    uint256 public nextTokenId;
    mapping(address => bool) public whitelist;

    event Whitelist(address[] indexed accounts);
    event RevokeWhitelist(address[] indexed accounts);
    event TransferOwner(address to);
    event AcceptOwner(address owner);

    function claim() external returns (uint256 tokenId) {
        require(whitelist[msg.sender]);
        whitelist[msg.sender] = false;
        tokenId = nextTokenId;
        _mint(msg.sender, tokenId);
        nextTokenId++;
        return tokenId;
    }

    function setWhitelist(address[] calldata accounts) external {
        require(owner == msg.sender);
        for (uint256 i = 0; i < accounts.length; i++) {
            if (balanceOf(accounts[i]) > 0) {
                continue;
            }
            whitelist[accounts[i]] = true;
        }
        emit Whitelist(accounts);
    }

    function revokeWhitelist(address[] calldata accounts) external {
        require(owner == msg.sender);
        for (uint256 i = 0; i < accounts.length; i++) {
            whitelist[accounts[i]] == false;
        }
        emit RevokeWhitelist(accounts);
    }

    function transferOwner(address to) external {
        require(owner == msg.sender);
        pendingOwner = to;
        emit TransferOwner(pendingOwner);
    }

    function acceptOwner() external {
        require(msg.sender == pendingOwner);
        owner = pendingOwner;
        pendingOwner = address(0);
        emit AcceptOwner(owner);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        _requireMinted(tokenId);
        return _tokenURI(tokenId);
    }

    function _tokenURI(uint256 _tokenId)
        internal
        view
        returns (string memory output)
    {
        output = string(
            abi.encodePacked(
                "https://multichaindao.org/Souvenirs/",
                eventID,
                "/",
                toString(_tokenId)
            )
        );
    }

    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT license
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }
}

contract NFTFactory {
    address public owner;
    address public pendingOwner;
    mapping(string => address) public nftAddress;

    event CreateNFT(address nft);
    event TransferOwner(address to);
    event AcceptOwner(address owner);
    event SetCreator(address creator);
    event RevokeCreator(address creator);

    constructor() {
        owner = msg.sender;
        isCreator[msg.sender] = true;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function transferOwner(address newOwner) external onlyOwner {
        pendingOwner = newOwner;
        emit TransferOwner(newOwner);
    }

    function acceptOwner() external {
        require(msg.sender == pendingOwner);
        owner = pendingOwner;
        pendingOwner = address(0);
        emit AcceptOwner(owner);
    }

    mapping(address => bool) public isCreator;

    function setCreator(address creator) external onlyOwner {
        isCreator[creator] = true;
        emit SetCreator(creator);
    }

    function revokeCreator(address creator) external onlyOwner {
        isCreator[creator] = false;
        emit RevokeCreator(creator);
    }

    function createNFT(
        string memory name_,
        string memory symbol_,
        string memory eventID_,
        uint256 salt
    ) external returns (address addr) {
        require(isCreator[msg.sender], "not allowed");
        require(nftAddress[name_] == address(0), "duplicated nft name");
        bytes memory bytecode = type(NFT).creationCode;
        bytecode = abi.encodePacked(
            bytecode,
            abi.encode(name_, symbol_, eventID_, msg.sender)
        );
        assembly {
            addr := create2(
                0,
                add(bytecode, 0x20),
                mload(bytecode),
                salt
            )

            if iszero(extcodesize(addr)) {
                revert(0, 0)
            }
        }
        nftAddress[name_] = addr;
        emit CreateNFT(addr);
        return addr;
    }
}
