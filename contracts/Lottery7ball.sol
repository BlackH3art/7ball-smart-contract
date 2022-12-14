// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@chainlink/contracts/src/v0.8/AutomationCompatible.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Lottery7ball is VRFConsumerBaseV2, Ownable, AutomationCompatible {


  uint8[] rangeArray;
  uint8[] public drawnNumbersArray;

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

  uint256 ticketPrice;

  uint256 public prizePool;
  uint256 public protocolPool;
  uint256 public adminPool;

  uint256 public lastTimeStamp;
  uint256 public interval;
  bool public gameIsOn;

  mapping(address => uint256) public addressToRewardBalance;

  event UpdatedNumbersDrawn();
  event UpdatedInterval(uint256 indexed interval);
  event UpdatedPrizePool();
  event UpdatedBalances();
  event GameIsOn(bool isGameOn);
  event GameReset();

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

    ticketPrice = 1 ether;

    lastTimeStamp = block.timestamp;
    interval = 1 hours;
    gameIsOn = true;
  }




  // ===================================================
  //                  AUTOMATION INTERFACE
  // ===================================================

  function checkUpkeep(bytes calldata /* checkData */) external view override returns (bool upkeepNeeded, bytes memory /* performData */) {
    upkeepNeeded = (block.timestamp - lastTimeStamp) > interval;
  }

  function performUpkeep(bytes calldata /* performData */) external override {

    if ((block.timestamp - lastTimeStamp) > interval ) {

      if(gameIsOn) {
        lastTimeStamp = block.timestamp;
        startLottery();

        interval = 20 minutes;
        gameIsOn = false;

        emit GameIsOn(gameIsOn);
        emit UpdatedInterval(interval);

      } else {
        lastTimeStamp = block.timestamp;
        resetGame();

        interval = 1 hours;
        gameIsOn = true;

        emit GameIsOn(gameIsOn);
        emit UpdatedInterval(interval);
      }
    }
  }

  function startLottery() internal {

    requestId = COORDINATOR.requestRandomWords(
      keyHash,
      subscriptionId,
      requestConfirmations,
      callbackGasLimit,
      randomNumbersAmount
    );
  }

  function resetGame() internal {

    rangeArray = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42];

    delete ticketsArray;
    delete ticketOwnersArray;
    delete drawnNumbersArray;

    delete winners7ball;
    delete winners6ball;
    delete winners5ball;
    delete winners4ball;
    delete winners3ball;

    emit GameReset();
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

    pushWinnersToArrays();
    assignPrizesToWinnersBalances();

    emit UpdatedNumbersDrawn();
  }




  // ===================================================
  //               PUBLIC INTERFACE
  // ===================================================

  function claimReward() public {
    require(address(this).balance >= addressToRewardBalance[msg.sender], "Insufficient funds in contract");

    uint256 rewardBalance = addressToRewardBalance[msg.sender];
    addressToRewardBalance[msg.sender] = 0;
    payable(msg.sender).transfer(rewardBalance);
  }

  
  function buyTicket(
    uint8 first,
    uint8 second,
    uint8 third,
    uint8 fourth,
    uint8 fifth,
    uint8 sixth,
    uint8 seventh) public payable payThePrice lotteryIsOn {

    prizePool = prizePool + (msg.value / 100) * 90;
    protocolPool = protocolPool + (msg.value / 100) * 10;

    ticketsArray.push([first, second, third, fourth, fifth, sixth, seventh]);
    ticketOwnersArray.push(msg.sender);

    emit UpdatedPrizePool();
  }




  // ===================================================
  //               ADMIN INTERFACE
  // ===================================================

  function adminWithdrawProtocolPool(address payable withdrawTo, uint256 amount) public onlyOwner {
    require(amount <= protocolPool, "Cannot withdraw more than protocolPool");

    protocolPool = protocolPool - amount;
    withdrawTo.transfer(amount);
  }

  function adminWithdrawAdminPool(address payable withdrawTo, uint256 amount) public onlyOwner {
    require(amount <= adminPool, "Cannot withdraw more than adminPool");

    adminPool = adminPool - amount;
    prizePool = prizePool - amount;
    withdrawTo.transfer(amount);

    emit UpdatedPrizePool();
  }

  function adminFundContract() public payable onlyOwner {
    prizePool += msg.value;
    adminPool += msg.value;

    emit UpdatedPrizePool();
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


  function assignPrizesToWinnersBalances() internal {

    /*
      This function is called to assign prize to each winner.
      Prizes for up to 6 matched numbers are fixed that is why they are determined first.
      Main prize for 7 matched numbers is always prizePool, so to make sure that all winners
      will get their prize, it is calculated at the end, and has to be split between all
      who matched 7 numbers evenly.
    */

    if(winners3ball.length != 0) {
      for(uint32 i = 0; i < winners3ball.length; i++) {
        addressToRewardBalance[winners3ball[i]] += prize3matched;
      }
      prizePool = prizePool - (winners3ball.length * prize3matched);
    }


    if(winners4ball.length != 0) {
      for(uint32 i = 0; i < winners4ball.length; i++) {
        addressToRewardBalance[winners4ball[i]] += prize4matched;
      }
      prizePool = prizePool - (winners4ball.length * prize4matched);
    }


    if(winners5ball.length != 0) {
      for(uint32 i = 0; i < winners5ball.length; i++) {
        addressToRewardBalance[winners5ball[i]] += prize5matched;
      }
      prizePool = prizePool - (winners5ball.length * prize5matched);
    }


    if(winners6ball.length != 0) {
      for(uint32 i = 0; i < winners6ball.length; i++) {
        addressToRewardBalance[winners6ball[i]] += prize6matched;
      }
      prizePool = prizePool - (winners6ball.length * prize6matched);
    }


    if(winners7ball.length != 0) {
      prize7matched = prizePool / winners7ball.length;

      for(uint32 i = 0; i < winners7ball.length; i++) {
        addressToRewardBalance[winners7ball[i]] += prize7matched;
      }
      prizePool = prizePool - (winners7ball.length * prize7matched);
    }

    emit UpdatedBalances();
  }




  // ===================================================
  //                  MODIFIERS
  // ===================================================

  modifier payThePrice() {
    require(msg.value >= ticketPrice, "Insufficient transfer");
    _;
  }

  modifier lotteryIsOn() {
    require(gameIsOn == true, "Lottery has not started yet");
    _;
  }




  // ===================================================
  //               TESTING INTERFACE
  //               only for testnet
  // ===================================================

  function test_withdrawAll() public onlyOwner {
    payable(msg.sender).transfer(address(this).balance);
  }

  function test_fundContract() public payable onlyOwner {
    prizePool += msg.value;
    
    emit UpdatedPrizePool();
  }

}