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

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";

contract SignatureVerifierDevV2 is EIP712 {

    struct InitVoucher {
        uint256 tokenId;        
        address creator;
        uint256 maxSupply;
        string tokenURI;
        address royaltyRecipient;
        uint96 royaltyFeeBasisPoint;
        uint256 price;
        uint256 maxAmountPerTx;
        bool sale;
        bytes signature;
    }

    struct RedeemVoucher {
        uint256 tokenId;
        uint256 nonce;
        bytes signature;
    }

    // Signature domain name
    string private constant SIGNATURE_DOMAIN = "EditionDev";

    // Signature domain version
    string private constant SIGNATURE_VERSION = "1";

    constructor() EIP712(SIGNATURE_DOMAIN, SIGNATURE_VERSION) {}

    /**
     * @dev Verifies the signature for a given InitVoucher.
     * @param voucher InitVoucher with voucher information and signature of authorized signer.
     * @return {address} - Address of the InitVoucher signer.
     */
    function _verifyInitVoucher(
        InitVoucher calldata voucher
    ) internal view returns (address) {
        return ECDSA.recover(_hashInitVoucher(voucher), voucher.signature);
    }

    /**
     * @dev Returns a hash of the given InitVoucher
     * @return {bytes32} - Hash data of InitVoucher.
     */
    function _hashInitVoucher(
        InitVoucher calldata voucher
    ) internal view returns (bytes32) {
        return
            _hashTypedDataV4(
                keccak256(
                    abi.encode(
                        keccak256("InitVoucher(uint256 tokenId,address creator,uint256 maxSupply,string tokenURI,address royaltyRecipient,uint96 royaltyFeeBasisPoint,uint256 price,uint256 maxAmountPerTx,bool sale)"),
                        voucher.tokenId,
                        voucher.creator,
                        voucher.maxSupply,
                        keccak256(bytes(voucher.tokenURI)),
                        voucher.royaltyRecipient,
                        voucher.royaltyFeeBasisPoint,
                        voucher.price,
                        voucher.maxAmountPerTx,
                        voucher.sale
                    )
                )
            );
    }

    /**
     * @dev Verifies the signature for a given RedeemVoucher.
     * @param voucher RedeemVoucher with voucher information and signature of authorized signer.
     * @return {address} - Address of the RedeemVoucher signer.
     */
    function _verifyRedeemVoucher(
        RedeemVoucher calldata voucher
    ) internal view returns (address) {
        return ECDSA.recover(_hashRedeemVoucher(voucher), voucher.signature);
    }

    /**
     * @dev Returns a hash of the given RedeemVoucher.
     * @return {bytes32} - Hash data of RedeemVoucher.
     */
    function _hashRedeemVoucher(
        RedeemVoucher calldata voucher
    ) internal view returns (bytes32) {
        return
            _hashTypedDataV4(
                keccak256(
                    abi.encode(
                        keccak256("RedeemVoucher(uint256 tokenId,uint256 nonce)"),
                        voucher.tokenId,
                        voucher.nonce
                    )
                )
            );
    }

    /**
     * @dev Returns the chain id of the current blockchain.
     * @return {uint256} 
     */
    function getChainID() external view returns (uint256) {
        uint256 id;
        assembly {
            id := chainid()
        }
        return id;
    }
}
