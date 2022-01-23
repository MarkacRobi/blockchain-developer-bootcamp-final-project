// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol";

contract RobiToken is ERC20, ERC20Permit, ERC20Votes {

  struct BalanceCheckpoint {
    uint blockHeight;
    uint balance;
  }

  mapping(address => BalanceCheckpoint[]) private _balanceCheckpoints;

  constructor(uint256 initialSupply, string memory name, string memory symbol) ERC20(name, symbol) ERC20Permit(name) {
    _mint(msg.sender, initialSupply);
  }

  function getBalanceCheckpoints(address _address) public view returns (BalanceCheckpoint[] memory) {
    return _balanceCheckpoints[_address];
  }

  function getLatestBalanceCheckpoint(address _address) public view returns (BalanceCheckpoint memory) {
    BalanceCheckpoint[] memory checkpointsArray = _balanceCheckpoints[_address];
    if (checkpointsArray.length > 0) {
      return checkpointsArray[checkpointsArray.length - 1];
    } else {
      return BalanceCheckpoint(0, 0);
    }
  }

  function getBalanceAtBlockHeight(address _address, uint voteStart) public view returns (uint) {
    BalanceCheckpoint[] storage checkpoints = _balanceCheckpoints[_address];

    // iterate from back to front seeking last checkpoint before voteStart
    for (uint i = checkpoints.length; i > 0; i--) {
      // when you find first checkpoint before voteStart
      if (checkpoints[i-1].blockHeight < voteStart) {
        return checkpoints[i-1].balance;
      }
    }

    return 0;
  }

  // The functions below are overrides required by Solidity.

  function _afterTokenTransfer(address from, address to, uint256 amount)
  internal
  override(ERC20, ERC20Votes)
  {
    super._afterTokenTransfer(from, to, amount);

    // checkpoint sender and receiver balance at this block height
    _balanceCheckpoints[from].push(BalanceCheckpoint(block.number, balanceOf(from)));
    _balanceCheckpoints[to].push(BalanceCheckpoint(block.number, balanceOf(to)));
  }

  function mintMe(uint256 amount) public {
    return _mint(msg.sender, amount);
  }

  function _mint(address to, uint256 amount)
  internal
  override(ERC20, ERC20Votes)
  {
    super._mint(to, amount);
  }

  function _burn(address account, uint256 amount)
  internal
  override(ERC20, ERC20Votes)
  {
    super._burn(account, amount);
  }
}
