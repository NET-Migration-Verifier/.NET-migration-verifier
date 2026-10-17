# Building the legacy app

How `eShopLegacyMVC` was restored and built on the Windows host for [T1.1](https://github.com/NET-Migration-Verifier/.NET-migration-verifier/issues/65). These are the steps the [R-104](https://github.com/NET-Migration-Verifier/.NET-migration-verifier/issues/16) script has to reproduce.

## 1. Clone the fork

The upstream `dotnet-architecture/eShopModernizing` is archived, so we build from our fork. Clone it to `D:`, since `C:` has no room for the packages and build output.

```powershell
git clone https://github.com/NET-Migration-Verifier/eShopModernizing.git D:\Source\eShopModernizing
```

## 2. Do not accept Visual Studio's retarget prompt

`eShopLegacy.Utilities` targeted .NET Framework 4.6.1. That developer pack is out of support and isn't installed with Visual Studio 2022, so Visual Studio offers to retarget the project, and it suggests 4.8. Accepting breaks the build: `eShopLegacyMVC` targets 4.7.2, and MSBuild drops a reference to a project built for a newer framework. `FilesController` and `BrandsController` then fail with `CS0246: The type or namespace name 'eShopLegacy' could not be found`.

The fork retargets Utilities to 4.7.2 instead ([eShopModernizing#1](https://github.com/NET-Migration-Verifier/eShopModernizing/pull/1)). Until that PR is merged, check out `build/retarget-utilities-net472`.

## 3. Restore and build

The solution mixes `packages.config` and `PackageReference`, so restore with `RestorePackagesConfig`. Build the MVC project rather than the solution. The solution also contains `eShopPorted`, which is the upstream port and not part of T1.1.

```powershell
$msbuild = 'D:\VisualStudio\2022\Community\MSBuild\Current\Bin\MSBuild.exe'
$sln = 'D:\Source\eShopModernizing\eShopLegacyMVCSolution'
& $msbuild "$sln\eShopLegacyMVC.sln" -t:Restore -p:RestorePackagesConfig=true -v:minimal
& $msbuild "$sln\src\eShopLegacyMVC\eShopLegacyMVC.csproj" -t:Rebuild -p:Configuration=Debug -p:SolutionDir="$sln\" -v:minimal
```

The restore finishes with only warnings, all from the app's own pinned packages. Leave them as they are; the legacy app is the baseline we migrate from.

- NU1903: `Newtonsoft.Json` 12.0.1 has a high-severity advisory.
- NU1902: `log4net` 2.0.10 has a moderate one.
- NU1605 and NU1608: Autofac 6.1.0 pulls newer `System.Diagnostics.DiagnosticSource` and `System.Threading.Tasks.Extensions` than the project pins.

The build ends with one MSB3247 warning, a `System.Net.Http.Formatting` version conflict that the app's binding redirects cover.

**Evidence:** `Build succeeded`, `0 Error(s)`, and `src\eShopLegacyMVC\bin\eShopLegacyMVC.dll` is written.
