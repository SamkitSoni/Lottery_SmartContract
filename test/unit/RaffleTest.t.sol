// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Test, console} from "forge-std/Test.sol";
import {DeployRaffle} from "../../script/DeployRaffle.s.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {Raffle} from "../../src/Raffle.sol";
import {Vm} from "forge-std/Vm.sol";
import {VRFCoordinatorV2_5Mock} from
    "chainlink-brownie-contracts/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";
import {CodeConstants} from "../../script/HelperConfig.s.sol";

contract RaffleTest is Test, CodeConstants {
    Raffle public raffle;
    HelperConfig public helperConfig;

    uint256 enteranceFee;
    uint256 interval;
    address vrfCoordinator;
    bytes32 gasLane;
    uint256 subscriptionId;
    uint32 callbackGasLimit;

    address public PLAYER = makeAddr("player");
    uint256 public constant STARTING_PLAYER_BALANCE = 10 ether;

    event RaffleEntered(address indexed player);
    event WinnerPicked(address indexed winner);

    function setUp() external {
        DeployRaffle deployer = new DeployRaffle();
        (raffle, helperConfig) = deployer.deployContract();
        HelperConfig.NetworkConfig memory config = helperConfig.getConfig();
        enteranceFee = config.enteranceFee;
        interval = config.interval;
        vrfCoordinator = config.vrfCoordinator;
        gasLane = config.gasLane;
        subscriptionId = config.subscriptionId;
        callbackGasLimit = config.callbackGasLimit;
        vm.deal(PLAYER, STARTING_PLAYER_BALANCE);
    }

    function testRaffleState() public view {
        assert(raffle.getRaffleState() == Raffle.RaffleState.OPEN);
    }
    /*ENTER RAFFLE*/

    function testRaffle_NotEnoughFunds() public {
        //Arrange
        vm.prank(PLAYER);
        //Act / Assert
        vm.expectRevert(Raffle.Raffle__NotEnoughFunds.selector);
        raffle.enterRaffle();
    }

    function testRaffleRecordsPlayers() public {
        vm.prank(PLAYER);
        raffle.enterRaffle{value: enteranceFee}();
        address playerRecorded = raffle.getPlayers(0);
        assert(playerRecorded == PLAYER);
    }

    function testEnteringRaffleEmitEvent() public {
        vm.prank(PLAYER);
        vm.expectEmit(true, false, false, false, address(raffle));
        emit RaffleEntered(PLAYER);
        raffle.enterRaffle{value: enteranceFee}();
    }

    function testDontAllowPlayersWhileRaffleIsCal() public {
        vm.prank(PLAYER);
        raffle.enterRaffle{value: enteranceFee}();
        vm.warp(block.timestamp + interval + 1); //To make sure enough time has passed
        vm.roll(block.number + 1); //Block is increamented by 1
        raffle.performUpkeep("");

        //Act / Assert
        vm.expectRevert(Raffle.Raffle__NotOpen.selector);
        vm.prank(PLAYER);
        raffle.enterRaffle{value: enteranceFee}();
    }
    /* Check UpKeep */

    function testUpKeepIfItHasNoBalance() public {
        //Arrange
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);
        //Act
        (bool upkeepNeeded,) = raffle.checkUpkeep("");
        //Assert
        assert(!upkeepNeeded);
    }

    function testCheckUpKeepReturnsFalseIfRaffleIsntOpen() public {
        //Arrange
        vm.prank(PLAYER);
        raffle.enterRaffle{value: enteranceFee}();
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);
        raffle.performUpkeep("");
        //Act
        (bool upkeepNeeded,) = raffle.checkUpkeep("");
        //Assert
        assert(!upkeepNeeded);
    }
    /* Perform Upkeep */

    function testPerformUpKeepOnlyIfCheckUpKeepTrue() public {
        //Arrange
        vm.prank(PLAYER);
        raffle.enterRaffle{value: enteranceFee}();
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);
        //Act / Assert
        raffle.performUpkeep("");
    }

    function testPerformUpKeepRevertsIfCheckUpKeepFalse() public {
        //Arrange
        uint256 currentBalance = 0;
        uint256 playersCount = 0;
        Raffle.RaffleState rState = raffle.getRaffleState();
        vm.prank(PLAYER);
        raffle.enterRaffle{value: enteranceFee}();
        currentBalance = currentBalance + enteranceFee;
        playersCount++;
        //Act / Assert
        vm.expectRevert(
            abi.encodeWithSelector(Raffle.Raffle__UpkeepNotNeeded.selector, currentBalance, rState, playersCount)
        );
        raffle.performUpkeep("");
    }

    modifier raffleEntered() {
        vm.prank(PLAYER);
        raffle.enterRaffle{value: enteranceFee}();
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);
        _;
    }

    function testPerformUpkeepUpdatesRaffleStateAndEmitsRequestID() public raffleEntered {
        //Act
        vm.recordLogs();
        raffle.performUpkeep("");
        Vm.Log[] memory entries = vm.getRecordedLogs();
        bytes32 requestId = entries[0].topics[1];
        //Assert
        Raffle.RaffleState rState = raffle.getRaffleState();
        assert(uint256(requestId) > 0);
        assert(uint256(rState) == 1);
    }

    /* Fulfil Random Words */
    modifier skipFork() {
        if (block.chainid != LOCAL_CHAIN_ID) {
            return;
        }
        _;
    }

    // The below written is a statless fuzz test
    function testFulfillRandomWordsCanOnlyBeCalledAfterPerformUpKeep(uint256 randomRequestID) public raffleEntered {
        //Arrange / Act / Assert
        vm.expectRevert(VRFCoordinatorV2_5Mock.InvalidRequest.selector);
        VRFCoordinatorV2_5Mock(vrfCoordinator).fulfillRandomWords(randomRequestID, address(raffle));
    }

    function testFulfillrandomWordsPicksWinner() public raffleEntered skipFork {
        //Arrange
        uint256 additionalEntrants = 3; //4 total entrants
        uint256 startingIndex = 1;
        address expectedWinner = address(1);

        for (uint256 i = startingIndex; i < additionalEntrants + startingIndex; i++) {
            address newPlayer = address(uint160(i));
            hoax(newPlayer, 1 ether);
            raffle.enterRaffle{value: enteranceFee}();
        }
        uint256 startingTimeStamp = raffle.getLastTimeStamp();
        uint256 winnerStartingBalance = expectedWinner.balance;

        //Act
        vm.recordLogs();
        raffle.performUpkeep("");
        Vm.Log[] memory entries = vm.getRecordedLogs();
        bytes32 requestId = entries[1].topics[1];
        VRFCoordinatorV2_5Mock(vrfCoordinator).fulfillRandomWords(uint256(requestId), address(raffle));

        //Assert
        address recentWinner = raffle.getRecentWinner();
        Raffle.RaffleState rState = raffle.getRaffleState();
        uint256 endingTimeStamp = raffle.getLastTimeStamp();
        uint256 winnerBalance = recentWinner.balance;
        uint256 prize = enteranceFee * (additionalEntrants + 1);

        assert(recentWinner == expectedWinner);
        assert(uint256(rState) == 0);
        assert(endingTimeStamp > startingTimeStamp);
        assert(winnerBalance == winnerStartingBalance + prize);
    }
}
