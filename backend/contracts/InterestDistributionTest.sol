// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@chainlink/contracts/src/v0.8/KeeperCompatible.sol";

// MUST RESTRICT ACCESS
// MUST INCREASE SECURITY
// MUST BECOME GAS EFFICIENT - reduce size of uints/ immutable

interface IAaveInteraction {
    function deposit() external payable;

    function withdraw(address _recipient, uint _withdrawAmount) external;
}

contract InterestDistributionTest is KeeperCompatibleInterface {
    IERC20 private immutable aWNative;
    IAaveInteraction private immutable aave;

    // Testing
    uint public totalAwarded;

    // Change the below visibility to private 4444444444444444
    address[] public students;
    mapping(address => uint) public index;
    mapping(address => uint) public initialDeposit;
    mapping(address => uint) public interestEarned;
    mapping(address => uint) public recordedStartDay; // for payout
    mapping(address => uint) public pingExpiresAt; // 2^32 -1 equals to 4294967295 = 07/02/2106

    uint public depositTotal;

    uint public interval; // maybe uint32
    uint public todayUTC0;

    constructor(
        address _AaveInteractionAddress,
        address _tokenAddress,
        uint _interval
    ) {
        aave = IAaveInteraction(_AaveInteractionAddress);
        aWNative = IERC20(_tokenAddress);

        // Pass in number of seconds (day = 86400)
        interval = _interval;
        // Get most recent start period (midnight)
        todayUTC0 = (block.timestamp / interval) * interval;
    }

    uint public prevATokenBal;
    uint public curATokenBal;

    function register() external payable {
        // This stops divide by 0 error
        require(msg.value > 0, "not enough funds deposited");

        // Issue interest from previous remuneration period
        calcInterestPrevPeriod();

        // Add student data to mappings
        addStudent(msg.sender);

        // Ping is active for rest of interval + 1 interval
        ping();

        //Deposit user funds through AaveInteraction
        aave.deposit{value: msg.value}();

        // Update prevATokenBal for when register() calls calcInterestPrevPeriod() next time
        prevATokenBal = aWNative.balanceOf(AaveInteraction);
    }

    // The difference between the current and previous token balance is accrued interest
    // Exclude in-active parties from interest repayment
    // Distribute the accrued interest between active parties
    uint public interestPrevPeriod;

    function calcInterestPrevPeriod() internal {
        curATokenBal = aWNative.balanceOf(AaveInteraction);
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

    // tUTC0 updates each `interval`
    // ping  emits an expiration timestamp which lasts until the end of the next day (This allows spam/multiple pinging)
    // |------|----p--|------|
    //      tUTC0      +1     +2
    function ping() public {
        pingExpiresAt[msg.sender] = todayUTC0 + (2 * interval);
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
        removeStudent(msg.sender);

        // Is there a safer way to do this?? withdraw doesn't seem to return an uint/ or any value...
        // this withdraws funds to AaveInteraction
        aave.withdraw(msg.sender, withdrawAmount);

        // Update prevATokenBal for when register() calls calcInterestPrevPeriod() next time
        prevATokenBal = aWNative.balanceOf(AaveInteraction);
    }

    function addStudent(address stu) internal {
        // for itterable mapping
        index[stu] = students.length;
        students.push(stu);

        // for interest calculations
        initialDeposit[stu] = msg.value;
        depositTotal += msg.value;

        // For payout
        recordedStartDay[stu] = todayUTC0 + interval;
    }

    function removeStudent(address stu) internal {
        uint delStudentIndex = index[stu];
        delete index[stu];
        delete initialDeposit[stu];
        delete interestEarned[stu];
        delete recordedStartDay[stu];
        delete pingExpiresAt[stu];

        // Replace deleted Stu with last Stu
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

    // TESTING TESTING TESTING TESTING TESTING TESTING TESTING TESTING TESTING TESTING TESTING TESTING TESTING
    // TESTING TESTING TESTING TESTING TESTING TESTING TESTING TESTING TESTING TESTING TESTING TESTING TESTING
}
