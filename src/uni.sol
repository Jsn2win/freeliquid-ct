pragma solidity ^0.5.0;

import "./base.sol";
import "./safeMath.sol";

interface UniswapV2PairLike {
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);

    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
}


contract UniswapAdapterForStables is IAdapter {
    using SafeMath for uint;

    struct TokenPair {
        address t0;
        address t1;
        uint r0;
        uint r1;
        uint usdPrec;
    }


    function calc(address gem, uint value, uint factor) external view returns (uint) {

        (uint112 _reserve0, uint112 _reserve1,) = UniswapV2PairLike(gem).getReserves();

        TokenPair memory tokenPair;
        tokenPair.usdPrec = 10**6;

        tokenPair.t0 = UniswapV2PairLike(gem).token0();
        tokenPair.t1 = UniswapV2PairLike(gem).token1();


        tokenPair.r0 = uint(_reserve0).mul(tokenPair.usdPrec).div(uint(10) ** IERC20(tokenPair.t0).decimals());
        tokenPair.r1 = uint(_reserve1).mul(tokenPair.usdPrec).div(uint(10) ** IERC20(tokenPair.t1).decimals());


        uint totalValue = tokenPair.r0.min(tokenPair.r1).mul(2); //total value in uni's reserves for stables only

        uint supply = UniswapV2PairLike(gem).totalSupply();

        return value.mul(totalValue).mul(factor).mul(1e18).div(supply.mul(tokenPair.usdPrec));
    }
}


contract UniswapAdapterWithOneStable is IAdapter {
    using SafeMath for uint;

    struct LocalVars {
        address t0;
        address t1;
        uint totalValue;
        uint supply;
        uint usdPrec;
    }

    address public deployer;
    address public buck;


    constructor () public {
        deployer = msg.sender;
    }

    function setup(address _buck) public {
        require(deployer == msg.sender);
        buck = _buck;
        deployer = address(0);
    }


    function calc(address gem, uint value, uint factor) external view returns (uint) {
        (uint112 _reserve0, uint112 _reserve1,) = UniswapV2PairLike(gem).getReserves();

        LocalVars memory loc;
        loc.t0 = UniswapV2PairLike(gem).token0();
        loc.t1 = UniswapV2PairLike(gem).token1();
        loc.usdPrec = 10**6;

        if (buck == loc.t0) {
            loc.totalValue = uint(_reserve0).mul(loc.usdPrec).div(uint(10) ** IERC20(loc.t0).decimals());
        } else if (buck == loc.t1) {
            loc.totalValue = uint(_reserve1).mul(loc.usdPrec).div(uint(10) ** IERC20(loc.t1).decimals());
        } else {
            require(false, "gem w/o buck");
        }

        loc.supply = UniswapV2PairLike(gem).totalSupply();

        return value.mul(loc.totalValue).mul(2).mul(factor).mul(1e18).div(loc.supply.mul(loc.usdPrec));
    }
}


contract UniForRewardCheckerBase {

    mapping(address => bool) public tokens;

    function check(address gem) external {
        address t0 = UniswapV2PairLike(gem).token0();
        address t1 = UniswapV2PairLike(gem).token1();

        require(tokens[t0] && tokens[t1], "non-approved-stable");
    }
}


contract UniForRewardCheckerMainnet is UniForRewardCheckerBase {

    constructor (address usdfl, address gov) public {
        tokens[usdfl]=true;
        tokens[gov]=true;
        tokens[0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48]=true; //usdc
        tokens[0xdAC17F958D2ee523a2206206994597C13D831ec7]=true; //usdt
        tokens[0x6B175474E89094C44Da98b954EedeAC495271d0F]=true; //dai
        tokens[0x674C6Ad92Fd080e4004b2312b45f796a192D27a0]=true; //usdn
    }
}


contract UniForRewardCheckerKovan is UniForRewardCheckerBase {

    constructor (address usdfl, address gov) public {
        tokens[usdfl]=true;
        tokens[gov]=true;
        tokens[0xe22da380ee6B445bb8273C81944ADEB6E8450422]=true; //usdc
        tokens[0x13512979ADE267AB5100878E2e0f485B568328a4]=true; //usdt
        tokens[0xFf795577d9AC8bD7D90Ee22b6C1703490b6512FD]=true; //dai
        tokens[0x5f99471D242d04C42a990A33e8233f5B48F89C43]=true; //usdn
    }
}

