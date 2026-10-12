Get this Dependabot PR ready to merge while preserving existing application behavior.

Read previous reports and current CI results first.

Investigate the release changes and how we use each dependency. Classify which updates are safe, explain the risks, and flag useful new features.

Fix mechanical problems and make necessary coordinated changes across consumers and platforms. Investigate updates that need adaptation rather than immediately excluding them. Respect deliberate pins and existing exceptions.

Validate the changes with relevant builds and tests. Where existing coverage is insufficient, establish what would give us confidence; for migrations, compare behavior before and after the update.

Keep the updates we can confidently accept. Leave out those requiring a human decision or further work, without blocking independent updates.

The harness commits your changes and posts your final response as a PR comment. Explain what changed, what was verified, and what was withheld and why. If there’s nothing new to do or report, return an empty final response; the harness skips empty responses.
