// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract DogCoinGame is ERC20 {
    uint256 public currentPrize;
    uint256 public numberPlayers;
    address payable[] public players;
    address payable[] public winners;
    // Event not containing any indexed params
    event startPayout();

    constructor() ERC20("DogCoin", "DOG") {}

    function addPlayer(address payable _player) public payable {
        // 1. msg.value == 1 checks msg.value to be equal to 1 wei, not ETH. This breaks logic. (XXX)
        if (msg.value == 1) {
            // 1.1 no check for zero address
            players.push(_player);
        }
        numberPlayers++;
        // 2. event will be emitted at 201 players, which is 1 more than 200. This breaks logic. Should be >=200 (XXX)
        if (numberPlayers > 200) {
            emit startPayout();
        }
    }

    // 3. Needs to be called for each winner individually. NWS any other problems, 100 calls! (XX)
    function addWinner(address payable _winner) public {
        // 4. No check on winner length, can exceed 100! (XXX)
        // 4.1 No check for zero address
        winners.push(_winner);
    }

    // 5. Anyone can call payout! (XXX)
    function payout() public {
        // 6. Check is for 100 wei, not 100 ETH. (XXX)
        if (address(this).balance == 100) {
            // 7. amountToPay is assumed to be 1ETH, but NWS other problems, its 1 WEI. However, can be any number since no check. (XXX)
            uint256 amountToPay = winners.length / 100;
            payWinners(amountToPay);
        }
    }

    // 8. Anyone can call payWinners! (XXX)
    function payWinners(uint256 _amount) public {
        // 9. NWS other problems, this loop runs for 201 iterations, solidity will revert
        for (uint256 i = 0; i <= winners.length; i++) {
            //10. Send doesnt forward gas, but fixes gas stiped of 2300. On running out of gas, it just returns 0 (which isn't handled here).
            winners[i].send(_amount);
        }
    }
}