# Introduction
The standardized VS-Code configuration used by each repository

# How to setup
Setup in target repository as a git subtree using:

#1 Setup as remote (for shorter commands)
`git remote add -f VsCode-repo https://broker2clouds@dev.azure.com/broker2clouds/CMP/_git/VsCode`

#2 Add as subtree
`git subtree add --prefix .vscode VsCode-repo master --squash`


# How to use target repository
No changes, just git as usual


# How to sync .vscode repository in target repository
Pull in target repository:
`git subtree pull --prefix .vscode VsCode-repo master --squash`



# How it works
https://www.atlassian.com/git/tutorials/git-subtree
