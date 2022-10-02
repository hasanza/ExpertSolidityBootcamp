pragma solidity ^0.8.4;

contract Intro {
    function intro() public pure returns (uint16) {
        uint256 mol = 420;
        // Yul assembly magic happens within assembly{} section
        assembly {
            // instantiate a stack variable that holds the value of mol
            let mol_val := mol 
            // store to memory with command mstore(MEMORY_LOCATION, STACK_VARIABLE)
            mstore(0x80, mol_val)
            //return(offset, size)
            // return the value starting from mem slot 0x80, running 32 bytes (the whole slot)
            return(0x80, 32)
        }
    }
}
