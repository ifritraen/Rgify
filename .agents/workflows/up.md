---
description: Build the active project, commit changes, push to origin, and release it to GitHub under the user's identity.
---
Before executing any steps, look up and read credentials from the universal sensitive storage at `C:\Users\akhla\.gemini\.agents\sensitive.md` if available.
If a credential is not defined in `sensitive.md`, check the resolved fallback profiles below.

1. **Parse Credentials & Actions**:
   Inspect the user's prompt or instruction to determine the selected credential and whether repository creation is requested:
   - **`akhlak` profile**:
     - Username: `{{AKHLAK_USERNAME}}`
     - Token/Password: `{{AKHLAK_TOKEN}}`
     - Email: `{{AKHLAK_EMAIL}}`
   - **`ifrit` profile** (Default if not specified):
     - Username: `{{IFRIT_USERNAME}}`
     - Token/Password: `{{IFRIT_TOKEN}}`
     - Email: `{{IFRIT_EMAIL}}`
   - **`create` command**:
     - If "create" is in the command, create a new GitHub repository for this project first.

2. **Configure Git & GitHub CLI Credentials**:
   Run the following commands using the resolved profile credentials:
   ```powershell
   git config user.name "<USERNAME>"
   git config user.email "<EMAIL>"
   $env:GITHUB_TOKEN="<TOKEN>"
   echo "<TOKEN>" | gh auth login --with-token
   ```

3. **Repository Creation (Optional)**:
   If "create" is requested:
   - Verify if Git is initialized. If not, run `git init` and commit initial files.
   - Create the repository via GitHub CLI:
     ```powershell
     $repoName = (Split-Path -Leaf $pwd)
     gh repo create $repoName --public --source=. --remote=origin --push
     ```
   - If the remote origin already exists or needs updating:
     ```powershell
     git remote set-url origin "https://<USERNAME>:<TOKEN>@github.com/<USERNAME>/$repoName.git"
     ```

4. **Dynamically Detect Project Type & Build (Optional)**:
   - If `pubspec.yaml` exists, run `flutter build apk --split-per-abi` or appropriate build command.
   - If `package.json` exists, run `npm run build` or appropriate build command.
   - If `gradlew` or Gradle project files exist, run `.\gradlew.bat assembleRelease` or `.\gradlew.bat assembleDebug`.

5. **Commit & Push to Main/Active Branch**:
   Stage changes and commit:
   ```powershell
   $branch = (git branch --show-current).Trim()
   if ([string]::IsNullOrEmpty($branch)) { $branch = "main" }
   git add .
   git commit -m "Auto-release update: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
   git push origin $branch
   ```

6. **Create a GitHub Release**:
   - Determine release tag and description.
   - If a build output or artifact exists (e.g. `.apk`, `.eapk`, build directory bundle), locate it and attach it to the release.
   - Run `gh release create` to publish the release:
     ```powershell
     $hash = (git rev-parse HEAD).SubString(0, 7)
     gh release create "v$hash" --title "v$hash" --notes "Release version v$hash"
     ```

7. **Output Status**:
   Report a concise summary of the successful deployment and release link to the user.
