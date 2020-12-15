@{
    Severity = @(
        'ParseError',
        'Error',
        'Warning',
        'Information'
    )

    Rules    = @{

        # OTBS: PS: Warning => https://github.com/PowerShell/PSScriptAnalyzer/blob/master/RuleDocumentation/PlaceOpenBrace.md
        PSPlaceOpenBrace                               = @{
            Enable             = $true
            OnSameLine         = $true
            IgnoreOneLineBlock = $true
            NewLineAfter       = $true
        }

        # OTBS: PS: Warning => https://github.com/PowerShell/PSScriptAnalyzer/blob/master/RuleDocumentation/PlaceCloseBrace.md
        PSPlaceCloseBrace                              = @{
            Enable             = $true
            NoEmptyLineBefore  = $false
            IgnoreOneLineBlock = $true
            NewLineAfter       = $false
        }

        # OTBS: PS: Warning => https://github.com/PowerShell/PSScriptAnalyzer/blob/master/RuleDocumentation/UseConsistentIndentation.md
        PSUseConsistentIndentation                     = @{
            Enable              = $true
            IndentationSize     = 4
            Kind                = 'space'
            PipelineIndentation = 'IncreaseIndentationForFirstPipeline'
        }

        # OTBS: PS: Warning => https://github.com/PowerShell/PSScriptAnalyzer/blob/master/RuleDocumentation/UseConsistentWhitespace.md
        PSUseConsistentWhitespace                      = @{
            Enable                          = $true
            CheckInnerBrace                 = $true
            CheckOpenBrace                  = $true
            CheckOpenParen                  = $true
            CheckOperator                   = $false # Disabled due https://github.com/PowerShell/PSScriptAnalyzer/issues/769 (Fixed @vNext)
            CheckPipe                       = $true
            CheckPipeForRedundantWhitespace = $true
            CheckSeparator                  = $true
            CheckParameter                  = $false # Disabled due https://github.com/PowerShell/PSScriptAnalyzer/issues/1561 & https://github.com/PowerShell/PSScriptAnalyzer/issues/1540
        }

        # OTBS: PS: Warning => https://github.com/PowerShell/PSScriptAnalyzer/blob/master/RuleDocumentation/AlignAssignmentStatement.md
        PSAlignAssignmentStatement                     = @{
            Enable         = $true
            CheckHashtable = $true
        }

        # OTBS: PS: Information => https://github.com/PowerShell/PSScriptAnalyzer/blob/master/RuleDocumentation/UseCorrectCasing.md
        PSUseCorrectCasing                             = @{
            Enable = $true
        }



        # PSDSC: Error => https://github.com/PowerShell/PSScriptAnalyzer/blob/master/RuleDocumentation/UseIdenticalMandatoryParametersForDSC.md
        PSDSCUseIdenticalMandatoryParametersForDSC     = @{
            Enable = $true
        }

        # PSDSC: Error => https://github.com/PowerShell/PSScriptAnalyzer/blob/master/RuleDocumentation/UseIdenticalParametersForDSC.md
        PSDSCUseIdenticalParametersForDSC              = @{
            Enable = $true
        }

        # PSDSC: Error => https://github.com/PowerShell/PSScriptAnalyzer/blob/master/RuleDocumentation/StandardDSCFunctionsInResource.md
        PSDSCStandardDSCFunctionsInResource            = @{
            Enable = $true
        }

        # PSDSC: Information => https://github.com/PowerShell/PSScriptAnalyzer/blob/master/RuleDocumentation/DscExamplesPresent.md
        PSDSCDscExamplesPresent                        = @{
            Enable = $true
        }

        # PSDSC: Information => https://github.com/PowerShell/PSScriptAnalyzer/blob/master/RuleDocumentation/DscTestsPresent.md
        PSDSCDscTestsPresent                           = @{
            Enable = $true
        }

        # PSDSC: Information => https://github.com/PowerShell/PSScriptAnalyzer/blob/master/RuleDocumentation/ReturnCorrectTypesForDSCFunctions.md
        PSDSCReturnCorrectTypesForDSCFunctions         = @{
            Enable = $true
        }

        # PSDSC: Information => https://github.com/PowerShell/PSScriptAnalyzer/blob/master/RuleDocumentation/UseVerboseMessageInDSCResource.md
        PSDSCUseVerboseMessageInDSCResource            = @{
            Enable = $true
        }

        # PS: Error => https://github.com/PowerShell/PSScriptAnalyzer/blob/master/RuleDocumentation/AvoidUsingUsernameAndPasswordParams.md
        PSAvoidUsingUsernameAndPasswordParams          = @{
            Enable = $true
        }

        # PS: Error => https://github.com/PowerShell/PSScriptAnalyzer/blob/master/RuleDocumentation/AvoidUsingComputerNameHardcoded.md
        PSAvoidUsingComputerNameHardcoded              = @{
            Enable = $true
        }

        # PS: Error => https://github.com/PowerShell/PSScriptAnalyzer/blob/master/RuleDocumentation/AvoidUsingConvertToSecureStringWithPlainText.md
        PSAvoidUsingConvertToSecureStringWithPlainText = @{
            Enable = $true
        }

        # PS: Error => https://github.com/PowerShell/PSScriptAnalyzer/blob/master/RuleDocumentation/UseCompatibleSyntax.md
        PSUseCompatibleSyntax                          = @{
            Enable         = $true
            TargetVersions = '7.0'
        }

        # PS: Warning => https://github.com/PowerShell/PSScriptAnalyzer/blob/master/RuleDocumentation/AvoidUsingCmdletAliases.md
        PSAvoidUsingCmdletAliases                      = @{
            Enable = $true
        }

        # PS: Warning => https://github.com/PowerShell/PSScriptAnalyzer/blob/master/RuleDocumentation/AvoidAssignmentToAutomaticVariable.md
        PSAvoidAssignmentToAutomaticVariable           = @{
            Enable = $true
        }

        # PS: Warning => https://github.com/PowerShell/PSScriptAnalyzer/blob/master/RuleDocumentation/AvoidDefaultValueSwitchParameter.md
        PSAvoidDefaultValueSwitchParameter             = @{
            Enable = $true
        }

        # PS: Warning => https://github.com/PowerShell/PSScriptAnalyzer/blob/master/RuleDocumentation/AvoidDefaultValueForMandatoryParameter.md
        PSAvoidDefaultValueForMandatoryParameter       = @{
            Enable = $true
        }

        # PS: Warning => https://github.com/PowerShell/PSScriptAnalyzer/blob/master/RuleDocumentation/AvoidUsingEmptyCatchBlock.md
        PSAvoidUsingEmptyCatchBlock                    = @{
            Enable = $true
        }

        # PS: Warning => https://github.com/PowerShell/PSScriptAnalyzer/blob/master/RuleDocumentation/AvoidGlobalAliases.md
        PSAvoidGlobalAliases                           = @{
            Enable = $true
        }

        # PS: Warning => https://github.com/PowerShell/PSScriptAnalyzer/blob/master/RuleDocumentation/AvoidGlobalFunctions.md
        PSAvoidGlobalFunctions                         = @{
            Enable = $true
        }

        # PS: Warning => https://github.com/PowerShell/PSScriptAnalyzer/blob/master/RuleDocumentation/AvoidGlobalVars.md
        PSAvoidGlobalVars                              = @{
            Enable = $true
        }

        # PS: Warning => https://github.com/PowerShell/PSScriptAnalyzer/blob/master/RuleDocumentation/AvoidInvokingEmptyMembers.md
        PSAvoidInvokingEmptyMembers                    = @{
            Enable = $true
        }

        # PS: Warning => https://github.com/PowerShell/PSScriptAnalyzer/blob/master/RuleDocumentation/AvoidLongLines.md
        PSAvoidLongLines                               = @{
            Enable            = $false
            MaximumLineLength = 120
        }

        # PS: Warning => https://github.com/PowerShell/PSScriptAnalyzer/blob/master/RuleDocumentation/AvoidNullOrEmptyHelpMessageAttribute.md
        PSAvoidNullOrEmptyHelpMessageAttribute         = @{
            Enable = $true
        }

        # PS: Warning => https://github.com/PowerShell/PSScriptAnalyzer/blob/master/RuleDocumentation/AvoidOverwritingBuiltInCmdlets.md
        PSAvoidOverwritingBuiltInCmdlets               = @{
            Enable            = $false
            PowerShellVersion = @('core-6.1.0-linux', 'core-6.1.0-windows')
        }

        # PS: Warning => https://github.com/PowerShell/PSScriptAnalyzer/blob/master/RuleDocumentation/ReservedCmdletChar.md
        PSReservedCmdletChar                           = @{
            Enable = $true
        }

        # PS: Warning => https://github.com/PowerShell/PSScriptAnalyzer/blob/master/RuleDocumentation/ReservedParams.md
        PSReservedParams                               = @{
            Enable = $true
        }

        # PS: Warning => https://github.com/PowerShell/PSScriptAnalyzer/blob/master/RuleDocumentation/AvoidShouldContinueWithoutForce.md
        PSAvoidShouldContinueWithoutForce              = @{
            Enable = $true
        }

        # PS: Warning => https://github.com/PowerShell/PSScriptAnalyzer/blob/master/RuleDocumentation/AvoidUsingDeprecatedManifestFields.md
        PSAvoidUsingDeprecatedManifestFields           = @{
            Enable = $true
        }

        # PS: Warning => https://github.com/PowerShell/PSScriptAnalyzer/blob/master/RuleDocumentation/AvoidUsingInvokeExpression.md
        PSAvoidUsingInvokeExpression                   = @{
            Enable = $true
        }

        # PS: Warning => https://github.com/PowerShell/PSScriptAnalyzer/blob/master/RuleDocumentation/AvoidUsingPlainTextForPassword.md
        PSAvoidUsingPlainTextForPassword               = @{
            Enable = $true
        }

        # PS: Warning => https://github.com/PowerShell/PSScriptAnalyzer/blob/master/RuleDocumentation/AvoidUsingWMICmdlet.md
        PSAvoidUsingWMICmdlet                          = @{
            Enable = $true
        }

        # PS: Warning => https://github.com/PowerShell/PSScriptAnalyzer/blob/master/RuleDocumentation/AvoidUsingWriteHost.md
        PSAvoidUsingWriteHost                          = @{
            Enable = $true
        }

        # PS: Warning => https://github.com/PowerShell/PSScriptAnalyzer/blob/master/RuleDocumentation/UseCompatibleCommands.md
        PSUseCompatibleCommands                        = @{
            Enable         = $false
            IgnoreCommands = @()
            TargetProfiles = @(                                # Profiles: https://github.com/PowerShell/PSScriptAnalyzer/tree/master/PSCompatibilityCollector/profiles
                'win-8_x64_10.0.17763.0_7.0.0_x64_3.1.2_core', # Pwsh 7.0 + Windows Server 2019
                'win-4_x64_10.0.18362.0_7.0.0_x64_3.1.2_core', # Pwsh 7.0 + Windows 10 1809 (RS5)
                'ubuntu_x64_18.04_7.0.0_x64_3.1.2_core'        # Pwsh 7.0 + Ubuntu 18.04 LTS
            )
            # ProfileDirPath = ''
        }

        # PS: Warning => https://github.com/PowerShell/PSScriptAnalyzer/blob/master/RuleDocumentation/UseCompatibleTypes.md
        PSUseCompatibleTypes                           = @{
            Enable         = $false
            IgnoreTypes    = @()
            TargetProfiles = @(                                # Profiles: https://github.com/PowerShell/PSScriptAnalyzer/tree/master/PSCompatibilityCollector/profiles
                'win-8_x64_10.0.17763.0_7.0.0_x64_3.1.2_core', # Pwsh 7.0 + Windows Server 2019
                'win-4_x64_10.0.18362.0_7.0.0_x64_3.1.2_core', # Pwsh 7.0 + Windows 10 1809 (RS5)
                'ubuntu_x64_18.04_7.0.0_x64_3.1.2_core'        # Pwsh 7.0 + Ubuntu 18.04 LTS
            )
            # ProfileDirPath = ''
        }

        # PS: Warning => https://github.com/PowerShell/PSScriptAnalyzer/blob/master/RuleDocumentation/MisleadingBacktick.md
        PSMisleadingBacktick                           = @{
            Enable = $true
        }

        # PS: Warning => https://github.com/PowerShell/PSScriptAnalyzer/blob/master/RuleDocumentation/MissingModuleManifestField.md
        PSMissingModuleManifestField                   = @{
            Enable = $true
        }

        # PS: Warning => https://github.com/PowerShell/PSScriptAnalyzer/blob/master/RuleDocumentation/PossibleIncorrectComparisonWithNull.md
        PSPossibleIncorrectComparisonWithNull          = @{
            Enable = $true
        }

        # PS: Warning => https://github.com/PowerShell/PSScriptAnalyzer/blob/master/RuleDocumentation/PossibleIncorrectUsageOfRedirectionOperator.md
        PSPossibleIncorrectUsageOfRedirectionOperator  = @{
            Enable = $true
        }

        # PS: Warning => https://github.com/PowerShell/PSScriptAnalyzer/blob/master/RuleDocumentation/ReviewUnusedParameter.md
        PSReviewUnusedParameter                        = @{
            Enable = $true
        }

        # PS: Warning => https://github.com/PowerShell/PSScriptAnalyzer/blob/master/RuleDocumentation/UseApprovedVerbs.md
        PSUseApprovedVerbs                             = @{
            Enable = $true
        }

        # PS: Warning => https://github.com/PowerShell/PSScriptAnalyzer/blob/master/RuleDocumentation/UseBOMForUnicodeEncodedFile.md
        PSUseBOMForUnicodeEncodedFile                  = @{
            Enable = $true
        }

        # PS: Warning => https://github.com/PowerShell/PSScriptAnalyzer/blob/master/RuleDocumentation/UseCmdletCorrectly.md
        PSUseCmdletCorrectly                           = @{
            Enable = $true
        }

        # PS: Warning => https://github.com/PowerShell/PSScriptAnalyzer/blob/master/RuleDocumentation/UseCompatibleCmdlets.md
        PSUseCompatibleCmdlets                         = @{
            Enable = $true
        }

        # PS: Warning => https://github.com/PowerShell/PSScriptAnalyzer/blob/master/RuleDocumentation/UseDeclaredVarsMoreThanAssignments.md
        PSUseDeclaredVarsMoreThanAssignments           = @{
            Enable = $true
        }

        # PS: Warning => https://github.com/PowerShell/PSScriptAnalyzer/blob/master/RuleDocumentation/UseLiteralInitializerForHashtable.md
        PSUseLiteralInitializerForHashtable            = @{
            Enable = $true
        }

        # PS: Warning => https://github.com/PowerShell/PSScriptAnalyzer/blob/master/RuleDocumentation/UseProcessBlockForPipelineCommand.md
        PSUseProcessBlockForPipelineCommand            = @{
            Enable = $true
        }

        # PS: Warning => https://github.com/PowerShell/PSScriptAnalyzer/blob/master/RuleDocumentation/UsePSCredentialType.md
        PSUsePSCredentialType                          = @{
            Enable = $true
        }

        # PS: Warning => https://github.com/PowerShell/PSScriptAnalyzer/blob/master/RuleDocumentation/ShouldProcess.md
        PSShouldProcess                                = @{
            Enable = $true
        }

        # PS: Warning => https://github.com/PowerShell/PSScriptAnalyzer/blob/master/RuleDocumentation/UseShouldProcessForStateChangingFunctions.md
        PSUseShouldProcessForStateChangingFunctions    = @{
            Enable = $true
        }

        # PS: Warning => https://github.com/PowerShell/PSScriptAnalyzer/blob/master/RuleDocumentation/UseSupportsShouldProcess.md
        PSUseSupportsShouldProcess                     = @{
            Enable = $true
        }

        # PS: Warning => https://github.com/PowerShell/PSScriptAnalyzer/blob/master/RuleDocumentation/UseToExportFieldsInManifest.md
        PSUseToExportFieldsInManifest                  = @{
            Enable = $true
        }

        # PS: Warning => https://github.com/PowerShell/PSScriptAnalyzer/blob/master/RuleDocumentation/UseUsingScopeModifierInNewRunspaces.md
        PSUseUsingScopeModifierInNewRunspaces          = @{
            Enable = $true
        }

        # PS: Warning => https://github.com/PowerShell/PSScriptAnalyzer/blob/master/RuleDocumentation/UseUTF.md
        PSUseUTF8EncodingForHelpFile                   = @{
            Enable = $true
        }

        # PS: Information => https://github.com/PowerShell/PSScriptAnalyzer/blob/master/RuleDocumentation/AvoidUsingPositionalParameters.md
        PSAvoidUsingPositionalParameters               = @{
            Enable = $true
        }

        # PS: Information => https://github.com/PowerShell/PSScriptAnalyzer/blob/master/RuleDocumentation/AvoidTrailingWhitespace.md
        PSAvoidTrailingWhitespace                      = @{
            Enable = $true
        }

        # PS: Information => https://github.com/PowerShell/PSScriptAnalyzer/blob/master/RuleDocumentation/AvoidUsingDoubleQuotesForConstantString.md
        PSAvoidUsingDoubleQuotesForConstantString      = @{
            Enable = $true
        }

        # PS: Information => https://github.com/PowerShell/PSScriptAnalyzer/blob/master/RuleDocumentation/PossibleIncorrectUsageOfAssignmentOperator.md
        PSPossibleIncorrectUsageOfAssignmentOperator   = @{
            Enable = $true
        }

        # PS: Information => https://github.com/PowerShell/PSScriptAnalyzer/blob/master/RuleDocumentation/ProvideCommentHelp.md
        PSProvideCommentHelp                           = @{
            Enable                  = $true
            ExportedOnly            = $true
            BlockComment            = $true
            VSCodeSnippetCorrection = $false
            Placement               = 'before'
        }

        # PS: Information => https://github.com/PowerShell/PSScriptAnalyzer/blob/master/RuleDocumentation/UseOutputTypeCorrectly.md
        PSUseOutputTypeCorrectly                       = @{
            Enable = $true
        }
    }
}
