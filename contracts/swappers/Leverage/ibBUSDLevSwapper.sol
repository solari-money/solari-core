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
//  ###################### ibBUSDLevSwapper.sol ######################
//  ##################################################################
//
// Author(s): 0xTerrence
//

pragma solidity 0.6.12;

import "../../lib/SafeMath.sol";
import "../../lib/SafeERC20.sol";
import "@sushiswap/bentobox-sdk/contracts/IBentoBoxV1.sol";
import "@sushiswap/core/contracts/uniswapv2/interfaces/IUniswapV2Pair.sol";

interface AlpacaVault {
    function deposit(uint256 amountToken) external;
    function balanceOf(address account) external view returns (uint256);
}

interface IWBNB {
    function deposit() external payable;
    function approve(address guy, uint256 wad) external;
    function balanceOf(address account) external view returns (uint256);
}

// solhint-disable-next-line contract-name-camelcase
contract ibBUSDLeverageSwapper {
    using SafeMath for uint256;
    using SafeERC20 for uint256;

    // Local variables
    IBentoBoxV1 public immutable bentoBox;

    // solhint-disable-next-line const-name-snakecase
    IUniswapV2Pair public constant WBNB_slUSD_PAIR = IUniswapV2Pair(address(0));
    IUniswapV2Pair public constant WBNB_BUSD_PAIR = IUniswapV2Pair(address(0));
    AlpacaVault public constant BUSD_VAULT = AlpacaVault(address(0));
    IWBNB public constant WBNB = IWBNB(address(0));

    // solhint-disable-next-line const-name-snakecase
    IERC20 public constant slUSD = IERC20(address(0));
    IERC20 public constant BUSD = IERC20(address(0));

    constructor(
        IBentoBoxV1 bentoBox_
    ) public {
        bentoBox = bentoBox_;

        slUSD.approve(address(WBNB_slUSD_PAIR), type(uint256).max);
        WBNB.approve(address(WBNB_BUSD_PAIR), type(uint256).max);
        BUSD.approve(address(BUSD_VAULT), type(uint256).max);
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

    // Swaps to a flexible amount, from an exact input amount
    function swap(
        address recipient,
        uint256 shareToMin,
        uint256 shareFrom
    ) public returns (uint256 extraShare, uint256 shareReturned) {

        (uint256 amountFrom, ) = bentoBox.withdraw(slUSD, address(this), address(this), 0, shareFrom);

        (uint256 reserve0, uint256 reserve1, ) = WBNB_slUSD_PAIR.getReserves();

        uint256 amountIntermediate = getAmountOut(amountFrom, reserve0, reserve1);

        WBNB_slUSD_PAIR.swap(0, amountIntermediate, address(this), new bytes(0));

        uint256 balance = WBNB.balanceOf(address(this));

        (reserve0, reserve1, ) = WBNB_BUSD.getReserves();

        amountIntermediate = getAmountOut(balance, reserve0, reserve1);

        WBNB_BUSD_PAIR.swap(0, amountIntermediate, address(this), new bytes(0));

        balance = BUSD.balanceOf(address(this));

        BUSD_VAULT.deposit(balance);

        uint256 amountTo = BUSD_VAULT.balanceOf(address(this));

        (, shareReturned) = bentoBox.deposit(IERC20(address(BUSD_VAULT)), address(bentoBox), recipient, amountTo, 0);
        extraShare = shareReturned.sub(shareToMin);
    }
}