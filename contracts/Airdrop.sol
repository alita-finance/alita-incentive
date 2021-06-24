// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import '@pancakeswap/pancake-swap-lib/contracts/math/SafeMath.sol';
import '@pancakeswap/pancake-swap-lib/contracts/token/BEP20/IBEP20.sol';
// import '@pancakeswap/pancake-swap-lib/contracts/token/BEP20/SafeBEP20.sol';
// import '@pancakeswap/pancake-swap-lib/contracts/access/Ownable.sol';
import './Ownable.sol';

contract Airdrop is Owner {

    using SafeMath for uint256;
    // using SafeBEP20 for IBEP20;

    address public claimableAdress; // the only address can claim airdrop token and then distribute to other users

    address public XXX;

    // uint public startBlock;
    uint public numberTokenperBlock;
    uint public lastRewardBlock;
    
    event Claim(uint indexed lastBlock, uint indexed currentBlock, uint indexed amount, address add);
    event ChangeNumberTokenperBlock(uint indexed oldNumer, uint indexed newNumber);

    constructor(address _xxx, address add, uint _startBlock, uint _numberTokenperBlock ) public {
        XXX = _xxx;
        claimableAdress = add;
        // startBlock = _startBlock;
        numberTokenperBlock = _numberTokenperBlock;
        lastRewardBlock = _startBlock;
    }

    function changeNumberTokenperBlock(uint val) external isOwner{
        require(val > 0, "invalid number");
        emit ChangeNumberTokenperBlock(numberTokenperBlock, val);
        numberTokenperBlock = val;
    }

    function claim() external{
        require(msg.sender == claimableAdress, "not allow to claim");
        
        if(IBEP20(XXX).balanceOf(address(this)) == 0){
            return;
        }
        
        uint interval = block.number.sub(lastRewardBlock);
        uint claimableAmount = interval.mul(numberTokenperBlock);
        
        safeCakeTransfer(msg.sender, claimableAmount);
        emit Claim(lastRewardBlock, block.number, claimableAmount, msg.sender);
        lastRewardBlock = block.number;
    }

    // Safe token transfer function, just in case if not have enough token.
    function safeCakeTransfer(address _to, uint256 _amount) internal {
        uint256 bal = IBEP20(XXX).balanceOf(address(this));
        if (_amount > bal) {
            IBEP20(XXX).transfer(_to, bal);
        } else {
            IBEP20(XXX).transfer(_to, _amount);
        }
    }
 
}
