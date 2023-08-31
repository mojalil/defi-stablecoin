// SPDX-License-Identifier: MIT

// Layout of Contract:
// version
// imports
// interfaces, libraries, contracts
// errors
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

import {DecentralizedStableCoin} from "./DecentralizedStableCoin.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

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
contract DSCEngine is ReentrancyGuard {
    // Errors
    error DSCEngine__MustBeMoreThanZero();
    error DSCEngine__TokenAddressesAndPriceFeedAddressesMustBeSameLength();
    error DSCEngine__NotAllowedToken();
    error DSCEngine__DepositTransferFailed();


    // State Variables
    mapping(address token => address s_priceFeeds) public s_priceFeeds;
    mapping(address user => mapping(address token => uint256 amount)) private s_collateralDeposited;

    DecentralizedStableCoin private immutable i_dsc;

    // Events
    event CollateralDeposited(address indexed user, address indexed token, uint256 indexed amount);

    // Modifiers
    modifier moreThanZero(uint256 _amount){
        if(_amount <= 0) {
            revert DSCEngine__MustBeMoreThanZero();
        }
        _;
    }

    modifier isAllowedToken(address token) {
        if(s_priceFeeds[token] == address(0)) {
            revert DSCEngine__NotAllowedToken();
        }
        _;
    }

    // Functions
    constructor(
        address[] memory tokenAddresses,
        address[] memory priceFeedAddresses,
        address dscAddress
    ) {
        // We will be using USD pricefeeds for all tokens
        if(tokenAddresses.length != priceFeedAddresses.length) {
            revert DSCEngine__TokenAddressesAndPriceFeedAddressesMustBeSameLength();
        }

        // E.g. ETH/USD, BTC/USD, LINK/USD, etc.
        for(uint256 i = 0; i < tokenAddresses.length; i++) {
            s_priceFeeds[tokenAddresses[i]] = priceFeedAddresses[i];
        }

        i_dsc = DecentralizedStableCoin(dscAddress);

    }

    // External Functions
    function depositCollateralAndMintDsc() external {}

    /**
     * @notice Follows CEI pattern (Checks - Effects - Interactions)
     * @param tokenCollateralAddress The address of the token to deposit
     * @param amountCollateral The amount of the token to deposit
     * @dev This function is meant to be called by the user. It will transfer the tokens from the user to this contract.
     * We are using the CEI pattern to prevent reentrancy attacks.
     * We are using IERC20 because the exteral may be a contract that is not standard ERC20 but does implment it's interface.
     */
    function depositCollateral( address tokenCollateralAddress, uint256 amountCollateral) 
        external 
        moreThanZero(amountCollateral) 
        isAllowedToken(tokenCollateralAddress)
        nonReentrant {
            s_collateralDeposited[msg.sender][tokenCollateralAddress] += amountCollateral;
            emit CollateralDeposited(msg.sender, tokenCollateralAddress, amountCollateral);
            bool success = IERC20(tokenCollateralAddress).transferFrom(msg.sender, address(this), amountCollateral);
            if(!success) {
                revert DSCEngine__DepositTransferFailed();
            }

        // Transfer the tokens from the user to this contract
        // Approve the transfer first
        // Transfer the tokens
        // Check the balance of the contract
        // If the balance is greater than the amount of collateral, mint DSC
        // If the balance is less than the amount of collateral, revert
        // If the balance is equal to the amount of collateral, do nothing
    }


    function redeemCollateralForDsc() external {}

    function redeemCollateral() external {}

    function mintDsc() external {}

    function burnDsc() external {}

    function liquidate() external {}

    function getHealthFactor() external view {}
}