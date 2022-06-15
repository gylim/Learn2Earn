//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "hardhat/console.sol";

contract LearnToEarn {
    address public provost;
    uint256 public sessions;
    bool public open;
    struct Student {
        address wallet;
        uint256 lastping;
        uint256 tuitionFee;
        uint256 pingcount;
        bool completed;
    }
    Student[] public cohort;

    event Completed(address indexed student);

    constructor(uint256 _sessions) {
        sessions = _sessions;
        open = true;
        provost = msg.sender;
    }

    function isStudent(address _target) public view returns(bool, uint) {
        for (uint i=0; i<cohort.length; i++) {
            if (cohort[i].wallet == _target) return (true, i);
        }
        return (false, 0);
    }
    function register() external payable {
        require(open == true, "The cohort is now closed, try again next time!");
        (bool tf, ) = isStudent(msg.sender);
        require(tf == false, "You are already registered");
        require(msg.value > 0, "Please pay some tuition fee");
        cohort.push(Student(msg.sender, block.timestamp, msg.value, 0, false));
    }
    function ping() external {
        (bool tf, uint idx) = isStudent(msg.sender);
        require(tf == true, "You are not a student");
        require(cohort[idx].completed == false, "You have already completed the course");
        cohort[idx].lastping = block.timestamp;
        cohort[idx].pingcount++;
        if (cohort[idx].pingcount == sessions) {
            cohort[idx].completed =true;
            emit Completed(msg.sender);
        }
    }
    function allComplete() public returns(bool, uint) {
        uint complete = 0;
        uint totalShares = 0;
        for (uint j=0; j<cohort.length; j++) {
            totalShares += cohort[j].pingcount;
            if ((block.timestamp - cohort[j].lastping) > 3 days) {
                cohort[j].completed = true;
            }
            if (cohort[j].completed == true) complete++;
        }
        return complete == cohort.length ? (true, totalShares) : (false, 0);
    }
    function closeRegistration() external {
        require(msg.sender == provost, "You are not the provost");
        require(open == true, "Registration for this cohort is already closed");
        open = false;
    }
    function totalDeposit() public view returns(uint) {
        uint total = 0;
        for (uint l=0; l<cohort.length; l++) {
            total += cohort[l].tuitionFee;
        }
        return total;
    }
    function payAll(uint _totalInterest) external {
        (bool tf, ) = allComplete();
        uint totalDep = totalDeposit();
        require(tf == true, "Not all students have completed");
        require(open == false, "Cohort still open for registration");
        for (uint k=0; k<cohort.length; k++) {
            uint payout = cohort[k].tuitionFee + _totalInterest * (cohort[k].tuitionFee / totalDep) * (cohort[k].pingcount / sessions);
            (bool success, ) = payable(cohort[k].wallet).call{value: payout}("");
            require(success, "Failed to send");
        }
    }
}
