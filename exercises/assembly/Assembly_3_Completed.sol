pragma solidity ^0.8.4;

contract SubOverflow {
    // Modify this function so that on overflow it returns the value 0
    // otherwise it should return x - y
    function subtract(uint256 x, uint256 y) public pure returns (uint256) {
        // Write assembly code that handles overflows
        assembly {
            // If y is greater than x, return 0
            if gt(y, x) { return(0,0) }
            // otherwise return x - y
            let res := sub(x, y)
            // load into memory
            mstore(0x80, res)
            // return
            return(0x80, 32)
        }
    }
}
