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
    error DSCEngine__RedeemTransferFailed();
    error DSCEngine__BurnTransferFailed();
    error DSCEngine__BreaksHealthFactor(uint256 healthFactor);
    error DSCEngine__MintFailed();
    error DSCEngine__HealthFactorOk();
    error DSCEngine__HealthFactorNotImproved();

    // State Variables
    uint256 private constant PRECISION = 1e18;
    uint256 private constant ADDITIONAL_FEED_PRECISION = 1e10;
    uint256 private constant LIQUIDATION_THRESHOLD = 50; // means you have to be 200% over collateralized to be safe
    uint256 private constant LIQUIDATION_PRECISION = 100;
    uint256 private constant MIN_HEALTH_FACTOR = 1;
    uint256 private constant LIQUIDATION_BONUS = 10; // 10% bonus for liquidating someone

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

    event CollateralRedeemed(
        address indexed redeemedFrom,
        address indexed redeemedTo,
        address indexed token,
        uint256 amount
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

    /**
     *
     * @param tokenCollateralAddress The address of the token to deposit
     * @param amountCollateral The amount of the token to deposit
     * @param amountDscToMint The amount of DSC to mint
     * @notice this function will deposit the collateral and mint the DSC
     */
    function depositCollateralAndMintDsc(
        address tokenCollateralAddress,
        uint256 amountCollateral,
        uint256 amountDscToMint
    ) external {
        depositCollateral(tokenCollateralAddress, amountCollateral);
        mintDsc(amountDscToMint);
    }

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
        public
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

    /**
     *
     * @param tokenCollateralAddress The address of the token to redeem
     * @param amountCollateral The amount of the token to redeem
     * @param amountDscToBurn The amount of DSC to burn
     * @notice this function will redeem the collateral and burn the DSC in one transaction
     */
    function redeemCollateralForDsc(
        address tokenCollateralAddress,
        uint256 amountCollateral,
        uint256 amountDscToBurn
    ) external {
        burnDsc(amountDscToBurn);
        // redeem collateral already checks health factor
        redeemCollateral(tokenCollateralAddress, amountCollateral);
    }

    // In order to redeem collateral
    // 1. health factor must be over 1 AFTER collateral is pulled
    // Follow CEI: Checks - Effects - Interactions
    function redeemCollateral(
        address tokenCollateralAddress,
        uint256 amountCollateral
    ) public moreThanZero(amountCollateral) nonReentrant {
        _redeemCollateral(
            tokenCollateralAddress,
            amountCollateral,
            msg.sender,
            msg.sender
        );
        _revertIfHealthFactorIsBroken(msg.sender);
    }

    /**
     * @notice Follows CEI pattern (Checks - Effects - Interactions)
     * @param amountDscToMint The amount of DSC to mint
     * @notice They must have more collateral than the amount of DSC they want to mint
     */
    function mintDsc(
        uint256 amountDscToMint
    ) public moreThanZero(amountDscToMint) nonReentrant {
        s_DSCMinted[msg.sender] += amountDscToMint;
        // If they minted too much ($150 DSC for $100 collateral), revert
        _revertIfHealthFactorIsBroken(msg.sender);
        bool minted = i_dsc.mint(msg.sender, amountDscToMint);
        if (!minted) {
            revert DSCEngine__MintFailed();
        }
    }

    function burnDsc(uint256 amount) public moreThanZero(amount) {
        _burnDsc(amount, msg.sender, msg.sender);
        _revertIfHealthFactorIsBroken(msg.sender);
    }

    // If someone is almost undercollateralized, users will be paid to liquidate them
    /**
     *
     * @param collateral The ERC20 collateral address to liquidate
     * @param user The user who has broken the healthfactor. The _healthFactor should be below MIN_HEALTH_FACTOR
     * @param debtToCover The amount of DSC to burn to improve the health factor
     * @notice You can partially liquidate a user by passing in the amount of DSC to burn
     * @notice You will get a liquidation reward for liquidating a user
     * @notice This function working assumes the protocol is 200% overcollateralized
     * @notice A known bug would be if the protocol was 100% or less overcollateralized, then the liquidator would not be incentivised to liquidate
     */
    function liquidate(
        address collateral,
        address user,
        uint256 debtToCover
    ) external moreThanZero(debtToCover) nonReentrant {
        uint256 startingUserHealthFactor = _healthFactor(user);

        // We want to exit if the user has a good health factor, this is a liquidation function
        if (startingUserHealthFactor >= MIN_HEALTH_FACTOR) {
            revert DSCEngine__HealthFactorOk();
        }

        // We want to burn DSC and take their collateral

        uint256 tokenAmountFromDebtCovered = getTokenAmountFromUsd(
            collateral,
            debtToCover
        );

        //  And give them a 10% bonus
        uint256 bonusCollateral = (tokenAmountFromDebtCovered *
            LIQUIDATION_BONUS) / LIQUIDATION_PRECISION;

        uint256 totalCollateralToRedeem = tokenAmountFromDebtCovered +
            bonusCollateral;

        // We want to redeem the collateral
        _redeemCollateral(
            collateral,
            totalCollateralToRedeem,
            user,
            msg.sender
        );

        _burnDsc(debtToCover, user, msg.sender);

        uint256 endingUserHealthFactor = _healthFactor(user);

        // We want to make sure the health factor is better after the liquidation
        if (endingUserHealthFactor < startingUserHealthFactor) {
            revert DSCEngine__HealthFactorNotImproved();
        }

        // We should also call revert if healtfactor is broken for msg.msg.sender
        _revertIfHealthFactorIsBroken(msg.sender);
    }

    function getHealthFactor() external view {}

    // Private & Internal View Functions

    function _burnDsc(
        uint256 amountDscToBurn,
        address onBehalfOf,
        address dscFrom
    ) private {
        s_DSCMinted[onBehalfOf] -= amountDscToBurn;
        bool success = i_dsc.transferFrom(dscFrom, address(this), amountDscToBurn);

        if (!success) {
            revert DSCEngine__BurnTransferFailed();
        }

        i_dsc.burn(amountDscToBurn);
    }

    function _redeemCollateral(
        address tokenCollateralAddress,
        uint256 amountCollateral,
        address from,
        address to
    ) private {
        s_collateralDeposited[from][tokenCollateralAddress] -= amountCollateral;
        emit CollateralRedeemed(
            from,
            to,
            tokenCollateralAddress,
            amountCollateral
        );
        bool success = IERC20(tokenCollateralAddress).transfer(
            to,
            amountCollateral
        );
        if (!success) {
            revert DSCEngine__RedeemTransferFailed();
        }
    }

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

        // Return adujusted health factor using the liquidation threshold
        uint256 collateralAdjustedForThreshold = (collateralValueInUsd *
            LIQUIDATION_THRESHOLD) / LIQUIDATION_PRECISION;

        return (collateralAdjustedForThreshold * PRECISION) / totalDscMinted;
    }

    function _revertIfHealthFactorIsBroken(address user) internal view {
        // check health factor
        // if health factor is broken, revert, see AAVE docs for formula. Link: https://docs.aave.com/risk/asset-risk/risk-parameters

        uint256 userHealthFactor = _healthFactor(user);

        if (userHealthFactor < MIN_HEALTH_FACTOR) {
            revert DSCEngine__BreaksHealthFactor(userHealthFactor);
        }
    }

    // Public & External View Functions

    /**
     *
     * @param token The address of the token to get the amount of
     * @param usdAmountInWei The amount of USD in wei to get the amount of tokens
     */
    function getTokenAmountFromUsd(
        address token,
        uint256 usdAmountInWei
    ) public view returns (uint256) {
        // Price of eth
        // Price of token
        AggregatorV3Interface priceFeed = AggregatorV3Interface(
            s_priceFeeds[token]
        );
        (, int256 price, , , ) = priceFeed.latestRoundData();

        return
            (usdAmountInWei * PRECISION) /
            (uint256(price) * ADDITIONAL_FEED_PRECISION);
    }

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
        // Convert the price to 10^18 decimals so they are all the right precision. Then divide by the precision to get the price (otherwise it'll be a huge number)
        uint256 precisePrice = ((uint256(price) * ADDITIONAL_FEED_PRECISION) *
            amount) / PRECISION;
        // Return the price
        return precisePrice;
    }
}
