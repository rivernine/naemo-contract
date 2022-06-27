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

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";

contract UniqueBetaDev is ERC721URIStorage, ERC2981 {
    
    struct TokenInfo {
        uint256 tokenId;
        string tokenURI;
        address royaltyRecipient;
        uint96 royaltyFeeBasisPoint;
    }

    // NAEMO's wallet.
    address public NAEMO = 0x6A5C5f7964d0cA5a313Bd237ecA6657F52F17810;

    // Mapping from token ID to craetor address.
    mapping(uint256 => address) public creator;

    event SetTokenRoyalty(
        uint256 indexed _tokenId, 
        address indexed _royaltyRecipient, 
        uint96 indexed _royaltyFeeBasisPoint
    );  

    constructor() ERC721("UniqueBetaDev", "UBD") {}

    /**
     * @dev Update naemo address.
     * @param naemo NAEMO wallet address.
     */
    function setNaemo(address naemo) external {
        require(_msgSender() == NAEMO, "Caller is not a NAEMO.");
        require(naemo != address(0), "The NAEMO cannot be null address.");
        NAEMO = naemo;
    }

    /**
     * @dev Update the royalty information of the token.
     * @param tokenId Token ID to change royalty.
     * @param royaltyRecipient Royalty recipient wallet.
     * @param royaltyFeeBasisPoint Basis point of royalty. e.g. 100->1%
     */
    function setTokenRoyalty(
        uint256 tokenId,
        address royaltyRecipient,
        uint96 royaltyFeeBasisPoint
    ) external {        
        require(_exists(tokenId), "Token does not exist.");
        require(_msgSender() == creator[tokenId], "Caller is not a creator.");
        _setTokenRoyalty(tokenId, royaltyRecipient, royaltyFeeBasisPoint);
        emit SetTokenRoyalty(tokenId, royaltyRecipient, royaltyFeeBasisPoint);
    }

    /**
     * @dev Mint NFT.
     * 
     * Your minted NFTs can seen in NAEMO service.
     * 
     * @param tokenInfo Structure containing information from tokens.
     */
    function mint(
        TokenInfo calldata tokenInfo
    ) external {
        require(_msgSender() == tx.origin, "Caller cannot be a contract.");
        
        creator[tokenInfo.tokenId] = _msgSender();
        _mint(_msgSender(), tokenInfo.tokenId);
        _setTokenURI(tokenInfo.tokenId, tokenInfo.tokenURI);
        _setTokenRoyalty(
            tokenInfo.tokenId, 
            tokenInfo.royaltyRecipient, 
            tokenInfo.royaltyFeeBasisPoint
        );
        _transfer(_msgSender(), NAEMO, tokenInfo.tokenId);
    }

    function supportsInterface(bytes4 interfaceId) 
        public 
        view 
        virtual 
        override(ERC721, ERC2981) 
        returns (bool) 
    {
        return 
            ERC721.supportsInterface(interfaceId) ||
            ERC2981.supportsInterface(interfaceId);
    }
}
