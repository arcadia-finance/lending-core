/**
 * Created by Arcadia Finance
 * https://www.arcadia.finance
 *
 * SPDX-License-Identifier: BUSL-1.1
 */
pragma solidity ^0.8.13;

import "../lib/forge-std/src/Test.sol";
import { DeployAddresses, DeployNumbers, DeployBytes } from "./Constants/DeployConstants.sol";

import "../src/Factory.sol";
import "../src/Proxy.sol";
import "../src/Vault.sol";
import { ERC20 } from "../lib/solmate/src/tokens/ERC20.sol";
import "../src/MainRegistry.sol";
import { PricingModule, StandardERC20PricingModule } from "../src/PricingModules/StandardERC20PricingModule.sol";
import "../src/OracleHub.sol";
import { RiskConstants } from "../src/utils/RiskConstants.sol";

contract ArcadiaVaultDeployer is Test {
    Factory public factory;
    Vault public vault;
    ERC20 public dai;
    ERC20 public eth;
    ERC20 public link;
    ERC20 public snx;
    ERC20 public usdc;
    ERC20 public btc;
    OracleHub public oracleHub;
    MainRegistry public mainRegistry;
    StandardERC20PricingModule public standardERC20PricingModule;

    address[] public oracleDaiToUsdArr = new address[](1);
    address[] public oracleEthToUsdArr = new address[](1);
    address[] public oracleLinkToEthEthToUsdArr = new address[](2);
    address[] public oracleSnxToUsdArr = new address[](1);
    address[] public oracleUsdcToUsdArr = new address[](1);
    address[] public oracleBtcToEthEthToUsdArr = new address[](2);

    uint16 public collateralFactor = RiskConstants.DEFAULT_COLLATERAL_FACTOR;
    uint16 public liquidationFactor = RiskConstants.DEFAULT_LIQUIDATION_FACTOR;

    PricingModule.RiskVarInput[] public riskVarsDai;
    PricingModule.RiskVarInput[] public riskVarsEth;
    PricingModule.RiskVarInput[] public riskVarsLink;
    PricingModule.RiskVarInput[] public riskVarsSnx;
    PricingModule.RiskVarInput[] public riskVarsUsdc;
    PricingModule.RiskVarInput[] public riskVarsBtc;

    OracleHub.OracleInformation public daiToUsdOracleInfo;
    OracleHub.OracleInformation public ethToUsdOracleInfo;
    OracleHub.OracleInformation public linkToEthEthToUsdOracleInfo;
    OracleHub.OracleInformation public snxToUsdOracleInfo;
    OracleHub.OracleInformation public usdcToUsdOracleInfo;
    OracleHub.OracleInformation public btcToEthEthToUsdOracleInfo;

    MainRegistry.BaseCurrencyInformation public usdBaseCurrencyInfo;
    MainRegistry.BaseCurrencyInformation public ethBaseCurrencyInfo;
    MainRegistry.BaseCurrencyInformation public usdcBaseCurrencyInfo;

    address public deployerAddress;

    constructor() {
        dai = ERC20(DeployAddresses.dai);
        eth = ERC20(DeployAddresses.eth);
        link = ERC20(DeployAddresses.link);
        snx = ERC20(DeployAddresses.snx);
        usdc = ERC20(DeployAddresses.usdc);
        btc = ERC20(DeployAddresses.btc);

        oracleDaiToUsdArr[0] = DeployAddresses.oracleDaiToUsd;
        oracleEthToUsdArr[0] = DeployAddresses.oracleEthToUsd;
        oracleLinkToEthEthToUsdArr[0] = DeployAddresses.oracleLinkToEth;
        oracleLinkToEthEthToUsdArr[1] = DeployAddresses.oracleEthToUsd;
        oracleSnxToUsdArr[0] = DeployAddresses.oracleSnxToUsd;
        oracleUsdcToUsdArr[0] = DeployAddresses.oracleUsdcToUsd;
        oracleBtcToEthEthToUsdArr[0] = DeployAddresses.oracleBtcToEth;
        oracleBtcToEthEthToUsdArr[1] = DeployAddresses.oracleEthToUsd;

        daiToUsdOracleInfo = OracleHub.OracleInformation({
            oracleUnit: uint64(DeployNumbers.oracleDaiToUsdUnit),
            baseAssetBaseCurrency: uint8(DeployNumbers.UsdBaseCurrency),
            quoteAsset: "DAI",
            baseAsset: "USD",
            oracle: DeployAddresses.oracleDaiToUsd,
            quoteAssetAddress: DeployAddresses.dai,
            baseAssetIsBaseCurrency: true,
            isActive: true
        });

        ethToUsdOracleInfo = OracleHub.OracleInformation({
            oracleUnit: uint64(DeployNumbers.oracleEthToUsdUnit),
            baseAssetBaseCurrency: uint8(DeployNumbers.UsdBaseCurrency),
            quoteAsset: "ETH",
            baseAsset: "USD",
            oracle: DeployAddresses.oracleEthToUsd,
            quoteAssetAddress: DeployAddresses.eth,
            baseAssetIsBaseCurrency: true,
            isActive: true
        });

        linkToEthEthToUsdOracleInfo = OracleHub.OracleInformation({
            oracleUnit: uint64(DeployNumbers.oracleLinkToEthUnit),
            baseAssetBaseCurrency: uint8(DeployNumbers.EthBaseCurrency),
            quoteAsset: "LINK",
            baseAsset: "ETH",
            oracle: DeployAddresses.oracleLinkToEth,
            quoteAssetAddress: DeployAddresses.link,
            baseAssetIsBaseCurrency: true,
            isActive: true
        });

        snxToUsdOracleInfo = OracleHub.OracleInformation({
            oracleUnit: uint64(DeployNumbers.oracleSnxToUsdUnit),
            baseAssetBaseCurrency: uint8(DeployNumbers.UsdBaseCurrency),
            quoteAsset: "SNX",
            baseAsset: "USD",
            oracle: DeployAddresses.oracleSnxToUsd,
            quoteAssetAddress: DeployAddresses.snx,
            baseAssetIsBaseCurrency: true,
            isActive: true
        });

        usdcToUsdOracleInfo = OracleHub.OracleInformation({
            oracleUnit: uint64(DeployNumbers.oracleUsdcToUsdUnit),
            baseAssetBaseCurrency: uint8(DeployNumbers.UsdBaseCurrency),
            quoteAsset: "USDC",
            baseAsset: "USD",
            oracle: DeployAddresses.oracleUsdcToUsd,
            quoteAssetAddress: DeployAddresses.usdc,
            baseAssetIsBaseCurrency: true,
            isActive: true
        });

        btcToEthEthToUsdOracleInfo = OracleHub.OracleInformation({
            oracleUnit: uint64(DeployNumbers.oracleBtcToEthUnit),
            baseAssetBaseCurrency: uint8(DeployNumbers.EthBaseCurrency),
            quoteAsset: "BTC",
            baseAsset: "ETH",
            oracle: DeployAddresses.oracleBtcToEth,
            quoteAssetAddress: DeployAddresses.btc,
            baseAssetIsBaseCurrency: true,
            isActive: true
        });

        ethBaseCurrencyInfo = MainRegistry.BaseCurrencyInformation({
            baseCurrencyToUsdOracleUnit: uint64(DeployNumbers.oracleEthToUsdUnit),
            assetAddress: DeployAddresses.eth,
            baseCurrencyToUsdOracle: address(DeployAddresses.oracleEthToUsd),
            baseCurrencyLabel: "wETH",
            baseCurrencyUnitCorrection: uint64(10 ** (18 - DeployNumbers.ethDecimals))
        });

        usdcBaseCurrencyInfo = MainRegistry.BaseCurrencyInformation({
            baseCurrencyToUsdOracleUnit: uint64(DeployNumbers.oracleUsdcToUsdUnit),
            assetAddress: DeployAddresses.usdc,
            baseCurrencyToUsdOracle: address(DeployAddresses.oracleUsdcToUsd),
            baseCurrencyLabel: "USDC",
            baseCurrencyUnitCorrection: uint64(10 ** (18 - DeployNumbers.usdcDecimals))
        });

        riskVarsDai.push(
            PricingModule.RiskVarInput({
                baseCurrency: 0,
                asset: address(0),
                collateralFactor: DeployRiskConstants.dai_collFact_0,
                liquidationFactor: DeployRiskConstants.dai_liqFact_0
            })
        );
        riskVarsDai.push(
            PricingModule.RiskVarInput({
                baseCurrency: 1,
                asset: address(0),
                collateralFactor: DeployRiskConstants.dai_collFact_1,
                liquidationFactor: DeployRiskConstants.dai_liqFact_1
            })
        );
        riskVarsDai.push(
            PricingModule.RiskVarInput({
                baseCurrency: 2,
                asset: address(0),
                collateralFactor: DeployRiskConstants.dai_collFact_2,
                liquidationFactor: DeployRiskConstants.dai_liqFact_2
            })
        );

        riskVarsEth.push(
            PricingModule.RiskVarInput({
                baseCurrency: 0,
                asset: address(0),
                collateralFactor: DeployRiskConstants.eth_collFact_0,
                liquidationFactor: DeployRiskConstants.eth_liqFact_0
            })
        );
        riskVarsEth.push(
            PricingModule.RiskVarInput({
                baseCurrency: 1,
                asset: address(0),
                collateralFactor: DeployRiskConstants.eth_collFact_1,
                liquidationFactor: DeployRiskConstants.eth_liqFact_1
            })
        );
        riskVarsEth.push(
            PricingModule.RiskVarInput({
                baseCurrency: 2,
                asset: address(0),
                collateralFactor: DeployRiskConstants.eth_collFact_2,
                liquidationFactor: DeployRiskConstants.eth_liqFact_2
            })
        );

        riskVarsLink.push(
            PricingModule.RiskVarInput({
                baseCurrency: 0,
                asset: address(0),
                collateralFactor: DeployRiskConstants.link_collFact_0,
                liquidationFactor: DeployRiskConstants.link_liqFact_0
            })
        );
        riskVarsLink.push(
            PricingModule.RiskVarInput({
                baseCurrency: 1,
                asset: address(0),
                collateralFactor: DeployRiskConstants.link_collFact_1,
                liquidationFactor: DeployRiskConstants.link_liqFact_1
            })
        );
        riskVarsLink.push(
            PricingModule.RiskVarInput({
                baseCurrency: 2,
                asset: address(0),
                collateralFactor: DeployRiskConstants.link_collFact_2,
                liquidationFactor: DeployRiskConstants.link_liqFact_2
            })
        );

        riskVarsSnx.push(
            PricingModule.RiskVarInput({
                baseCurrency: 0,
                asset: address(0),
                collateralFactor: DeployRiskConstants.snx_collFact_0,
                liquidationFactor: DeployRiskConstants.snx_liqFact_0
            })
        );
        riskVarsSnx.push(
            PricingModule.RiskVarInput({
                baseCurrency: 1,
                asset: address(0),
                collateralFactor: DeployRiskConstants.snx_collFact_1,
                liquidationFactor: DeployRiskConstants.snx_liqFact_1
            })
        );
        riskVarsSnx.push(
            PricingModule.RiskVarInput({
                baseCurrency: 2,
                asset: address(0),
                collateralFactor: DeployRiskConstants.snx_collFact_2,
                liquidationFactor: DeployRiskConstants.snx_liqFact_2
            })
        );

        riskVarsUsdc.push(
            PricingModule.RiskVarInput({
                baseCurrency: 0,
                asset: address(0),
                collateralFactor: DeployRiskConstants.usdc_collFact_0,
                liquidationFactor: DeployRiskConstants.usdc_liqFact_0
            })
        );
        riskVarsUsdc.push(
            PricingModule.RiskVarInput({
                baseCurrency: 1,
                asset: address(0),
                collateralFactor: DeployRiskConstants.usdc_collFact_1,
                liquidationFactor: DeployRiskConstants.usdc_liqFact_1
            })
        );
        riskVarsUsdc.push(
            PricingModule.RiskVarInput({
                baseCurrency: 2,
                asset: address(0),
                collateralFactor: DeployRiskConstants.usdc_collFact_2,
                liquidationFactor: DeployRiskConstants.usdc_liqFact_2
            })
        );

        riskVarsBtc.push(
            PricingModule.RiskVarInput({
                baseCurrency: 0,
                asset: address(0),
                collateralFactor: DeployRiskConstants.btc_collFact_0,
                liquidationFactor: DeployRiskConstants.btc_liqFact_0
            })
        );
        riskVarsBtc.push(
            PricingModule.RiskVarInput({
                baseCurrency: 1,
                asset: address(0),
                collateralFactor: DeployRiskConstants.btc_collFact_1,
                liquidationFactor: DeployRiskConstants.btc_liqFact_1
            })
        );
        riskVarsBtc.push(
            PricingModule.RiskVarInput({
                baseCurrency: 2,
                asset: address(0),
                collateralFactor: DeployRiskConstants.btc_collFact_2,
                liquidationFactor: DeployRiskConstants.btc_liqFact_2
            })
        );

    }

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        deployerAddress = vm.addr(deployerPrivateKey);
        
        vm.startBroadcast(deployerPrivateKey);

        oracleHub = new OracleHub();

        factory = new Factory();

        oracleHub.addOracle(daiToUsdOracleInfo);
        oracleHub.addOracle(ethToUsdOracleInfo);
        oracleHub.addOracle(linkToEthEthToUsdOracleInfo);
        oracleHub.addOracle(snxToUsdOracleInfo);
        oracleHub.addOracle(usdcToUsdOracleInfo);
        oracleHub.addOracle(btcToEthEthToUsdOracleInfo);

        mainRegistry = new MainRegistry(address(factory));
        mainRegistry.addBaseCurrency(ethBaseCurrencyInfo);
        mainRegistry.addBaseCurrency(usdcBaseCurrencyInfo);

        standardERC20PricingModule = new StandardERC20PricingModule(
            address(mainRegistry),
            address(oracleHub)
        );

        mainRegistry.addPricingModule(address(standardERC20PricingModule));

        PricingModule.RiskVarInput[] memory riskVarsDai_ = riskVarsDai;
        PricingModule.RiskVarInput[] memory riskVarsEth_ = riskVarsEth;
        PricingModule.RiskVarInput[] memory riskVarsLink_ = riskVarsLink;
        PricingModule.RiskVarInput[] memory riskVarsSnx_ = riskVarsSnx;
        PricingModule.RiskVarInput[] memory riskVarsUsdc_ = riskVarsUsdc;
        PricingModule.RiskVarInput[] memory riskVarsBtc_ = riskVarsBtc;

        standardERC20PricingModule.addAsset(DeployAddresses.dai, oracleDaiToUsdArr, riskVarsDai_, type(uint128).max);
        standardERC20PricingModule.addAsset(DeployAddresses.eth, oracleEthToUsdArr, riskVarsEth_, type(uint128).max);
        standardERC20PricingModule.addAsset(
            DeployAddresses.link, oracleLinkToEthEthToUsdArr, riskVarsLink_, type(uint128).max
        );
        standardERC20PricingModule.addAsset(DeployAddresses.snx, oracleSnxToUsdArr, riskVarsSnx_, type(uint128).max);
        standardERC20PricingModule.addAsset(DeployAddresses.usdc, oracleUsdcToUsdArr, riskVarsUsdc_, type(uint128).max);
        standardERC20PricingModule.addAsset(
            DeployAddresses.btc, oracleBtcToEthEthToUsdArr, riskVarsBtc_, type(uint128).max
        );

        vault = new Vault(address(mainRegistry), 1);
        factory.setNewVaultInfo(address(mainRegistry), address(vault), DeployBytes.upgradeRoot1To1, "");

        vm.stopBroadcast();
    }

    function test_deployment() public {
        assertTrue(address(oracleHub) != address(0));
        assertTrue(address(factory) != address(0));
        assertTrue(address(mainRegistry) != address(0));
        assertTrue(address(standardERC20PricingModule) != address(0));
        assertTrue(address(vault) != address(0));
    }

    function test_Factory() public {
        assertTrue(factory.owner() == address(this));
        assertTrue(factory.vaultDetails(1).vault == address(vault));
        assertTrue(factory.vaultDetails(1).upgradeRoot == DeployBytes.upgradeRoot1To1);
        assertTrue(factory.vaultDetails(1).upgradeData == "");

        vm.expectRevert(stdError.indexOOBError);
        factory.allVaults(0);

        assertTrue(factory.name() == "Arcadia Vault");
        assertTrue(factory.symbol() == "ARCADIA");
    }

    function test_Vault() public {
        assertTrue(vault.owner() == address(this));
        assertTrue(vault.mainRegistry() == address(mainRegistry));
        assertTrue(vault.vaultVersion() == 1);
    }

    function test_MainRegistry() public {
        assertTrue(mainRegistry.owner() == address(this));
        assertTrue(mainRegistry.factory() == address(factory));
        assertTrue(mainRegistry.baseCurrencyCounter() == 3);

        assertTrue(mainRegistry.isBaseCurrency(address(0)));
        assertTrue(mainRegistry.isBaseCurrency(address(eth)));
        assertTrue(mainRegistry.isBaseCurrency(address(usdc)));

        assertTrue(mainRegistry.baseCurrencyInfo(0).baseCurrencyToUsdOracleUnit == 1e18);
        assertTrue(mainRegistry.baseCurrencyInfo(0).assetAddress == address(0));
        assertTrue(mainRegistry.baseCurrencyInfo(0).baseCurrencyToUsdOracle == address(0));
        assertTrue(mainRegistry.baseCurrencyInfo(0).baseCurrencyLabel == "USD");
        assertTrue(mainRegistry.baseCurrencyInfo(0).baseCurrencyUnitCorrection == 1);

        assertTrue(mainRegistry.baseCurrencyInfo(1).baseCurrencyToUsdOracleUnit == 1e8);
        assertTrue(mainRegistry.baseCurrencyInfo(1).assetAddress == address(eth));
        assertTrue(mainRegistry.baseCurrencyInfo(1).baseCurrencyToUsdOracle == address(ethToUsdOracle));
        assertTrue(mainRegistry.baseCurrencyInfo(1).baseCurrencyLabel == "ETH");
        assertTrue(mainRegistry.baseCurrencyInfo(1).baseCurrencyUnitCorrection == 1);

        assertTrue(mainRegistry.baseCurrencyInfo(2).baseCurrencyToUsdOracleUnit == 1e8);
        assertTrue(mainRegistry.baseCurrencyInfo(2).assetAddress == address(usdc));
        assertTrue(mainRegistry.baseCurrencyInfo(2).baseCurrencyToUsdOracle == address(usdcToUsdOracle));
        assertTrue(mainRegistry.baseCurrencyInfo(2).baseCurrencyLabel == "USDC");
        assertTrue(mainRegistry.baseCurrencyInfo(2).baseCurrencyUnitCorrection == 1e12);

        assertTrue(mainRegistry.isPricingModule(address(standardERC20PricingModule)));

        assertTrue(mainRegistry.inMainRegistry(address(dai)));
        assertTrue(mainRegistry.inMainRegistry(address(eth)));
        assertTrue(mainRegistry.inMainRegistry(address(link)));
        assertTrue(mainRegistry.inMainRegistry(address(snx)));
        assertTrue(mainRegistry.inMainRegistry(address(usdc)));
        assertTrue(mainRegistry.inMainRegistry(address(btc)));

        assertTrue(mainRegistry.assetsInMainRegistry(0) == address(dai));
        assertTrue(mainRegistry.assetsInMainRegistry(1) == address(eth));
        assertTrue(mainRegistry.assetsInMainRegistry(2) == address(link));
        assertTrue(mainRegistry.assetsInMainRegistry(3) == address(snx));
        assertTrue(mainRegistry.assetsInMainRegistry(4) == address(usdc));
        assertTrue(mainRegistry.assetsInMainRegistry(5) == address(btc));

        vm.expectRevert(stdError.indexOOBError);
        mainRegistry.assetsInMainRegistry(6);
    }

    function test_oracleHub() public {
        assertTrue(oracleHub.owner() == address(this));

        assertTrue(oracleHub.inOracleHub(DeployAddresses.oracleDaiToUsd));
        assertTrue(oracleHub.inOracleHub(DeployAddresses.oracleEthToUsd));
        assertTrue(oracleHub.inOracleHub(DeployAddresses.oracleLinkToEth));
        assertTrue(oracleHub.inOracleHub(DeployAddresses.oracleSnxToUsd));
        assertTrue(oracleHub.inOracleHub(DeployAddresses.oracleUsdcToUsd));
        assertTrue(oracleHub.inOracleHub(DeployAddresses.oracleBtcToEth));

        vm.expectRevert(stdError.indexOOBError);
        oracleHub.oracles(6);
    }
}
