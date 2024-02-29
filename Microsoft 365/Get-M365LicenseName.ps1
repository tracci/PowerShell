<#
    .SYNOPSIS
    Gets M365 license name from SKU or SKUID.
    
    .DESCRIPTION
    Provides an understandable M365 license name from SKU or SKUID.
    
    .PARAMETER License
    Accepts SKU or SKUID.
    
    .EXAMPLE
    Get-M365LicenseName -License "bba890d4-7881-4584-8102-0c3fdfb739a7"
    Get-M365LicenseName -License "M365EDU_A5_FACULTY"
   
    .NOTES
    Created on:     2023-03-29
    Created by:     tracci
    Organization:   public

    Helpful sites, though none are comprehensive:
    https://learn.microsoft.com/en-us/microsoftteams/sku-reference-edu
    https://learn.microsoft.com/en-us/azure/active-directory/enterprise-users/licensing-service-plan-reference (CSV downloadable)
    https://learn.microsoft.com/en-us/projectonline/renew-your-project-online-plans-in-a-larger-organization (MS Project specific)
    https://www.powershellgallery.com/packages/Find-LicenseName/1.1/Content/Find-LicenseName.psm1
    https://www.thelazyadministrator.com/2018/03/19/get-friendly-license-name-for-all-users-in-office-365-using-powershell/
#>

function Get-M365LicenseName {
    # This function gives an understandable name for our SKU or SKUIDs.
    [cmdletbinding()]
    Param (
        [Parameter(Mandatory = $true)]
        [string]$License
    )
    Process {
        switch ($License) {
            { ($_ -eq "bba890d4-7881-4584-8102-0c3fdfb739a7") -or ($_ -eq "DEFENDER_ENDPOINT_P1_EDU") } { "Microsoft Defender for Endpoint (Plan 1)" }
            { ($_ -eq "efccb6f7-5641-4e0e-bd10-b4976e1bf68e") -or ($_ -eq "EMS") } { "Enterprise Mobility + Security E3" }
            { ($_ -eq "98b6e773-24d4-4c0d-a968-6e787a1f8204") -or ($_ -eq "ENTERPRISEPACKPLUS_STUDENT") } { "Office 365 A3 for Students" }
            { ($_ -eq "0b7b15a8-7fd2-4964-bb96-5a566d4e3c15") -or ($_ -eq "EXCHANGEENTERPRISE_FACULTY") } { "Exchange Online (Plan 2) for Faculty" }
            { ($_ -eq "2970a0b3-301d-46e6-8ff9-a37e3ef3091b") -or ($_ -eq "EXCHANGEENTERPRISE_STUDENT") } { "Exchange Online (Plan 2) for Student" }
            { ($_ -eq "aa0f9eb7-eff2-4943-8424-226fb137fcad") -or ($_ -eq "EXCHANGESTANDARD_ALUMNI") } { "Exchange Online (Plan 1) for Alumni with Yammer" }
            { ($_ -eq "f30db892-07e9-47e9-837c-80727f46fd3d") -or ($_ -eq "FLOW_FREE") } { "Microsoft Flow Free" }
            { ($_ -eq "4a51bf65-409c-4a91-b845-1121b571cc9d") -or ($_ -eq "FLOW_PER_USER") } { "Power Automate per user plan" }
            { ($_ -eq "4b590615-0888-425a-a965-b3bf7789848d") -or ($_ -eq "M365EDU_A3_FACULTY") } { "Microsoft 365 A3 for Faculty" }
            { ($_ -eq "e97c048c-37a4-45fb-ab50-922fbf07a370") -or ($_ -eq "M365EDU_A5_FACULTY") } { "Microsoft 365 A5 for Faculty" }
            { ($_ -eq "31d57bc7-3a05-4867-ab53-97a17835a411") -or ($_ -eq "M365EDU_A5_STUUSEBNFT") } { "Microsoft 365 A5 for Students Use Benefit" }
            { ($_ -eq "c2cda955-3359-44e5-989f-852ca0cfa02f") -or ($_ -eq "MCOMEETADV_FACULTY") } { "Skype for Business PSTN Conferencing for Faculty" }
            { ($_ -eq "533b8f26-f74b-4e9c-9c59-50fc4b393b63") -or ($_ -eq "MEE_STUDENT") } { "Minecraft Education Edition Student" }
            { ($_ -eq "5560741d-469a-4afe-8ce5-676b6b86d8e2") -or ($_ -eq "MICROSOFT_REMOTE_ASSIST_FACULTY") } { "Microsoft Remote Assistant for Faculty" }
            { ($_ -eq "e6564056-c8cb-4977-a87c-45c90fe87ea9") -or ($_ -eq "OFFICE_PROPLUS_DEVICE_EDUCATION") } { "Office 365 Apps for Education (device)" }
            { ($_ -eq "12b8c807-2e20-48fc-b453-542b6ee9d171") -or ($_ -eq "OFFICESUBSCRIPTION_FACULTY") } { "Microsoft 365 Apps for Faculty" }
            { ($_ -eq "c32f9321-a627-406d-a114-1f9c81aaafac") -or ($_ -eq "OFFICESUBSCRIPTION_STUDENT") } { "Microsoft 365 Apps for Students" }
            { ($_ -eq "c05b235f-be75-4029-8851-6a4170758eef") -or ($_ -eq "PBI_PREMIUM_PER_USER_ADDON_FACULTY") } { "Power BI Premium Per User Add-On for Faculty" }
            { ($_ -eq "e2767865-c3c9-4f09-9f99-6eee6eef861a") -or ($_ -eq "POWER_BI_INDIVIDUAL_USER") } { "Power BI for Office 365 Individual" }
            { ($_ -eq "de5f128b-46d7-4cfc-b915-a89ba060ea56") -or ($_ -eq "POWER_BI_PRO_FACULTY") } { "Power BI Pro for Faculty" }
            { ($_ -eq "616d775f-ca75-42b2-8aeb-0beb1ca90b77") -or ($_ -eq "POWER_BI_PRO_STUDENT") } { "Power BI Pro for Students" }
            { ($_ -eq "ade29b5f-397e-4eb9-a287-0344bd46c68d") -or ($_ -eq "POWER_BI_STANDARD_FACULTY") } { "Power BI (free) for Faculty" }
            { ($_ -eq "bdcaf6aa-04c1-4b8f-b64e-6e3bd505ac64") -or ($_ -eq "POWER_BI_STANDARD_STUDENT") } { "Power BI (free) for Students" }
            { ($_ -eq "eda1941c-3c4f-4995-b5eb-e85a42175ab9") -or ($_ -eq "POWERAUTOMATE_ATTENDED_RPA") } { "Power Automate per user with attended RPA plan" }
            { ($_ -eq "b732e2a7-5694-4dff-a0f2-9d9204c794ac") -or ($_ -eq "PROJECTONLINE_PLAN_1_FACULTY") } { "Project Online for Faculty Plan 1" }
            { ($_ -eq "977b341b-78b3-4173-bf7e-b5a97ec06536") -or ($_ -eq "PROJECTONLINE_PLAN_1_STUDENT") } { "Project Online for Students Plan 1" }
            { ($_ -eq "930cc132-4d6b-4d8c-8818-587d17c50d56") -or ($_ -eq "PROJECTPREMIUM_FACULTY") } { "Project Online Premium Faculty" }
            { ($_ -eq "46974aed-363e-423c-9e6a-951037cec495") -or ($_ -eq "PROJECTPROFESSIONAL_FACULTY") } { "Project Online Professional Faculty" }
            { ($_ -eq "a2367322-2be4-443f-837c-06798507b89d") -or ($_ -eq "Remote_Help_AddOn") } { "N/A" }
            { ($_ -eq "8c4ce438-32a7-4ac5-91a6-e22ae08d9c8b") -or ($_ -eq "RIGHTSMANAGEMENT_ADHOC") } { "Rights Management Adhoc" }
            { ($_ -eq "60023c66-283d-4785-9334-1d4ca7fd3a18") -or ($_ -eq "RIGHTSMANAGEMENT_STANDARD_FACULTY") } { "Azure Rights Management for Faculty" }
            { ($_ -eq "ff14db38-7582-4a15-aa7d-a856f1e5c23c") -or ($_ -eq "RIGHTSMANAGEMENT_STANDARD_STUDENT") } { "Azure Rights Management for Students" }
            { ($_ -eq "94763226-9b3c-4e75-a931-5c89701abe66") -or ($_ -eq "STANDARDWOFFPACK_FACULTY") } { "Office 365 A1 for Faculty" }
            { ($_ -eq "78e66a63-337a-4a9a-8959-41c6654dfb56") -or ($_ -eq "STANDARDWOFFPACK_IW_FACULTY") } { "Office 365 A1 Plus for Faculty" }
            { ($_ -eq "e82ae690-a2d5-4d76-8d30-7c6e01e6022e") -or ($_ -eq "STANDARDWOFFPACK_IW_STUDENT") } { "Office 365 A1 Plus for Students" }
            { ($_ -eq "314c4481-f395-4525-be8b-2ec4bb1e9d91") -or ($_ -eq "STANDARDWOFFPACK_STUDENT") } { "Office 365 A1 for Students" }
            { ($_ -eq "bf95fd32-576a-4742-8d7a-6dc4940b9532") -or ($_ -eq "VISIOCLIENT_FACULTY") } { "Visio Pro for Office 365 for Faculty" }
            { ($_ -eq "640f2deb-50b1-49f6-a2c6-84adeaf67497") -or ($_ -eq "VISIOCLIENT_STUDENT") } { "Visio Pro for Office 365 for Students" }
            { ($_ -eq "1277e1cf-7be4-4a04-9af1-e7e114efaabc") -or ($_ -eq "VISIOONLINE_PLAN1_FAC") } { "Visio Online Plan 1 for Faculty" }
            { ($_ -eq "d4ef921e-840b-4b48-9a90-ab6698bc7b31") -or ($_ -eq "WIN10_ENT_A3_STU") } { "Windows 10 Enterprise A3 for students" }
            { ($_ -eq "6470687e-a428-4b7a-bef2-8a291ad947c9") -or ($_ -eq "WINDOWS_STORE") } { "Windows Store for Business" }
            Default { "N/A" }
        }
    }
}