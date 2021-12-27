const { expect } = require("chai");
const { ethers, waffle } = require("hardhat");
const { provider } = waffle;

describe("Exchange", function () {
  beforeEach(async function () {
    const Token = await ethers.getContractFactory("ScammCoin");
    token = await Token.deploy(10000);
    await token.deployed();

    const Exchange = await ethers.getContractFactory("Exchange");
    exchange = await Exchange.deploy(token.address);
    await exchange.deployed();
  });

  it("Adds liquidity", async function () {
    await token.approve(exchange.address, 200);
    await exchange.addLiquidity(200, { value: 100 });

    expect(await provider.getBalance(exchange.address)).to.equal(100);
    expect(await exchange.getReserve()).to.equal(200);
  });

  it("Returns correct amout of token", async function(){
    await token.approve(exchange.address, 1000);
    await exchange.addLiquidity(1000, { value: 50 });
    
    let tokenOut = await exchange.getTokenAmount(1);

    expect(tokenOut).to.equal(19);

  });

  it("Returns correct amout of ETH", async function(){
    await token.approve(exchange.address, 1000);
    await exchange.addLiquidity(1000, { value: 50 });
    
    let ethOut = await exchange.getEthAmount(190);

    expect(ethOut).to.equal(7);

  });

});
