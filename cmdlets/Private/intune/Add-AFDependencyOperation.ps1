function Add-AFDependencyOperation {
  param($Entry,$Journal,[string]$JournalPath)
  $Journal.DependencyOperations=@($Journal.DependencyOperations)+@($Entry)
  Save-AFClientProcessJournal -Path $JournalPath -Journal $Journal
  Invoke-AFDependencyOperation -Entry $Entry -Journal $Journal -JournalPath $JournalPath
}

