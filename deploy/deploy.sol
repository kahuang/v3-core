// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.7.0;
import 'forge-std/Test.sol';

import {UniswapV3Factory} from '../contracts/UniswapV3Factory.sol';
import {UniswapInterfaceMulticall} from '@v3-periphery/lens/UniswapInterfaceMulticall.sol';
import {ProxyAdmin} from '@openzeppelin/contracts/proxy/ProxyAdmin.sol';
import {TickLens} from '@v3-periphery/lens/TickLens.sol';
import {NFTDescriptor} from '@v3-periphery/libraries/NFTDescriptor.sol';
import {NonfungibleTokenPositionDescriptor} from '@v3-periphery/NonfungibleTokenPositionDescriptor.sol';
import {ProxyAdmin} from '@openzeppelin/contracts/proxy/ProxyAdmin.sol';
import {TransparentUpgradeableProxy} from '@openzeppelin/contracts/proxy/TransparentUpgradeableProxy.sol';
import {NonfungiblePositionManager} from '@v3-periphery/NonfungiblePositionManager.sol';
import {V3Migrator} from '@v3-periphery/V3Migrator.sol';
import {UniswapV3Staker, IUniswapV3Factory} from '@v3-staker/UniswapV3Staker.sol';
import {QuoterV2} from '@v3-periphery/lens/QuoterV2.sol';
import {SwapRouter02} from '@swap-router-contracts/contracts/SwapRouter02.sol';

contract Deploy is Test {
    // Config
    address weth9Address = address(0x1337);
    bytes32 nativeCurrencyLabelBytes = bytes32(uint256(0x1338));
    address v2CoreFactoryAddress = address(0x1339);
    
    uint256 ONE_MINUTE_SECONDS = 60;
    uint256 ONE_HOUR_SECONDS = ONE_MINUTE_SECONDS * 60;
    uint256 ONE_DAY_SECONDS = ONE_HOUR_SECONDS * 24;
    uint256 ONE_MONTH_SECONDS = ONE_DAY_SECONDS * 30;
    uint256 ONE_YEAR_SECONDS = ONE_DAY_SECONDS * 365;

    // Contracts
    UniswapV3Factory v3CoreFactoryAddress;
    UniswapInterfaceMulticall multicall2Address;
    ProxyAdmin proxyAdminAddress;
    TickLens tickLensAddress;
    // NFTDescriptor nftDescriptorLibraryAddressV1_3_0;
    NonfungibleTokenPositionDescriptor nonfungibleTokenPositionDescriptorAddressV1_3_0;
    TransparentUpgradeableProxy descriptorProxyAddress;
    NonfungiblePositionManager nonfungibleTokenPositionManagerAddress;
    V3Migrator v3MigratorAddress;
    UniswapV3Staker v3StakerAddress;
    QuoterV2 quoterV2Address;
    SwapRouter02 swapRouter02;

    bytes emptyBytes;

    function run() public {
        vm.startBroadcast();

        // DEPLOY_V3_CORE_FACTORY
        v3CoreFactoryAddress = new UniswapV3Factory();

        // ADD_1BP_FEE_TIER
        uint24 ONE_BP_FEE = 100;
        int24 ONE_BP_TICK_SPACING = 1;
        v3CoreFactoryAddress.enableFeeAmount(ONE_BP_FEE, ONE_BP_TICK_SPACING);

        // DEPLOY_MULTICALL2
        multicall2Address = new UniswapInterfaceMulticall();

        // DEPLOY_PROXY_ADMIN
        proxyAdminAddress = new ProxyAdmin();

        // DEPLOY_TICK_LENS
        tickLensAddress = new TickLens();

        // DEPLOY_NFT_DESCRIPTOR_LIBRARY_V1_3_0
        // NFTDescriptor is auto deployed

        // DEPLOY_NFT_POSITION_DESCRIPTOR_V1_3_0
        nonfungibleTokenPositionDescriptorAddressV1_3_0 = new NonfungibleTokenPositionDescriptor(
            weth9Address,
            nativeCurrencyLabelBytes
        );

        // DEPLOY_TRANSPARENT_PROXY_DESCRIPTOR
        descriptorProxyAddress = new TransparentUpgradeableProxy(
            address(nonfungibleTokenPositionDescriptorAddressV1_3_0),
            address(proxyAdminAddress),
            emptyBytes
        );

        // DEPLOY_NONFUNGIBLE_POSITION_MANAGER
        nonfungibleTokenPositionManagerAddress = new NonfungiblePositionManager(
            address(v3CoreFactoryAddress),
            weth9Address,
            address(descriptorProxyAddress)
        );

        // DEPLOY_V3_MIGRATOR
        v3MigratorAddress = new V3Migrator(
            address(v3CoreFactoryAddress),
            weth9Address,
            address(nonfungibleTokenPositionManagerAddress)
        );

        // DEPLOY_V3_STAKER
        uint256 MAX_INCENTIVE_START_LEAD_TIME = ONE_MONTH_SECONDS;
        uint256 MAX_INCENTIVE_DURATION = ONE_YEAR_SECONDS * 2;
        v3StakerAddress = new UniswapV3Staker(
            IUniswapV3Factory(address(v3CoreFactoryAddress)),
            nonfungibleTokenPositionManagerAddress,
            MAX_INCENTIVE_START_LEAD_TIME,
            MAX_INCENTIVE_DURATION
        );

        // DEPLOY_QUOTER_V2
        quoterV2Address = new QuoterV2(address(v3CoreFactoryAddress),weth9Address);

        // DEPLOY_V3_SWAP_ROUTER_02
        swapRouter02 = new SwapRouter02(
            v2CoreFactoryAddress,
            address(v3CoreFactoryAddress),
            address(nonfungibleTokenPositionManagerAddress),
            weth9Address
        );

        // TRANSFER_PROXY_ADMIN
        proxyAdminAddress.transferOwnership(msg.sender);
        assert(proxyAdminAddress.owner() == msg.sender);
        
        console.log(msg.sender);

        vm.stopBroadcast();
    }

}
