// SPDX-License-Identifier: MIT 
pragma solidity ^0.8.19;

import {Script, console} from "forge-std/Script.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {VRFCoordinatorV2_5Mock} from
    "chainlink-brownie-contracts/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";

contract CreateSubscription is Script {
    function createSubscriptionUsingConfig() public returns (uint256, address) {
        HelperConfig helperConfig = new HelperConfig();
        address vrfCoordinator = helperConfig.getConfig().vrfCoordinator;
        (uint256 subID, ) = createSubscription(vrfCoordinator);
        return (subID, vrfCoordinator);      
    }

    function createSubscription(address vrfCoordinator) public returns (uint256, address) {
        console.log("Creating subscription on chain ID: ", block.chainid);
        vm.startBroadcast();
        uint256 subID = VRFCoordinatorV2_5Mock(vrfCoordinator).createSubscription();
        vm.stopBroadcast();
        console.log("Your Subscription ID is: ", subID);
        console.log("Please update your subscription ID in the HelperConfig contract");
        return (subID, vrfCoordinator);
    }
    
    function run() public {
        createSubscriptionUsingConfig();
    }
}

contract FundSubscription is Script {
    uint256 public constant FUND_AMOUNT = 3 ether; //3 LINK

    function FundSubscriptionUsingConfig() public {
        HelperConfig helperConfig = new HelperConfig();
        address vrfCoordinator = helperConfig.getConfig().vrfCoordinator;
        uint256 subscriptionID = helperConfig.getConfig().subscriptionId;
    }
    function run() public {
        FundSubscriptionUsingConfig();
    }
}