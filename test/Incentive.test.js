const { time } = require('@openzeppelin/test-helpers');
const { assert } = require('chai');
const Incentive = artifacts.require('Incentive');
const MockTestAliToken = artifacts.require('libs/MockTestAliToken');

contract('Incentive', ([minter]) => {
    const startBlock = 0;
    const blockPerPeriod = 20;
    const maximumPeriodIndex = 2;
    const maxBlock = startBlock + blockPerPeriod * (maximumPeriodIndex + 1);

    beforeEach(async () => {
        this.ali = await MockTestAliToken.new(startBlock, minter, '1000000', 50, 50, { from: minter });
        this.incentive = await Incentive.new(this.ali.address, minter, startBlock, { from: minter });
    });

    it('getRewardPerBlock: the rewardPerBlock of first period must equal initialRewardPerBlock', async () => {
        const initialRewardPerBlock = await this.ali.getInitialRewardPerBlock();
        const rewardPerBlock0 = await this.incentive.getRewardPerBlock(0);
        assert.equal(rewardPerBlock0.toString(), initialRewardPerBlock.toString());
    })

    it('getRewardPerBlock: the rewardPerBlock of second period must equal (keepPercent)% of first period', async () => {
        const initialRewardPerBlock = await this.ali.getInitialRewardPerBlock();
        const keepPercent = await this.ali.getKeepPercent();
        const rewardPerBlock1 = await this.incentive.getRewardPerBlock(1);
        assert.equal(rewardPerBlock1.toString(), (initialRewardPerBlock * keepPercent / 100).toString());
    })

    it('getClaimableReward: can receive rewards if not yet received even though the maximum period has passed ', async () => {
        const rewardPerBlock0 = await this.incentive.getRewardPerBlock(0);
        const rewardPerBlock1 = await this.incentive.getRewardPerBlock(1);
        const rewardPerBlock2 = await this.incentive.getRewardPerBlock(2);
        let currentBlock = await time.latestBlock();

        if (currentBlock < maxBlock + 10) {
            await time.advanceBlockTo(maxBlock + 10);
        }
        currentBlock = await time.latestBlock();
        
        assert.isAbove(currentBlock.toNumber() , maxBlock , 'Make sure that current block is out of the last period');
        console.log('[INFO] currentBlock', currentBlock.toNumber());
        console.log('[INFO] maxBlock', maxBlock);
        

        const incentiveWeight = await this.ali.getIncentiveWeight();
        const reward = await this.incentive.getClaimableReward();
        
        const expectedReward = ( (rewardPerBlock0 * blockPerPeriod + rewardPerBlock1 * blockPerPeriod + rewardPerBlock2 * blockPerPeriod)  * incentiveWeight / 100);
        assert.equal(reward.toString(), expectedReward.toString());
    })

});
