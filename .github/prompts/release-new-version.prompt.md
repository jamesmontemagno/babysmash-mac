---
agent: agent
---

# Release New Version

Create a new git tag for releasing a new version of BabySmash macOS.

## Task Steps

1. **Fetch existing git tags** - Run `git fetch --tags` and list all existing version tags using `git tag -l "v*"`

2. **Determine current version** - Parse the tags to find the latest version (format: v0.0.x)

3. **Suggest next version** - By default, increment the patch version by 1 (e.g., v0.0.5 → v0.0.6)

4. **Ask user for version type**:
   - Present the suggested patch version
   - Ask if the user wants a **minor** version increment instead (e.g., v0.0.5 → v0.1.0)
   - If user confirms minor, reset patch to 0 and increment minor

5. **Create the tag** - Once version is confirmed:
   - Prompt user for release notes/tag message
   - Create an annotated tag: `git tag -a <version> -m "<message>"`

6. **Push the tag** - Push to remote: `git push origin <version>`

## Success Criteria

- New version tag is created with proper format (v0.0.x or v0.x.0)
- Tag is pushed to remote repository
- Version number is higher than all existing tags
- Tag includes meaningful release notes

## Constraints

- Must follow semantic versioning format (v0.0.x)
- Must verify no tag conflicts exist before creating
- Must be on a clean working directory (or confirm with user if changes exist)