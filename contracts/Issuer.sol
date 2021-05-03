// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { IIssuer } from "./interfaces/IIssuer.sol";
import { ICfManager } from "./interfaces/ICfManager.sol";
import { IAssetFactory } from "./interfaces/IAssetFactory.sol";
import { ICfManagerFactory } from "./interfaces/ICfManagerFactory.sol";
import { AssetState } from "./Enums.sol";

contract Issuer is IIssuer, Ownable {

    address public override stablecoin;
    IAssetFactory public assetFactory;
    ICfManagerFactory public cfManagerFactory;
    mapping (address => bool) public approvedWallets;
    address[] public assets;
    address[] public cfManagers;

    constructor(address _stablecoin, address _assetFactory, address _cfManagerFactory) {
        stablecoin = _stablecoin;
        assetFactory = IAssetFactory(_assetFactory);
        cfManagerFactory = ICfManagerFactory(_cfManagerFactory);
    }

    event CfManagerCreated(address _cfManager);
    event AssetCreated(address _asset);

    modifier walletApproved(address _wallet) {
        require(
            approvedWallets[_wallet],
            "This action is forbidden. Wallet not approved by the Issuer."
        );
        _;
    }

    function approveWallet(address _wallet) external onlyOwner {
        approvedWallets[_wallet] = true;
    }

    function suspendWallet(address _wallet) external onlyOwner {
        approvedWallets[_wallet] = false;
    }

    function createAsset(
        uint256 _categoryId,
        uint256 _totalShares,
        AssetState _state,
        string memory _name,
        string memory _symbol
    ) external walletApproved(msg.sender) returns (address)
    {
        address asset = assetFactory.create(
            msg.sender,
            address(this),
            _state,
            _categoryId,
            _totalShares,
            _name,
            _symbol
        );
        assets.push(asset);
        emit AssetCreated(asset);
        return asset;
    }

    function createCrowdfundingCampaign(
        uint256 _categoryId,
        uint256 _totalShares,
        string memory _name,
        string memory _symbol,
        uint256 _minInvestment,
        uint256 _maxInvestment,
        uint256 _endsAt
    ) external walletApproved(msg.sender) returns(address)
    {
        address manager = cfManagerFactory.create(
            _minInvestment,
            _maxInvestment,
            _endsAt  
        );
        address asset = assetFactory.create(
            manager,
            address(this),
            AssetState.CREATION,
            _categoryId,
            _totalShares,
            _name,
            _symbol
        );
        ICfManager(manager).setAsset(asset);
        assets.push(asset);
        cfManagers.push(manager);
        emit CfManagerCreated(manager);
        emit AssetCreated(asset);
        return manager;
    }

    function isWalletApproved(address _wallet) external view override returns (bool) {
        return approvedWallets[_wallet];
    }

}
