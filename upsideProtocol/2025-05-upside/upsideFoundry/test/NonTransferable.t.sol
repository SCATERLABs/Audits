// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import "../src/UpsideProtocol.sol";
import "../src/UpsideStakingStub.sol";
import "../src/UpsideMetaCoin.sol";
import "../src/interfaces/IERC20Metadata.sol";

contract UpsideWhitelistTest is Test {
    address owner;
    address user1;
    IERC20Metadata liquidityToken;
    UpsideProtocol upsideProtocol;
    UpsideStakingStub stakingContract;
    UpsideMetaCoin linkToken1;
    UpsideMetaCoin linkToken2;

    address USDC = 0x833589fcd6edb6e08f4c7c32d4f71b54bda02913;
    address whale = 0x3304E22DDaa22bCdC5fCa2269b418046aE7b566A;

    function setUp() public {
        vm.createSelectFork(vm.envString("BASE_FORK_URL"), 28_668_000);

        owner = vm.addr(2);
        user1 = vm.addr(0);

        vm.deal(owner, 100 ether);
        vm.deal(user1, 100 ether);

        liquidityToken = IERC20Metadata(USDC);

        stakingContract = new UpsideStakingStub(owner);
        stakingContract.setFeeDestinationAddress(owner);

        upsideProtocol = new UpsideProtocol(owner);
    }

    function testObtainUSDC() public {
        uint256 amount = 250_000 * 1e6;

        vm.startPrank(whale);
        deal(address(liquidityToken), whale, amount);
        liquidityToken.transfer(owner, amount);
        vm.stopPrank();

        assertEq(liquidityToken.balanceOf(owner), amount);
    }

    function testInitProtocol() public {
        vm.startPrank(owner);

        // Init
        upsideProtocol.init(address(liquidityToken));

        vm.expectRevert("ALREADY INITIALISED");
        upsideProtocol.init(address(liquidityToken));

        vm.stopPrank();
    }

    function testSetStaking() public {
        vm.startPrank(owner);
        upsideProtocol.setStakingContractAddress(address(stakingContract));
        vm.stopPrank();
    }

    function testTokenize() public {
        vm.startPrank(owner);

        linkToken1 = UpsideMetaCoin(upsideProtocol.tokenize("https://bbc.co.uk", address(liquidityToken)));
        linkToken2 = UpsideMetaCoin(upsideProtocol.tokenize("https://google.co.uk", address(liquidityToken)));

        vm.stopPrank();
    }

    function testSetFeesAndTokenizeFee() public {
        vm.startPrank(owner);
        upsideProtocol.setTokenizeFee(address(liquidityToken), 5 * 1e6);

        UpsideProtocol.FeeInfo memory newFee = UpsideProtocol.FeeInfo({
            tokenizeFeeEnabled: true,
            tokenizeFeeDestinationAddress: owner,
            swapFeeStartingBp: 9900,
            swapFeeDecayBp: 100,
            swapFeeDecayInterval: 6,
            swapFeeFinalBp: 100,
            swapFeeDeployerBp: 1000,
            swapFeeSellBp: 100
        });

        upsideProtocol.setFeeInfo(newFee);
        vm.stopPrank();
    }

    function testSwapAndTransferControl() public {
        uint256 tokenAmount = 10 * 1e6;

        vm.startPrank(owner);

        // Assume token already minted to owner
        liquidityToken.approve(address(upsideProtocol), tokenAmount);

        // Static call
        uint256 outTokens = upsideProtocol
            .swap
            .staticcall(
                abi.encodeWithSelector(upsideProtocol.swap.selector, address(linkToken1), true, tokenAmount, 0, owner)
            )
            .length;

        upsideProtocol.swap(address(linkToken1), true, tokenAmount, 0, owner);

        vm.expectRevert(); // Assuming NonTransferable custom error
        linkToken1.transfer(user1, 1 ether);

        // Whitelist user
        address;
        address;
        bool;
        tokens[0] = address(linkToken1);
        users[0] = owner;
        flags[0] = true;

        upsideProtocol.setMetaCoinWhitelist(tokens, users, flags);

        // Now transfer should work
        linkToken1.transfer(user1, 1 ether);

        // Attempt transferFrom without approval
        vm.expectRevert("ERC20: transfer amount exceeds allowance");
        linkToken1.transferFrom(user1, owner, 1 ether);

        vm.stopPrank();
    }

    function testDisableWhitelist() public {
        vm.startPrank(owner);
        upsideProtocol.disableWhitelist(address(linkToken1));

        vm.expectRevert(abi.encodeWithSignature("MetaCoinNonExistent()"));
        upsideProtocol.disableWhitelist(owner);

        vm.expectRevert(abi.encodeWithSignature("AlreadyTransferable()"));
        upsideProtocol.disableWhitelist(address(linkToken1));
        vm.stopPrank();
    }

    function testToken2NonTransferable() public {
        vm.startPrank(owner);
        vm.expectRevert(); // NonTransferable
        linkToken2.transfer(user1, 1 ether);
        vm.stopPrank();
    }
}
