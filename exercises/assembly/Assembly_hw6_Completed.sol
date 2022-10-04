contract ReturnETH {

    function func() public payable returns (uint256) {
        // Return the amount of eth passed to thsi function
        assembly {
            // store wei sent in this call in a stack variable
            let amount := callvalue()
            // store this value in memory
            mstore(0x80, amount)
            // return the value 
            return(0x80, 32)
        }
    }
}

// Question2

push9 0x601e8060093d393df3 // Push 9 bytes onto the stack
msize // total bytes stored in memory + 32 (0x20). 0 for now
mstore // store the 9 bytes starting at mem slot 0x00
// slot 0 looks like 0000000000000000000000000000000000000000000000601e8060093d393df3
codesize // Size of current contract's code, 1e   
returndatasize // size of the last returned data, 0 for now       
msize // highest offset accessed, 0x20 or 32 bytes have been accessed
codecopy // read code from 0x00 till 0x20 bytes, copy to locaiton starting from 0x10 (right after our 9 bytes). This "expands" the memor in use
// When storing, the right bytes are used, so if a value is 9 bytes, the bytes on the left will remain, which will be 23 bytes
// Now, memory looks like 
//0000000000000000000000000000000000000000000000601e8060093d393df368601e8060093d393df35952383d59396009380160173d828234f050f0ff0000

                            
push1 9 // Push 1 byte 0x90 on stack               
codesize // size of the contract code, so all the opcodes, 1e or 30
add // add 9 + codesize = 0x27 (or 39 bytes), which is on the stack

push1 23 // push 1byte, 23 (0x17) onto the stack
returndatasize  // size of last returned data, 0
// slots look like: [0, 17, 27] 0 is on top
dup3 // duplicate 3rd slot item, 27, now [27, 0, 17, 27]

dup3 // dup 3rd slot item, 17, now [17, 27, 0, 17, 27]                     
callvalue // amount of wei sent in deployment tx (0), stack now [0, 17, 27, 0, 17, 27] 
create // creates a new contract, i.e., an account with associated code
// takes value (wei), offset(where init code starts from), size (of the init code)
// On the stack we have, 0x00, 0x17 (23), 0x27 (39)
// so, 0 wei, 0x23 as the offset, and 39 bytes as the init code size
// Then, it returns the contract address, in this case 0x43a61f3f4c73ea0d444c5c1c1a8544067a86219b
// stack now is [43a61f3f4c73ea0d444c5c1c1a8544067a86219b,0,17,27]
pop //Pops off the address off the stack [0,17,27]
create   // creates again, new addr is: 0x3fa89944e11022fc67d12a9d2bf35ebe1164f7ef                   
selfdestruct // stops execution and marks account (created in the previous step) for later deletion