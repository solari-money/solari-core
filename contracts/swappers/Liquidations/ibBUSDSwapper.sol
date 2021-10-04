//  SPDX-License-Identifier: MIT
//
//  ##################################################################
//  ##################################################################
//  |      ___       ___       ___       ___       ___       ___     |
//  |     /\  \     /\  \     /\__\     /\  \     /\  \     /\  \    |
//  |    /::\  \   /::\  \   /:/  /    /::\  \   /::\  \   _\:\  \   |
//  |   /\:\:\__\ /:/\:\__\ /:/__/    /::\:\__\ /::\:\__\ /\/::\__\  |
//  |   \:\:\/__/ \:\/:/  / \:\  \    \/\::/  / \;:::/  / \::/\/__/  |
//  |    \::/  /   \::/  /   \:\__\     /:/  /   |:\/__/   \:\__\    |
//  |     \/__/     \/__/     \/__/     \/__/     \|__|     \/__/    |
//  |                                                                |
//  ##################################################################
//  ######################## ibBUSDSwapper.sol #######################
//  ##################################################################
//
// Author(s): 0xTerrence
//

pragma solidity 0.6.12;

import "@sushiswap/core/contracts/uniswapv2/interfaces/IUniswapV2Pair.sol";
import "@sushiswap/bentobox-sdk/contracts/IBentoBoxV1.sol";
import "../../lib/SafeMath.sol";
import "../../lib/SafeERC20.sol";
import "../../interfaces/ISwapper.sol";

interface AlpacaVault {
    function withdraw(uint256 share) external;
    function balanceOf(address account) external view;
}

interface IBUSD {
    function balanceOf(address account) external view returns (uint256);
    function approve(address spender, uint256 amount) external;
}

interface IWBNB {
    function deposit() external payable;
    function approve(address guy, uint256 wad) external;
    function balanceOf(address account) external view returns (uint256);
}

// solhint-disable-next-line contract-name-camelcase
contract ibBUSDSwapper is ISwapper {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // Local variables
    IBentoBoxV1 public immutable bentoBox;

    // TODO Replace all zero addresses with production values
    IBUSD public constant BUSD = IBUSD(address(0));
    IWBNB public constant WBNB = IWBNB(address(0));
    AlpacaVault public constant BUSD_VAULT = AlpacaVault(address(0));
    IUniswapV2Pair public constant WBNB_SLUSD_PAIR = IUniswapV2Pair(address(0));
    IUniswapV2Pair public constant WBNB_BUSD_PAIR = IUniswapV2Pair(address(0));

    constructor(
        IBentoBoxV1 bentoBox_
    ) public {
        bentoBox = bentoBox_;
        BUSD.approve(address(WBNB_BUSD_PAIR), type(uint256).max);
        IWBNB.approve(address(WBNB_SLUSD_PAIR), type(uint256).max);
    }

    // Given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) internal pure returns (uint256 amountOut) {
        uint256 amountInWithFee = amountIn.mul(997);
        uint256 numerator = amountInWithFee.mul(reserveOut);
        uint256 denominator = reserveIn.mul(1000).add(amountInWithFee);
        amountOut = numerator / denominator;
    }

    // Given an output amount of an asset and pair reserves, returns a required input amount of the other asset
    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) internal pure returns (uint256 amountIn) {
        uint256 numerator = reserveIn.mul(amountOut).mul(1000);
        uint256 denominator = reserveOut.sub(amountOut).mul(997);
        amountIn = (numerator / denominator).add(1);
    }

    function swap(
        IERC20 fromToken,
        IERC20 toToken,
        address recipient,
        uint256 shareToMin,
        uint256 shareFrom
    ) public override returns (uint256 extraShare, uint256 shareReturned) {
        
        (uint256 amountFrom, ) = bentoBox.withdraw(fromToken, address(this), address(this), 0, shareFrom);

        BUSD_VAULT.withdraw(amountFrom);

        uint256 busdBalance = BUSD.balanceOf(address(this));

        (uint256 reserve0, uint256 reserve1) = WBNB_BUSD_PAIR.getReserves();

        uint256 amountIntermediate = getAmountOut(busdBalance, reserve0, reserve1);
        WBNB_BUSD_PAIR.swap(0, amountIntermediate, address(this), new bytes(0));

        uint256 wbnbBalance = WBNB.balanceOf(address(this));

        (uint256 reserve2, uint256 reserve3) = WBNB_SLUSD_PAIR.getReserves();

        amountIntermediate = getAmountOut(wbnbBalance, reserve2, reserve3);
        WBNB_SLUSD_PAIR.swap(0, amountIntermediate, address(this), new bytes(0));

        uint256 amountTo = toToken.balanceOf(address(this));

        (, shareReturned) = bentoBox.deposit(toToken, address(bentoBox), recipient, amountTo, 0);
        extraShare = shareReturned.sub(shareToMin);
    }

    // solhint-disable no-unused-vars
    // Swaps to an exact amount, from a flexible input amount
    function swapExact(
        IERC20 fromToken,
        IERC20 toToken,
        address recipient,
        address refundTo,
        uint256 shareFromSupplied,
        uint256 shareToExact
    ) public override returns (uint256 shareUsed, uint256 shareReturned) {
        return (0,0);
    }
}