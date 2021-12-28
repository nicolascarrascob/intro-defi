//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Exchange is ERC20 {
    address public tokenAddress;

    constructor(address _token) ERC20("LP Token", "LP") {
        require(_token != address(0), "Invalid Token");
        tokenAddress = _token;
    }

    function addLiquidity(uint256 _tokenAmount)
        public
        payable
        returns (uint256)
    {
        uint256 mintedTokens;

        if (totalSupply() == 0) {
            mintedTokens = address(this).balance;
        } else {
            uint256 ethReserve = address(this).balance - msg.value;
            uint256 tokenReserve = getReserve();
            uint256 correctTokenAmount = (msg.value * tokenReserve) /
                ethReserve;
            require(_tokenAmount >= correctTokenAmount, "invalid ratio");
            mintedTokens = (totalSupply() * msg.value) / ethReserve;
        }

        IERC20 token = IERC20(tokenAddress);
        token.transferFrom(msg.sender, address(this), _tokenAmount);

        _mint(msg.sender, mintedTokens);
        return mintedTokens;
    }

    function getReserve() public view returns (uint256) {
        return IERC20(tokenAddress).balanceOf(address(this));
    }

    function getAmount(
        uint256 inputAmount,
        uint256 inputReserve,
        uint256 outputReserve
    ) private pure returns (uint256) {
        require(inputReserve > 0 && outputReserve > 0, "invalid reserves");
        // X * Y = K
        // X = inputReserve
        // Y = outputReserve
        // (x + dx) * (y - dy) = K
        // dy = y - dx ..........
        //uint256 outputAmount = (inputAmount * outputReserve) /
        //    (inputReserve + inputAmount);
        //return (outputAmount);
        uint256 fee = 99;
        uint256 inputAmountWithFee = inputAmount * fee;
        uint256 numerator = inputAmountWithFee * outputReserve;
        uint256 denominator = (inputReserve * 100) + inputAmountWithFee;

        return numerator / denominator;

    }

    function getTokenAmount(uint256 _ethSold) public view returns (uint256) {
        require(_ethSold > 0, "invalid amount");

        uint256 tokenReserve = getReserve();
        return getAmount(_ethSold, address(this).balance, tokenReserve);
    }

    function getEthAmount(uint256 _tokenSold) public view returns (uint256) {
        require(_tokenSold > 0, "invalid amount");

        uint256 tokenReserve = getReserve();
        return getAmount(_tokenSold, tokenReserve, address(this).balance);
    }

    function ethToTokenSwap(uint256 _minTokens) public payable {
        uint256 tokenReserve = getReserve();

        uint256 tokensBought = getAmount(
            msg.value,
            address(this).balance - msg.value,
            tokenReserve
        );

        require(tokensBought >= _minTokens, "minimun amout not reach");
        IERC20(tokenAddress).transfer(msg.sender, tokensBought);
    }

    function tokenToEthSwap(uint256 _tokenSold, uint256 _minEth) public {
        uint256 tokenReserve = getReserve();

        uint256 ethBought = getAmount(
            _tokenSold,
            tokenReserve,
            address(this).balance
        );

        require(ethBought >= _minEth, "minumun amount not reach");

        IERC20(tokenAddress).transferFrom(
            msg.sender,
            address(this),
            _tokenSold
        );
        payable(msg.sender).transfer(ethBought);
    }
}
