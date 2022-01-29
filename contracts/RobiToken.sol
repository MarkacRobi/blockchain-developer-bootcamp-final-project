// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol";

/// @title ERC20 compliant implementation of custom token.
/// @author Robi Markac
/// @notice This contract can be used as POC governance token
/// @dev Functions are implemented in the spirit of POC thus it should be adjusted before deploying to main net
contract RobiToken is ERC20, ERC20Permit, ERC20Votes {

  /// @notice BalanceCheckpoint struct determines balance at certain block height
  struct BalanceCheckpoint {
    uint blockHeight;
    uint balance;
  }

  /// @dev _balanceCheckpoints mapping maps user address to his balance checkpoints
  mapping(address => BalanceCheckpoint[]) private _balanceCheckpoints;

  /// @notice Construct contract by providing ERC20 params (token name and symbol) and initial supply of token
  /// @param initialSupply The initial token supply
  /// @param name A token name
  /// @param symbol A token symbol
  constructor(uint256 initialSupply, string memory name, string memory symbol) ERC20(name, symbol) ERC20Permit(name) {
    _mint(msg.sender, initialSupply);
  }

  /// @notice Retrieve balance checkpoints for specific address
  /// @param _address Users address for which balance checkpoints are being requested
  /// @return BalanceCheckpoint[] Array of users balance checkpoints
  function getBalanceCheckpoints(address _address) public view returns (BalanceCheckpoint[] memory) {
    return _balanceCheckpoints[_address];
  }

  /// @notice Retrieve balance checkpoint for specific address
  /// @dev  Returned BalanceCheckpoint will be set to 0 values if none exist
  /// @param _address Users address for which latest balance checkpoint is requested
  /// @return BalanceCheckpoint Latest users balance checkpoint or zero initialized BalanceCheckpoint
  function getLatestBalanceCheckpoint(address _address) public view returns (BalanceCheckpoint memory) {
    BalanceCheckpoint[] memory checkpointsArray = _balanceCheckpoints[_address];
    if (checkpointsArray.length > 0) {
      return checkpointsArray[checkpointsArray.length - 1];
    } else {
      return BalanceCheckpoint(0, 0);
    }
  }

  /// @notice Retrieve balance of specific address at specific block height
  /// @dev  This function can be computing intensive so consider caching value
  /// @param _address Users address for which balance is requested
  /// @param _blockHeight Block height at which users balance is requested
  /// @return uint Users balance at provided block height
  function getBalanceAtBlockHeight(address _address, uint _blockHeight) public view returns (uint) {
    BalanceCheckpoint[] storage checkpoints = _balanceCheckpoints[_address];

    // iterate from back to front seeking last checkpoint before voteStart
    for (uint i = checkpoints.length; i > 0; i--) {
      // when you find first checkpoint before voteStart
      if (checkpoints[i-1].blockHeight < _blockHeight) {
        return checkpoints[i-1].balance;
      }
    }

    return 0;
  }

  /// @notice Override of _afterTokenTransfer with custom added balance checkpoint logic
  /// @dev Override of _afterTokenTransfer is required by Solidity
  function _afterTokenTransfer(address from, address to, uint256 amount)
  internal
  override(ERC20, ERC20Votes)
  {
    super._afterTokenTransfer(from, to, amount);

    // checkpoint sender and receiver balance at this block height
    _balanceCheckpoints[from].push(BalanceCheckpoint(block.number, balanceOf(from)));
    _balanceCheckpoints[to].push(BalanceCheckpoint(block.number, balanceOf(to)));
  }

  /// @notice Testing function to mint contracts tokens to specific address
  /// @dev This function should be removed or constrained with role check modifier for production
  /// @param amount uint256 number representing amount to mint to msg.sender
  function mintMe(uint256 amount) public {
    return _mint(msg.sender, amount);
  }

  /// @notice Override of _mint ERC20 function
  /// @dev Override of _mint is required by Solidity
  function _mint(address to, uint256 amount)
  internal
  override(ERC20, ERC20Votes)
  {
    super._mint(to, amount);
  }

  /// @notice Override of _burn ERC20 function
  /// @dev Override of _burn is required by Solidity
  function _burn(address account, uint256 amount)
  internal
  override(ERC20, ERC20Votes)
  {
    super._burn(account, amount);
  }
}
