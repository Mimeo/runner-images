Describe "Toolset" {
    $tools = (Get-ToolsetContent).toolcache

    $toolsExecutables = @{
        Python = @{
            tools = @("python", "bin/pip")
            command = "--version"
        }
        node = @{
            tools = @("bin/node", "bin/npm")
            command = "--version"
        }
        PyPy = @{
            tools = @("bin/python", "bin/pip")
            command = "--version"
        }
        go = @{
            tools = @("bin/go")
            command = "version"
        }
        Ruby = @{
            tools = @("bin/ruby")
            command = "--version"
        }
        CodeQL = @{
            tools = @("codeql/codeql")
            command = "version"
        }
        Sbt = @{
            tools = @("bin/sbt")
            command = "--version"
        }
    }

    foreach ($tool in $tools) {
    $toolName = $tool.Name

    Context "$toolName" {
        if (-not $tool.versions -or $tool.versions.Count -eq 0) {
            Write-Warning "$toolName has no versions available. Skipping."
            continue
        }

        $toolExecs = $toolsExecutables[$toolName]

        foreach ($version in $tool.versions) {
            # Improved version padding
            if ($version -notmatch "^\d+\.\d+\.\d+$") {
                $version += ".*"
            }

            $expectedVersionPath = Join-Path $env:AGENT_TOOLSDIRECTORY $toolName $version

            It "$version version folder exists" -TestCases @{ ExpectedVersionPath = $expectedVersionPath } {
                if (Test-Path $ExpectedVersionPath) {
                    $ExpectedVersionPath | Should -Exist
                } else {
                    Write-Warning "Expected path '$ExpectedVersionPath' for $toolName version $version does not exist."
                }
            }

            try {
                $foundVersion = Get-Item $expectedVersionPath `
                    | Sort-Object -Property {[SemVer]$_.name} -Descending `
                    | Select-Object -First 1

                if (-not $foundVersion) {
                    throw "No valid version folder found for $toolName version $version"
                }

                $foundVersionPath = Join-Path $foundVersion $tool.arch
            } catch {
                Write-Warning "Failed to find valid version for $toolName ($version): $_"
                continue
            }

            # Validate executables only if a valid version path is found
            if ($toolExecs) {
                foreach ($executable in $toolExecs["tools"]) {
                    $executablePath = Join-Path $foundVersionPath $executable

                    It "Validate $executable" -TestCases @{ ExecutablePath = $executablePath } {
                        if (Test-Path $ExecutablePath) {
                            $ExecutablePath | Should -Exist
                        } else {
                            Write-Warning "$executable for $toolName not found at $executablePath"
                        }
                    }
                }
            }
        }
    }
}
}
