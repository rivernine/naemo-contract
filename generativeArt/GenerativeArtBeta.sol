//
// 888b    888        d8888 8888888888 888b     d888  .d88888b.
// 8888b   888       d88888 888        8888b   d8888 d88P" "Y88b
// 88888b  888      d88P888 888        88888b.d88888 888     888
// 888Y88b 888     d88P 888 8888888    888Y88888P888 888     888
// 888 Y88b888    d88P  888 888        888 Y888P 888 888     888
// 888  Y88888   d88P   888 888        888  Y8P  888 888     888
// 888   Y8888  d8888888888 888        888   "   888 Y88b. .d88P
// 888    Y888 d88P     888 8888888888 888       888  "Y88888P"
//
// Copyright (C) 2022 Bithumb meta

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";

contract GenerativeArtBeta is
    ERC721URIStorage,
    ERC2981,
    Ownable
{

    // NAEMO wallet.
    address public NAEMO = 0x6A5C5f7964d0cA5a313Bd237ecA6657F52F17810;

    uint256 private _currentIndex = 0;

    // Mapping from token ID to burn status.
    // true: burned, false: unburned
    mapping(uint256 => bool) private _burned;

    // Maximum supply of token.
    uint256 public maxSupply = 10;

    // Base URI of metadata.
    string public baseURI = "ipfs://QmQbRroNMsDZuYEG3w6ZfJa8PA8EpaQdAJVMZ8MMZQFXWs/";

    // Royalty recipient wallet.
    address public royaltyRecipient = 0x6A5C5f7964d0cA5a313Bd237ecA6657F52F17810;

    // Basis point of royalty.
    // e.g. 100->1%
    uint96 public royaltyFeeBasisPoint = 500;

    modifier onlyNaemo() {
        require(_msgSender() == NAEMO, "Caller is not a NAEMO.");
        _;
    }

    modifier onlyEOA() {
        require(_msgSender() == tx.origin, "Caller cannot be a contract.");
        _;
    }

    event SetBaseURI(string indexed _baseURI);

    constructor() ERC721("Generative Art Beta", "GAB") {
        _setDefaultRoyalty(royaltyRecipient, royaltyFeeBasisPoint);
    }

    /**
     * @dev Total number of tokens minted.
     * @return {uint256} - The amount of tokens.
     */
    function totalSupply() public view returns (uint256) {
        return _currentIndex;
    }

    /**
     * @dev Base URI for computing {tokenURI}.
     * @return {string} - Base URI in IPFS or S3 format.
     */
    function _baseURI()
        internal
        view
        virtual
        override
        returns (string memory)
    {
        return baseURI;
    }

    /**
     * @dev Check whether the token is burned.
     * @param tokenId Token ID.
     * @return {bool} - The burned state of the token.
     */
    function burned(uint256 tokenId) public view returns (bool) {
        return _burned[tokenId];
    }

    /**
     * @dev Update naemo address.
     * @param naemo NAEMO wallet address.
     */
    function setNaemo(address naemo) external onlyNaemo {
        require(naemo != address(0), "The NAEMO cannot be null address.");
        NAEMO = naemo;
    }

    /**
     * @dev Update the base URI of tokens.
     * @param baseURI_ Base URI in IPFS or S3 format.
     */
    function setBaseURI(string memory baseURI_) public onlyOwner {
        baseURI = baseURI_;
        emit SetBaseURI(baseURI);
    }

    /**
     * @dev Mint NFT.
     * @param tokenId Token ID to mint.
     * @param tokenURI URI of token.
     */
    function mint(
        uint256 tokenId,
        string memory tokenURI
    ) external onlyEOA onlyNaemo {
        require(totalSupply() + 1 <= maxSupply, "Supply has been exceeded.");
        require(!burned(tokenId), "Token number already burned.");

        _currentIndex += 1;
        _mint(_msgSender(), tokenId);
        _setTokenURI(tokenId, tokenURI);
    }


    /**
     * @dev Burns `tokenId`.
     * @param tokenId Token ID to burn.
     */
    function burn(uint256 tokenId) public {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "Caller is not owner nor approved");
        _burned[tokenId] = true;
        _burn(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721, ERC2981)
        returns (bool)
    {
        return
            ERC721.supportsInterface(interfaceId)  ||
            ERC2981.supportsInterface(interfaceId);
    }
}