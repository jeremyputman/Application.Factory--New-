# 0.2.0
- Bug fix for leaking variable scope in Copy-AFApplicationClientGroups
- Working at removing dependency on external Intune powershell module
- Changed argumentList to -AdditionalArgumentList for MSI so it always defaults to /qn

# 0.1.15
- Added a check if ArgumentList is empty

# 0.1.14
- Implemented a cmdlet to get the applications that can filter for notes field and upload state
- Fix for test mode with the new finally block

# 0.1.13
- Added additional check for bad uploads. There is a chance for a race condition if two people are running the script at the same time.

# 0.1.10-12
- Updated 7-zip exe
- Updated ECNO functions

# 0.1.9
- Added some extra ECNO specific import logging and cleanup

# 0.1.8
- Added some missing cleanup functions

# 0.1.7
- Bug fix for version comparing
- Fix for active flag
- Added some functions to try to help with throttling.
- Bug fix for missing display name

# 0.1.6
- Modified logging functions

# 0.1.5
- Clear the script variable for Package List

# 0.1.4
- Fix for Graph Access Token Error

# 0.1.3 
- Fix for some group logic
- Fix for blank prefix
- Added filter for application Start-AFProcess so that can do a single app
- Added filter for single application to Start-AFClientProcess
- Added logic to remove applications where the upload failed
- Fixed some bugs in the logic around closing processes
- Fixed bug on exit code errors
- Added WIM support to script installer
- Lowered sleep for end conflicting process

# 0.1.2
- Removed extrenious printing of version information in Test-AFApplicationVersion

# 0.1.1
- Removed required modules as causing issue with module load

# 0.1
- Initial Build of New Application Factory module tied to new web app
- Created cmdlets to interact with the new APIs

