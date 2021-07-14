// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { IAssetFactory } from "../asset/IAssetFactory.sol";
import { Asset } from "../asset/Asset.sol";

contract AssetFactory is IAssetFactory {
    
    event AssetCreated(address indexed creator, address asset, uint256 timestamp);

    address[] public instances;

    function create(
        address creator,
        address issuer,
        uint256 initialTokenSupply,
        bool whitelistRequiredForTransfer,
        string memory name,
        string memory symbol,
        string memory info
    ) public override returns (address)
    {
        uint256 id = instances.length;
        address asset = address(new Asset(
            id,
            creator,
            issuer,
            initialTokenSupply,
            whitelistRequiredForTransfer,
            name,
            symbol,
            info
        ));
        instances.push(asset);
        emit AssetCreated(creator, asset, block.timestamp);
        return asset;
    }

    function getInstances() external override view returns (address[] memory) { return instances; }
    
}
