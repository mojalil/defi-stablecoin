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

import {ERC20Burnable, ERC20} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";

/**
 * @title Decentralized Stable Coin
 * @author @motypes
 * Collateral: Exogenous (ETH & BTC)
 * Minting: Algorithmic 
 * Relative Stability: Pegged to USD
 * 
 * This is meant to be governed by DSCEngine. This contract is just the ERC20 implemention of our Stable coin system.
 */
contract DecentralizedStableCoin {
    constructor() {
        
    }

}