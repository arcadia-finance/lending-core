/**
 * Created by Arcadia Finance
 * https://www.arcadia.finance
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */
pragma solidity >=0.4.22 <0.9.0;

interface IMainRegistry {
    function addAsset(address, uint16[] calldata, uint16[] calldata) external;

    function getTotalValue(
        address[] calldata _assetAddresses,
        uint256[] calldata _assetIds,
        uint256[] calldata _assetAmounts,
        uint256 baseCurrency
    ) external view returns (uint256);

    function factoryAddress() external view returns (address);

    function baseCurrencyToInformation(uint256 baseCurrency)
        external
        view
        returns (uint64, uint64, address, address, string memory);

    function baseCurrencyCounter() external view returns (uint256);

    function batchIsWhiteListed(address[] calldata assetAddresses, uint256[] calldata assetIds)
        external
        view
        returns (bool);

    function assetToPricingModule(address) external view returns (address);

    function isBaseCurrency(address) external view returns (bool);

    function baseCurrencies(uint256) external view returns (address);
}
