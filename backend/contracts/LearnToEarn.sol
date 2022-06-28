// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@chainlink/contracts/src/v0.8/KeeperCompatible.sol";

// MUST RESTRICT ACCESS
// MUST INCREASE SECURITY
// MUST BECOME GAS EFFICIENT - reduce size of uints/ immutable

interface IAaveInteraction {
    function deposit() external payable;

    function withdraw(address _recipient) external;
}

interface ILearnToken {
    function mintToken(address recipient, uint256 amount) external;

    function transferOwnershipToken(address newOwner) external;
}

contract LearnToEarn is KeeperCompatibleInterface {
    IERC20 private immutable aWNative;
    IAaveInteraction private immutable aave;
    ILearnToken private immutable LearnToken;

    // Change the below visibility to private 4444444444444444
    address[] public students;
    mapping(address => uint) private index;
    mapping(address => uint) private initialDeposit;
    mapping(address => uint) private interestEarned;
    mapping(address => uint) private recordedStartDay; // for payout
    mapping(address => uint) private pingExpiresAt; // 2^32 -1 equals to 4294967295 = 07/02/2106
    mapping(address => uint) private pingCount; // to track student progress for frontend

    address private owner;
    address private AaveInteraction;
    uint private depositTotal;
    uint private interval; // maybe uint32
    uint private todayUTC0;
    uint private prevATokenBal;
    uint private curATokenBal;

    modifier onlyOwner() {
        require(owner == msg.sender, "msg.sender must be the owner");
        _;
    }

    constructor(
        address _AaveInteractionAddress,
        address _tokenAddress,
        address _LEARNAddress,
        uint _interval
    ) {
        AaveInteraction = _AaveInteractionAddress;
        aave = IAaveInteraction(_AaveInteractionAddress);
        aWNative = IERC20(_tokenAddress);
        LearnToken = ILearnToken(_LEARNAddress);

        owner = msg.sender;
        // Pass in number of seconds (day = 86400)
        interval = _interval;
        // Get most recent start period (midnight)
        todayUTC0 = (block.timestamp / interval) * interval;
    }

    // DelegateCall 4444444444
    function transferOwnership(address newOwner) external onlyOwner {
        LearnToken.transferOwnershipToken(newOwner);
    }

    // For AaveInteraction to get data from this contract's mapping, a getter function MUST be used
    function getWithdrawAmount(address stu) external view returns (uint) {
        return (interestEarned[stu] + initialDeposit[stu]);
    }

    function getStudentStatus() public view returns (bool) {
        return recordedStartDay[msg.sender] == 0 ? false : true;
    }

// 4444444444444444444444444444444444444444444444444444444
    // for frontend to determine if connected wallet is a student
    function isStudent() public view returns (bool) {
        return recordedStartDay[msg.sender] == 0 ? false : true;
    }

    function register() external payable {
        require(getStudentStatus() == false, "You are already registered");
        // This stops divide by 0 error
        require(msg.value > 0, "Not enough funds deposited");

        // Issue interest from previous remuneration period
        calcInterestPrevPeriod();

        // Add student data to mappings
        addStudent(msg.sender);

        // Ping is active for rest of interval + 1 interval
        ping();

        //Deposit user funds through AaveInteraction
        aave.deposit{value: msg.value}();

        // Give users LEARN for registering
        LearnToken.mintToken(msg.sender, msg.value * 2);

        // Update prevATokenBal for when register() calls calcInterestPrevPeriod() next time
        prevATokenBal = aWNative.balanceOf(AaveInteraction);
    }

    function payout() external {
        calcInterestPrevPeriod();

        depositTotal -= initialDeposit[msg.sender];
        aave.withdraw(msg.sender);
        removeStudent(msg.sender);

        // Update prevATokenBal for when register() calls calcInterestPrevPeriod() next time
        prevATokenBal = aWNative.balanceOf(AaveInteraction);
    }

    // tUTC0 updates each `interval`
    // Ping emits an expiration timestamp which lasts until the end of the next day (This allows spam/multiple pinging)
    // |------|----p--|------|
    //      tUTC0      +1     +2
    function ping() public {
        require(getStudentStatus() == true, "You must be registered to ping");
        pingExpiresAt[msg.sender] = todayUTC0 + (2 * interval);
        pingCount[msg.sender] += 1; // update pingCount for frontend
        LearnToken.mintToken(msg.sender, 1);
    }

    // CHAINLINK KEEPER
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
            // prevATokenBal updated to curATokenBal as no funds are added
            prevATokenBal = curATokenBal;
        }
    }

    // The difference between the current and previous token balance is accrued interest
    // Exclude in-active parties from interest repayment
    // Distribute the accrued interest between active parties
    function calcInterestPrevPeriod() internal {
        curATokenBal = aWNative.balanceOf(AaveInteraction);
        uint private interestPrevPeriod = curATokenBal - prevATokenBal; // always 0 or greater

        uint unclaimedInterest;
        uint unclaimedDepositTotal;

        // If inactive, accumulate funds to re-distribute
        for (uint i = 0; i < students.length; i++) {
            address student = students[i];
            uint deposit = initialDeposit[student];

            if (pingExpiresAt[student] < block.timestamp) {
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

    function addStudent(address stu) private {
        // for itterable mapping
        index[stu] = students.length;
        students.push(stu);

        // for interest calculations
        initialDeposit[stu] = msg.value;
        depositTotal += msg.value;

        // For payout
        recordedStartDay[stu] = todayUTC0 + interval;
    }

    function removeStudent(address stu) private {
        uint private delStudentIndex = index[stu];
        delete index[stu];
        delete initialDeposit[stu];
        delete interestEarned[stu];
        delete recordedStartDay[stu];
        delete pingExpiresAt[stu];
        delete pingCount[stu];

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

}
