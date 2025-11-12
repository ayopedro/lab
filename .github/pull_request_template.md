## Description
<!-- Provide a summary of the changes and the motivation. Link any related issue numbers. -->

## Changes
- 
- 
- 

## Screenshots / Logs (Optional)
<!-- Add before/after visuals or relevant log excerpts. -->

## Testing
Describe how you verified the changes:
- [ ] Ran `scripts/health.sh` (passed)
- [ ] Ran `shellcheck` locally (`shellcheck $(git ls-files '*.sh')`)
- [ ] Performed dry-run of DB script if modified (`spindb -n test_db --dry-run`)
- [ ] Started docker services (`docker compose up -d`) and validated connections

## Checklist
- [ ] Updated documentation (`README.md` / `linux/README.md`) if needed
- [ ] Added/updated `.env.sample` entries (if new env vars)
- [ ] Secrets or credentials are NOT committed
- [ ] No hard-coded passwords introduced
- [ ] CI ShellCheck passes
- [ ] Commit messages follow clear convention

## Impact / Rollback
If something goes wrong, steps to revert:
1. 
2. 
3. 

## Additional Notes
<!-- Anything else reviewers should know (trade-offs, follow-ups, security concerns). -->
