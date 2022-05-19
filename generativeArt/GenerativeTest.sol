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
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";

contract GenerativeTest is
    ERC721URIStorage,
    ERC2981,
    EIP712,
    Ownable
{
    struct Voucher {
        uint256 tokenId;
        string tokenURI;
        bytes signature;
    }

    // NAEMO wallet.
    address public NAEMO = 0x6A5C5f7964d0cA5a313Bd237ecA6657F52F17810;

    // Address with permission to mint.
    // Vouchers must sign with the private key of this address.
    address public VOUCHER_CREATOR = 0x75a23e5b8F814aA3cAb4bCcBaa68D1Ad08e9525b;

    uint256 private _currentIndex = 0;

    // Mapping from token ID to burn status.
    // true: burned, false: unburned
    mapping(uint256 => bool) private _burned;

    // Maximum supply of token.
    uint256 public maxSupply = 10;

    // Mint price.
    // unit: wei
    uint256 public price = 1000000000000000;

    // Base URI of metadata.
    string public baseURI = "ipfs://QmQbRroNMsDZuYEG3w6ZfJa8PA8EpaQdAJVMZ8MMZQFXWs/";

    // Sale status of token.
    // true: for sale, false: not for sale
    bool public sale = true;

    // Royalty recipient wallet.
    address public royaltyRecipient = 0x2befD7D81039ba98b90c719A28E3e80Fe2Cf900E;

    // Basis point of royalty.
    // e.g. 100->0.1%
    uint96 public royaltyFeeBasisPoint = 500;

    modifier onlyNaemo() {
        require(_msgSender() == NAEMO, "Caller is not a NAEMO.");
        _;
    }

    modifier onlyEOA() {
        require(_msgSender() == tx.origin, "Caller cannot be a contract.");
        _;
    }

    constructor() ERC721("GenerativeTest", "GT") EIP712("GenerativeTest", "1") {
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
     * @dev Update voucher creator address.
     * @param voucherCreator VOUCHER_CREATOR wallet address.
     */
    function setVoucherCreator(address voucherCreator) external {
        require(_msgSender() == VOUCHER_CREATOR, "Caller is not a VOUCHER_CREATOR.");
        require(voucherCreator != address(0), "The VOUCHER_CREATOR cannot be null address.");
        VOUCHER_CREATOR = voucherCreator;
    }

    /**
     * @dev Update a selling price.
     * @param price_ The cost of minting.
     */
    function setPrice(uint256 price_) public onlyOwner {
        price = price_;
    }

    /**
     * @dev Update the base URI of tokens.
     * @param baseURI_ Base URI in IPFS or S3 format.
     */
    function setBaseURI(string memory baseURI_) public onlyOwner {
        baseURI = baseURI_;
    }

    /**
     * @dev Flip the sales status.
     */
    function flipSale() external onlyOwner {
        sale = !sale;
    }

    /**
     * @dev Update the royalty information of this collection.
     * @param royaltyRecipient_ Royalty recipient wallet.
     * @param royaltyFeeBasisPoint_ Basis point of royalty. e.g. 100->0.1%
     */
    function setTokenRoyalty(
        address royaltyRecipient_,
        uint96 royaltyFeeBasisPoint_
    ) external onlyOwner {
        royaltyRecipient = royaltyRecipient_;
        royaltyFeeBasisPoint = royaltyFeeBasisPoint_;
        _setDefaultRoyalty(royaltyRecipient_, royaltyFeeBasisPoint_);
    }

    /**
     * @dev Mint NFT by redeeming a voucher.
     *
     * Each voucher has token ID and token URI info.
     * It can be mint even if it is not on sale.
     * This function is non-payable.
     *
     * @param voucher Voucher with voucher information and signature of authorized signer.
     */
    function reserve(Voucher calldata voucher) external onlyEOA onlyOwner {
        require(_verify(voucher) == VOUCHER_CREATOR, "Unknown voucher signer.");
        require(totalSupply() + 1 <= maxSupply, "Supply has been exceeded.");
        require(!burned(voucher.tokenId), "Token number already burned.");

        _safeMint(_msgSender(), voucher.tokenId);
        _setTokenURI(voucher.tokenId, voucher.tokenURI);
        _currentIndex += 1;
    }

    /**
     * @dev Mint NFT by redeeming a voucher.
     *
     * Voucher has token ID and token URI info.
     *
     * @param voucher Voucher with voucher information and signature of authorized signer.
     */
    function redeem(Voucher calldata voucher) external payable onlyEOA {
        require(_verify(voucher) == VOUCHER_CREATOR, "Unknown voucher signer.");
        require(sale, "It's not on sale.");
        require(totalSupply() + 1 <= maxSupply, "Supply has been exceeded.");
        require(!burned(voucher.tokenId), "Token number already burned.");
        require(msg.value >= price, "Ether Amount Denied");

        _safeMint(_msgSender(), voucher.tokenId);
        _setTokenURI(voucher.tokenId, voucher.tokenURI);
        _currentIndex += 1;
    }

    /**
     * @dev Send balance of contract to address referenced in {NAEMO}.
     */
    function withdraw() external onlyNaemo {
        require(payable(NAEMO).send(address(this).balance));
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

    /**
     * @dev Verifies the signature for a given Voucher.
     * @param voucher Voucher with voucher information and signature of authorized signer.
     * @return {address} - Address of the Voucher signer.
     */
    function _verify(
        Voucher calldata voucher
    ) internal view returns (address) {
        return ECDSA.recover(_hash(voucher), voucher.signature);
    }

    /**
     * @dev Returns a hash of the given Voucher.
     * @return {bytes32} - Hash data of Voucher.
     */
    function _hash(Voucher calldata voucher) internal view returns (bytes32) {
        return
            _hashTypedDataV4(
                keccak256(
                    abi.encode(
                        keccak256("Voucher(uint256 tokenId,string tokenURI)"),
                        voucher.tokenId,
                        keccak256(bytes(voucher.tokenURI))
                    )
                )
            );
    }

    /**
     * @dev Returns the chain ID of the current blockchain.
     * @return {uint256} - Chain ID.
     */
    function getChainID() external view returns (uint256) {
        uint256 id;
        assembly { id := chainid() }
        return id;
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