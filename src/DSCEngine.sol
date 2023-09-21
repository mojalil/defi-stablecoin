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
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

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
    uint256 private constant PRECISION = 1e18;
    uint256 private constant ADDITIONAL_FEED_PRECISION = 1e10;
    mapping(address token => address s_priceFeeds) public s_priceFeeds;
    mapping(address user => mapping(address token => uint256 amount))
        private s_collateralDeposited;
    mapping(address user => uint256 amountDscMinted) private s_DSCMinted;
    address[] private s_collateralTokens;

    DecentralizedStableCoin private immutable i_dsc;

    // Events
    event CollateralDeposited(
        address indexed user,
        address indexed token,
        uint256 indexed amount
    );

    // Modifiers
    modifier moreThanZero(uint256 _amount) {
        if (_amount <= 0) {
            revert DSCEngine__MustBeMoreThanZero();
        }
        _;
    }

    modifier isAllowedToken(address token) {
        if (s_priceFeeds[token] == address(0)) {
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
        if (tokenAddresses.length != priceFeedAddresses.length) {
            revert DSCEngine__TokenAddressesAndPriceFeedAddressesMustBeSameLength();
        }

        // E.g. ETH/USD, BTC/USD, LINK/USD, etc.
        for (uint256 i = 0; i < tokenAddresses.length; i++) {
            s_priceFeeds[tokenAddresses[i]] = priceFeedAddresses[i];
            s_collateralTokens.push(tokenAddresses[i]);
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
    function depositCollateral(
        address tokenCollateralAddress,
        uint256 amountCollateral
    )
        external
        moreThanZero(amountCollateral)
        isAllowedToken(tokenCollateralAddress)
        nonReentrant
    {
        s_collateralDeposited[msg.sender][
            tokenCollateralAddress
        ] += amountCollateral;
        emit CollateralDeposited(
            msg.sender,
            tokenCollateralAddress,
            amountCollateral
        );
        bool success = IERC20(tokenCollateralAddress).transferFrom(
            msg.sender,
            address(this),
            amountCollateral
        );
        if (!success) {
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

    /**
     * @notice Follows CEI pattern (Checks - Effects - Interactions)
     * @param amountDscToMint The amount of DSC to mint
     * @notice They must have more collateral than the amount of DSC they want to mint
     */
    function mintDsc(
        uint256 amountDscToMint
    ) external moreThanZero(amountDscToMint) nonReentrant {
        s_DSCMinted[msg.sender] += amountDscToMint;
        // If they minted too much ($150 DSC for $100 collateral), revert
        revertIfHealthFactorIsBroken(msg.sender);
    }

    function burnDsc() external {}

    function liquidate() external {}

    function getHealthFactor() external view {}

    // Private & Internal View Functions

    function _getAccountInformation(
        address user
    )
        private
        view
        returns (uint256 totalDscMinted, uint256 collateralValueInUsd)
    {
        // get the value of the collateral
        // get the value of the DSC
        // return the value of the collateral and the value of the DSC

        totalDscMinted = s_DSCMinted[user];
        collateralValueInUsd = getAccountCollateralValue(user);
    }

    /**
     * This function is used to calculate the health factor of a user. Returns how close the user is to being liquidated.
     * If a user goes below 1, they can get liquidated
     */
    function _healthFactor(address user) private view returns (uint256) {
        // get the value of the collateral
        // get the value of the DSC

        (
            uint256 totalDscMinted,
            uint256 collateralValueInUsd
        ) = _getAccountInformation(user);
        // divide the value of the collateral by the value of the DSC
        // return the health factor
    }

    function revertIfHealthFactorIsBroken(address user) internal view {
        // check health factor
        // if health factor is broken, revert, see AAVE docs for formula. Link: https://docs.aave.com/risk/asset-risk/risk-parameters
    }

    // Public & External View Functions

    /**
     * @notice This function is used to get the value of the collateral in USD
     * @param user The address of the user
     * @return totalCollateralValueInUsd The value of the collateral in USD
     */
    function getAccountCollateralValue(
        address user
    ) public view returns (uint256 totalCollateralValueInUsd) {
        // Loop through each collateral tokens and map it to the price
        for (uint256 i = 0; i < s_collateralTokens.length; i++) {
            address token = s_collateralTokens[i];
            uint256 amount = s_collateralDeposited[user][token];
            totalCollateralValueInUsd += getUsdValue(token, amount);
        }

        return totalCollateralValueInUsd;
    }

    function getUsdValue(
        address token,
        uint256 amount
    ) public view returns (uint256) {
        // Get the price feed address
        AggregatorV3Interface priceFeed = AggregatorV3Interface(
            s_priceFeeds[token]
        );
        // Get the price from the price feed
        (, int256 price, , , ) = priceFeed.latestRoundData();
        // if 1eth = $1000, the returned value is be 1000 * 10^8. We can check the decimals from chainlink docs
        // Convert the price to 10^18 decimals
        uint256 precisePrice = ((uint256(price) * ADDITIONAL_FEED_PRECISION) *
            amount) / PRECISION;
        // Return the price
        return precisePrice;
    }
}
