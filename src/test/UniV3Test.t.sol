/**
 * Created by Pragma Labs
 * SPDX-License-Identifier: BUSL-1.1
 */
pragma solidity ^0.8.13;

import "../../lib/forge-std/src/Test.sol";
import { DeployedContracts } from "./fixtures/DeployedContracts.f.sol";
import { ERC20Fixture } from "./fixtures/ERC20Fixture.f.sol";
import { ERC20 } from "../../lib/solmate/src/tokens/ERC20.sol";
import {
    UniswapV3PricingModule, TickMath, LiquidityAmounts
} from "../PricingModules/UniswapV3/UniswapV3PricingModule.sol";
import { INonfungiblePositionManagerExtension } from "./interfaces/INonfungiblePositionManagerExtension.sol";
import { IUniswapV3PoolExtension } from "./interfaces/IUniswapV3PoolExtension.sol";
import { IUniswapV3Factory } from "./interfaces/IUniswapV3Factory.sol";
import { ISwapRouter } from "./interfaces/ISwapRouter.sol";
import { LiquidityAmountsExtension } from "./libraries/LiquidityAmountsExtension.sol";
import { TickMathsExtension } from "./libraries/TickMathsExtension.sol";

contract UniswapV3PricingModuleExtension is UniswapV3PricingModule {
    constructor(address mainRegistry_, address oracleHub_, address riskManager_, address erc20PricingModule_)
        UniswapV3PricingModule(mainRegistry_, oracleHub_, riskManager_, erc20PricingModule_)
    { }

    function getTickTwap(IUniswapV3PoolExtension pool) external view returns (int24 tick) {
        return _getTickTwap(pool);
    }

    function setExposure(address asset, uint128 exposure_, uint128 maxExposure) public {
        exposure[asset].exposure = exposure_;
        exposure[asset].maxExposure = maxExposure;
    }
}

abstract contract UniV3Test is DeployedContracts, Test {
    string RPC_URL = vm.envString("RPC_URL");
    uint256 fork;

    address public liquidityProvider = address(1);
    address public swapper = address(2);

    UniswapV3PricingModuleExtension uniV3PricingModule;
    INonfungiblePositionManagerExtension public uniV3 =
        INonfungiblePositionManagerExtension(0xC36442b4a4522E871399CD717aBDD847Ab11FE88);
    ISwapRouter public router = ISwapRouter(0xE592427A0AEce92De3Edee1F18E0157C05861564);
    IUniswapV3Factory public uniV3factory = IUniswapV3Factory(0x1F98431c8aD98523631AE4a59f267346ea31F984);

    ERC20Fixture erc20Fixture;

    event RiskManagerUpdated(address riskManager);

    //this is a before
    constructor() {
        fork = vm.createFork(RPC_URL);

        erc20Fixture = new ERC20Fixture();
        vm.makePersistent(address(erc20Fixture));
    }

    //this is a before each
    function setUp() public virtual { }
}

/* ///////////////////////////////////////////////////////////////
                        DEPLOYMENT
/////////////////////////////////////////////////////////////// */
contract DeploymentTest is UniV3Test {
    function setUp() public override { }

    function testSuccess_deployment(
        address mainRegistry_,
        address oracleHub_,
        address riskManager_,
        address erc20PricingModule_
    ) public {
        vm.startPrank(deployer);
        vm.expectEmit(true, true, true, true);
        emit RiskManagerUpdated(riskManager_);
        uniV3PricingModule =
            new UniswapV3PricingModuleExtension(mainRegistry_, oracleHub_, riskManager_, erc20PricingModule_);
        vm.stopPrank();

        assertEq(uniV3PricingModule.assetType(), 1);
    }
}

/*///////////////////////////////////////////////////////////////
                    ASSET MANAGEMENT
///////////////////////////////////////////////////////////////*/
contract AssetManagementTest is UniV3Test {
    using stdStorage for StdStorage;

    function setUp() public override {
        super.setUp();
        vm.selectFork(fork);

        vm.startPrank(deployer);
        uniV3PricingModule =
        new UniswapV3PricingModuleExtension(address(mainRegistry), address(oracleHub), deployer, address(standardERC20PricingModule));
        mainRegistry.addPricingModule(address(uniV3PricingModule));
        vm.stopPrank();
    }

    function testRevert_addAsset_NonOwner(address unprivilegedAddress_) public {
        vm.assume(unprivilegedAddress_ != deployer);
        vm.startPrank(unprivilegedAddress_);

        vm.expectRevert("UNAUTHORIZED");
        uniV3PricingModule.addAsset(address(uniV3));
        vm.stopPrank();
    }

    function testRevert_addAsset_NonUniswapV3PositionManager(address badAddress) public {
        // badAddress cannot be a contract with a function: factory()
        (bool success,) = badAddress.call(abi.encodeWithSignature("factory()"));
        vm.assume(success == false);

        vm.startPrank(deployer);
        vm.expectRevert();
        uniV3PricingModule.addAsset(badAddress);
        vm.stopPrank();
    }

    function testRevert_addAsset_OverwriteExistingAsset() public {
        vm.startPrank(deployer);
        uniV3PricingModule.addAsset(address(uniV3));
        vm.expectRevert("PMUV3_AA: already added");
        uniV3PricingModule.addAsset(address(uniV3));
        vm.stopPrank();
    }

    function testRevert_addAsset_MainRegistryReverts() public {
        vm.prank(deployer);
        uniV3PricingModule =
        new UniswapV3PricingModuleExtension(address(mainRegistry), address(oracleHub), deployer, address(standardERC20PricingModule));

        vm.startPrank(deployer);
        vm.expectRevert("MR: Only PriceMod.");
        uniV3PricingModule.addAsset(address(uniV3));
        vm.stopPrank();
    }

    function testSuccess_addAsset() public {
        vm.prank(deployer);
        uniV3PricingModule.addAsset(address(uniV3));

        address factory = uniV3.factory();
        assertTrue(uniV3PricingModule.inPricingModule(address(uniV3)));
        assertEq(uniV3PricingModule.assetsInPricingModule(0), address(uniV3));
        assertEq(uniV3PricingModule.assetToV3Factory(address(uniV3)), factory);
    }
}

/*///////////////////////////////////////////////////////////////
                    ALLOW LIST MANAGEMENT
///////////////////////////////////////////////////////////////*/
contract AllowListManagementTest is UniV3Test {
    using stdStorage for StdStorage;

    function setUp() public override {
        super.setUp();
        vm.selectFork(fork);

        vm.startPrank(deployer);
        uniV3PricingModule =
        new UniswapV3PricingModuleExtension(address(mainRegistry), address(oracleHub), deployer, address(standardERC20PricingModule));
        mainRegistry.addPricingModule(address(uniV3PricingModule));
        vm.stopPrank();

        vm.prank(deployer);
        uniV3PricingModule.addAsset(address(uniV3));
    }

    function testSuccess_isAllowListed_NegativeUnknownAsset(address asset, uint256 assetId) public {
        vm.assume(asset != address(uniV3));

        assertFalse(uniV3PricingModule.isAllowListed(asset, assetId));
    }

    function testSuccess_isAllowListed_NegativeNoExposure(uint256 assetId) public {
        bound(assetId, 1, uniV3.totalSupply());

        assertFalse(uniV3PricingModule.isAllowListed(address(uniV3), assetId));
    }

    function testSuccess_isAllowListed_NegativeUnknownId(uint256 assetId) public {
        bound(assetId, 2 * uniV3.totalSupply(), type(uint256).max);

        assertFalse(uniV3PricingModule.isAllowListed(address(uniV3), assetId));
    }

    function testSuccess_isAllowListed_Positive(address lp, uint128 maxExposureA, uint128 maxExposureB) public {
        vm.assume(lp != address(0));
        vm.assume(maxExposureA > 0);
        vm.assume(maxExposureB > 0);

        // Create a LP-position of two underlying assets: tokenA and tokenB.
        ERC20 tokenA = erc20Fixture.createToken();
        ERC20 tokenB = erc20Fixture.createToken();
        uniV3.createAndInitializePoolIfNecessary(address(tokenA), address(tokenB), 100, 1 << 96);

        deal(address(tokenA), lp, 1e8);
        deal(address(tokenB), lp, 1e8);
        vm.startPrank(lp);
        tokenA.approve(address(uniV3), type(uint256).max);
        tokenB.approve(address(uniV3), type(uint256).max);
        (uint256 tokenId,,,) = uniV3.mint(
            INonfungiblePositionManagerExtension.MintParams({
                token0: address(tokenA),
                token1: address(tokenB),
                fee: 100,
                tickLower: -1,
                tickUpper: 1,
                amount0Desired: 1e8,
                amount1Desired: 1e8,
                amount0Min: 0,
                amount1Min: 0,
                recipient: lp,
                deadline: type(uint256).max
            })
        );
        vm.stopPrank();

        // Set an allowed exposure for tokenA and tokenB greater than 0.
        vm.startPrank(deployer);
        uniV3PricingModule.setExposureOfAsset(address(tokenA), maxExposureA);
        uniV3PricingModule.setExposureOfAsset(address(tokenB), maxExposureB);
        vm.stopPrank();

        // Test that Uni V3 LP token with allowed exposure to the underlying assets is allowlisted.
        assertTrue(uniV3PricingModule.isAllowListed(address(uniV3), tokenId));
    }
}

/*///////////////////////////////////////////////////////////////
                RISK VARIABLES MANAGEMENT
///////////////////////////////////////////////////////////////*/
contract RiskVariablesManagementTest is UniV3Test {
    using stdStorage for StdStorage;

    ERC20 token0;
    ERC20 token1;
    IUniswapV3PoolExtension pool;

    // Before Each.
    function setUp() public override {
        super.setUp();
        vm.selectFork(fork);

        vm.startPrank(deployer);
        uniV3PricingModule =
        new UniswapV3PricingModuleExtension(address(mainRegistry), address(oracleHub), deployer, address(standardERC20PricingModule));
        mainRegistry.addPricingModule(address(uniV3PricingModule));
        vm.stopPrank();

        vm.prank(deployer);
        uniV3PricingModule.addAsset(address(uniV3));

        token0 = erc20Fixture.createToken();
        token1 = erc20Fixture.createToken();
        (token0, token1) = token0 < token1 ? (token0, token1) : (token0, token1);
    }

    // Helper function.
    function isBelowMaxLiquidityPerTick(
        int24 tickLower,
        int24 tickHigher,
        uint256 amount0,
        uint256 amount1,
        IUniswapV3PoolExtension pool_
    ) public view returns (bool) {
        (uint160 sqrtPrice,,,,,,) = pool_.slot0();

        uint256 liquidity = LiquidityAmountsExtension.getLiquidityForAmounts(
            sqrtPrice, TickMath.getSqrtRatioAtTick(tickLower), TickMath.getSqrtRatioAtTick(tickHigher), amount0, amount1
        );

        return liquidity <= pool_.maxLiquidityPerTick();
    }

    // Helper function.
    function isWithinAllowedRange(int24 tick) public pure returns (bool) {
        int24 MIN_TICK = -887_272;
        int24 MAX_TICK = -MIN_TICK;
        return (tick < 0 ? uint256(-int256(tick)) : uint256(int256(tick))) <= uint256(uint24(MAX_TICK));
    }

    // Helper function.
    function createPool(uint160 sqrtPriceX96, uint16 observationCardinality) public {
        address poolAddress =
            uniV3.createAndInitializePoolIfNecessary(address(token0), address(token1), 100, sqrtPriceX96); // Set initial price to lowest possible price.
        pool = IUniswapV3PoolExtension(poolAddress);
        pool.increaseObservationCardinalityNext(observationCardinality);
    }

    // Helper function.
    function addLiquidity(
        uint128 liquidity,
        address liquidityProvider_,
        int24 tickLower,
        int24 tickHigher,
        bool revertsOnZeroLiquidity
    ) public returns (uint256 tokenId) {
        (uint160 sqrtPrice,,,,,,) = pool.slot0();

        (uint256 amount0, uint256 amount1) = LiquidityAmounts.getAmountsForLiquidity(
            sqrtPrice, TickMath.getSqrtRatioAtTick(tickLower), TickMath.getSqrtRatioAtTick(tickHigher), liquidity
        );

        tokenId = addLiquidity(amount0, amount1, liquidityProvider_, tickLower, tickHigher, revertsOnZeroLiquidity);
    }

    // Helper function.
    function addLiquidity(
        uint256 amount0,
        uint256 amount1,
        address liquidityProvider_,
        int24 tickLower,
        int24 tickHigher,
        bool revertsOnZeroLiquidity
    ) public returns (uint256 tokenId) {
        // Check if test should revert or be skipped when liquidity is zero
        // This is hard to assume by checking the fuzzed inputs due to rounding errors
        // In the various advanced numeric libraries.
        if (!revertsOnZeroLiquidity) {
            (uint160 sqrtPrice,,,,,,) = pool.slot0();
            uint256 liquidity = LiquidityAmountsExtension.getLiquidityForAmounts(
                sqrtPrice,
                TickMath.getSqrtRatioAtTick(tickLower),
                TickMath.getSqrtRatioAtTick(tickHigher),
                amount0,
                amount1
            );
            vm.assume(liquidity > 0);
        }

        deal(address(token0), liquidityProvider_, amount0);
        deal(address(token1), liquidityProvider_, amount1);
        vm.startPrank(liquidityProvider_);
        token0.approve(address(uniV3), type(uint256).max);
        token1.approve(address(uniV3), type(uint256).max);
        (tokenId,,,) = uniV3.mint(
            INonfungiblePositionManagerExtension.MintParams({
                token0: address(token0),
                token1: address(token1),
                fee: 100,
                tickLower: tickLower,
                tickUpper: tickHigher,
                amount0Desired: amount0,
                amount1Desired: amount1,
                amount0Min: 0,
                amount1Min: 0,
                recipient: liquidityProvider_,
                deadline: type(uint256).max
            })
        );
        vm.stopPrank();
    }

    function testSuccess_getTickTwap(
        uint256 timePassed,
        int24 tickLower,
        int24 tickHigher,
        uint128 amount0Initial,
        uint128 amountOut0,
        uint128 amountOut1
    ) public {
        // Limit timePassed between the two swaps to 300s (the TWAP duration).
        timePassed = bound(timePassed, 0, 300);

        // Check that ticks are within allowed ranges.
        vm.assume(tickLower < tickHigher);
        vm.assume(isWithinAllowedRange(tickLower));
        vm.assume(isWithinAllowedRange(tickHigher));

        // Check that amounts are within allowed ranges.
        vm.assume(amountOut0 > 0);
        vm.assume(amountOut1 > 0);
        vm.assume(uint256(amountOut0) + amountOut1 < amount0Initial);

        // Create a pool with the minimum initial price (4_295_128_739) and cardinality 300.
        createPool(4_295_128_739, 300);
        vm.assume(isBelowMaxLiquidityPerTick(tickLower, tickHigher, amount0Initial, 0, pool));

        // Provide liquidity only in token0.
        addLiquidity(amount0Initial, 0, liquidityProvider, tickLower, tickHigher, false);

        // Do a first swap.
        deal(address(token1), swapper, type(uint256).max);
        vm.startPrank(swapper);
        token1.approve(address(router), type(uint256).max);
        router.exactOutputSingle(
            ISwapRouter.ExactOutputSingleParams({
                tokenIn: address(token1),
                tokenOut: address(token0),
                fee: 100,
                recipient: swapper,
                deadline: type(uint160).max,
                amountOut: amountOut0,
                amountInMaximum: type(uint160).max,
                sqrtPriceLimitX96: 1_461_446_703_485_210_103_287_273_052_203_988_822_378_723_970_341
            })
        );
        vm.stopPrank();

        // Cache the current tick after the first swap.
        (, int24 tick0,,,,,) = pool.slot0();

        // Do second swap after timePassed seconds.
        uint256 timestamp = block.timestamp;
        vm.warp(timestamp + timePassed);
        vm.startPrank(swapper);
        token1.approve(address(router), type(uint256).max);
        router.exactOutputSingle(
            ISwapRouter.ExactOutputSingleParams({
                tokenIn: address(token1),
                tokenOut: address(token0),
                fee: 100,
                recipient: swapper,
                deadline: type(uint160).max,
                amountOut: amountOut1,
                amountInMaximum: type(uint160).max,
                sqrtPriceLimitX96: 1_461_446_703_485_210_103_287_273_052_203_988_822_378_723_970_341
            })
        );
        vm.stopPrank();

        // Cache the current tick after the second swap.
        (, int24 tick1,,,,,) = pool.slot0();

        // Calculate the TWAP.
        vm.warp(timestamp + 300);
        int256 expectedTickTwap =
            (int256(tick0) * int256(timePassed) + int256(tick1) * int256((300 - timePassed))) / 300;

        // Compare with the actual TWAP.
        int256 actualTickTwap = uniV3PricingModule.getTickTwap(pool);
        assertEq(actualTickTwap, expectedTickTwap);
    }

    function testRevert_processDeposit_NonMainRegistry(address unprivilegedAddress, address asset, uint256 id) public {
        vm.assume(unprivilegedAddress != address(mainRegistry));

        vm.startPrank(unprivilegedAddress);
        vm.expectRevert("APM: ONLY_MAIN_REGISTRY");
        uniV3PricingModule.processDeposit(address(0), asset, id, 0);
        vm.stopPrank();
    }

    function testRevert_processDeposit_BelowAcceptedRange(
        uint128 liquidity,
        int24 tickLower,
        int24 tickHigher,
        int24 tickCurrent
    ) public {
        // Condition on which the call should revert: tick_lower is more than 16_095 ticks below tickCurrent.
        vm.assume(tickCurrent > int256(tickLower) + 16_095);

        // Check that ticks are within allowed ranges.
        vm.assume(tickLower < tickHigher);
        vm.assume(isWithinAllowedRange(tickLower));
        vm.assume(isWithinAllowedRange(tickHigher));
        vm.assume(isWithinAllowedRange(tickCurrent));

        // Create Uniswap V3 pool initiated at tickCurrent with cardinality 300.
        createPool(TickMath.getSqrtRatioAtTick(tickCurrent), 300);

        // Check that Liquidity is within allowed ranges.
        vm.assume(liquidity > 0);
        vm.assume(liquidity <= pool.maxLiquidityPerTick());

        // Mint liquidity position.
        uint256 tokenId = addLiquidity(liquidity, liquidityProvider, tickLower, tickHigher, false);
        // Warp 300 seconds to ensure that TWAP of 300s can be calculated.
        vm.warp(block.timestamp + 300);

        vm.startPrank(address(mainRegistry));
        vm.expectRevert("PMUV3_PD: Range not in limits");
        uniV3PricingModule.processDeposit(address(0), address(uniV3), tokenId, 0);
        vm.stopPrank();
    }

    function testRevert_processDeposit_AboveAcceptedRange(
        uint128 liquidity,
        int24 tickLower,
        int24 tickHigher,
        int24 tickCurrent
    ) public {
        // tick_lower is less than 16_095 ticks below tickCurrent.
        vm.assume(tickCurrent <= int256(tickLower) + 16_095);
        // Condition on which the call should revert: tickHigher is more than 16_095 ticks above tickCurrent.
        vm.assume(tickCurrent < int256(tickHigher) - 16_095);

        // Check that ticks are within allowed ranges.
        vm.assume(tickLower < tickHigher);
        vm.assume(isWithinAllowedRange(tickLower));
        vm.assume(isWithinAllowedRange(tickHigher));
        vm.assume(isWithinAllowedRange(tickCurrent));

        // Create Uniswap V3 pool initiated at tickCurrent with cardinality 300.
        createPool(TickMath.getSqrtRatioAtTick(tickCurrent), 300);

        // Check that Liquidity is within allowed ranges.
        vm.assume(liquidity > 0);
        vm.assume(liquidity <= pool.maxLiquidityPerTick());

        // Mint liquidity position.
        uint256 tokenId = addLiquidity(liquidity, liquidityProvider, tickLower, tickHigher, false);
        // Warp 300 seconds to ensure that TWAP of 300s can be calculated.
        vm.warp(block.timestamp + 300);

        vm.startPrank(address(mainRegistry));
        vm.expectRevert("PMUV3_PD: Range not in limits");
        uniV3PricingModule.processDeposit(address(0), address(uniV3), tokenId, 0);
        vm.stopPrank();
    }

    function testRevert_processDeposit_OverflowExposureToken0(
        uint128 liquidity,
        int24 tickLower,
        int24 tickHigher,
        int24 tickCurrent,
        uint128 initialExposure0,
        uint128 maxExposure0
    ) public {
        // Check that ticks are within allowed ranges.
        vm.assume(tickCurrent <= int256(tickLower) + 16_095);
        vm.assume(tickCurrent >= int256(tickHigher) - 16_095);
        vm.assume(tickLower < tickHigher);
        vm.assume(isWithinAllowedRange(tickLower));
        vm.assume(isWithinAllowedRange(tickHigher));
        vm.assume(isWithinAllowedRange(tickCurrent));

        // Create Uniswap V3 pool initiated at tickCurrent with cardinality 300.
        createPool(TickMath.getSqrtRatioAtTick(tickCurrent), 300);

        // Check that Liquidity is within allowed ranges.
        vm.assume(liquidity > 0);
        vm.assume(liquidity <= pool.maxLiquidityPerTick());

        // Mint liquidity position.
        uint256 tokenId = addLiquidity(liquidity, liquidityProvider, tickLower, tickHigher, false);

        // Calculate expose to underlying tokens.
        // We do not use the fuzzed liquidity, but fetch liquidity from the contract.
        // This is because there might be some small differences due to rounding errors.
        (,,,,,,, uint128 liquidity_,,,,) = uniV3.positions(tokenId);
        uint256 amount0 = LiquidityAmounts.getAmount0ForLiquidity(
            TickMath.getSqrtRatioAtTick(tickLower), TickMath.getSqrtRatioAtTick(tickHigher), liquidity_
        );
        // Condition on which the call should revert: overflow of exposure0.
        vm.assume(amount0 + initialExposure0 > type(uint128).max);
        // Set maxExposures
        vm.startPrank(deployer);
        uniV3PricingModule.setExposure(address(token0), initialExposure0, maxExposure0);
        uniV3PricingModule.setExposureOfAsset(address(token1), type(uint128).max);
        vm.stopPrank();

        // Warp 300 seconds to ensure that TWAP of 300s can be calculated.
        vm.warp(block.timestamp + 300);

        vm.startPrank(address(mainRegistry));
        vm.expectRevert(stdError.arithmeticError);
        uniV3PricingModule.processDeposit(address(0), address(uniV3), tokenId, 0);
        vm.stopPrank();
    }

    function testRevert_processDeposit_ExposureToken0ExceedingMax(
        uint128 liquidity,
        int24 tickLower,
        int24 tickHigher,
        int24 tickCurrent,
        uint128 initialExposure0,
        uint128 maxExposure0
    ) public {
        // Check that ticks are within allowed ranges.
        vm.assume(tickCurrent <= int256(tickLower) + 16_095);
        vm.assume(tickCurrent >= int256(tickHigher) - 16_095);
        vm.assume(tickLower < tickHigher);
        vm.assume(isWithinAllowedRange(tickLower));
        vm.assume(isWithinAllowedRange(tickHigher));
        vm.assume(isWithinAllowedRange(tickCurrent));

        // Create Uniswap V3 pool initiated at tickCurrent with cardinality 300.
        createPool(TickMath.getSqrtRatioAtTick(tickCurrent), 300);

        // Check that Liquidity is within allowed ranges.
        vm.assume(liquidity > 0);
        vm.assume(liquidity <= pool.maxLiquidityPerTick());

        // Mint liquidity position.
        uint256 tokenId = addLiquidity(liquidity, liquidityProvider, tickLower, tickHigher, false);

        // Calculate expose to underlying tokens.
        // We do not use the fuzzed liquidity, but fetch liquidity from the contract.
        // This is because there might be some small differences due to rounding errors.
        (,,,,,,, uint128 liquidity_,,,,) = uniV3.positions(tokenId);
        uint256 amount0 = LiquidityAmounts.getAmount0ForLiquidity(
            TickMath.getSqrtRatioAtTick(tickLower), TickMath.getSqrtRatioAtTick(tickHigher), liquidity_
        );
        // No Overflow.
        vm.assume(amount0 + initialExposure0 <= type(uint128).max);
        // Condition on which the call should revert: exposure to token0 becomes bigger as maxExposure0.
        vm.assume(amount0 + initialExposure0 > maxExposure0);
        // Set maxExposures
        vm.startPrank(deployer);
        uniV3PricingModule.setExposure(address(token0), initialExposure0, maxExposure0);
        uniV3PricingModule.setExposureOfAsset(address(token1), type(uint128).max);
        vm.stopPrank();

        // Warp 300 seconds to ensure that TWAP of 300s can be calculated.
        vm.warp(block.timestamp + 300);

        vm.startPrank(address(mainRegistry));
        vm.expectRevert("PMUV3_PD: Exposure not in limits");
        uniV3PricingModule.processDeposit(address(0), address(uniV3), tokenId, 0);
        vm.stopPrank();
    }

    function testRevert_processDeposit_OverflowExposureToken1(
        uint128 liquidity,
        int24 tickLower,
        int24 tickHigher,
        int24 tickCurrent,
        uint128 initialExposure1,
        uint128 maxExposure1
    ) public {
        // Check that ticks are within allowed ranges.
        vm.assume(tickCurrent <= int256(tickLower) + 16_095);
        vm.assume(tickCurrent >= int256(tickHigher) - 16_095);
        vm.assume(tickLower < tickHigher);
        vm.assume(isWithinAllowedRange(tickLower));
        vm.assume(isWithinAllowedRange(tickHigher));
        vm.assume(isWithinAllowedRange(tickCurrent));

        // Create Uniswap V3 pool initiated at tickCurrent with cardinality 300.
        createPool(TickMath.getSqrtRatioAtTick(tickCurrent), 300);

        // Check that Liquidity is within allowed ranges.
        vm.assume(liquidity > 0);
        vm.assume(liquidity <= pool.maxLiquidityPerTick());

        // Mint liquidity position.
        uint256 tokenId = addLiquidity(liquidity, liquidityProvider, tickLower, tickHigher, false);

        // Calculate expose to underlying tokens.
        // We do not use the fuzzed liquidity, but fetch liquidity from the contract.
        // This is because there might be some small differences due to rounding errors.
        (,,,,,,, uint128 liquidity_,,,,) = uniV3.positions(tokenId);
        uint256 amount1 = LiquidityAmounts.getAmount1ForLiquidity(
            TickMath.getSqrtRatioAtTick(tickLower), TickMath.getSqrtRatioAtTick(tickHigher), liquidity_
        );
        // Condition on which the call should revert: overflow of exposure1.
        vm.assume(amount1 + initialExposure1 > type(uint128).max);

        // Set maxExposures
        vm.startPrank(deployer);
        uniV3PricingModule.setExposureOfAsset(address(token0), type(uint128).max);
        uniV3PricingModule.setExposure(address(token1), initialExposure1, maxExposure1);
        vm.stopPrank();

        // Warp 300 seconds to ensure that TWAP of 300s can be calculated.
        vm.warp(block.timestamp + 300);

        vm.startPrank(address(mainRegistry));
        vm.expectRevert(stdError.arithmeticError);
        uniV3PricingModule.processDeposit(address(0), address(uniV3), tokenId, 0);
        vm.stopPrank();
    }

    function testRevert_processDeposit_ExposureToken1ExceedingMax(
        uint128 liquidity,
        int24 tickLower,
        int24 tickHigher,
        int24 tickCurrent,
        uint128 initialExposure1,
        uint128 maxExposure1
    ) public {
        // Check that ticks are within allowed ranges.
        vm.assume(tickCurrent <= int256(tickLower) + 16_095);
        vm.assume(tickCurrent >= int256(tickHigher) - 16_095);
        vm.assume(tickLower < tickHigher);
        vm.assume(isWithinAllowedRange(tickLower));
        vm.assume(isWithinAllowedRange(tickHigher));
        vm.assume(isWithinAllowedRange(tickCurrent));

        // Create Uniswap V3 pool initiated at tickCurrent with cardinality 300.
        createPool(TickMath.getSqrtRatioAtTick(tickCurrent), 300);

        // Check that Liquidity is within allowed ranges.
        vm.assume(liquidity > 0);
        vm.assume(liquidity <= pool.maxLiquidityPerTick());

        // Mint liquidity position.
        uint256 tokenId = addLiquidity(liquidity, liquidityProvider, tickLower, tickHigher, false);

        // Calculate expose to underlying tokens.
        // We do not use the fuzzed liquidity, but fetch liquidity from the contract.
        // This is because there might be some small differences due to rounding errors.
        (,,,,,,, uint128 liquidity_,,,,) = uniV3.positions(tokenId);
        uint256 amount1 = LiquidityAmounts.getAmount1ForLiquidity(
            TickMath.getSqrtRatioAtTick(tickLower), TickMath.getSqrtRatioAtTick(tickHigher), liquidity_
        );
        // No Overflow
        vm.assume(amount1 + initialExposure1 <= type(uint128).max); // Overflow
        // Condition on which the call should revert: exposure to token1 becomes bigger as maxExposure1.
        vm.assume(amount1 + initialExposure1 > maxExposure1);
        // Set maxExposures
        vm.startPrank(deployer);
        uniV3PricingModule.setExposureOfAsset(address(token0), type(uint128).max);
        uniV3PricingModule.setExposure(address(token1), initialExposure1, maxExposure1);
        vm.stopPrank();

        // Warp 300 seconds to ensure that TWAP of 300s can be calculated.
        vm.warp(block.timestamp + 300);

        vm.startPrank(address(mainRegistry));
        vm.expectRevert("PMUV3_PD: Exposure not in limits");
        uniV3PricingModule.processDeposit(address(0), address(uniV3), tokenId, 0);
        vm.stopPrank();
    }

    function testRevert_processDeposit_Success(
        uint128 liquidity,
        int24 tickLower,
        int24 tickHigher,
        int24 tickCurrent,
        uint128 initialExposure0,
        uint128 initialExposure1,
        uint128 maxExposure0,
        uint128 maxExposure1
    ) public {
        // Check that ticks are within allowed ranges.
        vm.assume(tickCurrent <= int256(tickLower) + 16_095);
        vm.assume(tickCurrent >= int256(tickHigher) - 16_095);
        vm.assume(tickLower < tickHigher);
        vm.assume(isWithinAllowedRange(tickLower));
        vm.assume(isWithinAllowedRange(tickHigher));
        vm.assume(isWithinAllowedRange(tickCurrent));

        // Create Uniswap V3 pool initiated at tickCurrent with cardinality 300.
        createPool(TickMath.getSqrtRatioAtTick(tickCurrent), 300);

        // Check that Liquidity is within allowed ranges.
        vm.assume(liquidity > 0);
        vm.assume(liquidity <= pool.maxLiquidityPerTick());

        // Mint liquidity position.
        uint256 tokenId = addLiquidity(liquidity, liquidityProvider, tickLower, tickHigher, false);

        // Calculate expose to underlying tokens.
        // We do not use the fuzzed liquidity, but fetch liquidity from the contract.
        // This is because there might be some small differences due to rounding errors.
        (,,,,,,, uint128 liquidity_,,,,) = uniV3.positions(tokenId);
        uint256 amount0 = LiquidityAmounts.getAmount0ForLiquidity(
            TickMath.getSqrtRatioAtTick(tickLower), TickMath.getSqrtRatioAtTick(tickHigher), liquidity_
        );
        uint256 amount1 = LiquidityAmounts.getAmount1ForLiquidity(
            TickMath.getSqrtRatioAtTick(tickLower), TickMath.getSqrtRatioAtTick(tickHigher), liquidity_
        );

        // Check that exposure to tokens stays below maxExposures.
        vm.assume(amount0 + initialExposure0 <= maxExposure0);
        vm.assume(amount1 + initialExposure1 <= maxExposure1);
        // Set maxExposures
        vm.startPrank(deployer);
        uniV3PricingModule.setExposure(address(token0), initialExposure0, maxExposure0);
        uniV3PricingModule.setExposure(address(token1), initialExposure1, maxExposure1);
        vm.stopPrank();

        // Warp 300 seconds to ensure that TWAP of 300s can be calculated.
        vm.warp(block.timestamp + 300);

        vm.prank(address(mainRegistry));
        uniV3PricingModule.processDeposit(address(0), address(uniV3), tokenId, 0);

        (, uint128 exposure0) = uniV3PricingModule.exposure(address(token0));
        (, uint128 exposure1) = uniV3PricingModule.exposure(address(token1));
        assertEq(exposure0, amount0 + initialExposure0);
        assertEq(exposure1, amount1 + initialExposure1);
    }

    function testRevert_processWithdrawal_NonMainRegistry(address unprivilegedAddress, address asset, uint256 id)
        public
    {
        vm.assume(unprivilegedAddress != address(mainRegistry));

        vm.startPrank(unprivilegedAddress);
        vm.expectRevert("APM: ONLY_MAIN_REGISTRY");
        uniV3PricingModule.processWithdrawal(address(0), asset, id, 0);
        vm.stopPrank();
    }

    function testRevert_processWithdrawal_Success(
        uint128 liquidity,
        int24 tickLower,
        int24 tickHigher,
        int24 tickCurrent,
        uint128 initialExposure0,
        uint128 initialExposure1,
        uint128 maxExposure0,
        uint128 maxExposure1
    ) public {
        // Check that ticks are within allowed ranges.
        vm.assume(tickCurrent <= int256(tickLower) + 16_095);
        vm.assume(tickCurrent >= int256(tickHigher) - 16_095);
        vm.assume(tickLower < tickHigher);
        vm.assume(isWithinAllowedRange(tickLower));
        vm.assume(isWithinAllowedRange(tickHigher));
        vm.assume(isWithinAllowedRange(tickCurrent));

        // Create Uniswap V3 pool initiated at tickCurrent with cardinality 300.
        createPool(TickMath.getSqrtRatioAtTick(tickCurrent), 300);

        // Check that Liquidity is within allowed ranges.
        vm.assume(liquidity > 0);
        vm.assume(liquidity <= pool.maxLiquidityPerTick());

        // Mint liquidity position.
        uint256 tokenId = addLiquidity(liquidity, liquidityProvider, tickLower, tickHigher, false);

        // Calculate expose to underlying tokens.
        // We do not use the fuzzed liquidity, but fetch liquidity from the contract.
        // This is because there might be some small differences due to rounding errors.
        (,,,,,,, uint128 liquidity_,,,,) = uniV3.positions(tokenId);
        uint256 amount0 = LiquidityAmounts.getAmount0ForLiquidity(
            TickMath.getSqrtRatioAtTick(tickLower), TickMath.getSqrtRatioAtTick(tickHigher), liquidity_
        );
        uint256 amount1 = LiquidityAmounts.getAmount1ForLiquidity(
            TickMath.getSqrtRatioAtTick(tickLower), TickMath.getSqrtRatioAtTick(tickHigher), liquidity_
        );

        // Check that exposures are bigger than amounts (tokens had to be deposited first).
        // Contract should never be able to reach a state where amount > exposure.
        vm.assume(amount0 <= initialExposure0);
        vm.assume(amount1 <= initialExposure1);
        // Set maxExposures
        vm.startPrank(deployer);
        uniV3PricingModule.setExposure(address(token0), initialExposure0, maxExposure0);
        uniV3PricingModule.setExposure(address(token1), initialExposure1, maxExposure1);
        vm.stopPrank();

        // Warp 300 seconds to ensure that TWAP of 300s can be calculated.
        vm.warp(block.timestamp + 300);

        vm.prank(address(mainRegistry));
        uniV3PricingModule.processWithdrawal(address(0), address(uniV3), tokenId, 0);

        (, uint128 exposure0) = uniV3PricingModule.exposure(address(token0));
        (, uint128 exposure1) = uniV3PricingModule.exposure(address(token1));
        assertEq(exposure0, initialExposure0 - amount0);
        assertEq(exposure1, initialExposure1 - amount1);
    }
}
