# Decentralized Stable Coin (DSC) Engine

![Solidity Version](https://img.shields.io/badge/Solidity-0.8.18-blue?logo=solidity)
![Stablecoin Pegged](https://img.shields.io/badge/Pegged-USD%20$1.00-green)
![Collateral Supported](https://img.shields.io/badge/Collateral-wETH%20|%20wBTC-orange)
![Stability Mechanism](https://img.shields.io/badge/Stability-Algo--Decentralized-purple)

The **Decentralized Stable Coin Engine** offers an autonomous, decentralized, algorithmic stable coin system backed by wETH and wBTC. It aims to provide a 1:1 peg with the USD. Unlike other stablecoin systems, DSC eliminates governance interference, unwanted fees, and stays anchored at $1.00 USD.

## Key Features
- **Chainlink PriceFeed**: Ensure accurate, up-to-date, and tamper-resistant price data.
- **Stability Mechanism**: Algorithmically stabilized with decentralized mechanisms.
- **Overcollateralized**: Always maintain collateral value greater than the dollar value of DSC.
- **Collateral**: Exogenous backing through wETH and wBTC.

## Contract Details
The [DSCengine.sol](./contracts/DSCengine.sol) contract is the heart of the system. It handles:
- Depositing and withdrawing collateral.
- Minting and redeeming DSC.
- Health factor checks and liquidation.

## Functions

1. `depositCollateralAndMintDsc()`: Allows users to deposit collateral and mint DSC in one transaction.
2. `depositCollateral()`: Deposit collateral without minting DSC.
3. `redeemCollateralForDsc()`: Redeem DSC for its collateral value.
4. `redeemCollateral()`: Withdraw collateral.
5. `mintDsc()`: Mint new DSC tokens.
6. `burnDsc()`: Burn DSC tokens.
7. `liquidate()`: Liquidate unhealthy positions.
8. `getHealthFactor()`: View the current health factor for a given position.

## How It Compares

Imagine DAI, but with:
- No governance.
- No fees.
- Backed by both wETH and wBTC.

This is what DSC offers. A simplified, yet secure stable coin system.

## Usage

To integrate or use this system, deploy the contract, and call its functions as required by your platform. 

## Running Tests

To run individual test use forge test and match with the test you want to run e.g `forge test --match-test testGetUsdValue` or use `-vvv` tag for a more verborse output `forge test --match-test testGetUsdValue -vvv`

## Safety

Always ensure that you are interacting with the correct contract address. Beware of imitations or scams. We recommend reading the contract code thoroughly and even getting it audited by third-party services before using it in a production environment.

---

Designed with ❤️ by @motypes. Join our [community](#) for updates and discussions.