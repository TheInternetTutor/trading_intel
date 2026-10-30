# Git Identity Configuration

Configure the intended collaborator identity in the home/global Git configuration. Replace the example values with that collaborator's own identity:

- `git config --global user.name "Your Name"`
- `git config --global user.email "you@example.com"`

Then remove any repository-local identity overrides with the project's Make rule:

`make ugu`

Verify the effective identity and where it comes from:

- `git config --show-origin --get user.name`
- `git config --show-origin --get user.email`
- `git var GIT_AUTHOR_IDENT`
- `git var GIT_COMMITTER_IDENT`

Git's local settings override global settings, which is why `make ugu` is part of setup. Do not create commits until the effective author and committer identities have been checked. Each human or AI collaborator should configure their own intended identity; do not blindly reuse another collaborator's identity.
