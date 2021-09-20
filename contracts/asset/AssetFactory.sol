// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../asset/IAssetFactory.sol";
import "../deployers/IAssetDeployer.sol";
import "../shared/Structs.sol";
import "../registry/INameRegistry.sol";

contract AssetFactory is IAssetFactory {

    string constant public FLAVOR = "AssetV1";
    string constant public VERSION = "1.0.13";

    address public deployer;
    address[] public instances;
    mapping (address => address[]) instancesPerIssuer;

    event AssetCreated(address indexed creator, address asset, uint256 timestamp);

    constructor(address _deployer) { deployer = _deployer; }

    function create(Structs.AssetFactoryParams memory params) public override returns (address) {
        INameRegistry nameRegistry = INameRegistry(params.nameRegistry);
        require(
            nameRegistry.getAsset(params.mappedName) == address(0),
            "AssetFactory: asset with this name already exists"
        );
        address asset = IAssetDeployer(deployer).create(FLAVOR, VERSION, params);
        instances.push(asset);
        instancesPerIssuer[params.issuer].push(asset);
        emit AssetCreated(params.creator, asset, block.timestamp);
        return asset;
    }

    function getInstances() external override view returns (address[] memory) { return instances; }
    
    function getInstancesForIssuer(address issuer) external override view returns (address[] memory) { 
        return instancesPerIssuer[issuer];
    }
}
