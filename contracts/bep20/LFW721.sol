// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721URIStorageUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract LFW721 is
    Initializable,
    ERC721URIStorageUpgradeable,
    OwnableUpgradeable
{
    using SafeMath for uint256;
    // reserve token_id for vault marketplace
    uint64 public constant MAX_FIRST_OFFERING_SUPPLY = 14800;

    // a token_id[address] whitelist mapping, only allow address can mint a specific token_id
    mapping(uint256 => address) public whitelisted;

    string public baseUri;
    uint256 public dropPrice;
    uint256 public currentSession;

    mapping(uint256 => uint256[]) public dropList;
    // nonce for generate random number
    uint256 private nonce;
    // events list
    event WhitelistMinter(address minter, uint256 token_id);

    bool public offeringStart;
    bool public mintStart;

    function initialize() public initializer {
        __Ownable_init();
        __ERC721_init("LegendWarFantasay", "LFWN");
        nonce = 0;
    }

    function mintFirstOffering(uint256 tokenId) public {
        require(tokenId <= MAX_FIRST_OFFERING_SUPPLY, "01");
        require(whitelisted[tokenId] == address(0), "02");
        require(offeringStart == true, "disabled");

        _safeMint(_msgSender(), tokenId);
    }

    function mintWhitelist(uint256 tokenId) public {
        require(whitelisted[tokenId] == _msgSender(), "03");

        _safeMint(_msgSender(), tokenId);
        delete (whitelisted[tokenId]);
    }

    function mintDrop() public payable {
        require(msg.value == dropPrice);
        require(dropList[currentSession].length > 0);
        require(mintStart == true, "disabled");

        uint256 randomPosition = random(0, dropList[currentSession].length);
        _safeMint(_msgSender(), dropList[currentSession][randomPosition]);
        dropList[currentSession][randomPosition] = dropList[currentSession][
            dropList[currentSession].length - 1
        ];
        dropList[currentSession].pop();
    }

    function toogleOffering() external onlyOwner {
        offeringStart = !offeringStart;
    }

    function toogleMint() external onlyOwner {
        mintStart = !mintStart;
    }

    function setDropPrice(uint256 price) public onlyOwner {
        dropPrice = price;
    }

    function setDropList(
        uint256 session,
        uint256 index,
        uint256 length
    ) public onlyOwner {
        for (uint256 i = 0; i < length; i++) {
            dropList[session].push(index + i);
        }
    }

    function setCurrentSession(uint256 session) public onlyOwner {
        currentSession = session;
    }

    /**
     * @dev set base uri that is used to return nft uri.
     * Can only be called by the current owner. No validation is done
     * for the input.
     * @param uri new base uri
     */
    function setBaseURI(string calldata uri) public onlyOwner {
        baseUri = uri;
    }

    /**
     * @dev set minter whitelist for specific token_id
     * Can only be called by the current owner.
     * @param _minter minter wallet address
     * @param tokenId nft token id
     */
    function whitelist(address _minter, uint256 tokenId) public onlyOwner {
        require(
            whitelisted[tokenId] == address(0),
            "tokenId already whitelisted"
        );

        whitelisted[tokenId] = _minter;
        emit WhitelistMinter(_minter, tokenId);
    }

    /**
     * @dev generate a random number
     * @param min min number include
     * @param max max number exclude
     */
    function random(uint256 min, uint256 max)
        internal
        view
        returns (uint256 randomnumber)
    {
        randomnumber = uint256(
            keccak256(abi.encodePacked(block.timestamp, msg.sender, nonce))
        ).mod(max - min);
        randomnumber = randomnumber + min;
        nonce.add(1);
        return randomnumber;
    }
}
