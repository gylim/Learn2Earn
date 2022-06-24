// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

// KeeperCompatible.sol imports the functions from both ./KeeperBase.sol and
// ./interfaces/KeeperCompatibleInterface.sol
import "@chainlink/contracts/src/v0.8/KeeperCompatible.sol";

contract Keeper is KeeperCompatibleInterface {
    // KEEPER check for 24hr
    // uint interval = 30 seconds; // maybe uint32 // use 1 days
    uint public immutable interval = 30 seconds;
    uint public todayUTC0 = 1656073265;
    uint public current;
    uint public tokenBal;

    constructor() {
        // uint _todayUTC0
        // todayUTC0 = _todayUTC0;
    }

    function calcInterestPrevPeriod() public {
        current += 1;
    }

    function checkUpkeep(bytes calldata)
        external
        view
        override
        returns (bool upkeepNeeded, bytes memory)
    {
        upkeepNeeded = (block.timestamp - todayUTC0) > interval;
    }

    function performUpkeep(bytes calldata) external override {
        // Re-validation check
        if ((block.timestamp - todayUTC0) > interval) {
            // Could automate todayUTC0 with % ?? where upkeep handles all time parameters 4444444444444444
            todayUTC0 += 1 days;
            calcInterestPrevPeriod();
            // the previous balance is updated to the Current balance as no additional funds are added (as in recipient)
            tokenBal += 3;
        }
    }
}
