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

import "@sushiswap/bentobox-sdk/contracts/IBentoBoxV1.sol";
import "./lib/SafeMath.sol";
import "./utils/ERC20.sol";
import "./utils/Ownable.sol";

/// @title Solari
/// @date Sep 2021
/// @dev Solari token implementation
contract Solari is ERC20, Ownable {
    using SafeMath for uint256;

    // ERC20 `variables`
    // solhint-disable-next-line const-name-snakecase
    string public constant symbol = "slUSD"; // TODO figure out actual token symbol

    // solhint-disable-next-line const-name-snakecase
    string public constant name = "Solari USD"; // TODO figure out actual token name

    // solhint-disable-next-line const-name-snakecase 
    uint8 public constant decimals = 18;

    // solhint-disable-next-line const-name-snakecase 
    uint256 public override totalSupply;

    struct Minting {
        uint128 time;
        uint128 amount;
    }

    Minting public lastMint;
    uint256 private constant MINTING_PERIOD = 24 hours;
    uint256 private constant MINTING_INCREASE = 15000;
    uint256 private constant MINTING_PRECISION = 1e5;

    /// @dev mints `amount` tokens to `to`
    /// @param to the account to mint to
    /// @param amount the amount to mint
    function mint(address to, uint256 amount) public onlyOwner {
        // solhint-disable-next-line reason-string
        require(to != address(0), "Solari: can not mint to zero address");

        // Limits the amount minted per period to a conversion function, with the period duration restarting every mint
        // solhint-disable-next-line not-rely-on-time
        uint256 totalMintedAmount = uint256(lastMint.time < block.timestamp - MINTING_PERIOD ? 0 : lastMint.amount).add(amount);

        // solhint-disable-next-line reason-string
        require(totalSupply == 0 || totalSupply.mul(MINTING_INCREASE) / MINTING_PRECISION >= totalMintedAmount);

        // solhint-disable-next-line not-rely-on-time
        lastMint.time = block.timestamp.to128();
        lastMint.amount = totalMintedAmount.to128();

        totalSupply = totalSupply + amount;
        balanceOf[to] += amount;
        emit Transfer(address(0), to, amount);
    }

    /// @dev mints tokens to BentoBox
    /// @param clone receiver
    /// @param amount the amount to mint
    /// @param bentoBox BentoBox contract
    function minttoBentoBox(address clone, uint256 amount, IBentoBoxV1 bentoBox) public onlyOwner {
        mint(address(bentoBox), amount);
        bentoBox.deposit(address(this), address(bentoBox), clone, amount, 0);
    }

    function burn(uint256 amount) public {
        require(amount <= balanceOf[msg.sender], "Solari: not enough balance");

        balanceOf[msg.sender] -= amount;
        totalSupply -= amount;
        emit Transfer(msg.sender, address(0), amount);
    }
}