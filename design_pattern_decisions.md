# Design Pattern Decisions

## Inter-Contract Execution

One of the features of `RobiGovernor` contract is to cast vote on the active proposal.
Using `IRobiToken` interface, `castVote` method of `RobiToken` contract is called in order to fetch users balance at certain block height.

## Access Control Design Patterns

`Ownable` design pattern is used to restrict calling some contract functionality only
to owner of the contract. 

### In `RobiGovernor` Contract functions

- `updateVotingPeriod()`
- `confirmProposalExecution()`


## Inheritance and Interfaces

Both `RobiToken` and `RobiGovernor` contracts use different imported contracts from OpenZeppelin.

### `RobiToken` Contract

It inherits `ERC20` contract that contains implementation of `IERC20` token standard interface.

### `RobiGovernor` Contract

It inherits `Ownable` contract to restrict some function access only to owner.
It inherits `ReentrancyGuard` contract to prevent reentrancy calls on functions vulnerable to it.