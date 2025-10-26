# Adding a Screenshot to the README

To add a screenshot of the TodoErr app to the README:

1. **Take a screenshot of the app:**
   - Open the TodoErr desktop app
   - Add a few sample tasks
   - Take a screenshot (Cmd+Shift+4 on macOS)

2. **Save the screenshot:**
   - Save it as `screenshot.png` in the `docs/` directory
   - Recommended size: 1200px wide or similar

3. **Update the README:**
   - Uncomment the screenshot line in README.md:
   ```markdown
   ![TodoErr App Screenshot](docs/screenshot.png)
   ```

4. **Commit the screenshot:**
   ```bash
   git add docs/screenshot.png
   git commit -m "docs: add app screenshot to README"
   ```

## Screenshot Tips

- Show the app with 3-5 tasks (some completed, some not)
- Ensure the glassmorphic design is visible
- Capture the full window with the macOS title bar
- Use a clean desktop background for better contrast
