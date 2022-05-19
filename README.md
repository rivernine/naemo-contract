# naemo-contract

## Generative Art Contract
Generative art contract is created through creator's input values and templates.

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