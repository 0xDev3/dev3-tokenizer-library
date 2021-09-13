// @ts-ignore
import {ethers} from "hardhat";
import {Contract, Signer} from "ethers";
import * as helpers from "../../util/helpers";
import * as deployerServiceUtil from "../../util/deployer-service";
import {expect} from "chai";
import {it} from "mocha";

describe("Asset transferable test", function () {

    //////// FACTORIES ////////
    let issuerFactory: Contract;
    let assetFactory: Contract;
    let assetTransferableFactory: Contract;
    let cfManagerFactory: Contract;
    let payoutManagerFactory: Contract;

    //////// SERVICES ////////
    let walletApproverService: Contract;
    let deployerService: Contract;
    let queryService: Contract;

    ////////// APX //////////
    let apxRegistry: Contract;

    //////// SIGNERS ////////
    let deployer: Signer;
    let assetManager: Signer;
    let priceManager: Signer;
    let walletApprover: Signer;
    let issuerOwner: Signer;
    let alice: Signer;
    let jane: Signer;
    let frank: Signer;
    let mark: Signer;

    //////// CONTRACTS ////////
    let stablecoin: Contract;
    let issuer: Contract;
    let asset: Contract;
    let cfManager: Contract;

    beforeEach(async function () {
        const accounts: Signer[] = await ethers.getSigners();

        deployer        = accounts[0];
        assetManager    = accounts[1];
        priceManager    = accounts[2];
        walletApprover  = accounts[3];

        issuerOwner     = accounts[4];
        alice           = accounts[5];
        jane            = accounts[6];
        frank           = accounts[7];
        mark            = accounts[8];

        stablecoin = await helpers.deployStablecoin(deployer, "1000000000000");
        apxRegistry = await helpers.deployApxRegistry(
            deployer,
            await deployer.getAddress(),
            await assetManager.getAddress(),
            await priceManager.getAddress()
        );

        const factories = await helpers.deployFactories(deployer);
        issuerFactory = factories[0];
        assetFactory = factories[1];
        assetTransferableFactory = factories[2];
        cfManagerFactory = factories[3];
        payoutManagerFactory = factories[4];

        const walletApproverAddress = await walletApprover.getAddress();
        const services = await helpers.deployServices(
            deployer,
            walletApproverAddress,
            "0.001"
        );
        walletApproverService = services[0];
        deployerService = services[1];
        queryService = services[2];
        //// Set the config for Issuer, Asset and Crowdfunding Campaign
        const issuerAnsName = "test-issuer";
        const issuerInfoHash = "issuer-info-ipfs-hash";
        const issuerOwnerAddress = await issuerOwner.getAddress();
        const assetName = "Test Asset";
        const assetAnsName = "test-asset";
        const assetTicker = "TSTA";
        const assetInfoHash = "asset-info-ipfs-hash";
        const assetWhitelistRequiredForRevenueClaim = true;
        const assetWhitelistRequiredForLiquidationClaim = true;
        const assetTokenSupply = 300000;              // 300k tokens total supply
        const campaignInitialPricePerToken = 10000;   // 1$ per token
        const maxTokensToBeSold = 200000;             // 200k tokens to be sold at most (200k $$$ to be raised at most)
        const campaignSoftCap = 100000;               // minimum $100k funds raised has to be reached for campaign to succeed
        const campaignMinInvestment = 10000;          // $10k min investment per user
        const campaignMaxInvestment = 400000;         // $200k max investment per user
        const campaignWhitelistRequired = true;       // only whitelisted wallets can invest
        const campaignAnsName = "test-campaign";
        const campaignInfoHash = "campaign-info-ipfs-hash";
        const childChainManager = ethers.Wallet.createRandom().address;

        //// Deploy the contracts with the provided config
        issuer = await helpers.createIssuer(
            issuerOwnerAddress,
            issuerAnsName,
            stablecoin,
            walletApproverService.address,
            issuerInfoHash,
            issuerFactory
        );
        const contracts = await deployerServiceUtil.createAssetTransferableCampaign(
            issuer,
            issuerOwnerAddress,
            assetAnsName,
            assetTokenSupply,
            assetWhitelistRequiredForRevenueClaim,
            assetWhitelistRequiredForLiquidationClaim,
            assetName,
            assetTicker,
            assetInfoHash,
            issuerOwnerAddress,
            campaignAnsName,
            campaignInitialPricePerToken,
            campaignSoftCap,
            campaignMinInvestment,
            campaignMaxInvestment,
            maxTokensToBeSold,
            campaignWhitelistRequired,
            campaignInfoHash,
            apxRegistry.address,
            childChainManager,
            assetTransferableFactory,
            cfManagerFactory,
            deployerService
        );
        asset = contracts[0];
        cfManager = contracts[1];
    });

    it(`should verify notLiquidated modifier`, async function () {
        const modifierMessage = "Asset: Action forbidden, asset liquidated."
        await liquidateAsset()

        await expect(
            asset.connect(assetManager).finalizeSale()
        ).to.be.revertedWith(modifierMessage);
        await expect(
            asset.connect(issuerOwner).approveCampaign(cfManager.address)
        ).to.be.revertedWith(modifierMessage);
        await expect(
            asset.connect(issuerOwner).suspendCampaign(cfManager.address)
        ).to.be.revertedWith(modifierMessage);
        await expect(
            asset.connect(assetManager).liquidate()
        ).to.be.revertedWith(modifierMessage);
        await expect(
            asset.connect(assetManager).snapshot()
        ).to.be.revertedWith(modifierMessage);
        await expect(
            asset.connect(assetManager).liquidate()
        ).to.be.revertedWith(modifierMessage);
    })

    it('should verify ownerOnly modifier', async function () {
        const modifierMessage = "Asset: Only asset creator can make this action."
        const address = await jane.getAddress()

        await expect(
            asset.connect(alice).approveCampaign(cfManager.address)
        ).to.be.revertedWith(modifierMessage);
        await expect(
            asset.connect(alice).suspendCampaign(cfManager.address)
        ).to.be.revertedWith(modifierMessage);
        await expect(
            asset.connect(alice).changeOwnership(address)
        ).to.be.revertedWith(modifierMessage);
        await expect(
            asset.connect(alice).setInfo("ipfs-hash")
        ).to.be.revertedWith(modifierMessage);
        await expect(
            asset.connect(alice).setWhitelistRequiredForRevenueClaim(false)
        ).to.be.revertedWith(modifierMessage);
        await expect(
            asset.connect(alice).setWhitelistRequiredForLiquidationClaim(false)
        ).to.be.revertedWith(modifierMessage);
        await expect(
            asset.connect(alice).changeOwnership(address)
        ).to.be.revertedWith(modifierMessage);
        await expect(
            asset.connect(alice).setChildChainManager(address)
        ).to.be.revertedWith(modifierMessage);
    })

    it('should verify that only issuer owner can set issuer status', async function () {
        await expect(
            asset.connect(assetManager).setIssuerStatus(false)
        ).to.be.revertedWith("Asset: Only issuer owner can make this action.")
        await asset.connect(issuerOwner).setIssuerStatus(false)
    })

    it('should fail to claim liquidation share on not liquidated asset', async function () {
        await expect(
            asset.connect(alice).claimLiquidationShare(await alice.getAddress())
        ).to.be.revertedWith("Asset: not liquidated")
    })

    it('should fail to claim liquidation share on not whitelisted address', async function () {
        await liquidateAsset()
        await expect(
            asset.connect(alice).claimLiquidationShare(await alice.getAddress())
        ).to.be.revertedWith("Asset: wallet must be whitelisted before claiming liquidation share.")
    })

    it('should fail to claim zero liquidation funds', async function () {
        await asset.connect(issuerOwner).setWhitelistRequiredForLiquidationClaim(false)
        await liquidateAsset()
        await expect(
            asset.connect(alice).claimLiquidationShare(await alice.getAddress())
        ).to.be.revertedWith("Asset: no tokens approved for claiming liquidation share")
    })

    it('should verify that only apxRegistry can change apxRegistry address', async function () {
        const newApxRegistry = await alice.getAddress()
        await expect(
            asset.connect(issuerOwner).migrateApxRegistry(newApxRegistry)
        ).to.be.revertedWith("AssetTransferable: Only apxRegistry can call this function.")
    })

    it.skip('should fail to finalize not approved campaign', async function () {
        // don't know how to test finalize sale
        await asset.connect(issuerOwner).suspendCampaign(cfManager.address)
        await cfManager.connect(issuerOwner).finalize()
        await expect(
            cfManager.connect(issuerOwner).finalize()
        ).to.be.revertedWith("Asset: Campaign not approved.")
    })

    it.skip('should fail to finalize already finalized campaign', async function () {
        // don't know how to test finalize sale
        await asset.connect(issuerOwner).finalizeSale()
        await expect(
            asset.connect(issuerOwner).finalizeSale()
        ).to.be.revertedWith("Asset: Campaign not finalized")
    })

    it.skip('should fail to claim zero liquidation funds', async function () {
        // this case is not possible, not sure how to assert that it cannot happen
        await expect(
            asset.connect(alice).claimLiquidationShare(await alice.getAddress())
        ).to.be.revertedWith("Asset: no liquidation funds to claim")
    })

    async function liquidateAsset() {
        const liquidationFunds = 300000;
        await stablecoin.transfer(await issuerOwner.getAddress(), ethers.utils.parseEther(liquidationFunds.toString()));
        await stablecoin.connect(assetManager).approve(asset.address, ethers.utils.parseEther(liquidationFunds.toString()));
        await helpers.registerAsset(assetManager, apxRegistry, asset.address, asset.address);
        await helpers.updatePrice(priceManager, apxRegistry, asset.address, 1, 1, 60);
        await helpers.liquidate(issuerOwner, asset, stablecoin, liquidationFunds);
    }

})
