function New-AFDependencyOperation {
  param([Parameter(Mandatory)]$App,[object[]]$Before,[object[]]$Desired,
    [string]$DesiredNotes,[string]$Key,[string]$Kind='Relationships')
  [pscustomobject]@{
    Key=$Key; Kind=$Kind; SourceAppId=[string]$App.id
    SourceVersion=[string]$App.displayVersion; SourceContentVersion=[string]$App.committedContentVersion
    BeforeNotes=[string]$App.notes; DesiredNotes=$DesiredNotes
    BeforeRelationships=@($Before); DesiredRelationships=@($Desired)
    State='Planned'; Error=''
  }
}

