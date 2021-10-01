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
//  ######################## ibTUSDOracle.sol ########################
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

// Alpaca Vault

interface IAlpacaVault {
    function totalSupply() external view returns (uint256);
    function totalToken() external view returns (uint256);
}

// solhint-disable contract-name-camelcase, const-name-snakecase
contract ibTUSDOracle is IOracle {
    using SafeMath for uint256;

    IAlpacaVault public constant vault = IAlpacaVault(0x3282d2a151ca00BfE7ed17Aa16E42880248CD3Cd);

    // TODO replace with production address
    IAggregator public constant tusdOracle = IAggregator(0x87Ea38c9F24264Ec1Fff41B04ec94a97Caf99941);
    IAggregator public constant bnbUsdOracle = IAggregator(0x0567F2323251f0Aab15c8dFb1967E4e8A7D42aeE);

    // Calculates the latest exchange rate
    _get() internal view returns (uint256) {
        /// @dev calculates exchange rate between ibTUSD and TUSD
        uint256 exchangeRate = vault.totalToken().div(vault.totalSupply());

        return 1e44 / uint256(tusdOracle.latestAnswer()).mul(exchangeRate).mul(uint256(bnbUsdOracle.latestAnswer()));
    }

    // Get the latest exchange rate
    function get(bytes calldata) public override returns (bool, uint256) {
        return (true, _get());
    }

    // Check the last exchange rate without any changes
    function peek(bytes calldata) public view override returns (bool, uint256) {
        return (true, _get());
    }

    // Check the current spot exchange rate without any state changes
    function peekSpot(bytes calldata data) external view override returns (uint256 rate) {
        (, rate) = peek(data);
    }

    function name(bytes calldata) public view override returns (string memory) {
        return "ibTUSD Chainlink";
    }

    function symbol(bytes calldata) public view override returns (string memory) {
        return "LINK/ibTUSD";
    }
}