// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

// CHC: Cheat code

import {Test, console} from "forge-std/Test.sol";
import {StdCheats} from "forge-std/StdCheats.sol";
import {FundMe} from "../../src/FundMe.sol";
import {DeployFundMe} from "../../script/DeployFundMe.s.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";

contract FundMeTest is StdCheats, Test {
    FundMe public fundMe;
    HelperConfig public helperConfig;

    // CHC
    address USER = makeAddr("user");

    // address public constant USER = address(1);
    uint256 public constant SEND_VALUE = 0.1 ether; // just a value to make sure we are sending enough!
    uint256 public constant STARTING_BALANCE = 10 ether;

    function setUp() external {
        // fundMe = new FundMe(0x694AA1769357215DE4FAC081bf1f309aDC325306);
        // U can Hard code like this or use below one
        DeployFundMe deployer = new DeployFundMe();
        (fundMe, helperConfig) = deployer.run();

        // CHC Add balance to USER
        vm.deal(USER, STARTING_BALANCE);
    }

    function testMinimumUsdisFive() public {
        console.log("FundeMeTest: testMinimumUsdisFive");
        assertEq(fundMe.MINIMUM_USD(), 5e18);
    }

    function testOwnerIsMsgSender() public {
        console.log("FundeMeTest: testOwnerIsMsgSender");
        // it will fail because us => called FundMeTest => called msg.sender
        // assertEq(fundMe.i_owner(), msg.sender);
        assertEq(fundMe.getOwner(), msg.sender);
    }

    function testGetVersion() public {
        console.log("FundeMeTest: testGetVersion");
        assertEq(fundMe.getVersion(), 4);
    }

    function testfundFailsWithoutEnoughEth() public {
        console.log("FundeMeTest: testfundFailsWithoutEnoughEth");
        //CHC: it will expect to fail next after this command
        vm.expectRevert();
        fundMe.fund();
    }

    function testFundUpdatesFundedDataStructure() public {
        console.log("FundeMeTest: testFundUpdatesFundedDataStructure");
        // CHC: The next tx will be sent bu USER to avoid confusion
        vm.startPrank(USER);
        fundMe.fund{value: SEND_VALUE}();
        vm.stopPrank();

        uint256 amtFounded = fundMe.getAddressToAmountFunded(USER);
        assertEq(SEND_VALUE, amtFounded);
    }

    function testAddsFunderToArrayOfFunders() public {
        console.log("FundeMeTest: testAddsFunderToArrayOfFunders");
        vm.startPrank(USER);
        fundMe.fund{value: SEND_VALUE}();
        vm.stopPrank();

        address funder = fundMe.getFunder(0);
        assertEq(funder, USER);
    }

    modifier funded() {
        vm.prank(USER);
        fundMe.fund{value: SEND_VALUE}();
        _;
    }

    function testOnlyOwnerCanWithdraw() public funded {
        console.log("FundeMeTest: testOnlyOwnerCanWithdraw");
        vm.expectRevert();
        fundMe.withdraw();
    }

    function testWithdrawFromASingleFunder() public funded {
        // Arrange
        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;

        // ACT
        vm.prank(fundMe.getOwner());
        fundMe.withdraw();

        // Assert
        uint256 endingOwnerBalance = fundMe.getOwner().balance;
        uint256 endingFundMeBalance = address(fundMe).balance;
        assertEq(endingFundMeBalance, 0);
        assertEq(startingOwnerBalance + startingFundMeBalance, endingOwnerBalance);
    }

    function testWithDrawFromMultipleFunders() public funded {
        // uint160 becasue of address
        uint160 noOfFunders = 10;
        // Deafult addr might take 0
        uint160 stratingIndex = 1;

        for (uint160 i = stratingIndex; i < noOfFunders; i++) {
            //  vm.deal +  vm.prank
            // we get hoax from stdcheats
            hoax(address(i), SEND_VALUE);
            fundMe.fund{value: SEND_VALUE}();
        }

        // Arrange
        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;

        // ACT
        vm.startPrank(fundMe.getOwner());
        fundMe.withdraw();
        vm.stopPrank();

        assertEq(address(fundMe).balance, 0);
        assert(startingOwnerBalance + startingFundMeBalance == fundMe.getOwner().balance);
    }

    function testWithDrawFromMultipleFundersCheaper() public funded {
        // uint160 becasue of address
        uint160 noOfFunders = 10;
        // Deafult addr might take 0
        uint160 stratingIndex = 1;

        for (uint160 i = stratingIndex; i < noOfFunders; i++) {
            //  vm.deal +  vm.prank
            // we get hoax from stdcheats
            hoax(address(i), SEND_VALUE);
            fundMe.fund{value: SEND_VALUE}();
        }

        // Arrange
        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;

        // ACT
        vm.startPrank(fundMe.getOwner());
        fundMe.cheaperWithdraw();
        vm.stopPrank();

        assertEq(address(fundMe).balance, 0);
        assert(startingOwnerBalance + startingFundMeBalance == fundMe.getOwner().balance);
    }
}
