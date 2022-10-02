pragma solidity ^0.8.4;

contract Scope {
    uint256 public count = 10;

    function increment(uint256 num) public {
        // Modify state of the count variable from within
        // the assembly segment
        assembly {
            // load count from storage to slot, while adding num to its value
            let newCount := add(num, sload(count.slot))
            // store newCount at storage slot of count (0 in this case)
            sstore(count.slot, newCount)
        }
    }
}
