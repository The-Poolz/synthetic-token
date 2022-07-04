# List of events

<table>
<thead>
<tr>
<th align="center">functions</th>
<th>events</th>
<th>links</th>
</tr>
</thead>
<tbody>
<tr>
<td align="center"><b>constructor</b></td>
<td align="left"><pre>
<b>if without whitelist</b>

<b>id: 0</b> OwnershipTransferred (address previousOwner, address newOwner)
<b>id: 1</b> Transfer (address from, address to, uint256 value)

<b>if with whitelist</b>
<b>id: 0</b> OwnershipTransferred (address previousOwner, address newOwner)
<b>id: 1</b> Transfer (address from, address to, uint256 value)
<b>id: 2</b> NewWhiteList (uint256 _WhiteListCount, address _creator, address _contract, uint256 _changeUntil)</pre></td>
<td><pre><a href="https://testnet.bscscan.com/tx/0x7a6c8e3a116525bab39eecd17f2c2992aed937fb386de5d91c1750278dce4085#eventlog">if without whitelist</a>
<a href="https://testnet.bscscan.com/tx/0xc90fc3988eeac64b6cfc8d913f85dd750c329677ad056a9423c5fb90a7b96663#eventlog">if with whitelist</a>
</pre></td>
</tr>
<tr>
<td align="center"><b>SetLockingDetails</b></td>
<td align="left"><pre>
<b>id: 0</b>  Transfer(address indexed from, address indexed to, uint256 value)
<b>id: 1</b>  Approval(address indexed owner, address indexed spender, uint256 value)
<b>id: 2</b>  TransferIn(uint256 Amount, address From, address Token)
<b>id: 3</b>  LockingDetails(address TokenAddress, uint256 Amount, uint8 TotalUnlocks, uint256 FinishTime)
</pre></td>
<td><a href="https://testnet.bscscan.com/tx/0x072c7f97baf0ecbd802878ffdbfd810f4e698ed5c49c66d2d3f389bfe9c38bf1#eventlog">SetLockingDetails</a></td>
</tr>
<tr>
<td align="center"><b>ActivateSynthetic</b></td>
<td align="left"><pre>
<b>if without create new pool</b>
<b>id: 0</b>  TransferOut(uint256 Amount, address To, address Token)
<b>id: 1</b>  Transfer(address indexed from, address indexed to, uint256 value)
<b>id: 2</b>  Approval(address indexed owner, address indexed spender, uint256 value)
<b>id: 3</b>  TokenActivated(address Owner, uint256 Amount)
<br>
<b>if create new pool</b>
<b>id: 0</b>  TransferOut(uint256 Amount, address To, address Token)
<b>id: 1</b>  Transfer(address indexed from, address indexed to, uint256 value)
<b>id: 2</b>  Approval(address indexed owner, address indexed spender, uint256 value)
       NewPoolCreated(uint256 PoolId, address Token, uint64 FinishTime, uint256 StartAmount, address Owner) 
       TokenActivated(address Owner, uint256 Amount)
</pre></td>
<td><pre><a href="https://testnet.bscscan.com/tx/0x461fbb318fd0a2a39d5afa3fdecee4b1b0d97930c958c4ae96afb2476eea24e6#eventlog">if without create new pool</a>
<a href="https://testnet.bscscan.com/tx/0x302a813f8ed18ceb15afb0ab4e7487d85a3f2d1dfebddad4552fff992b3e7e71#eventlog">if create new pool</a>
</pre></td>
</tr>
</tbody>
</table>