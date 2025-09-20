# AGENTS.md
 
## Monorepo overview
- This monorepo encapsulates what we call a `Theatre` in this context.
- We are building and deploying on the Spruce Experience Platform.
- The `Theatre` is configured based on a `Blueprint` that exists at the root level named: `blueprint.yml`.
- The `Blueprint` defines not only what `Skills` (./packages/*) are to cloned, but what their .env files should contain.
- There are also `Theatre`-wide settings in the `blueprint.yml`, keyed by `theatre` or `admin`.

## Setting up a Theatre
- The principle behind the `Theatre` and the `Blueprint` is that you should be able to clone this repo and run `yarn setup.theatre path/to/blueprint.yml` and by the time the process is done, have a fully functioning deployment.
- The script responsible for this process is `./support/setup-theatre.sh`.
- The script's capabilities are continuing to grow, but there are certain things each `Theater` must do, at minimum, to get to a functioning state:
  - Clone the skills defined in the `blueprint.yml` -> `skills` section.
  - Propogate values in the `blueprint.yml` -> `env` section to each skill's `.env` file.
  - Pull node dependencies
  - Build each skill
  - Boot Mercury (the Spruce Experience Platform backend)
  - Log in with the Spruce CLI
    - The Spruce CLI (https://cli.spruce.bot) is the command line interface that every `Theatre` and Skill Developer needs to build, run, and test the platform.
    - Logging in for this steps simply sets the session token for the CLI, so all commands run are authenticated.
  - Each `skill` is "registered" with `Mercury`. This creates a record in Mercury's database for the skill, and returns the `skillId` and `apiKey`. Those values are saved to the skill's `.env` file.
  - Then, an attempt is made to `login.skill`. This does nothing if the skills were registerd in the last step. But, if the skill was already registed, the registeration will fail and the login will succeed. This makes the setup process idempotent.
  - Next, the `publish` process is run, which sets each skill as `published` so that it's visible in the front-end, then certain skills' `canBeInstalled` is set to `true` so that they can be installed.

## Skills


## Booting a Theatre
 - 