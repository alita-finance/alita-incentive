// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import '@pancakeswap/pancake-swap-lib/contracts/math/SafeMath.sol';
import '@pancakeswap/pancake-swap-lib/contracts/token/BEP20/IBEP20.sol';
// import '@pancakeswap/pancake-swap-lib/contracts/token/BEP20/SafeBEP20.sol';
// import '@pancakeswap/pancake-swap-lib/contracts/access/Ownable.sol';
import './Ownable.sol';
import './ALIToken.sol';

contract Incentive is Owner {

    using SafeMath for uint256;
    // using SafeBEP20 for IBEP20;

    address public claimableAdress; // the only address can claim airdrop token and then distribute to other users

    AliToken public ali; // claimed token address

    // uint public startBlock;
    // uint public numberTokenperBlock; // number of reward tokens are issued per 1 block 
    uint public lastRewardBlock; // record last reward block
    
    event Claim(uint indexed lastBlock, uint indexed currentBlock, uint indexed amount, address add);
    event ChangeNumberTokenperBlock(uint indexed oldNumer, uint indexed newNumber);

    constructor(AliToken _ali, address add, uint _startBlock) public {
        ali = _ali;
        claimableAdress = add;
        // startBlock = _startBlock;
        // numberTokenperBlock = _numberTokenperBlock;
        lastRewardBlock = _startBlock;
    }

    // Return current block reward.
    function getALIBlockReward() public view returns (uint256) {
        uint256 interval = now.sub(ali.releaseDate());
        uint256 currentPeriod = interval.div(ali.period());
        return ali.getReleasedTokenperPeriod(currentPeriod).div(2);
    }

    // function changeNumberTokenperBlock(uint val) external isOwner{
    //     require(val > 0, "invalid number");
    //     emit ChangeNumberTokenperBlock(numberTokenperBlock, val);
    //     numberTokenperBlock = val;
    // }

    function claim() external{
        require(msg.sender == claimableAdress, "not allow to claim");
        
        if(IBEP20(ali).balanceOf(address(this)) == 0){
            return;
        }
        
        uint interval = block.number.sub(lastRewardBlock);
        uint claimableAmount = interval.mul(getALIBlockReward());
        
        ali.mint(msg.sender, claimableAmount);
        emit Claim(lastRewardBlock, block.number, claimableAmount, msg.sender);
        lastRewardBlock = block.number;
    }

    // Safe token transfer function, just in case if not have enough token.
    // function safeCakeTransfer(address _to, uint256 _amount) internal {
    //     uint256 bal = IBEP20(ali).balanceOf(address(this));
    //     if (_amount > bal) {
    //         IBEP20(ali).transfer(_to, bal);
    //     } else {
    //         IBEP20(ali).transfer(_to, _amount);
    //     }
    // }
 
}
