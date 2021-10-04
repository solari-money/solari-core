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
//  ####################### mooCakeSwapper.sol #######################
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

interface BeefyVault {
    function withdrawAll() external;
}

interface ICake {
    function balanceOf(address account) external view returns (uint256);
    function approve(address spender, uint256 amount) external;
}

interface IWBNB {
    function balanceOF(address account) external view returns (uint256);
    function approve(address spender, uint256 amount) external;
}

// solhint-disable-next-line contract-name-camelcase
contract mooCakeSwapper is ISwapper {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // Local variables
    IBentoBoxV1 public immutable bentoBox;

    // TODO replace all zero addresses with production values
    ICake public constant CAKE = ICake(address(0));
    IWBNB public constant WBNB = IWBNB(address(0));
    BeefyVault public constant CAKE_VAULT = BeefyVault(address(0));
    IUniswapV2Pair public constant WBNB_CAKE_PAIR = IUniswapV2Pair(address(0));
    IUniswapV2Pair public constant WBNB_SLUSD_PAIR = IUniswapV2Pair(address(0));

    constructor(
        IBentoBoxV1 bentoBox_
    ) public {
        bentoBox = bentoBox_;
        CAKE.approve(WBNB_CAKE_PAIR, type(uint256).max);
        WBNB.approve(WBNB_SLUSD_PAIR, type(uint256).max);
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

        bentoBox.withdraw(fromToken, address(this), address(this), 0, shareFrom);

        CAKE_VAULT.withdrawAll();

        uint256 cakeBalance = CAKE.balanceOf(address(this));

        (uint256 reserve0, uint256 reserve1) = WBNB_CAKE_PAIR.getReserves();

        uint256 amountIntermediate = getAmountOut(cakeBalance, reserve0, reserve1);
        WBNB_CAKE_PAIR.swap(0, amountIntermediate, address(this), new bytes(0));

        uint256 wbnbBalance = WBNB.balanceOF(address(this));

        (uint256 reserve2, uint256 reserve3) = WBNB_SLUSD_PAIR.getReserves();

        amountIntermediate = getAmountOut(wbnbBalance, reserve2, reserve3);
        WBNB_SLUSD_PAIR.swap(0, amountIntermediate, address(this), new bytes(0));

        uint256 amountTo = toToken.balanceOf(address(this));

        (, shareReturned) = bentoBox.deposit(toToken, address(bentoBox), recipient, amountTo, 0);
        extraShare = shareReturned.sub(shareToMin);
    }
}