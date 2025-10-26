# Release Checklist

Before pushing to the repository, complete these steps:

## Required

- [ ] **Add Screenshot**
  - Open the TodoErr app
  - Add 3-5 sample tasks (mix of completed and incomplete)
  - Take a screenshot (Cmd+Shift+4)
  - Save as `docs/screenshot.png`
  - Uncomment the screenshot line in README.md
  - Commit: `git add docs/screenshot.png README.md && git commit -m "docs: add app screenshot"`

## Optional (Recommended)

- [ ] **Test the app one final time**
  - Run `./scripts/build_and_run.sh --fast`
  - Verify all features work (add, complete, delete tasks)
  - Check that styling looks correct

- [ ] **Review commit history**
  - Run `git log --oneline -20`
  - Ensure commit messages are clear

- [ ] **Check for sensitive data**
  - Run `git status`
  - Ensure no API keys, secrets, or personal data are committed

## Ready to Push

Once the screenshot is added and everything looks good:

```bash
# Push to remote
git push origin feature/ui-improvements

# Or if pushing to main
git checkout main
git merge feature/ui-improvements
git push origin main
```

## Post-Push

- [ ] Create a GitHub release (optional)
- [ ] Update any project documentation
- [ ] Share with the team!

---

**Current Status:**
- ✅ Modern glassmorphic UI implemented
- ✅ Full LiveView functionality working
- ✅ Build scripts optimized (fast & full clean modes)
- ✅ Comprehensive documentation
- ✅ Cache busting strategy documented
- ⏳ Screenshot pending
