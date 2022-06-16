// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Learn is ERC20, ERC20Burnable, Ownable {
    uint constant _initial_supply = 1000000000000000000;
    constructor() ERC20("LEARN", "LRN") {
        _mint(msg.sender, _initial_supply);
    }
    function mint(address to , uint256 amount) public onlyOwner {
        _mint(to, amount);
    }
}