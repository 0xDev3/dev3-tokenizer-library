 // SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../shared/IVersioned.sol";
import "../registry/INameRegistry.sol";
import "../shared/Structs.sol";
import "../shared/IIssuerFactoryCommon.sol";
import "../shared/IIssuerCommon.sol";

interface IIssuerQueryService is IVersioned {
    function getIssuersForOwner(
        address[] memory factories,
        INameRegistry nameRegistry,
        address owner
    ) external view returns (Structs.IssuerCommonStateWithName[] memory);
}

contract IssuerQueryService is IIssuerQueryService {

    string constant public FLAVOR = "IssuerQueryServiceV1";
    string constant public VERSION = "1.0.31";

    function flavor() external pure override returns (string memory) { return FLAVOR; }
    function version() external pure override returns (string memory) { return VERSION; }

    function getIssuersForOwner(
        address[] memory factories,
        INameRegistry nameRegistry,
        address owner
    ) public view override returns (Structs.IssuerCommonStateWithName[] memory) {
        if (factories.length == 0) { return new Structs.IssuerCommonStateWithName[](0); }
        
        uint256 totalItems = 0;
        uint256[] memory instanceCountPerFactory = new uint256[](factories.length);
        for (uint256 i = 0; i < factories.length; i++) {
            address[] memory instances = IIssuerFactoryCommon(factories[i]).getInstances();
            uint256 length = instances.length;
            for (uint256 j = 0; j < length; j++) {
                if (IIssuerCommon(instances[j]).commonState().owner == owner) {
                    totalItems += 1;
                    instanceCountPerFactory[i] += 1;
                }
            }
        }
        if (totalItems == 0) { return new Structs.IssuerCommonStateWithName[](0); }
        
        Structs.IssuerCommonStateWithName[] memory response = new Structs.IssuerCommonStateWithName[](totalItems);
        uint256 position = 0;
        for (uint256 i = 0; i < factories.length; i++) {
            if (instanceCountPerFactory[i] == 0) continue;
            address[] memory instances = IIssuerFactoryCommon(factories[i]).getInstances();
            uint256 length = instances.length;
            for (uint256 j = 0; j < length; j++) {
                IIssuerCommon issuerInterface = IIssuerCommon(instances[j]);
                if (issuerInterface.commonState().owner == owner) {
                    response[position] = Structs.IssuerCommonStateWithName(
                        issuerInterface.commonState(),
                        nameRegistry.getIssuerName(instances[j])
                    );
                    position++;
                }
            }
        }

        return response;
    }

}
