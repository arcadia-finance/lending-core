/**
 * Created by Arcadia Finance
 * https://www.arcadia.finance
 *
 * SPDX-License-Identifier: MIT
 */
pragma solidity >=0.4.22 <0.9.0;

interface ITrustedCreditor {
    /**
     * @notice Checks if vault fulfills all requirements and returns application settings.
     * @param vaultVersion The current version of the vault
     * @return success Bool indicating if all requirements are met.
     * @return baseCurrency The base currency of the application.
     * @return liquidator The liquidator of the application.
     */
    function openMarginAccount(uint256 vaultVersion) external view returns (bool, address, address);

    /**
     * @notice Returns the open position of the vault.
     * @param vault The vault address.
     * @return openPosition The open position of the vault.
     */
    function getOpenPosition(address vault) external view returns (uint256);
}
