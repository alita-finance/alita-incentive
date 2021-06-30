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

    uint public startBlock;

    uint public lastRewardBlock; // record last reward block
    
    event Claim(uint indexed lastBlock, uint indexed currentBlock, uint indexed amount, address add);
    event ChangeNumberTokenperBlock(uint indexed oldNumer, uint indexed newNumber);

    constructor(AliToken _ali, address add, uint256 _startBlock) public {
        ali = _ali;
        claimableAdress = add;
        lastRewardBlock = _startBlock;
        startBlock = _startBlock;
    }

    // Return current block reward.
    // function getALIBlockReward() public view returns (uint256) {
    //     uint256 interval = now.sub(ali.releaseDate());
    //     uint256 currentPeriod = interval.div(ali.period());
    //     return ali.getReleasedTokenperPeriod(currentPeriod).div(2);
    // }

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
        
        uint claimableAmount = getClaimableReward();
        
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


    /**
     * @notice Returns the result of (base ** exponent) with SafeMath
     * @param base The base number. Example: 2
     * @param exponent The exponent used to raise the base. Example: 3
     * @return A number representing the given base taken to the power of the given exponent. Example: 2 ** 3 = 8
     */
    function pow(uint base, uint exponent) internal pure returns (uint) {
        if (exponent == 0) {
            return 1;
        } else if (exponent == 1) {
            return base;
        } else if (base == 0 && exponent != 0) {
            return 0;
        } else {
            uint result = base;
            for (uint i = 1; i < exponent; i++) {
                result = result.mul(base);
            }
            return result;
        }
    }

    /**
     * @notice Caculate the reward per block at the period: (keepPercent / 100) ** period * initialRewardPerBlock
     * @param periodIndex The period index. The period index must be between [0, maxiumPeriodIndex]
     * @return A number representing the reward token per block at specific period. Result is scaled by 1e18.
     */
    function getRewardPerBlock(uint periodIndex) public view returns (uint) {
        require(periodIndex <= ali.getMaxiumPeriodIndex(), 'Incentive: period invalid');
        return pow(ali.getKeepPercent(), periodIndex).mul(ali.getInitialRewardPerBlock()).div(pow(100, periodIndex));
    }

    /**
     * @notice Calculate the block number corresponding to each milestone at the beginning of each period.
     * @param periodIndex The period index. The period index must be between [0, maxiumPeriodIndex]
     * @return A number representing the block number of the milestone at the beginning of the period.
     */
    function getBlockNumberOfMilestone(uint periodIndex) public view returns (uint) {
        require(periodIndex <= ali.getMaxiumPeriodIndex(), 'Incentive: period invalid');
        return ali.getBlockPerPeriod().mul(periodIndex).add(startBlock);
    }

    /**
     * @notice Determine the period corresponding to any block number.
     * @param blockNumber The block number. The block number must be >= startBlock
     * @return A number representing period index of the input block number.
     */
    function getPeriodIndexByBlockNumber(uint blockNumber) public view returns (uint) {
        require(blockNumber >= startBlock, 'Incentive: blockNumber invalid');
        return blockNumber.sub(startBlock).div(ali.getBlockPerPeriod());
    }

    /**
     * @notice Calculate the reward that can be claimed from the last received time to the present time.
     * @return A number representing the reclamable ALI tokens. Result is scaled by 1e18.
     */
    function getClaimableReward() public view returns (uint) {
        uint currentBlock = block.number;
        require(currentBlock >= startBlock, 'Incentive: currentBlock invalid');

        uint lastClaimPeriod = getPeriodIndexByBlockNumber(lastRewardBlock); 
        uint currentPeriod = getPeriodIndexByBlockNumber(currentBlock);
        
        uint startCalculationBlock = lastRewardBlock; 
        uint sum = 0; 
        
        for(uint i = lastClaimPeriod ; i  <= currentPeriod ; i++) { 
            uint nextBlock = i < currentPeriod ? getBlockNumberOfMilestone(i+1) : currentBlock;
            uint delta = nextBlock.sub(startCalculationBlock);
            sum = sum.add(delta.mul(getRewardPerBlock(i)));
            startCalculationBlock = nextBlock; 
        } 
        return sum;
}
}
