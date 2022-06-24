// SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.10;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@chainlink/contracts/src/v0.8/KeeperCompatible.sol";

// MUST RESTRICT ACCESS
// MUST INCREASE SECURITY
// MUST BECOME GAS EFFICIENT

// TEDDY create an Ikeeper and get it to work with a 24hr update, where it changes the state or the existing contract

interface IAaveInteraction {
    function deposit() external payable;

    function withdraw(address _recipient, uint256 _withdrawAmount) external;
}

contract InterestDistribution2 is KeeperCompatibleInterface {
    // Testing
    // uint public interestPrevPeriod;
    // uint public totalAwarded;

    // Could neaten these up by using a struct, nested mapping ,iterable mapping??? 4444444444444444444444
    address[] public students;
    mapping(address => uint256) initialDeposit;
    mapping(address => uint256) interestEarned;
    uint depositTotal;
    mapping(address => uint256) recordedStartDay; // for payout
    mapping(address => uint256) pingExpiresAt; // 2^32 -1 equals to 4294967295 = 07/02/2106

    uint256 todayUTC0;
    uint256 studyDays; // for payout require statement
    IERC20 aPolWMatic = IERC20(0x89a6AE840b3F8f489418933A220315eeA36d11fF);

    // Interface requires the correct deployed address for AaveInteraction contract (maybe pass through constructor??) 4444444444444444
    address AaveInteraction = 0xd4208B4cC619e7Ec67f0D35dF1853118738F5D3A;
    IAaveInteraction aave = IAaveInteraction(AaveInteraction);

    constructor(uint256 _todayUTC0, uint256 _studyDays) payable {
        todayUTC0 = _todayUTC0;
        studyDays = _studyDays;
        // for contract to have some gas(maybe not needed)
        // deposit{value: msg.value}();
        // Currently payable. Not necessary if all gas is passed to user
    }

    // Check the AdminContract/User balance
    function getBalance(address tokenHolder) external view returns (uint256) {
        return aPolWMatic.balanceOf(tokenHolder);
    }

    uint prevATokenBal;
    uint curATokenBal;

    function register() external payable {
        // Issue interest from previous remuneration period
        calcInterestPrevPeriod();

        // Add new student
        students.push(msg.sender);
        initialDeposit[msg.sender] = msg.value;
        depositTotal += msg.value;

        // For payout
        recordedStartDay[msg.sender] = todayUTC0 + 1 days;

        // ping active for rest of day + 1 days
        ping();

        //Deposit user funds into Aave
        aave.deposit{value: msg.value}();

        // Update prevATokenBal for when register() calls calcInterestPrevPeriod() next time
        prevATokenBal = aPolWMatic.balanceOf(AaveInteraction);
    }

    // The difference between the current and previous token balance is accrued interest
    // Exclude in-active parties from interest repayment
    // Distribute the accrued interest between active parties
    function calcInterestPrevPeriod() internal {
        curATokenBal = aPolWMatic.balanceOf(AaveInteraction);
        uint interestPrevPeriod = curATokenBal - prevATokenBal;

        uint unclaimedInterest;
        uint unclaimedDepositTotal;

        // If inactive, accumulate funds to re-distribute
        for (uint i = 0; i < students.length; i++) {
            address student = students[i];
            uint deposit = initialDeposit[student];

            uint studentShare = deposit / depositTotal;

            if (pingExpiresAt[student] < block.timestamp) {
                unclaimedInterest += interestPrevPeriod * studentShare;
                unclaimedDepositTotal += deposit;
            }
        }

        // If active, student gets default and unclaimed share
        for (uint i = 0; i < students.length; i++) {
            address student = students[i];
            uint deposit = initialDeposit[student];

            uint studentShare = deposit / depositTotal;
            uint studentShareUnclaimed = deposit /
                (depositTotal - unclaimedDepositTotal);

            if (pingExpiresAt[student] >= block.timestamp) {
                // default share
                interestEarned[student] += interestPrevPeriod * studentShare;
                // share of unclaimed
                interestEarned[student] +=
                    unclaimedInterest *
                    studentShareUnclaimed;

                // Testing
                // totalAwarded += interestPrevPeriod * studentShare;
            }
        }
    }

    // tUTC0 updates each 24hr period
    // ping  emits an expiration timestamp which lasts until the end of the next day (This allows spam/multiple pinging)
    // |------|----p--|------|
    //     tUTC0      +1     +2
    function ping() public {
        pingExpiresAt[msg.sender] = todayUTC0 + 2 days;
    }

    // KEEPER check for 24hr
    uint256 interval = 1 days; // maybe uint32

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
            prevATokenBal = curATokenBal;
        }
    }

    function payout() external {
        // add security checks 4444444444444444444
        // recordedStartDay UTC0 + number of study days
        require(
            block.timestamp >= (recordedStartDay[msg.sender] + 5 days),
            "You can only receive a payout once the study session is over"
        );
        calcInterestPrevPeriod();

        uint256 withdrawAmount = interestEarned[msg.sender] +
            initialDeposit[msg.sender];
        depositTotal -= initialDeposit[msg.sender];
        interestEarned[msg.sender] = 0;
        initialDeposit[msg.sender] = 0;
        // REMOVE student from array/struct 444444444444444444444

        // Is there a safer way to do this?? withdraw doesn't seem to return an uint/ or any value...
        // this withdraws funds to AaveInteraction
        aave.withdraw(msg.sender, withdrawAmount);

        // Update prevATokenBal for when register() calls calcInterestPrevPeriod() next time
        prevATokenBal = aPolWMatic.balanceOf(AaveInteraction);
    }
}
// on deployment of contract send some funds into aave (surplus funds will be added to this??)
// user registers, their funds go into aave
// store their initial deposit in a mapping
// have an array of Struct which contains student address, this will allow awards to be given to users (maybe just array)
// keeper will update user interest earnings based on their proportional deposited funds
// keeper will check the ping status of each user in the array
// if the ping status is true award funds
// ping at any stage in a 24hr period to earn interest for the next 24hr period (use the Official start plus x days)

// aave protocal aToken balance can only increase, so each keeper update will distribute funds (but is this accurate?? I can test this once set up. if not accurate withdraw then redeposit)
// users can withdraw funds at any time, any forefitted earning go to procol
// the next 24hr period they click ping and they become elidgable for reward
