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
//  ########################### Solari.sol ###########################
//  ##################################################################
//
// Author(s): 0xTerrence
//

pragma solidity 0.6.12;

import "./lib/SafeMath.sol";
import "./utils/ERC20.sol";
import "./utils/Ownable.sol";

/// @title Solari
/// @date Sep 2021
/// @dev Solari Token implementation
contract Solari is ERC20, Ownable {
    using SafeMath for uint256;

    // ERC20 `variables`
    // solhint-disable-next-line const-name-snakecase
    string public constant symbol = "SOLARI";

    // solhint-disable-next-line const-name-snakecase
    string public constant name = "Solari Token";

    // solhint-disable-next-line const-name-snakecase
    uint8 public constant decimals = 18;

    uint256 public override totalSupply;

    uint256 public constant MAX_SUPPLY = 1e27; // 1 billion tokens

    /// @dev mints `amount` tokens to account `to`
    /// @param to the account to mint to
    /// @param amount the amount to mint
    function mint(address to, uint256 amount) public onlyOwner {
        // solhint-disable-next-line reason-string
        require(to != address(0), "SOLARI: can not mint to zero address");
        require(MAX_SUPPLY >= totalSupply.add(amount), "SOLARI: Don't go over MAX");

        totalSupply += amount;
        balanceOf[to] += amount;
        emit Transfer(address(0), to, amount);
    }
}