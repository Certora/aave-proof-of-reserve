// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import {AggregatorV3Interface} from 'chainlink-brownie-contracts/interfaces/AggregatorV3Interface.sol';
import {Test} from 'forge-std/Test.sol';
import 'forge-std/console.sol';

import {ProofOfReserve} from '../src/contracts/ProofOfReserve.sol';
import {ProofOfReserveExecutorV3} from '../src/contracts/ProofOfReserveExecutorV3.sol';

import {IPool, ReserveConfigurationMap} from '../src/dependencies/IPool.sol';
import {IPoolAddressProvider} from '../src/dependencies/IPoolAddressProvider.sol';
import {IACLManager} from './helpers/IACLManager.sol';
import {ReserveConfiguration} from './helpers/ReserveConfiguration.sol';

contract ProofOfReserveExecutorV3Test is Test {
  ProofOfReserve private proofOfReserve;
  ProofOfReserveExecutorV3 private proofOfReserveExecutorV3;

  uint256 private avalancheFork;
  address private constant POOL = 0x794a61358D6845594F94dc1DB02A252b5b4814aD;

  address private constant ASSET_1 = address(1234);
  address private constant PROOF_OF_RESERVE_FEED_1 = address(4321);

  address private constant AAVEE = 0x63a72806098Bd3D9520cC43356dD78afe5D386D9;
  address private constant PORF_AAVE =
    0x14C4c668E34c09E1FBA823aD5DB47F60aeBDD4F7;
  address private constant BTCB = 0x152b9d0FdC40C096757F570A51E494bd4b943E50;
  address private constant PORF_BTCB =
    0x99311B4bf6D8E3D3B4b9fbdD09a1B0F4Ad8e06E9;

  event AssetStateChanged(address indexed asset, bool enabled);
  event AssetIsNotBacked(address indexed asset);
  event EmergencyActionExecuted();

  function setUp() public {
    avalancheFork = vm.createFork('https://avalancherpc.com');
    vm.selectFork(avalancheFork);
    proofOfReserve = new ProofOfReserve();
    proofOfReserveExecutorV3 = new ProofOfReserveExecutorV3(
      POOL,
      address(proofOfReserve)
    );
  }

  function testExecuteEmergencyActionAllBacked() public {
    enableFeedsOnRegistry();
    enableAssetsOnExecutor();

    bool isBorrowingEnabled = isBorrowingEnabledAtLeastOnOneAsset();

    assertEq(isBorrowingEnabled, true);
  }

  function testExecuteEmergencyActionV3() public {
    enableFeedsOnRegistry();
    enableAssetsOnExecutor();

    vm.mockCall(
      PORF_AAVE,
      abi.encodeWithSelector(AggregatorV3Interface.latestRoundData.selector),
      abi.encode(1, 1, 1, 1, 1)
    );

    vm.mockCall(
      PORF_BTCB,
      abi.encodeWithSelector(AggregatorV3Interface.latestRoundData.selector),
      abi.encode(1, 1, 1, 1, 1)
    );

    vm.expectEmit(true, false, false, true);
    emit AssetIsNotBacked(AAVEE);

    vm.expectEmit(true, false, false, true);
    emit AssetIsNotBacked(BTCB);

    vm.expectEmit(false, false, false, true);
    emit EmergencyActionExecuted();

    setRiskAdmin();

    proofOfReserveExecutorV3.executeEmergencyAction();

    bool isBorrowingEnabled = isBorrowingEnabledAtLeastOnOneAsset();
    assertEq(isBorrowingEnabled, false);
  }

  // emergency action - executed and events are emmited

  function enableFeedsOnRegistry() private {
    proofOfReserve.enableProofOfReserveFeed(AAVEE, PORF_AAVE);
    proofOfReserve.enableProofOfReserveFeed(BTCB, PORF_BTCB);
  }

  function enableAssetsOnExecutor() private {
    proofOfReserveExecutorV3.enableAsset(AAVEE);
    proofOfReserveExecutorV3.enableAsset(BTCB);
  }

  function setRiskAdmin() private {
    IPool pool = IPool(POOL);
    IPoolAddressProvider addressProvider = pool.ADDRESSES_PROVIDER();
    IACLManager aclManager = IACLManager(addressProvider.getACLManager());
    vm.prank(addressProvider.getACLAdmin());
    aclManager.addRiskAdmin(address(proofOfReserveExecutorV3));
  }

  function isBorrowingEnabledAtLeastOnOneAsset() private view returns (bool) {
    IPool pool = IPool(POOL);
    address[] memory allAssets = pool.getReservesList();
    bool isBorrowingEnabled = false;

    for (uint256 i; i < allAssets.length; i++) {
      ReserveConfigurationMap memory configuration = pool.getConfiguration(
        allAssets[i]
      );

      (, , bool borrowingEnabled, ) = ReserveConfiguration.getFlags(
        configuration
      );

      isBorrowingEnabled = isBorrowingEnabled || borrowingEnabled;
    }

    return isBorrowingEnabled;
  }
}