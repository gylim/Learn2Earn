// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@chainlink/contracts/src/v0.8/KeeperCompatible.sol";

// MUST RESTRICT ACCESS
// MUST INCREASE SECURITY
// MUST BECOME GAS EFFICIENT

interface IAaveInteraction {
    function deposit() external payable;

    function withdraw(address _recipient, uint _withdrawAmount) external;
}

contract InterestDistributionTest is KeeperCompatibleInterface {
    // Testing
    // uint public interestPrevPeriod;
    // uint public totalAwarded;

    // Could neaten these up by using a struct, nested mapping ,iterable mapping??? 4444444444444444444444
    address[] public students;
    mapping(address => uint) public index;
    mapping(address => uint) public initialDeposit;
    mapping(address => uint) public interestEarned;
    mapping(address => uint) public recordedStartDay; // for payout
    mapping(address => uint) public pingExpiresAt; // 2^32 -1 equals to 4294967295 = 07/02/2106
    mapping(address => uint) public pingCount; // to track student progress for frontend

    // for frontend to determine if connected wallet is a student
    function isStudent(address stu) public view returns(bool) {
        for (uint i=0; i< students.length; i++) {
            if (students[i] == stu) return true;
        }
        return false;
    }
    function addStudent(address stu) internal {
        index[stu] = students.length;
        students.push(stu);
    }

    function removeUser(address stu) internal {
        uint delStudentIndex = index[stu];
        delete index[stu];
        delete initialDeposit[stu];
        delete interestEarned[stu];
        delete recordedStartDay[stu];
        delete pingExpiresAt[stu];
        delete pingCount[stu]; // for completeness

        // Replace deleted user with last user
        students[delStudentIndex] = students[students.length - 1];
        // Update the moved student's index
        address endStuAddress = students[students.length - 1];
        index[endStuAddress] = delStudentIndex;
        // Remove dead space
        students.pop();

        // // Visual demo:
        // [address0, address1, address2, address3, address4]
        // // Remove a2 and move a4 into it's slot
        // [address0, address1, address4, address3]
    }

    uint public depositTotal;

    IERC20 aPolWNative = IERC20(0x608D11E704baFb68CfEB154bF7Fd641120e33aD4);

    // Interface requires the correct deployed address for AaveInteraction contract (maybe pass through constructor??) 4444444444444444
    address AaveInteraction = 0x04930BB78fB25B66C78e8662F66Ea2053ABEE86A;
    IAaveInteraction aave = IAaveInteraction(AaveInteraction);

    uint public interval; // maybe uint32
    uint public todayUTC0;

    // Create js file for complex constructor arguments 4444444444444444
    constructor(uint _interval) {
        // Pass in number of seconds (day = 86400)
        interval = _interval;
        // Get most recent start period (midnight)
        todayUTC0 = (block.timestamp / interval) * interval;
    }

    uint public prevATokenBal;
    uint public curATokenBal;

    function register() external payable {
        require(isStudent() == false, "You are already registered");
        require(msg.value > 0, "not enough funds deposited");
        // Issue interest from previous remuneration period
        calcInterestPrevPeriod();

        // Add new student
        students.push(msg.sender);
        initialDeposit[msg.sender] = msg.value;
        depositTotal += msg.value;

        // For payout
        // recordedStartDay[msg.sender] = todayUTC0 + 1 days;
        recordedStartDay[msg.sender] = todayUTC0 + interval;

        // ping active for rest of day + 1 days
        pingExpiresAt[msg.sender] = todayUTC0 + (2 * interval);

        //Deposit user funds into Aave
        aave.deposit{value: msg.value}();

        // Update prevATokenBal for when register() calls calcInterestPrevPeriod() next time
        prevATokenBal = aPolWNative.balanceOf(AaveInteraction);
    }

    // The difference between the current and previous token balance is accrued interest
    // Exclude in-active parties from interest repayment
    // Distribute the accrued interest between active parties
    uint public interestPrevPeriod;

    function calcInterestPrevPeriod() internal {
        curATokenBal = aPolWNative.balanceOf(AaveInteraction);
        interestPrevPeriod = curATokenBal - prevATokenBal; // always 0 or greater

        uint unclaimedInterest;
        uint unclaimedDepositTotal;

        // If inactive, accumulate funds to re-distribute
        for (uint i = 0; i < students.length; i++) {
            address student = students[i];
            uint deposit = initialDeposit[student];

            // uint studentShare = deposit / depositTotal;

            if (pingExpiresAt[student] < block.timestamp) {
                // unclaimedInterest += interestPrevPeriod * studentShare;
                unclaimedInterest +=
                    (interestPrevPeriod * deposit) /
                    depositTotal;
                unclaimedDepositTotal += deposit;
            }
        }

        // If active, student gets default and unclaimed share
        for (uint i = 0; i < students.length; i++) {
            address student = students[i];
            uint deposit = initialDeposit[student];

            // uint studentShare = deposit / depositTotal;
            // uint studentShareUnclaimed = deposit / (depositTotal - unclaimedDepositTotal);

            if (depositTotal > unclaimedDepositTotal) {
                if (pingExpiresAt[student] >= block.timestamp) {
                    // default share
                    interestEarned[student] +=
                        (interestPrevPeriod * deposit) /
                        depositTotal;
                    // share of unclaimed
                    interestEarned[student] +=
                        (unclaimedInterest * deposit) /
                        (depositTotal - unclaimedDepositTotal);
                }
            }
        }
    }

    // tUTC0 updates each 24hr period
    // ping  emits an expiration timestamp which lasts until the end of the next day (This allows spam/multiple pinging)
    // |------|----p--|------|
    //      tUTC0      +1     +2
    function ping() public {
        // check that caller is a student
        require(isStudent() == false, "You must be registered to ping");
        pingExpiresAt[msg.sender] = todayUTC0 + (2 * interval);
        pingCount[msg.sender] += 1; // update pingCount for frontend
    }

    // KEEPER check for 24hr
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
            todayUTC0 += interval;
            calcInterestPrevPeriod();
            // Previous balance is updated to the Current balance as no additional funds are added (as in recipient)
            prevATokenBal = curATokenBal;
        }
    }

    function payout() external {
        // add security checks 4444444444444444444
        // recordedStartDay UTC0 + number of study days
        // require(
        //     block.timestamp >= (recordedStartDay[msg.sender] + 20 minutes),
        //     // (recordedStartDay[msg.sender] + (4 * studyPeriodDuration)),
        //     "You can only receive a payout once the study session is over"
        // );
        calcInterestPrevPeriod();

        uint withdrawAmount = interestEarned[msg.sender] +
            initialDeposit[msg.sender];
        depositTotal -= initialDeposit[msg.sender];
        interestEarned[msg.sender] = 0;
        initialDeposit[msg.sender] = 0;
        // REMOVE student from array/struct 444444444444444444444

        // Is there a safer way to do this?? withdraw doesn't seem to return an uint/ or any value...
        // this withdraws funds to AaveInteraction
        aave.withdraw(msg.sender, withdrawAmount);

        // Update prevATokenBal for when register() calls calcInterestPrevPeriod() next time
        prevATokenBal = aPolWNative.balanceOf(AaveInteraction);
    }

    // TESTING TESTING TESTING TESTING TESTING TESTING TESTING TESTING TESTING TESTING TESTING TESTING TESTING
    // TESTING TESTING TESTING TESTING TESTING TESTING TESTING TESTING TESTING TESTING TESTING TESTING TESTING
}
