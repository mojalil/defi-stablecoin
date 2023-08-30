// SPDX-License-Identifier: MIT

// Layout of Contract:
// version
// imports
// errors
// interfaces, libraries, contracts
// Type declarations
// State variables
// Events
// Modifiers
// Functions

// Layout of Functions:
// constructor
// receive function (if exists)
// fallback function (if exists)
// external
// public
// internal
// private
// view & pure functions

pragma solidity ^0.8.18;

/**
 * @title Decentralized Stable Coin Engine
 * @author @motypes
 * The system is designed to be as minimal and autonomous as possible, and have the tokens maintain a 1:1 peg with the USD.
 * This stablecoin has the properties:
 * - Collateral: Exogenous (ETH & BTC)
 * - Dollar Pegged
 * - Algorithmically Stable
 * 
 * It is similar to DAI if DAI had no governance, no fees and was backed by WETH and WBTC.
 * Our DSC system should always be "overcollateralized". At no point should the value of the collateral be less than the dollar value of the DSC.
 * @notice This contract is the core of the DSC system. It handles all the logic for minting and redeming DSC, as well as depositing & withdrawing collateral.
 */
contract DSCEngine {
    function depositCollateralAndMintDsc() external {}

    function depositCollateral() external {}

    function redeemCollateralForDsc() external {}

    function redeemCollateral() external {}

    function mintDsc() external {}

    function burnDsc() external {}

    function liquidate() external {}

    function getHealthFactor() external view {}
}