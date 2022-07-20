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

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155URIStorage.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "./NaemoSignatureVerifier.sol";

contract NaemoSharedEdition is
    ERC1155Burnable,
    ERC1155Supply,
    ERC1155URIStorage,
    ERC2981,
    NaemoSignatureVerifier
{
    struct TokenInfo {
        uint256 tokenId;
        address creator;
        uint256 maxSupply;
        string tokenURI;
        address royaltyRecipient;
        uint96 royaltyFeeBasisPoint;
    }

    // Token name
    string public name = "NAEMO Shared Edition";

    // Token symbol
    string public symbol = "NAEMOEDITION";

    // NAEMO wallet.
    address public NAEMO = 0x52e827F1d72716a0dc2485550C80912eE8Ec1972;

    // NAEMO's NFT wallet.
    address public NAEMO_NFT = 0x52e827F1d72716a0dc2485550C80912eE8Ec1972;

    // Basis point of NAEMO service costs. 
    // e.g. 100->1%
    uint256 public NAEMO_FEE_BASIS_POINT = 1000;
    
    // Address with permission to mint.
    // Vouchers must sign with the private key of this address.
    address public VOUCHER_CREATOR = 0x08C25De9BC1C552c4c783F79BfD5B980737e9744;

    // Mapping from token ID to craetor address.
    mapping(uint256 => address) public creator;

    // Mapping from token ID to maximum supply.
    mapping(uint256 => uint256) public maxSupply;

    // Used for Alpha version only.
    // Mapping from token ID to maximum amount that can be minted for each transaction. 
    mapping(uint256 => uint256) public maxAmountPerTx;

    // Used for Alpha version only.
    // Mapping from token ID to mint price. 
    // unit: wei
    mapping(uint256 => uint256) public price;

    // Used for Alpha version only.
    // Mapping from token ID to sale status. 
    // true: for sale, false: not for sale
    mapping(uint256 => bool) public sale;

    // Used for Alpha version only.
    // Mapping from token ID to nonce status.
    // true: used nonce, false: not used nonce
    mapping(uint256 => mapping(uint256 => bool)) public nonce;

    modifier onlyCreator(uint256 tokenId) {
        require(_msgSender() == creator[tokenId], "Caller is not a creator.");
        _;
    }

    modifier onlyEOA() {
        require(_msgSender() == tx.origin, "Caller cannot be a contract.");
        _;
    }

    modifier tokenExists(uint256 tokenId) {
        require(initialized(tokenId), "Token does not exist.");
        _;
    }

    event SetPrice(
        uint256 indexed _tokenId, 
        uint256 indexed _price
    );

    event FlipSale(
        uint256 indexed _tokenId,
        bool indexed _sale
    );

    constructor() ERC1155("") NaemoSignatureVerifier() {}

    /**
     * @dev Returns the initialization state of the token.
     * @return {bool} true: already initialized, false: uninitialized.
     */
    function initialized(uint256 tokenId) public view returns (bool) {
        return maxSupply[tokenId] > 0;
    }

    /**
     * @dev Update NAEMO address.
     * @param naemo NAEMO wallet address.
     */
    function setNaemo(address naemo) external {
        require(_msgSender() == NAEMO, "Caller is not a NAEMO.");
        require(naemo != address(0), "The NAEMO cannot be null address.");
        NAEMO = naemo;
    }

    /**
     * @dev Update NAEMO's NFT address.
     * @param naemoNFT NFT wallet owned by NAEMO.
     */
    function setNaemoNFT(address naemoNFT) external {
        require(_msgSender() == NAEMO_NFT, "Caller is not a NAEMO_NFT.");
        require(naemoNFT != address(0), "The NAEMO_NFT cannot be null address.");
        NAEMO_NFT = naemoNFT;
    }

    /**
     * @dev Update voucher creator address.
     * @param voucherCreator VOUCHER_CREATOR wallet address.
     */
    function setVoucherCreator(address voucherCreator) external {
        require(_msgSender() == VOUCHER_CREATOR, "Caller is not a VOUCHER_CREATOR.");
        require(voucherCreator != address(0), "The VOUCHER_CREATOR cannot be null address.");
        VOUCHER_CREATOR = voucherCreator;
    }

    /**
     * @notice Used for Alpha version only.
     * @dev Update the sales price. 
     * @param tokenId Token ID to change status.
     * @param price_ Price of the token. The unit of price is wei.
     */
    function setPrice(
        uint256 tokenId, 
        uint256 price_
    ) external tokenExists(tokenId) onlyCreator(tokenId) {
        price[tokenId] = price_;
        emit SetPrice(tokenId, price[tokenId]);
    }
    
    /** 
     * @notice Used for Alpha version only.
     * @dev Flip the sales status. 
     * @param tokenId Token ID to change status.
     */
    function flipSale(
        uint256 tokenId
    ) external tokenExists(tokenId) onlyCreator(tokenId) {
        sale[tokenId] = !sale[tokenId];
        emit FlipSale(tokenId, sale[tokenId]);
    }

    /**
     * @dev Initialize token information.
     * @param tokenInfo InitVoucher with voucher information and signature of authorized signer.
     * @return {uint256} ID of the initialized token
     */
    function _initToken(
        TokenInfo memory tokenInfo
    ) internal returns (uint256) {
        require(!initialized(tokenInfo.tokenId), "Token has already been initialized.");

        creator[tokenInfo.tokenId] = tokenInfo.creator;
        maxSupply[tokenInfo.tokenId] = tokenInfo.maxSupply;
        _setURI(tokenInfo.tokenId, tokenInfo.tokenURI);
        _setTokenRoyalty(
            tokenInfo.tokenId, 
            tokenInfo.royaltyRecipient, 
            tokenInfo.royaltyFeeBasisPoint
        );

        return tokenInfo.tokenId;
    }

    /**
     * @notice Used for Alpha version only.
     * @dev Initialize token information. 
     * @param initVoucher InitVoucher with voucher information and signature of authorized signer.
     * @return {uint256} ID of the initialized token
     */
    function initToken(
        InitVoucher calldata initVoucher
    ) external onlyEOA returns (uint256) {
        require(_verifyInitVoucher(initVoucher) == VOUCHER_CREATOR, "Unknown voucher signer.");
        
        _initToken(
            TokenInfo(
                initVoucher.tokenId, 
                initVoucher.creator, 
                initVoucher.maxSupply, 
                initVoucher.tokenURI, 
                initVoucher.royaltyRecipient, 
                initVoucher.royaltyFeeBasisPoint
            )
        );
        price[initVoucher.tokenId] = initVoucher.price;
        maxAmountPerTx[initVoucher.tokenId] = initVoucher.maxAmountPerTx;
        sale[initVoucher.tokenId] = initVoucher.sale;

        return initVoucher.tokenId;
    }

    /**
     * @notice Used for Alpha version only.
     * @dev Airdrop tokens to 'to' address
     * @param tokenId Token ID to airdrop.
     * @param amount Amount of tokens to airdrop. 
     * @param to Address to receive airdrop.
     */
    function airdrop(
        uint256 tokenId, 
        uint256 amount,
        address to
    ) external onlyEOA tokenExists(tokenId) onlyCreator(tokenId) {        
        require(totalSupply(tokenId) + amount <= maxSupply[tokenId], "Supply has been exceeded.");
        _mint(to, tokenId, amount, new bytes(0));
    }

    /**
     * @notice Used for Alpha version only.
     * @dev Mint n NFTs by redeeming a voucher. (Lazy mint)
     * 
     * Each voucher has token id and nonce info.
     * Every nonce is un-reusable.     
     * 
     * @param redeemVoucher RedeemVoucher with voucher information and signature of authorized signer.
     * @param amount Amount of tokens to purchase.
     */
    function redeem(
        RedeemVoucher calldata redeemVoucher, 
        uint256 amount
    ) external payable onlyEOA tokenExists(redeemVoucher.tokenId) {        
        require(_verifyRedeemVoucher(redeemVoucher) == VOUCHER_CREATOR, "Unknown voucher signer.");
        require(sale[redeemVoucher.tokenId], "It's not on sale.");
        require(!nonce[redeemVoucher.tokenId][redeemVoucher.nonce], "Nonce already used.");
        require(amount > 0 && amount <= maxAmountPerTx[redeemVoucher.tokenId], "Amount Denied");
        require(totalSupply(redeemVoucher.tokenId) + amount <= maxSupply[redeemVoucher.tokenId], "Supply has been exceeded.");
        require(msg.value >= price[redeemVoucher.tokenId] * amount, "Ether Amount Denied");

        nonce[redeemVoucher.tokenId][redeemVoucher.nonce] = true;
        payable(NAEMO).transfer(
            (msg.value * NAEMO_FEE_BASIS_POINT) / 10000
        );
        payable(creator[redeemVoucher.tokenId]).transfer(
            (msg.value * (10000 - NAEMO_FEE_BASIS_POINT)) / 10000
        );
        _mint(_msgSender(), redeemVoucher.tokenId, amount, new bytes(0));
    }

    /**
     * @dev Mint n NFTs.
     * 
     * Your minted NFTs can seen in NAEMO service.
     * 
     * @param tokenInfo Structure containing information from tokens.
     */
    function mint(TokenInfo calldata tokenInfo) external onlyEOA {        
        _initToken(tokenInfo);
        _mint(
            _msgSender(), 
            tokenInfo.tokenId, 
            tokenInfo.maxSupply, 
            new bytes(0)
        );
        _safeTransferFrom(
            _msgSender(), 
            NAEMO_NFT, 
            tokenInfo.tokenId, 
            tokenInfo.maxSupply, 
            new bytes(0)
        );
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC1155, ERC2981)
        returns (bool)
    {
        return
            ERC1155.supportsInterface(interfaceId) ||
            ERC2981.supportsInterface(interfaceId);
    }

    function _beforeTokenTransfer(
        address operator,
        address from, 
        address to, 
        uint256[] memory ids, 
        uint256[] memory amounts, 
        bytes memory data
    ) internal override(ERC1155, ERC1155Supply) {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }

    function uri(
        uint256 tokenId
    ) public view override(ERC1155, ERC1155URIStorage) returns (string memory) {
        return super.uri(tokenId);
    }
}
