#!/bin/bash
elm make src/elm/Home.elm --optimize --output=public/index.js
elm make src/elm/TimeAttack.elm --optimize --output=public/TimeAttack/timeAttack.js
elm make src/elm/Translate.elm --optimize --output=public/Translate/translate.js
