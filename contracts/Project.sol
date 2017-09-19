pragma solidity ^0.4.10;

//import files
import "./ProjectRegistry.sol";
import "./TokenHolderRegistry.sol";
import "./WorkerRegistry.sol";

/*
  a created project
*/

contract Project{

//state variables
  address tokenHolderRegistry;
  address workerRegistry;
  address projectRegistry;

  address proposer;

  uint capitalCost;   //total amount of staked capital tokens needed
  uint workerCost;    //total amount of staked worker tokens needed
  uint proposerStake;   //amount of capital tokens the proposer stakes

  //keep track of staking on proposed project
  uint totalCapitalStaked;   //amount of capital tokens currently staked
  uint totalWorkerStaked;    //amount of worker tokens currently staked
  mapping (address => uint) stakedCapitalBalances;
  mapping (address => uint) stakedWorkerBalances;

  //keep track of workers with tasks
  Worker[] workers;   //array of tasked workers

  struct Worker {
    address workerAddress;
    bool taskComplete;
    //uint taskHash;
    //uint escrowTokens;   //tokens paid to sign up for task, amount they will earn if validated
    //uint ETHReward;      //unclear how to go about representing this
  }

  //keep track of validating complete project
  mapping (address => uint) validatedAffirmative;
  mapping (address => uint) validatedNegative;
  uint validationPeriod;

  //needed to keep track of voting complete project
  mapping (address => uint) votedAffirmative;
  mapping (address => uint) votedNegative;
  uint votingPeriod;

  //project states & deadlines
  State public projectState;
  uint public projectDeadline;
  enum State {
    Proposed,
    Active,
    Completed,
    Validated,
    Incomplete,
    Failed,
    Abandoned
  }

//events

//modifiers

  modifier onlyInState(State _state) {
    require(projectState == _state);
    _;
  }

  modifier onlyBefore(uint time) {
    require(now < time);
    _;
  }

/*
  modifier onlyWorker() {
    _;
  }

  modifier onlyTokenHolder() {
    _;
  }
*/

//constructor
  function Project(uint _cost, uint _projectDeadline) {
    //check has percentage of tokens to stake
    //move tokens from free to proposed in tokenholder contract
    projectRegistry = msg.sender;     //the project registry calls this function
    capitalCost = _cost;
    projectDeadline = _projectDeadline;
    projectState = State.Proposed;
    totalCapitalStaked = 0;
    totalWorkerStaked = 0;
  }

//functions

  //CHECK HAS TOKENS
  function checkHasFreeWorkerTokens() returns (bool) {
    //references worker registry

  }

  function checkHasFreeCapitalTokens() returns (bool) {

  }

  //PROPOSED PROJECT - STAKING FUNCTIONALITY
  function checkStaked() onlyInState(State.Proposed) internal returns (bool) {   //if staked, changes state and breaks
    if (totalCapitalStaked >= capitalCost && totalWorkerStaked >= workerCost)
      {
        projectState = State.Active;
        return true;
      }
    else {
      return false;
    }
  }

  function refundProposer() {   //called by proposer to return
    if (projectState != State.Proposed && ProjectRegistry(projectRegistry).proposers[this] == msg.sender) {   //make sure out of proposed state & msg.sender is the proposer
      TokenHolderRegistry(tokenHolderRegistry).totalFreeCapitalTokenSupply += ProjectRegistry(projectRegistry).proposerStakes[this];
      TokenHolderRegistry(tokenHolderRegistry).balances[msg.sender].freeTokenBalance += ProjectRegistry(projectRegistry).proposerStakes[this];
    }
  }


  function stakeCapitalToken(uint _tokens) onlyInState(State.Proposed) onlyBefore(projectDeadline) {
    if (checkStaked() == true) {
    //in case exchange rate has changed since last check
    //make sure has tokens to stake (reference TokenHolder contract)
    //move tokens from free to staked in TokenHolder contract
      if((stakedCapitalBalances[msg.sender] + _tokens) > stakedCapitalBalances[msg.sender]) {
        stakedCapitalBalances[msg.sender] += _tokens;
      }
      checkStaked();
    }
  }

  function unstakeCapitalToken(uint _tokens) onlyInState(State.Proposed) onlyBefore(projectDeadline) {
    checkStaked();
    //make sure has tokens to stake (reference TokenHolder contract)
    //move tokens from staked to free in TokenHolder contract
    if(stakedCapitalBalances[msg.sender] - _tokens < stakedCapitalBalances[msg.sender]) {
      stakedCapitalBalances[msg.sender] -= _tokens;
    }
  }

  function stakeWorkerToken(uint _tokens) onlyInState(State.Proposed) onlyBefore(projectDeadline) {
    checkStaked();
    //make sure has tokens to stake (reference Worker contract)
    //move tokens from free to staked in Worker contract
    if((stakedWorkerBalances[msg.sender] + _tokens) > stakedWorkerBalances[msg.sender]) {
      stakedWorkerBalances[msg.sender] += _tokens;
    }
    checkStaked();
  }

  function unstakeWorkerToken(uint _tokens) onlyInState(State.Proposed) onlyBefore(projectDeadline) {
    checkStaked();
    //make sure has tokens to unstake (reference Worker contract)
    //move tokens from staked to free in Worker contract
    if(stakedWorkerBalances[msg.sender] - _tokens < stakedWorkerBalances[msg.sender]) {
      stakedWorkerBalances[msg.sender] -= _tokens;
    }
  }

  //ACTIVE PROJECT
  function checkWorkersDone() onlyInState(State.Active) internal returns (bool) {
    for (uint i=0; i<workers.length; i++) {
        if (workers[i].taskComplete == false) {
          return false;
        }
        else {
          return true;
        }
    }
  }

  function addWorker(address _workerAddress) onlyInState(State.Active) onlyBefore(projectDeadline) {
    //need to restrict who can call this
    workers.push(Worker(_workerAddress, false));
  }

  function updateWorker() onlyInState(State.Active) returns (bool) {
    for (uint i=0; i<workers.length; i++) {
      if(workers[i].workerAddress == msg.sender) {
        workers[i].taskComplete = true;
        return true;
      }
      else {
      return false;
      }
    }
  }

  //COMPLETED PROJECT - VALIDATION & VOTING FUNCTIONALITY
  function checkValidationOver() onlyInState(State.Completed) internal {

  }

  function checkVotingOver() onlyInState(State.Completed) internal {

  }

  function validate(uint _tokens, bool _validationState) onlyInState(State.Completed) onlyBefore(projectDeadline) {
    //make sure has the free tokens
    //move msg.sender's tokens from freeTokenBalance to validatedTokenBalance
    if (_validationState) {
      //check for overflow
      //move tokens from free to validated
      validatedAffirmative[msg.sender] += _tokens;
    }
    else {
      //check for overflow
      //move tokens from free to validated in other contract
      validatedNegative[msg.sender] += _tokens;
    }
  }

  function vote(uint _tokens, bool _validationState, bool _isworker) onlyBefore(projectDeadline) {
    //check has the free tokens depending on bool _isworker
    //move tokens from free to vote in other contract
    //check for overflow
    //update votedAffirmative or votedNegative mapping
  }

}
