# Turbo

F-Chat web client that goes vroom. Provides desktop-like speed and comfort thanks to the newest browser technologies. Requires a recent browser-- older ones will likely not be supported.

## Contribution Guidelines

Turbo probably needs the most help in making it look nicer without hurting the speed (so, LESS/CSS designers wanted). Turbo's goals are, in descending order:

  * Speed (both the code and getting around the app).
  * Simplicity.
  * Power User features and usability.
  * Full control using only the keyboard.

I will consider any pull request or issue/enhancement, but if it impacts one of the above, I likely won't accept it.

## Working on Turbo

You only need [node.js](https://nodejs.org/) or [io.js](https://iojs.org/en/index.html) installed. To start hacking away:

  * Clone this repo.
  * In the repo directory, do `npm install`.
  * `npm run dev` will start a development server on [http://localhost:3000](http://localhost:3000).
  * To use Turbo locally, you have to disable web security in your browser to get around a problem with F-List's login tokens. Starting Chrome with `google-chrome --disable-web-security` will do that. I've put in a bug report about the login token situation, so hopefully this won't be necessary much longer.
  * The development server has the ability to hot-swap parts of the running code as you work, so in most cases you just need to save the file, and the code/CSS will auto-update inside the running chat. This means you can change the code while you're actually chatting and see your changes work in real time. Sometimes this doesn't work, and you'll have to properly reload the app-- check your browser console for messages.
  * Code hotswapping is disabled (intentionally) for the state and connection modules.
  * Please work off the `dev` branch. The `master` branch is basically our release branch-- `master` is (hopefully) always in a working state and reasonably tested.

## License

Turbo's source code is licensed under the [AGPL v3](http://www.gnu.org/licenses/agpl-3.0.en.html).
