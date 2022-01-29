# Avoiding Common Attacks

## Using Specific Compiler Pragma

Both `RobiGovernor` and `RobiToken` uses `pragma solidity 0.8.0` compiler version.

## Use Modifiers Only for Validation

Modifiers inside `RobiGovernor` are only used for validation and reentrancy guarding.

## Re-entrancy
Use a reentrancy guard when calling external function in `updateProposalStates()` function in `RobiGovernor`.

## Tx.Origin Authentication
Use of msg.sender instead of tx.origin.