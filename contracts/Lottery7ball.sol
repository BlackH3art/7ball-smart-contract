// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";

contract Lottery7ball is VRFConsumerBaseV2 {


  uint8[] rangeArray;
  uint8[] drawnNumbersArray;

  uint8[7][] public ticketsArray;
  address[] public ticketOwnersArray;

  address[] winners7ball;
  address[] winners6ball;
  address[] winners5ball;
  address[] winners4ball;
  address[] winners3ball;

  uint256 prize7matched;
  uint256 prize6matched;
  uint256 prize5matched;
  uint256 prize4matched;
  uint256 prize3matched;

  mapping(address => uint256) public addressToRewardBalance;

  // ===================================================
  //                  CHAINLINK CONFIGURATION
  // ===================================================

  VRFCoordinatorV2Interface COORDINATOR;

  address constant vrfCoordinator = 0x7a1BaC17Ccc5b313516C5E16fb24f7659aA5ebed;
  bytes32 constant keyHash = 0x4b09e658ed251bcafeebbc69400383d49f344ace09b9576fe248bb02c003fe9f;

  uint64 immutable subscriptionId;
  uint32 constant callbackGasLimit = 2000000;
  uint16 constant requestConfirmations = 3;
  uint16 constant randomNumbersAmount =  7;
  uint256 public requestId;

  

  constructor(
    uint64 _subscriptionId
  ) VRFConsumerBaseV2(vrfCoordinator) {

    COORDINATOR = VRFCoordinatorV2Interface(vrfCoordinator);
    subscriptionId = _subscriptionId;

    rangeArray = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42];

    prize6matched = 1000000000000000000; // 1.00 ether
    prize5matched = 100000000000000000; // 0.10 ether
    prize4matched = 50000000000000000; // 0.05 ether
    prize3matched = 12000000000000000; // 0.012 ether
  }





  // ===================================================
  //                  AUTOMATION INTERFACE
  // ===================================================

  function startLottery() public {

    requestId = COORDINATOR.requestRandomWords(
      keyHash,
      subscriptionId,
      requestConfirmations,
      callbackGasLimit,
      randomNumbersAmount
    );
  }

  


  // ===================================================
  //               CHAINLINK FALLBACK
  // ===================================================

  function fulfillRandomWords(uint256 _requestId, uint256[] memory _randomNumbers) internal override {

    addNumberToDrawnNumbersArray(_randomNumbers[0] % rangeArray.length);
    addNumberToDrawnNumbersArray(_randomNumbers[1] % rangeArray.length);
    addNumberToDrawnNumbersArray(_randomNumbers[2] % rangeArray.length);
    addNumberToDrawnNumbersArray(_randomNumbers[3] % rangeArray.length);
    addNumberToDrawnNumbersArray(_randomNumbers[4] % rangeArray.length);
    addNumberToDrawnNumbersArray(_randomNumbers[5] % rangeArray.length);
    addNumberToDrawnNumbersArray(_randomNumbers[6] % rangeArray.length);
  }







  // ===================================================
  //               UTILS / HELPERS
  // ===================================================

  function addNumberToDrawnNumbersArray(uint256 number) internal {
    drawnNumbersArray.push(rangeArray[number]);

    delete rangeArray[number];

    for(uint256 i = number; i < rangeArray.length - 1; i++) {
      rangeArray[i] = rangeArray[i + 1];
    }
  }


  function pushWinnersToArrays() internal {

    for(uint32 i = 0; i < ticketsArray.length; i++) {
      uint8 matching = 0;

      for(uint8 j = 0; j < ticketsArray[i].length; j++) {

        for(uint8 k = 0; k < drawnNumbersArray.length; k++) {
          if(drawnNumbersArray[k] == ticketsArray[i][j]) {
            matching = matching + 1;
          }
        }
      }

      if(matching == 7) {
        winners7ball.push(ticketOwnersArray[i]);

      } else if(matching == 6) {
        winners6ball.push(ticketOwnersArray[i]);

      } else if(matching == 5) {
        winners5ball.push(ticketOwnersArray[i]);

      } else if(matching == 4) {
        winners4ball.push(ticketOwnersArray[i]);
        
      } else if(matching == 3) { 
        winners3ball.push(ticketOwnersArray[i]);
      }
    }
  }

}