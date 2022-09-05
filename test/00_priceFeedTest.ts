import { expect } from "chai";
import { deBridge, ethers } from "hardhat";
import { MessageCaller, MessageReceiver } from './../typechain-types/contracts';
import { MessageReceiver__factory, MessageCaller__factory } from './../typechain-types/factories/contracts';
import { utils } from 'ethers';
import { BigNumber } from "ethers";
import { parseEther } from "ethers/lib/utils";
import { assert } from "console";
import { formatWithOptions } from "util";
import { send } from "process";

describe("MessageCaller and Message receiver communication\n", () => {
    it("Price feed from source chain should be sent to the destination chain", async() => {
        
        const dbGate = await deBridge.emulator.deployGate();
        const ethUsdMainnetPriceFeedAddr = "0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419"
        
        const MessageReceiver = (await ethers.getContractFactory("MessageReceiver")) as MessageReceiver__factory
        const messageReceiver = (await MessageReceiver.deploy(
            dbGate.address, 
            ethers.provider.network.chainId
        )) as MessageReceiver;
        await messageReceiver.deployed()


        const messageReceiverAddress = messageReceiver.address;
        const messageReceiverChainId = await messageReceiver.viewSupportedChain();
        
        
        const MessageCaller = await ethers.getContractFactory("MessageCaller") as MessageCaller__factory;
        const messageCaller = await MessageCaller.deploy(
            dbGate.address, 
            ethUsdMainnetPriceFeedAddr, 
            messageReceiverChainId, 
            messageReceiverAddress
            )
        await messageCaller.deployed()
        await messageReceiver.setTrustedChainCaller(messageCaller.address)
        const priceEth = await messageCaller.getPriceFeed()
        
        const protocolFee = await dbGate.globalFixedNativeFee();
        const executionFee = ethers.utils.parseEther('0.02');
        const sendTx = await messageCaller.sendPriceFeed(priceEth, executionFee, {
            value: protocolFee.add(executionFee)
        })
        await deBridge.emulator.autoClaim();
        const receiverPrice = await messageReceiver.viewCrossChainPrice();
        expect(receiverPrice).to.be.eq(priceEth)

        console.log(`\tbridgeadr: ${await messageReceiver.deBridgeGate()}`)
        console.log(`\n\tMessageReceiverAddress: ${messageReceiverAddress}`)
        console.log(`\tMessageReceiverChainId: ${messageReceiverChainId}`)
        console.log(`\tPriceEth: ${priceEth}`)
        console.log(`\tProtocol Fee: ${protocolFee}`)
        console.log(`\tExecution Fee: ${executionFee}`)
        console.log(`\tReceiver price: ${receiverPrice}`)
    })
})