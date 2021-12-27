//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Exchange {
    address public tokenAddress;

    constructor(address _token) {
        require(_token != address(0), "Invalid Token");
        tokenAddress = _token;
    }

    function addLiquidity(uint256 _tokenAmount) public payable {
        IERC20 token = IERC20(tokenAddress);
        token.transferFrom(msg.sender, address(this), _tokenAmount);
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
        uint256 outputAmount = (inputAmount * outputReserve) /
            (inputReserve + inputAmount);
        return (outputAmount);
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