enum Ensure
{
    Absent
    Present
}

enum FwProfile
{
    Domain = 1
    Private = 2
    Public = 4
}

[DscResource()]
class cFirewall
{
    [DscProperty(Key)]
    [ValidateSet("All","Domain","Private","Public")]
    [string]$Profile

    [DscProperty(Mandatory)]
    [Ensure]$Ensure

    [DscProperty(NotConfigurable)]
    [hashtable[]]$CurrentSet

    # リソースの適切な状態を設定します。
    [void] Set()
    {
        if("All" -eq $this.Profile){
            $ProfileSet = @([Enum]::GetNames([FwProfile]))
        }
        else{
            $ProfileSet = @($this.Profile)
        }
        # Set-NetFirewallProfile -Enabled ($this.Ensure -eq [Ensure]::Present) # Win7では使えないCmdlet
        $fw = New-Object -ComObject hnetcfg.fwpolicy2
        @($ProfileSet) | where {[Enum]::IsDefined([FwProfile], $_)} | foreach{
            try{
                $fw.FirewallEnabled([FwProfile]$_) = $this.Ensure
            }catch{}
        }
    }        
    
    # リソースの状態が適切かどうかをテストします。
    [bool] Test()
    {   
        if($this.Ensure -eq [Ensure]::Absent){
            return ($this.Ensure -eq $this.Get().Ensure)
        }
        else{
            return [bool]!($this.Get().CurrentSet | where {$_.Enabled -eq $false})
        }
    }

    # リソースの現在の状態を取得します。
    [cFirewall] Get()
    {
        $Ret = New-Object $this.GetType()
        $Ret.Profile = $this.Profile

        if("All" -eq $this.Profile){
            $ProfileSet = @([Enum]::GetNames([FwProfile]))
        }
        else{
            $ProfileSet = @($this.Profile)
        }

        $Ret.CurrentSet = @()
        $fw = New-Object -ComObject hnetcfg.fwpolicy2

        $Ret.Ensure = [Ensure]::Absent
        @($ProfileSet) | where {[Enum]::IsDefined([FwProfile], $_)} | foreach {
            try{
                if($fw.FirewallEnabled([FwProfile]$_)){
                    $Ret.CurrentSet += @{Profile=$_; Enabled=$true}
                    $Ret.Ensure = [Ensure]::Present
                }
                else{
                    $Ret.CurrentSet += @{Profile=$_; Enabled=$false}
                }
            }catch{}
        }
        return $Ret 
    }    
}