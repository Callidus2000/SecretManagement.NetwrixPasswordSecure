<!--
*** Thanks for checking out the Best-README-Template. If you have a suggestion
*** that would make this better, please fork the repo and create a pull request
*** or simply open an issue with the tag "enhancement".
*** Thanks again! Now go create something AMAZING! :D
***
-->

<!-- PROJECT SHIELDS -->
<!--
*** I'm using markdown "reference style" links for readability.
*** Reference links are enclosed in brackets [ ] instead of parentheses ( ).
*** See the bottom of this document for the declaration of the reference variables
*** for contributors-url, forks-url, etc. This is an optional, concise syntax you may use.
*** https://www.markdownguide.org/basic-syntax/#reference-style-links
-->
[![Contributors][contributors-shield]][contributors-url]
[![Forks][forks-shield]][forks-url]
[![Stargazers][stars-shield]][stars-url]
[![Issues][issues-shield]][issues-url]
[![GPLv3 License][license-shield]][license-url]


<br />
<p align="center">
<!-- PROJECT LOGO
  <a href="https://github.com/Callidus2000/SecretManagement.NetwrixPasswordSecure">
    <img src="images/logo.png" alt="Logo" width="80" height="80">
  </a>
-->

  <h3 align="center">SecretManagement PowerShell Extension for Netwrix PasswordSecure</h3>

  <p align="center">
    This Powershell Module is an extension to the <a href="https://github.com/PowerShell/SecretManagement">Microsoft Secret Management Module</a>
    <br />
    <a href="https://github.com/Callidus2000/SecretManagement.NetwrixPasswordSecure"><strong>Explore the docs »</strong></a>
    <br />
    <br />
    <a href="https://github.com/Callidus2000/SecretManagement.NetwrixPasswordSecure/issues">Report Bug</a>
    ·
    <a href="https://github.com/Callidus2000/SecretManagement.NetwrixPasswordSecure/issues">Request Feature</a>
  </p>
</p>



<!-- TABLE OF CONTENTS -->
<details open="open">
  <summary><h2 style="display: inline-block">Table of Contents</h2></summary>
  <ol>
    <li>
      <a href="#about-the-project">About The Project</a>
      <ul>
        <li><a href="#built-with">Built With</a></li>
      </ul>
    </li>
    <li>
      <a href="#getting-started">Getting Started</a>
      <ul>
        <li><a href="#prerequisites">Prerequisites</a></li>
        <li><a href="#installation">Installation</a></li>
      </ul>
    </li>
    <li><a href="#usage">Usage</a></li>
    <li><a href="#use-cases-or-why-was-the-module-developed">Use-Cases - Why was this module created?</a></li>
    <li><a href="#roadmap">Roadmap</a></li>
    <li><a href="#contributing">Contributing</a></li>
    <li><a href="#license">License</a></li>
    <li><a href="#contact">Contact</a></li>
    <li><a href="#acknowledgements">Acknowledgements</a></li>
  </ol>
</details>



<!-- ABOUT THE PROJECT -->
## About The Project

This Powershell Module is an extension to the [Microsoft Secret Management Module](https://github.com/PowerShell/SecretManagement) for accessing secrets stored within the Netwrix Password Secure Server. It is a wrapper for the API which is only accessible by using a C# SDK provided by NetWrix __only to enterprise customers__. __The module is useless if you are no enterprise customer__ (regarding the license modell you are using).



The usage of the SDK is documented in the [Netwrix Helpcenter](https://helpcenter.netwrix.com/) filed under the keyword 'SDK'. You have to sideload/copy the SDK *.DLL files to a given location in order to get the module up to work (see [Installation](#installation)).


### Built With

* [PSModuleDevelopment](https://github.com/PowershellFrameworkCollective/PSModuleDevelopment)
* [psframework](https://github.com/PowershellFrameworkCollective/psframework)



<!-- GETTING STARTED -->
## Getting Started

To get a local copy up and running follow these simple steps.

### Prerequisites

- Powershell 7.x (Core) (If possible get the latest version)  
  Maybe it's working under 5.1, just did not test it
- A Password Secure Server with a user account

### Installation

The releases are published in the Powershell Gallery, therefor it is quite simple:
```powershell
  install-module SecretManagement.NetwrixPasswordSecure -Scope CurrentUser
```

As the module 100% depends on the C# SDK API DLL Files you have to request them from the vendor. After acquiring the zipped files please extract them into the subdirectory `SecretManagement.NetwrixPasswordSecure.Extension\bin`. The local path is hinted by an error message if you try to import the module while the DLLs are missing:

```Powershell
Import-Module SecretManagement.NetwrixPasswordSecure
WARNING: [15:47:39][<Unknown>] Required Assemblies (like PsrAPI.dll) are missing in the folder 'C:\Users\root\Documents\PowerShell\Modules\SecretManagement.NetwrixPasswordSecure\1.0.0\SecretManagement.NetwrixPasswordSecure.Extension\bin'. They are provided for *Enterprise* cutomers by the product vendor on request. Please unzip all provided *.DLL within this folder
```
### Internal Concepts
#### Password Container
Every entry is a container.

#### Organizational Units (OU)
Which is grouped in OUs

<!-- USAGE EXAMPLES -->
## Usage
First you have to register the SecretManagement Vault:
```Powershell
# With the provided helper
Register-NetwrixSecureVault -Server "myserver" -UserName "max.mustermann" -Database "PWS8" -vaultName "PWS"
# Or by native command
Register-SecretVault -Name "PWS" -ModuleName SecretManagement.NetwrixPasswordSecure -VaultParameters @{
    server="myserver"
    UserName="max.mustermann"
    Database= "PWS8"
    port=11016
}
```

Lets pretend you've got just three entries stored in your server: `foo`, `hubba` and `hubba` (yes, a dupe regarding the name within different containers).
```Powershell
Get-Secret -Name foo

UserName                     Password
--------                     --------
foo      System.Security.SecureString

Get-Secret -Vault $Vaultname -Name hubba
[Error] Multiple credentials found; Search with Get-SecretInfo and require the correct one by *.MetaData.id
Get-Secret: Unable to get secret hubba from vault PWSafeInt
Get-Secret: The secret hubba was not found.
```
Seen it? The SecretManagement Framework does not allow to query duplicate entries, in the concept (off-world) there rule uniqueness regarding the name attribute. As duplicate names can be used you have to acquire the GUID of the correct entry and query this record in particular

```Powershell
Get-SecretInfo -Name hubba |fl

Name      : Hubba [5dd937c4-b0a0-ed11-a876-005056bce948]
Type      : PSCredential
VaultName : PWS
Metadata  : {[userName, Foo], [id, 5dd937c4-b0a0-ed11-a876-005056bce948], [Beschreibung, Hubba], [memo, ]…}

Name      : Hubba [ef2fe11d-b0a0-ed11-a876-005056bce948]
Type      : PSCredential
VaultName : PWS
Metadata  : {[userName, hubba], [id, ef2fe11d-b0a0-ed11-a876-005056bce948], [Beschreibung, Hubba], [memo, ]…}

# Query the one with the username 'hubba'
Get-Secret ef2fe11d-b0a0-ed11-a876-005056bce948

UserName                     Password
--------                     --------
hubba    System.Security.SecureString
```
For updating use `Set-Secret`:
```Powershell
Set-Secret -Secret (Get-Credential) -Name foo
```
Attention: If you use a `SecureString` secret only the password is updated, using a `PSCredential` secret updates the username, too.

For adding a new secret you also use Set-Secret - Sometimes in the future, as it's currently under development.
```Powershell
# Adding not possible yet
```

<!-- ROADMAP -->
## Roadmap
New features will be added if any of my scripts need it ;-)

The main focus of this module is to get access to our internal Password Servers. As the system is quite easy to customize (see [Internal Concepts](#internal-concepts)) I'd bet it might not be usable for your installation. If running into problems [open a new issue](https://github.com/Callidus2000/SecretManagement.NetwrixPasswordSecure/issues), I try to look into it.

I cannot guarantee that no breaking change will occur as the development follows my internal DevOps need completely. Likewise I will not insert full documentation of all parameters as I don't have time for this copy&paste. Sorry. But major changes which classify as breaking changes will result in an increment of the major version. See [Changelog](SecretManagement.NetwrixPasswordSecure/changelog.md) for information regarding breaking changes.

See the [open issues](https://github.com/Callidus2000/SecretManagement.NetwrixPasswordSecure/issues) for a list of proposed features (and known issues).

If you need a special function feel free to contribute to the project.

<!-- CONTRIBUTING -->
## Contributing

Contributions are what make the open source community such an amazing place to be learn, inspire, and create. Any contributions you make are **greatly appreciated**. For more details please take a look at the [CONTRIBUTE](docs/CONTRIBUTING.md#Contributing-to-this-repository) document

Short stop:

1. Fork the Project
2. Create your Feature Branch (`git checkout -b feature/AmazingFeature`)
3. Commit your Changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the Branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request


## Limitations
* Maybe there are some inconsistencies in the docs, which may result in a mere copy/paste marathon from my other projects

<!-- LICENSE -->
## License

Distributed under the GNU GENERAL PUBLIC LICENSE version 3. See `LICENSE.md` for more information.

<!-- CONTACT -->
## Contact


Project Link: [https://github.com/Callidus2000/SecretManagement.NetwrixPasswordSecure](https://github.com/Callidus2000/SecretManagement.NetwrixPasswordSecure)



<!-- ACKNOWLEDGEMENTS -->
## Acknowledgements

* [Friedrich Weinmann](https://github.com/FriedrichWeinmann) for his marvelous [PSModuleDevelopment](https://github.com/PowershellFrameworkCollective/PSModuleDevelopment) and [psframework](https://github.com/PowershellFrameworkCollective/psframework)





<!-- MARKDOWN LINKS & IMAGES -->
<!-- https://www.markdownguide.org/basic-syntax/#reference-style-links -->
[contributors-shield]: https://img.shields.io/github/contributors/Callidus2000/SecretManagement.NetwrixPasswordSecure.svg?style=for-the-badge
[contributors-url]: https://github.com/Callidus2000/SecretManagement.NetwrixPasswordSecure/graphs/contributors
[forks-shield]: https://img.shields.io/github/forks/Callidus2000/SecretManagement.NetwrixPasswordSecure.svg?style=for-the-badge
[forks-url]: https://github.com/Callidus2000/SecretManagement.NetwrixPasswordSecure/network/members
[stars-shield]: https://img.shields.io/github/stars/Callidus2000/SecretManagement.NetwrixPasswordSecure.svg?style=for-the-badge
[stars-url]: https://github.com/Callidus2000/SecretManagement.NetwrixPasswordSecure/stargazers
[issues-shield]: https://img.shields.io/github/issues/Callidus2000/SecretManagement.NetwrixPasswordSecure.svg?style=for-the-badge
[issues-url]: https://github.com/Callidus2000/SecretManagement.NetwrixPasswordSecure/issues
[license-shield]: https://img.shields.io/github/license/Callidus2000/SecretManagement.NetwrixPasswordSecure.svg?style=for-the-badge
[license-url]: https://github.com/Callidus2000/SecretManagement.NetwrixPasswordSecure/blob/master/LICENSE

