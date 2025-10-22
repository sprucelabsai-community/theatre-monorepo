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

## Blueprint settings
- `skills`: git remotes to clone into `./packages/*`. Namespaces in this list drive templated env defaults (e.g. `{{namespace}}`).
- `admin`: currently used for the primary phone number that is granted the owner role on first boot.
- `theatre` overrides:
  - `LOCK`: URL to a `yarn.lock` that replaces the repo lockfile during setup.
  - `SHOULD_SERVE_HEARTWOOD` (default `true`): disable if Heartwood assets come from a CDN.
  - `BOOT_STRATEGY`/`BUILD_STRATEGY`: `parallel` (default) or `serial` if the host struggles with concurrent work.
  - `SERIAL_BOOT_SPACER_SEC` (default `5`): delay between skill boots when using serial booting.
  - `MERCURY_BOOT_SPACER_SEC` (default `3`): pause after Mercury boots before starting skills.
  - `CIRCLECI_TOKEN`: enables `yarn circle.status`.
  - `POST_BOOT_SCRIPT`/`POST_BUNDLE_SCRIPT`: multiline shell hooks to run after skills boot or Heartwood finishes bundling.
- `env` values are grouped by scope and merged during setup:
  - `universal`: shared defaults for every skill (DB names, Mercury host, etc.).
  - `mercury`: service-specific fields (port, anonymous/demo numbers, messaging and LLM feature toggles).
  - `heartwood`: UI server settings (port, CDN/public URLs, idle timeout, keyboard toggles).
  - Additional sections match skill namespaces (e.g. `eightbitstories`) for per-skill secrets like API keys.

## Mercury
- Mercury is the “event bus” that facilitates the communication between clients (skills, browsers, Iot, etc). When clients communicate, they are always having their events routed through Mercury. It also comes with suite of events to support some core functionality you’de expect from any foundational platform (people & role management, permissions, messages, etc).
- Every skill utilizes the `MercuryClient` for communication. It's a websocket based client that facilitates both push and pull type communication (typical event driven systems stuff). All `events` route through Mercury. One outcome of this is that skills can be indepedently upgrade, updated, and rebooted without affecting the rest of the system.

## Skills
- A Skill is a descrete piece of functionality that includes the full stack of an application. It’s a way to encapsulate a feature or set of features that can easily be deployed, installed, updated, configured, removed, etc.
- A Skill is usually one github repo.
- A Skill has "full stack" capabilities. It can both present views to the user, but also be the backend to support those views.

## Booting a Theatre
- When a Theatre boots, it must boot Mercury first, then the skills.
- Because most Skills have views that users interact with, Heartwood needs to be booted next. This is because each Skill`s views are built and registered with Heartwood at boot.
- It also is useful to boot the Theatre skill next, so people running a Theatre for development can begin interacting immediately.
- After that, skills are booted either in parallel or one-at-a-time, depending on the `blueprint.yml` -> `theatre` -> `BOOT_STRATEGY` setting.
  - `BOOT_STRATEGY` can be either `parallel` or `serial`.
  - The default is `parallel`.
  - `serial` is only needed when the host machine lacks the resources to boot all skills at once.
  - If one skill depends on another skill being fully booted first, the dependent skill may crash and be restarted over-and-over until the skill it depends on is fully booted. This is not an issue.

## Making code changes
- Never make a code change without explicit confirmation based on an implementation plan.
- Always outline all the changes that will be made into an implementation plan before making any code changes.
- Whenever a change/addition is suggested, start by outlining it to confirm your comprehension before laying out the implementation plan.
