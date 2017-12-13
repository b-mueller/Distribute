// ===================================================================== //
// This contract manages the reputation balances of each user and serves as
// the interface through which users stake reputation, come to consensus around
// tasks, claim tasks, vote, refund their stakes, and claim their task rewards.
// ===================================================================== //

pragma solidity ^0.4.10;

//import files
import "./Project.sol";
import "./ProjectRegistry.sol";
import "./library/PLCRVoting.sol";

/*
  keeps track of worker token balances of all
  states (free, staked, voted
*/

//INCOMPLETE

contract ReputationRegistry{

// =====================================================================
// STATE VARIABLES
// =====================================================================

  ProjectRegistry projectRegistry;
  PLCRVoting plcrVoting;

  mapping (address => uint) public balances;                   //worker token balances

  uint256 public totalReputationSupply;               //total supply of reputation in all states
  uint256 public totalFreeReputationSupply;           //total supply of free reputation (not staked, validated, or voted)

// =====================================================================
// EVENTS
// =====================================================================

// =====================================================================
// FUNCTIONS
// =====================================================================

  // =====================================================================
  // CONSTRUCTOR
  // =====================================================================

  function init(address _projectRegistry, address _plcrVoting) public {
      require(address(projectRegistry) == 0 && address(plcrVoting) == 0);
      projectRegistry = ProjectRegistry(_projectRegistry);
      plcrVoting = PLCRVoting(_plcrVoting);
  }

  function register() public {
    require(balances[msg.sender] == 0);
    balances[msg.sender] = 1;
  }

  // =====================================================================
  // PROPOSED PROJECT - STAKING FUNCTIONALITY
  // =====================================================================

  function stakeReputation(address _projectAddress, uint256 _reputation) public {
    /*require(balances[msg.sender] > 1);*/

    require(balances[msg.sender] >= _reputation);   //make sure project exists & TH has tokens to stake
    balances[msg.sender] -= _reputation;
    totalFreeReputationSupply -= _reputation;
    Project(_projectAddress).stakeReputation(msg.sender, _reputation);
  }

  function unstakeReputation(address _projectAddress, uint256 _reputation) public {

    balances[msg.sender] += _reputation;
    totalFreeReputationSupply += _reputation;
    Project(_projectAddress).unstakeReputation(msg.sender, _reputation);
  }

  function submitTaskHash(address _projectAddress, bytes32 _taskHash) public view {
    /**/
    // Project(_projectAddress).addTaskHash(_taskHash, msg.sender);
  }

  // =====================================================================
  // ACTIVE PERIOD FUNCTIONALITY
  // =====================================================================

  function submitHashList(address _projectAddress, bytes32[] _hashes) public view {
    /**/
    // Project(_projectAddress).submitHashList(_hashes);
  }

  function claimTask(address _projectAddress, uint256 _index, string _taskDescription, uint256 _weiVal, uint256 _repVal) public {
    require(balances[msg.sender] >= _repVal);
    /**/
    balances[msg.sender] -= _repVal;
    // Project(_projectAddress).claimTask(_index, _taskDescription, _weiVal, _repVal, msg.sender);
  }

  // =====================================================================
  // VALIDATE/VOTING FUNCTIONALITY
  // =====================================================================

  function voteCommit(address _projectAddress, uint256 _reputation, bytes32 _secretHash, uint256 _prevPollID) public {     //_secretHash Commit keccak256 hash of voter's choice and salt (tightly packed in this order), done off-chain
    require(balances[msg.sender] > 1);      //worker can't vote with only 1 token
    uint256 pollId = projectRegistry.votingPollId(_projectAddress);
    /*uint256 nonce = projectRegistry.projectNonce();*/
    //calculate available tokens for voting
    uint256 availableTokens = plcrVoting.voteReputationBalance(msg.sender) - plcrVoting.getLockedTokens(msg.sender);
    //make sure msg.sender has tokens available in PLCR contract
    //if not, request voting rights for token holder
    if (availableTokens < _reputation) {
      require(balances[msg.sender] >= _reputation - availableTokens && pollId != 0);
      balances[msg.sender] -= _reputation;
      totalFreeReputationSupply -= _reputation;
      plcrVoting.requestVotingRights(msg.sender, _reputation - availableTokens);
    }
    plcrVoting.commitVote(msg.sender, pollId, _secretHash, _reputation, _prevPollID);
  }

  function voteReveal(address _projectAddress, uint256 _voteOption, uint _salt) public {
    uint256 pollId = projectRegistry.votingPollId(_projectAddress);
    plcrVoting.revealVote(pollId, _voteOption, _salt);
  }

  function refundVotingReputation(uint256 _reputation) public {
    plcrVoting.withdrawVotingRights(msg.sender, _reputation);
    balances[msg.sender] += _reputation;
    totalFreeReputationSupply += _reputation;
  }


  // =====================================================================
  // FAILED / VALIDATED PROJECT
  // =====================================================================

  // called by project if a project fails
  function burnReputation(uint256 _reputation) public {
    //check that valid project is calling this function
    totalReputationSupply -= _reputation;
  }

  function refundStaker(address _projectAddress) public {                                                                       //called by worker who staked or voted
    uint256 _refund = Project(_projectAddress).refundStaker(msg.sender);
    totalFreeReputationSupply += _refund;
    balances[msg.sender] += _refund;
  }

  function rewardTask(address _projectAddress, bytes32 _taskHash) public {                                   //called by worker who completed a task
    /**/
    // uint256 reward = Project(_projectAddress).claimTaskReward(_taskHash, msg.sender);

    uint256 reward = 0;
    totalFreeReputationSupply += reward;
    balances[msg.sender] += reward;
  }
}