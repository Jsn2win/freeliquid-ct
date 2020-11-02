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
    }


    function calc(address gem, uint value, uint factor) external view returns (uint) {

        (uint112 _reserve0, uint112 _reserve1,) = UniswapV2PairLike(gem).getReserves();

        TokenPair memory tokenPair;
        tokenPair.t0 = UniswapV2PairLike(gem).token0();
        tokenPair.t1 = UniswapV2PairLike(gem).token1();

        tokenPair.r0 = uint(_reserve0).div(uint(10) ** IERC20(tokenPair.t0).decimals());
        tokenPair.r1 = uint(_reserve1).div(uint(10) ** IERC20(tokenPair.t1).decimals());

        uint totalValue = tokenPair.r0.min(tokenPair.r1).mul(2); //total value in uni's reserves for stables only

        uint supply = UniswapV2PairLike(gem).totalSupply();

        return value.mul(totalValue).mul(factor).mul(1e18).div(supply);
    }
}


contract UniswapAdapterWithOneStable is IAdapter {
    using SafeMath for uint;

    struct LocalVars {
        address t0;
        address t1;
        uint totalValue;
        uint supply;
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

        if (buck == loc.t0) {
            loc.totalValue = uint(_reserve0).div(uint(10) ** IERC20(loc.t0).decimals());
        } else if (buck == loc.t1) {
            loc.totalValue = uint(_reserve1).div(uint(10) ** IERC20(loc.t1).decimals());
        } else {
            require(false, "gem w/o buck");
        }

        loc.supply = UniswapV2PairLike(gem).totalSupply();

        return value.mul(loc.totalValue).mul(2).mul(factor).mul(1e18).div(loc.supply);
    }
}
