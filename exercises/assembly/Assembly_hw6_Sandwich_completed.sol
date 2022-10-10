// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

library SafeTransfer {
    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        (bool s, ) = address(token).call(
            abi.encodeWithSelector(
                IERC20.transferFrom.selector,
                from,
                to,
                value
            )
        );
        require(s, "safeTransferFrom failed");
    }

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        (bool s, ) = address(token).call(
            abi.encodeWithSelector(IERC20.transfer.selector, to, value)
        );
        require(s, "safeTransfer failed");
    }

    function safeApprove(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        (bool s, ) = address(token).call(
            abi.encodeWithSelector(IERC20.approve.selector, to, value)
        );
        require(s, "safeApprove failed");
    }

    function safeTransferETH(address to, uint256 value) internal {
        (bool s, ) = to.call{value: value}(new bytes(0));
        require(s, "safeTransferETH failed");
    }
}


contract Sandwich {
    // safeTransfer uses the returned bool value from ERC20 contracts (some dont return it)
    using SafeTransfer for IERC20;

    // Authorized; Once set in constructor, can't be changed/
    address internal immutable user;

    // transfer(address,uint256)
    bytes4 internal constant ERC20_TRANSFER_ID = 0xa9059cbb;

    // swap(uint256,uint256,address,bytes)
    bytes4 internal constant PAIR_SWAP_ID = 0x022c0d9f;

    // Contructor sets the only user
    receive() external payable {}

    constructor(address _owner) {
        user = _owner;
    }

    // *** Receive profits from contract *** //
    // Send all of the given token to the caller, who gotta be the owner
    function recoverERC20(address token) public {
        require(msg.sender == user, "shoo");
        IERC20(token).safeTransfer(
            msg.sender,
            IERC20(token).balanceOf(address(this))
        );
    }

    /*
        Fallback function where you do your frontslice and backslice
        NO UNCLE BLOCK PROTECTION IN PLACE, USE AT YOUR OWN RISK
        Payload structure (abi encodePacked)
        - token: address        - Address of the token you're swapping
        - pair: address         - Univ2 pair you're sandwiching on
        - amountIn: uint128     - Amount you're giving via swap
        - amountOut: uint128    - Amount you're receiving via swap
        - tokenOutNo: uint8     - Is the token you're giving token0 or token1? (On univ2 pair)
        Note: This fallback function generates some dangling bits
    */
    // Triggered when function call doesn't match an existing function
    fallback() external payable {
        // Assembly cannot read immutable variables
        address memUser = user;

        assembly {
            // You can only access teh fallback function if you're authorized
            // if msg.sender is owner, and if its 0, revert
            if iszero(eq(caller(), memUser)) {
                // Ohm (3, 3) makes your code more efficient
                // WGMI
                // revert param1: byte offset in memory of the return data
                // param2: size of the return data.
                revert(3, 3)
            }

            // Extract out teh variables
            // We don't have function signatures sweet saving EVEN MORE GAS

            // bytes20
            // calldataload() loads 32bytes of calldata onto the stack ...
            // ... starting from given offset (0x00 here)
            // remaining bytes are set to 0
            // logical shift the calldata loaded to right by 96 bits (32bytes)
            // in other words, calldata / 2**96.

            // here, we are teasing out relevant data from the calldata.
            // stack now has 32 bytes. Then, we shift right 96bits/places/12bytes >>
            // So, 12 bytes go out of slot and are discarded. 20 bytes/ 160 bits remain.
            // That value is then stored in the slot variable token
            let token := shr(96, calldataload(0x00))
            // bytes20
            // load calldata starting from offset 0x14, push 12 bytes to the right,
            // 20 bytes remain, which is the token pair contract
            let pair := shr(96, calldataload(0x14))
            // uint128
            // load 32 bytes of calldata starting form offset 0x20, Push 16 bytes right,
            // 16 bytes/ 128 bits remain, this is the amount in
            let amountIn := shr(128, calldataload(0x28))
            // load calldata starting from 0x38, push 16bytes to the right, remaining is amount out
            let amountOut := shr(128, calldataload(0x38))
            // load calldata from offset 0x48, push 31 bytes to the right, 
            // remaining is 1 byte, this is the token we are giving, 0 or 11
            let tokenOutNo := shr(248, calldataload(0x48))

            // **** calls token.transfer(pair, amountIn) ****

            // store transfer function signature at memlocation 0x7c
            // Isnt this the 0 slot? 0x60 to 0x7f?
            // 0x7c, 0x7d, 0x7e, 0x7f, then comes 0x80
            // So, 4, 1-byte slots, 4 bytes.
            mstore(0x7c, ERC20_TRANSFER_ID)
            // destination
            // Starting at 0x80, store 20byte pair address
            mstore(0x80, pair)
            // starting at 0xa0, store the 16byte amountIn value
            mstore(0xa0, amountIn)
            // make a low level call to transfer amountIn to the pair contract

            // param1: gas sent in the subcontext call, minus 5000 gas
            // param2: token address
            // param3: value in wei to send in the call to the account
            // param4: byte offset in memory for the args i.e., calldata in this subcontext
            // param5: args size to copy starting from the offset
            // starting from 0x7c, copy 68 bytes: 
            // selector 4 bytes, 20 byte pair address, 32 byte amointIn = 
            // param6: memory byte offset, where to copy return data to, 0x0
            // param7: size of the return data, 0, no return data.
            let s1 := call(sub(gas(), 5000), token, 0, 0x7c, 0x44, 0, 0)
            // if call fails, revert
            if iszero(s1) {
                // WGMI
                revert(3, 3)
            }

            // ************
            /* 
                calls pair.swap(
                    tokenOutNo == 0 ? amountOut : 0,
                    tokenOutNo == 1 ? amountOut : 0,
                    address(this),
                    new bytes(0)
                )
            */

            // swap function signature
            // store 4 byte function signature from 0x7c to 0x7f
            mstore(0x7c, PAIR_SWAP_ID)
            // tokenOutNo == 0 ? ....
            // Switch for token swap order
            switch tokenOutNo
            // If tokenOutNo is 0
            case 0 {
                // store amountOut first in memory
                // 0x80 to 0x8f -> 16 bytes occpied by amountOut
                mstore(0x80, amountOut)
                // then store 0
                mstore(0xa0, 0)
                 // so, in memory AMOUNTOUT0
            }
            case 1 {
                // Otherwise, first store 0, then store amountOUt
                mstore(0x80, 0)
                mstore(0xa0, amountOut)
                // 0AMOUNTOUT
            }
            // address(this)
            // Store this contract's address at 0xc0 (20bytes
            mstore(0xc0, address())
            // empty bytes
            // store 0x80 at 0xe0 memory location
            mstore(0xe0, 0x80)
            // make swap call 2
            let s2 := call(sub(gas(), 5000), pair, 0, 0x7c, 0xa4, 0, 0)
            if iszero(s2) {
                revert(3, 3)
            }
        }
    }
}

/*
1. Searhers are people who search for MEV opps and the exploit them using flashbot miners (bypassing mempool). E.g., I spot a MEV opp on etherscan, I construct the MEV extraction sandwich and submit the bundle to a flashbot miner (miners running MEV-geth clients). For me, as a searcher, to succeed in this MEV opp, my sandwich has to be included in a block, whole - as a bundle. Miner accepts my bundle, mines it in the next block, keeps a % of the MEV profits. HOWEVER, sometimes, it may happen that the miner, instead of mining a main block, mines an uncle block. 

-UNCLE BLOCKS: Uncle blocks are created when two blocks are mined and broadcasted at the same time (with the same block number). Since only one of the blocks can enter the primary Ethereum chain, the block that gets validated across more nodes becomes the canonical block, and the other one becomes what is known as an uncle block. Uncle blocks are recorded and accessible from the chain, but they have no impact on the canonical chain and their transactions do not change any state. Unlike Bitcoin, in the Ethereum system, miners still receive a block reward for discovering the uncle block.

In this case, there may come an "Uncle Bandit" and steal my MEV as a searcher! E.g., My sandwich gets included in an uncle block, bandit sees the uncle block, picks profitable tx from amongst my sandwich, bundles his own, then sends it again to a flashbot miner. 

Now, what is the assembly code doing?

The assembly code is making a transafer and a swap call.

First, it checks if the caller is the owner, if its not, it reverts.

Second, it extracts the token address, pair contract address, amountIn, amountOut, and token flag (0 for token0, 1 for token1) from the calldata.

Third, it stores the 4byte function selector in memory (slots 0x7c to 0x7f), stores the 20 byte pair contract address (slots 0x80 to 0x89), stores the 16 byte amountIn value (slots 0xa0 tp 0xaf). 4+20+16 = 40 bytes total.

Fourth, it makes a call to token contract, transfering amountIn of a tokenm from the token contract to pair contract. If this call fails, it reverts.

Now, the pair contract has amountIn of the token.

Fifth, it stores the 4-byte pair.swap function selector in memory (slots 0x7c to 0x7f), then if the token being swapped is token0, it stores the 16-byte amountOut first (slots 0x80 to 0x8f) and then stores 0 (at slot 0xa0). Otherwise, if its token1, it first stores 0 (at slot 0x80 - 15 bytes wasted? ), and then stores the 16byte amountOut (slots 0xa0 to 0xaf). 

Then, it stores 20-byte self address at 0xc0 (slots 0xc0 to 0xd3). Then, stores 0x80 at location 0xe0. (d4 to df - 12 bytes wasted?)

Finally, it calls the pair.swap function, with the above arguments (0xa4 or 164 bytes from 0x7c)

If this call fails, the tx reverts.

So, essentially, this contract is a highly optimized contract and it does 2 things: transfer funds from token contract to the pair contract, and swap given amount of a token for another. These two operations are central in sandwiching. This contract is thus used in conjunction with the sandwich bot. 
*/