## OpenVPN Azure ARM Template ##

ARM template to setup OpenVPN server in Microsoft Azure.

<a href="https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fsmattoo%2Fopenvpn-azure-arm-template%2Fmaster%2Fopenvpn-azuredeploy.json" target="_blank">
    <img src="http://azuredeploy.net/deploybutton.png"/>
</a>
<a href="http://armviz.io/#/?load=https%3A%2F%2Fraw.githubusercontent.com%2Fsmattoo%2Fopenvpn-azure-arm-template%2Fmaster%2Fopenvpn-azuredeploy.json" target="_blank">
    <img src="http://armviz.io/visualizebutton.png"/>
</a>

### Steps ###

- Update the template parameters as required.
- Run the template
- Copy the **client1.ovpn**(~/client-configs/files/) from the provisioned ubuntu virtual machine `scp <username>@dgopenvpnserver.<location>.cloudapp.azure.com:/client-configs/files/client1.ovpn /some/local/directory`
- Install the openvpn client from [here](https://openvpn.net/index.php/open-source/downloads.html "OpenVPN client download")
- Post above install copy the **client1.ovpn** file under C:\Program Files\OpenVPN\config and connect to the server.
- Hurray! OpenVPN connection should be established.
