@{
	# Script module or binary module file associated with this manifest
	RootModule = 'SecretManagement.NetwrixPasswordSecure.psm1'

	# Version number of this module.
	ModuleVersion = '1.0.0'

	# ID used to uniquely identify this module
	GUID = '0a89c2cb-0080-485b-be9a-9071eae98a11'

	# Author of this module
	Author = 'Sascha Spiekermann'

	# Company or vendor of this module
	CompanyName = 'MyCompany'

	# Copyright statement for this module
	Copyright = 'Copyright (c) 2022 Sascha Spiekermann'

	# Description of the functionality provided by this module
	Description       = 'A Secret Management vault extension for Netwrix Password Secure'

	# Minimum version of the Windows PowerShell engine required by this module
	PowerShellVersion = '5.0'
	# Modules that must be imported into the global environment prior to importing this module
	NestedModules     = @(
		'./SecretManagement.NetwrixPasswordSecure.Extension/SecretManagement.NetwrixPasswordSecure.Extension.psd1'
	)

	# Modules that must be imported into the global environment prior to importing
	# this module
	RequiredModules = @(
		@{ModuleName = 'Microsoft.Powershell.SecretManagement'; ModuleVersion = '1.1.0' },
		@{ ModuleName = 'PSFramework'; ModuleVersion = '1.7.249' }
	)

	# Assemblies that must be loaded prior to importing this module
	# RequiredAssemblies = @('bin\SecretManagement.NetwrixPasswordSecure.dll')

	# Type files (.ps1xml) to be loaded when importing this module
	# TypesToProcess = @('xml\SecretManagement.NetwrixPasswordSecure.Types.ps1xml')

	# Format files (.ps1xml) to be loaded when importing this module
	# FormatsToProcess = @('xml\SecretManagement.NetwrixPasswordSecure.Format.ps1xml')

	# Functions to export from this module
	FunctionsToExport = @(
		'Register-NetwrixSecureVault'
	)

	# Cmdlets to export from this module
	CmdletsToExport = ''

	# Variables to export from this module
	VariablesToExport = ''

	# Aliases to export from this module
	AliasesToExport = ''

	# List of all modules packaged with this module
	ModuleList = @()

	# List of all files packaged with this module
	FileList = @()

	# Private data to pass to the module specified in ModuleToProcess. This may also contain a PSData hashtable with additional module metadata used by PowerShell.
	PrivateData = @{

		#Support for PowerShellGet galleries.
		PSData = @{

			# Tags applied to this module. These help with module discovery in online galleries.
			Tags = 'SecretManagement', 'Netwrix','Mateso', 'SecretVault', 'Vault', 'Secret'
			# Tags = @()

			# A URL to the license for this module.
			# LicenseUri = ''

			# A URL to the main website for this project.
			# ProjectUri = ''

			# A URL to an icon representing this module.
			# IconUri = ''

			# ReleaseNotes of this module
			# ReleaseNotes = ''

		} # End of PSData hashtable

	} # End of PrivateData hashtable
}