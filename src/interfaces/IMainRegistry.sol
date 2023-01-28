/**
 * Created by Arcadia Finance
 * https://www.arcadia.finance
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */
pragma solidity >=0.4.22 <0.9.0;

interface IMainRegistry {
    /**
     * @notice Returns number of basecurrencies.
     * @return counter the number of basecurrencies.
     */
    function baseCurrencyCounter() external view returns (uint256);

    /**
     * @notice Returns the Factory address.
     * @return factory The Factory address.
     */
    function factoryAddress() external view returns (address);

    /**
     * @notice Returns the contract of a basecurrency.
     * @param index The index of the baseCurrency in the array baseCurrencies.
     * @return baseCurrency The baseCurrency address.
     */
    function baseCurrencies(uint256 index) external view returns (address);

    /**
     * @notice Checks if a contract is a basecurrency.
     * @param baseCurrency The baseCurrency address.
     * @return boolean.
     */
    function isBaseCurrency(address baseCurrency) external view returns (bool);

    /**
     * @notice Checks if an action is allowed.
     * @param action The action address.
     * @return boolean.
     */
    function isActionAllowed(address action) external view returns (bool);

    /**
     * @notice Batch deposit multiple assets
     * @param assetAddresses An array of addresses of the assets
     * @param assetIds An array of asset ids
     * @param amounts An array of amounts to be deposited
     */
    function batchProcessDeposit(
        address[] calldata assetAddresses,
        uint256[] calldata assetIds,
        uint256[] calldata amounts
    ) external;

    /**
     * @notice Batch withdrawal multiple assets
     * @param assetAddresses An array of addresses of the assets
     * @param amounts An array of amounts to be withdrawn
     */
    function batchProcessWithdrawal(address[] calldata assetAddresses, uint256[] calldata amounts) external;

    /**
     * @notice Calculate the total value of a list of assets denominated in a given BaseCurrency
     * @param assetAddresses The List of token addresses of the assets
     * @param assetIds The list of corresponding token Ids that needs to be checked
     * @param assetAmounts The list of corresponding amounts of each Token-Id combination
     * @param baseCurrency The contract address of the BaseCurrency
     * @return valueInBaseCurrency The total value of the list of assets denominated in BaseCurrency
     */
    function getTotalValue(
        address[] calldata assetAddresses,
        uint256[] calldata assetIds,
        uint256[] calldata assetAmounts,
        address baseCurrency
    ) external view returns (uint256);

    /**
     * @notice Calculate the collateralValue given the asset details in given baseCurrency
     * @param assetAddresses The List of token addresses of the assets
     * @param assetIds The list of corresponding token Ids that needs to be checked
     * @param assetAmounts The list of corresponding amounts of each Token-Id combination
     * @param baseCurrency An address of the BaseCurrency contract
     * @return collateralValue Collateral value of the given assets denominated in BaseCurrency.
     */
    function getCollateralValue(
        address[] calldata assetAddresses,
        uint256[] calldata assetIds,
        uint256[] calldata assetAmounts,
        address baseCurrency
    ) external view returns (uint256);

    /**
     * @notice Calculate the getLiquidationValue given the asset details in given baseCurrency
     * @param assetAddresses The List of token addresses of the assets
     * @param assetIds The list of corresponding token Ids that needs to be checked
     * @param assetAmounts The list of corresponding amounts of each Token-Id combination
     * @param baseCurrency An address of the BaseCurrency contract
     * @return liquidationValue Liquidation value of the given assets denominated in BaseCurrency.
     */
    function getLiquidationValue(
        address[] calldata assetAddresses,
        uint256[] calldata assetIds,
        uint256[] calldata assetAmounts,
        address baseCurrency
    ) external view returns (uint256);
}
