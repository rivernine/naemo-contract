# naemo-contract

## MODIFIED 2022-06-27
### 271-01. Check Effect Interaction Pattern Violated
1. `EditionDevV2` on line 281
- before
```js
_mint(_msgSender(), redeemVoucher.tokenId, amount, new bytes(0));
nonce[redeemVoucher.tokenId][redeemVoucher.nonce] = true;
payable(NAEMO).transfer(msg.value);
```

- after
```js
nonce[redeemVoucher.tokenId][redeemVoucher.nonce] = true;
payable(NAEMO).transfer(msg.value);
_mint(_msgSender(), redeemVoucher.tokenId, amount, new bytes(0));
```

2. `GenerativeSampleBeta` on line 146
- before
```js
_safeMint(_msgSender(), tokenId);
```

- after
```js
_mint(_msgSender(), tokenId);
```

3. `GenerativeTest` on line 200, 219
- before
```js
_safeMint(_msgSender(), voucher.tokenId);
```

- after
```js
_mint(_msgSender(), voucher.tokenId);
```

4. `UniqueBetaDev.sol` on line 83
- before
```js
_safeMint(_msgSender(), tokenInfo.tokenId);
```

- after
```js
_mint(_msgSender(), tokenInfo.tokenId);
```

### 271-02. Voucher Creation Out Of Scope
- Voucher signing and verification process will be continuously monitored

### 271-03. Request Clarification On Design
1. It is for compatiblity issue. We've tested that RARIBLE pays royalties using the information in EIP-2981. Therefore we decided to query the on-chain royalty information based on EIP-2981 for our business purpose as well. 

2. Any NFTs traded inside our marketplace is processed by off-chain DB.
The purpose of NFTs minted using this contract is to make an 1-to-1 mapped on-chain data.
Therefore we, the marketplace, keep the ownership of any on-chain NFT minted at the first place. When an user wants to export an NFT outside, we transfer the on-chain NFT to that user. 

### EDV-01. Lack Of Restriction On Function
1. Before minting, the token ID is generated as a random number, and the token ID is checked for existence.

### GEN-01. Missing Emit Events
Add event method.

1. `GenerativeTest.sol`
```js
event SetPrice(uint256 indexed _price);

event SetBaseURI(string indexed _baseURI);

event FlipSale(bool indexed _sale);

event SetTokenRoyalty(
    address indexed _royaltyRecipient, 
    uint96 indexed _royaltyFeeBasisPoint
);
```

2. `GenerativeSampleBeta.sol`
```js
event SetBaseURI(string indexed _baseURI);

event SetTokenRoyalty(
    address indexed _royaltyRecipient, 
    uint96 indexed _royaltyFeeBasisPoint
)
```

3. `EditionDevV2.sol`
```js
event SetPrice(
    uint256 indexed _tokenId, 
    uint256 indexed _price
);

event FlipSale(
    uint256 indexed _tokenId,
    bool indexed _sale
);

event SetTokenRoyalty(
    uint256 indexed _tokenId, 
    address indexed _royaltyRecipient, 
    uint96 indexed _royaltyFeeBasisPoint
);   
```

4. `UniqueBetaDev.sol`
```js
event SetTokenRoyalty(
    uint256 indexed _tokenId, 
    address indexed _royaltyRecipient, 
    uint96 indexed _royaltyFeeBasisPoint
);
```

### GSB-01. Centralization Related Risks In GenerativeSampleBeta
The private key of NAEMO is managed by HSM. 

### GTA-01. Centralization Related Risks In GenerativeTest
The private key of NAEMO is managed by HSM. 

<hr>

## Generative Art Contract
Generative art contract is created through creator's input values and templates.
### Alpha version
The alpha version is minted by the buyer using a meta mask.

### Beta version
The beta version can only mint NAEMO.

## Edition Contract
Edition contract is a shared contract. 

Minting scenario (alpha version) - Lazy minting
- Max supply is set at `initToken()`.
- Tokens are minted at `redeem()` 
1. Creator requests server an `InitVoucher`.
  - `InitVoucher` contains the initialization information of the token and the signature of `VOUCHER_CREATOR`.
2. Creator initializes a token by calling `initToken(InitVoucher)`.
3. Buyer requests server an `RedeemVoucher`.
4. Buyer mints given amount of tokens by calling `redeem(RedeemVoucher, amount)`.

Minting scenario (beta version)
- Max supply is minted at init token.
1. Creator mints max supply amount of token by calling `mint(TokenInfo)`.
2. All tokens are sent to NAEMO address.

## Unique Contract
Unique contract is a shred contract.

Minting scenario (alpha version)
1. The buyer uses a meta mask to mint.
2. Immediately after minting, the token is sent to NAEMO's wallet address.

