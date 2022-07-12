# Deploy the `alacritty` config file
Before the actual config file will be deployed to a Windows machine, a
`Hack` font must be installed. For detailed installation instructions
for a Windows systems look at:
https://github.com/source-foundry/Hack-windows-installer

# Configuration file location
Place an `alacritty`'s configuration files under below path:

```powershell
%APPDATA%\alacritty\alacritty.yml
```
ref: https://github.com/alacritty/alacritty#windows

In order to check `APPDATA` environment variable in MS PowerShell
execute below command:

```powershell
$env:APPDATA
```
