/**
 * Created by Arcadia Finance
 * https://www.arcadia.finance
 *
 * SPDX-License-Identifier: BUSL-1.1
 */
pragma solidity >=0.8.0 <0.9.0;

import "../ActionBase.sol";
import "../helpers/UniswapV2Helper.sol";
import "../utils/ActionAssetData.sol";
import "../../interfaces/IMainRegistry.sol";
import "../../interfaces/IVault.sol";
import "../../interfaces/IERC20.sol";

contract UniswapV2SwapAction is ActionBase, UniswapV2Helper {
    constructor(address _router, address _mainreg) ActionBase(_mainreg) UniswapV2Helper(_router) {}

    function executeAction(address _vaultAddress, bytes calldata _actionData)
        public
        override
        returns (actionAssetsData memory)
    {
        require(_vaultAddress == msg.sender, "UV2_SWAP: can only be called by vault");
        // preCheck data
        (actionAssetsData memory _outgoing, actionAssetsData memory _incoming, address[] memory path) =
            _preCheck(_actionData);
        // execute Action
        _execute(_outgoing, _incoming, path);
        // postCheck data
        _incoming.assetAmounts = _postCheck(_incoming);

        for (uint256 i; i < _incoming.assets.length;) {
            IERC20(_incoming.assets[i]).approve(_vaultAddress, type(uint256).max);
            unchecked {
                i++;
            }
        }

        return (_incoming);
    }

    function _execute(actionAssetsData memory _outgoing, actionAssetsData memory _incoming, address[] memory path)
        internal
    {
        _uniswapV2Swap(address(this), _outgoing.assetAmounts[0], _incoming.assetAmounts[0], path);
    }

    function _preCheck(bytes memory _actionSpecificData)
        internal
        view
        returns (actionAssetsData memory _outgoing, actionAssetsData memory _incoming, address[] memory path)
    {
        /*///////////////////////////////
                    DECODE
        ///////////////////////////////*/

        (_outgoing, _incoming, path) = abi.decode(_actionSpecificData, (actionAssetsData, actionAssetsData, address[]));

        require(path.length >= 2, "UV2A_SWAP: _path must be >= 2");

        /*///////////////////////////////
                    OUTGOING
        ///////////////////////////////*/

        /*///////////////////////////////
                    INCOMING
        ///////////////////////////////*/

        //Check if incoming assets are Arcadia whitelisted assets
        require(
            IMainRegistry(MAIN_REGISTRY).batchIsWhiteListed(_incoming.assets, _incoming.assetIds),
            "UV2A_SWAP: Non-allowlisted incoming asset"
        );

        return (_outgoing, _incoming, path);
    }

    function _postCheck(actionAssetsData memory incomingAssets_)
        internal
        pure
        returns (uint256[] memory incomingAssetAmounts_)
    {
        /*///////////////////////////////
                    INCOMING
        ///////////////////////////////*/

        /*///////////////////////////////
                    OUTGOING
        ///////////////////////////////*/

        return incomingAssets_.assetAmounts;
    }
}
