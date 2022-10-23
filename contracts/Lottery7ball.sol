// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";

contract Lottery7ball is VRFConsumerBaseV2 {


  uint8[] rangeArray;
  uint8[] drawnNumbersArray;

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

    addDrawnNumberToArray(randomNumbers[0] % rangeArray.length);
    addDrawnNumberToArray(randomNumbers[1] % rangeArray.length);
    addDrawnNumberToArray(randomNumbers[2] % rangeArray.length);
    addDrawnNumberToArray(randomNumbers[3] % rangeArray.length);
    addDrawnNumberToArray(randomNumbers[4] % rangeArray.length);
    addDrawnNumberToArray(randomNumbers[5] % rangeArray.length);
    addDrawnNumberToArray(randomNumbers[6] % rangeArray.length);
  }







  // ===================================================
  //               UTILS / HELPERS
  // ===================================================

  function addDrawnNumberToArray(uint256 number) internal {
    drawnNumbersArray.push(rangeArray[number]);

    delete rangeArray[number];

    for(uint256 i = number; i < rangeArray.length - 1; i++) {
      rangeArray[i] = rangeArray[i + 1];
    }
  }

}