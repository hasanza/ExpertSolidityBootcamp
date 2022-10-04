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
