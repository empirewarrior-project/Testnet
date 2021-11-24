// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

import "./ERC20.sol";
import "./SafeMath.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./Uniswap.sol";

contract EMP is Ownable, ERC20 {
    using SafeMath for uint256;
    uint256 public maxTotalSupply = 1000 * 10**6 * 10**18;
    uint256 public inGameReward = 170 * 10**6 * 10**18;
    uint256 pulibc maxRewardPerCall = 1 * 10**6 * 10**18;
    uint256 public rewardForBattle;

    address public marketingWallet;
	
    uint256 public feeLimitation = 15;  
    uint256 public sellFee = 2;
    uint256 public buyFee = 0;

    mapping (address => bool) private _isExcludedFromFee;
    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapV2Pair;

    constructor(
        string memory _name,
        string memory _symbol, 
        address _manager) 
    ERC20(_name, _symbol, _manager) {
        _mint(_msgSender(), maxTotalSupply.sub(inGameReward));
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x10ED43C718714eb63d5aA57B78B54704E256024E);
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());
        uniswapV2Router = _uniswapV2Router;
        _approve(address(this), address(uniswapV2Router), ~uint256(0));
        marketingWallet = owner();
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[marketingWallet] = true;
    }


    function _transfer(address sender, address recipient, uint256 amount ) internal virtual override {
        uint256 transferFeeRate = recipient == uniswapV2Pair ? sellFee : (sender == uniswapV2Pair ? buyFee : 0);
        if ( transferFeeRate > 0 &&
             !_isExcludedFromFee[sender] && 
             !_isExcludedFromFee[recipient] && 
             !manager.farmOwners(sender) && 
             !manager.farmOwners(sender)
        ) {
            uint256 _fee = amount.mul(transferFeeRate).div(100);
            super._transfer(sender, marketingWallet, _fee);
            amount = amount.sub(_fee);
        }

        super._transfer(sender, recipient, amount);
    }

    function inGame(address player, uint256 reward) external returns (bool){
        require(manager.farmOwners(_msgSender()), "Caller is not the farmer");
        require (reward <= maxRewardPerCall, "Over Amount")
        require(rewardForBattle != inGameReward, "Over Amount");
        require(player != address(0), "wrong address");
        require(reward > 0, "wrong reward");

        rewardForBattle = rewardForBattle.add(reward);
        require(rewardForBattle <= inGameReward, "Exceed Game Reward");
        _mint(player, reward);
        return true;
    }
    
    function isExcludedFromFee(address account) public view returns(bool) {
        return _isExcludedFromFee[account];
    }
    
    function excludeFromFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = true;
    }
    
    function includeInFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = false;
    }

    function setManagerAddress(address _m) external onlyOwner {
        manager = ManagerInterface(_m);
    }
    
    function setMarketingAdrress(address _marketing) external onlyOwner {
        marketingWallet = _marketing;
    }

    function setTransferFeeRate(uint256 _sellFee, uint256 _buyFee) public onlyOwner {
        require (feeLimitation >= _sellFee && feeLimitation >= _buyFee, ' Exceed Limitation Fee')
        sellFee = _sellFee;
        buyFee = _buyFee;
    }
}
