// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../shared/Structs.sol";

interface IAssetFactory {
    
    function create(Structs.AssetFactoryParams memory params) external returns (address);
    
    function getInstances() external view returns (address[] memory);
    
    function getInstancesForIssuer(address issuer) external view returns (address[] memory);

    function namespace(address issuer, string memory ansName) external view returns (address);
    
}
