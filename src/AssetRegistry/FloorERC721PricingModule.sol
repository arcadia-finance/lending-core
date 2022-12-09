/**
 * Created by Arcadia Finance
 * https://www.arcadia.finance
 *
 * SPDX-License-Identifier: BUSL-1.1
 */
pragma solidity >=0.4.22 <0.9.0;

import "./AbstractPricingModule.sol";

/**
 * @title Pricing Module for ERC721 tokens for which a oracle exists for the floor price of the collection
 * @author Arcadia Finance
 * @notice The FloorERC721PricingModule stores pricing logic and basic information for ERC721 tokens for which a direct price feeds exists
 * for the floor price of the collection
 * @dev No end-user should directly interact with the FloorERC721PricingModule, only the Main-registry, Oracle-Hub or the contract owner
 */
contract FloorERC721PricingModule is PricingModule {
    mapping(address => AssetInformation) public assetToInformation;

    struct AssetInformation {
        uint256 idRangeStart;
        uint256 idRangeEnd;
        address assetAddress;
        uint16[] assetCollateralFactors;
        uint16[] assetLiquidationThresholds;
        address[] oracleAddresses;
    }

    /**
     * @notice A Pricing Module must always be initialised with the address of the Main-Registry and of the Oracle-Hub
     * @param mainRegistry The address of the Main-registry
     * @param oracleHub The address of the Oracle-Hub
     */
    constructor(address mainRegistry, address oracleHub) PricingModule(mainRegistry, oracleHub) {}

    /*///////////////////////////////////////////////////////////////
                        ASSET MANAGEMENT
    ///////////////////////////////////////////////////////////////*/

    /**
     * @notice Adds a new asset to the FloorERC721PricingModule, or overwrites an existing asset.
     * @param assetInformation A Struct with information about the asset
     * - idRangeStart: The id of the first NFT of the collection
     * - idRangeEnd: The id of the last NFT of the collection
     * - assetAddress: The contract address of the asset
     * - assetCollateralFactors: The List of collateral factors for the asset for the different BaseCurrencies
     * - assetLiquidationThresholds: The List of liquidation thresholds for the asset for the different BaseCurrencies
     * - oracleAddresses: An array of addresses of oracle contracts, to price the asset in USD
     * @dev The list of Risk Variables (Collateral Factor and Liquidation Threshold) should either be as long as
     * the number of assets added to the Main Registry,or the list must have length 0.
     * If the list has length zero, the risk variables of the baseCurrency for all assets
     * is initiated as default (safest lowest rating).
     * @dev Risk variable are variables with 2 decimals precision
     * @dev The assets are added/overwritten in the Main-Registry as well.
     * By overwriting existing assets, the contract owner can temper with the value of assets already used as collateral
     * (for instance by changing the oracleaddres to a fake price feed) and poses a security risk towards protocol users.
     * This risk can be mitigated by setting the boolean "assetsUpdatable" in the MainRegistry to false, after which
     * assets are no longer updatable.
     */
    function setAssetInformation(AssetInformation memory assetInformation) external onlyOwner {
        //no asset units

        address assetAddress = assetInformation.assetAddress;

        IOraclesHub(oracleHub).checkOracleSequence(assetInformation.oracleAddresses);

        if (!inPricingModule[assetAddress]) {
            inPricingModule[assetAddress] = true;
            assetsInPricingModule.push(assetAddress);
        }

        assetToInformation[assetAddress].idRangeStart = assetInformation.idRangeStart;
        assetToInformation[assetAddress].idRangeEnd = assetInformation.idRangeEnd;
        assetToInformation[assetAddress].assetAddress = assetAddress;
        assetToInformation[assetAddress].oracleAddresses = assetInformation.oracleAddresses;
        _setRiskVariables(
            assetAddress, assetInformation.assetCollateralFactors, assetInformation.assetLiquidationThresholds
        );

        isAssetAddressWhiteListed[assetAddress] = true;

        require(IMainRegistry(mainRegistry).addAsset(assetAddress), "PM721_SAI: Unable to add in MR");
    }

    function setRiskVariables(
        address assetAddress,
        uint16[] memory assetCollateralFactors,
        uint16[] memory assetLiquidationThresholds
    ) external override onlyMainRegistry {
        _setRiskVariables(assetAddress, assetCollateralFactors, assetLiquidationThresholds);
    }

    function _setRiskVariables(
        address assetAddress,
        uint16[] memory assetCollateralFactors,
        uint16[] memory assetLiquidationThresholds
    ) internal override {
        // Check: Valid length of arrays
        uint256 baseCurrencyCounter = IMainRegistry(mainRegistry).baseCurrencyCounter();
        uint256 assetCollateralFactorsLength = assetCollateralFactors.length;
        require(
            (
                assetCollateralFactorsLength + 1 == baseCurrencyCounter
                    && assetCollateralFactorsLength == assetLiquidationThresholds.length
            ) || (assetCollateralFactorsLength == 0 && assetLiquidationThresholds.length == 0),
            "PM721_SRV: LENGTH_MISMATCH"
        );

        // Logic Fork: If the list are empty, initate the variables with default collateralFactor and liquidationThreshold
        if (assetCollateralFactorsLength == 0) {
            // Loop: Per base currency
            assetCollateralFactors = new uint16[](baseCurrencyCounter);
            assetLiquidationThresholds = new uint16[](baseCurrencyCounter);
            for (uint256 i; i < baseCurrencyCounter;) {
                // Write: Default variables for collateralFactor and liquidationThreshold
                // make in memory, store once
                assetCollateralFactors[i] = DEFAULT_COLLATERAL_FACTOR;
                assetLiquidationThresholds[i] = DEFAULT_LIQUIDATION_THRESHOLD;

                unchecked {
                    i++;
                }
            }

            assetToInformation[assetAddress].assetCollateralFactors = assetCollateralFactors;
            assetToInformation[assetAddress].assetLiquidationThresholds = assetLiquidationThresholds;
        } else {
            // Loop: Per value of collateral factor and liquidation threshold
            for (uint256 i; i < assetCollateralFactorsLength;) {
                // Check: Values in the allowed limit
                require(
                    assetCollateralFactors[i] <= MAX_COLLATERAL_FACTOR
                        && assetCollateralFactors[i] >= MIN_COLLATERAL_FACTOR,
                    "PM20_SRV: Coll.Fact not in limits"
                );
                require(
                    assetLiquidationThresholds[i] <= MAX_LIQUIDATION_THRESHOLD
                        && assetLiquidationThresholds[i] >= MIN_LIQUIDATION_THRESHOLD,
                    "PM20_SRV: Liq.Thres not in limits"
                );

                unchecked {
                    i++;
                }
            }

            assetToInformation[assetAddress].assetCollateralFactors = assetCollateralFactors;
            assetToInformation[assetAddress].assetLiquidationThresholds = assetLiquidationThresholds;
        }
    }

    /**
     * @notice Returns the information that is stored in the Pricing Module for a given asset
     * @dev struct is not taken into memory; saves 6613 gas
     * @param asset The Token address of the asset
     * @return idRangeStart The id of the first token of the collection
     * @return idRangeEnd The id of the last token of the collection
     * @return assetAddress The contract address of the asset
     * @return oracleAddresses The list of addresses of the oracles to get the exchange rate of the asset in USD
     */
    function getAssetInformation(address asset) external view returns (uint256, uint256, address, address[] memory) {
        return (
            assetToInformation[asset].idRangeStart,
            assetToInformation[asset].idRangeEnd,
            assetToInformation[asset].assetAddress,
            assetToInformation[asset].oracleAddresses
        );
    }

    /*///////////////////////////////////////////////////////////////
                        WHITE LIST MANAGEMENT
    ///////////////////////////////////////////////////////////////*/

    /**
     * @notice Checks for a token address and the corresponding Id if it is white-listed
     * @param assetAddress The address of the asset
     * @param assetId The Id of the asset
     * @return A boolean, indicating if the asset passed as input is whitelisted
     */
    function isWhiteListed(address assetAddress, uint256 assetId) external view override returns (bool) {
        if (isAssetAddressWhiteListed[assetAddress]) {
            if (isIdInRange(assetAddress, assetId)) {
                return true;
            }
        }

        return false;
    }

    /**
     * @notice Checks if the Id for a given token is in the range for which there exists a price feed
     * @param assetAddress The address of the asset
     * @param assetId The Id of the asset
     * @return A boolean, indicating if the Id of the given asset is whitelisted
     */
    function isIdInRange(address assetAddress, uint256 assetId) private view returns (bool) {
        if (
            assetId >= assetToInformation[assetAddress].idRangeStart
                && assetId <= assetToInformation[assetAddress].idRangeEnd
        ) {
            return true;
        } else {
            return false;
        }
    }

    /*///////////////////////////////////////////////////////////////
                          PRICING LOGIC
    ///////////////////////////////////////////////////////////////*/

    /**
     * @notice Returns the value of a certain asset, denominated in USD or in another BaseCurrency
     * @param getValueInput A Struct with all the information neccessary to get the value of an asset
     * - assetAddress: The contract address of the asset
     * - assetId: The Id of the asset
     * - assetAmount: Since ERC721 tokens have no amount, the amount should be set to 0
     * - baseCurrency: The BaseCurrency (base-asset) in which the value is ideally expressed
     * @return valueInUsd The value of the asset denominated in USD with 18 Decimals precision
     * @return valueInBaseCurrency The value of the asset denominated in BaseCurrency different from USD with 18 Decimals precision
     * @dev If the Oracle-Hub returns the rate in a baseCurrency different from USD, the FloorERC721PricingModule will return
     * the value of the asset in the same BaseCurrency. If the Oracle-Hub returns the rate in USD, the FloorERC721PricingModule
     * will return the value of the asset in USD.
     * Only one of the two values can be different from 0.
     * @dev If the asset is not first added to PricingModule this function will return value 0 without throwing an error.
     * However no check in FloorERC721PricingModule is necessary, since the check if the asset is whitelisted (and hence added to PricingModule)
     * is already done in the Main-Registry.
     */
    function getValue(GetValueInput memory getValueInput)
        public
        view
        override
        returns (uint256 valueInUsd, uint256 valueInBaseCurrency, uint256 collFactor, uint256 liqThreshold)
    {
        (valueInUsd, valueInBaseCurrency) = IOraclesHub(oracleHub).getRate(
            assetToInformation[getValueInput.assetAddress].oracleAddresses, getValueInput.baseCurrency
        );

        collFactor = assetToInformation[getValueInput.assetAddress].assetCollateralFactors[getValueInput.baseCurrency];
        liqThreshold =
            assetToInformation[getValueInput.assetAddress].assetLiquidationThresholds[getValueInput.baseCurrency];
    }
}
