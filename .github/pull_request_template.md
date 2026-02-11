# Pull Request

## What does this do?

Brief description of what this PR changes or adds.

## Why?

Explain the motivation. What problem does this solve? What feature does this add?

## How to test

Clear steps to verify this works:

1.
2.
3.

## Checklist

- [ ] Tested on Niri (or Hyprland if relevant)
- [ ] Tested both `ii` and `waffle` families (if UI changes)
- [ ] Tested all three global styles: material, aurora, inir (if `ii` family changes)
- [ ] No hardcoded colors, fonts, or animation durations (use design tokens)
- [ ] Config changes synced between `Config.qml` and `defaults/config.json`
- [ ] Used optional chaining for config access (`Config.options?.section?.option ?? default`)
- [ ] IPC functions have explicit return types (`: void`, `: string`, etc.)
- [ ] Restarted shell after changes (`qs kill -c ii; qs -c ii`)
- [ ] Checked logs for errors (`qs log -c ii | tail -50`)
- [ ] Tested lazy-loaded components (Settings, overlays)
- [ ] No console errors or warnings

## Related issues

Closes #
Fixes #
Related to #

## Additional context

Screenshots, videos, or anything else relevant.
