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
//  ######################## ibBUSDOracle.sol ########################
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

// solhint-disable contract-name-camelcase, const-name-snakecase

// TODO Finish this oracle
contract ibBUSDOracle is IOracle {
    using SafeMath for uint256;

    IAggregator public constant busdOracle = IAggregator(0x87Ea38c9F24264Ec1Fff41B04ec94a97Caf99941);
    IAggregator public constant bnbUsdOracle = IAggregator(0x0567F2323251f0Aab15c8dFb1967E4e8A7D42aeE);
}