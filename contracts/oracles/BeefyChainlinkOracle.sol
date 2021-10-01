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
//  #################### BeefyChainlinkOracle.sol ####################
//  ##################################################################
//
// Author(s): 0xTerrence
//

pragma solidity 0.6.12;

import "../lib/SafeMath.sol";
import "../interfaces/IOracle.sol";

// Chainlink Aggregator

interface IAggregator {
    function latestAnswer() external view returns (int256 answer);
}

// Beefy Vault

interface IBeefyVaultv6 {
    function pricePerFullShare() external view returns (uint256);
}

contract BeefyChainlinkOracle is IOracle {
    using SafeMath for uint256;

    // Calculates the latest exchange rate
    function _get(
        address multiply,
        address divide,
        uint256 decimals,
        address beefyVault
    ) internal view returns (uint256) {
        uint256 price = uint256(1e36);
        if (multiply != address(0)) {
            price = price.mul(uint256(IAggregator(multiply).latestAnswer()));
        } else {
            price = price.mul(1e18);
        }

        if (divide != address(0)) {
            price = price / uint256(IAggregator(divide).latestAnswer());
        }

        // @note decimals have to take into account the decimals of the vault asset
        return price / decimals.mul(IBeefyVaultV6(beefyVault).pricePerFullShare());
    }

    function getDataParameter(
        address multiply,
        address divide,
        uint256 decimals,
        address beefyVault
    ) public pure returns (bytes memory) {
        return abi.encode(multiply, divide, decimals, beefyVault);
    }

    // Get the latest exchange rate
    function get(bytes calldata data) public override returns (bool, uint256) {
        (address multiply, address divide, uint256 decimals, address beefyVault) = abi.decode(data, (address, address, uint256, address));
        return (true, _get(multiply, divide, decimals, beefyVault));
    }

    // Check the last exchange rate without any state changes
    function peek(bytes calldata data) public view override returns (bool, uint256) {
        (address multiply, address divide, uint256 decimals, address beefyVault) = abi.decode(data, (address, address, uint256, address));
        return (true, _get(multiply, divide, decimals, beefyVault));
    }

    // Check the current spot exchange rate without any state changes
    function peekSpot(bytes calldata data) external view override returns (uint256 rate) {
        (, rate) = peek(data);
    }

    function name(bytes calldata) public view override returns (string memory) {
        return "Chainlink";
    }

    function symbol(bytes calldata) public view override returns (string memory) {
        return "LINK";
    }
}